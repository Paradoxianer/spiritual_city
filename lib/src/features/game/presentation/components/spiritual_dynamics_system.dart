import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:logging/logging.dart';
import '../../../../core/utils/game_time.dart';
import '../../../menu/domain/models/difficulty.dart';
import '../spirit_world_game.dart';
import '../../domain/models/city_chunk.dart';
import '../../domain/models/city_cell.dart';
import '../../domain/models/cell_object.dart';
import '../../domain/models/daemon_model.dart';
import 'daemon_component.dart';
import 'cell_component.dart';

/// Implements the Game-of-Life-style spiritual dynamics for the invisible world.
///
/// Each tick (every [tickInterval] seconds, representing one "game hour"):
/// - Cells with strong spiritual state influence their neighbours
/// - Positive cells spread light; negative cells spread darkness
/// - Church cells exert a constant positive baseline
/// - Very weakly-held cells decay slightly toward neutral
///
/// Lastenheft §5.2 & §5.3
class SpiritualDynamicsSystem extends Component
    with HasGameReference<SpiritWorldGame> {
  static final _log = Logger('SpiritualDynamicsSystem');

  /// How often (in real seconds) the spiritual world updates.
  /// 60 s = one "game day" – matches [GameTime.gameDaySeconds].
  static const double tickInterval = GameTime.gameDaySeconds;

  /// Spread strength: how much a cell's state bleeds into neighbours per tick.
  static const double spreadFactor = 0.04;

  /// Natural decay toward neutral for weakly-held cells (|state| < 0.1).
  static const double decayRate = 0.98;

  /// Church passive bonus applied to the cell each tick.
  static const double churchBonus = 0.02;

  /// Fall-back rate (negative drift) for cells without neighbours or support.
  /// Reduced from 0.005 → 0.002 so liberated areas hold longer (less frustrating).
  static const double fallbackRate = 0.002;

  /// Extra negative pressure a strongly-dark cell (< [_darkBastion]) exerts
  /// on each of its neighbours that is less negative than it (boundary seepage).
  /// Reduced from 0.008 → 0.004 so darkness spreads more slowly.
  static const double darkSeepageFactor = 0.004;

  /// Threshold below which a cell is considered a "dark bastion" that seeps.
  static const double _darkBastion = -0.55;

  /// How much of a positive delta a dark bastion absorbs (resistance to light).
  /// Increased from 0.35 → 0.55 so prayer is noticeably effective on dark cells.
  static const double darkResistanceFactor = 0.55;

  double _timer = 0.0;

  // ── Continuous daemon spawning ────────────────────────────────────────────

  /// Counts up while the player is in the invisible world.
  double _continuousSpawnTimer = 0.0;

  /// Next spawn fires after this many real seconds (re-randomised on each spawn).
  double _nextSpawnInterval = 5.0;

  /// Reduced min/max spawn interval so the world feels populated but not
  /// overwhelming, especially at the start of a prayer session.
  static const double _continuousSpawnMin = 3.0; // s
  static const double _continuousSpawnMax = 12.0; // s

  // ── Daemon spawning ───────────────────────────────────────────────────────

  static const int _maxDaemonsEasy = 10;
  static const int _maxDaemonsNormal = 15;
  static const int _maxDaemonsHard = 20;

  /// Spawn chance per tick per strongly-negative region – scales with difficulty.
  static const double _daemonSpawnChanceEasy = 0.08;
  static const double _daemonSpawnChanceNormal = 0.15;
  static const double _daemonSpawnChanceHard = 0.28;

  /// Initial daemon energy by difficulty (negative; closer to 0 = weaker daemon).
  /// Tripled vs. original values so daemons persist long enough to feel threatening.
  static const double _daemonEnergyEasy = -180.0;
  static const double _daemonEnergyNormal = -300.0;
  static const double _daemonEnergyHard = -420.0;

  int _daemonIdCounter = 0;
  final math.Random _rng = math.Random(77);

  // ── Prayer-attraction state ───────────────────────────────────────────────

  /// Remaining seconds of the prayer-attraction effect.
  double _prayerAttractionTimer = 0.0;

  /// How long the prayer-attraction effect lasts (seconds).
  static const double prayerAttractionDuration = 30.0;

  /// Spawn-chance bonus while prayer attraction is active.
  /// Reduced from 0.40 → 0.20 to keep daemon pressure noticeable but not
  /// punishing during a prayer session.
  static const double prayerAttractionSpawnBonus = 0.20;

  /// True while the prayer-attraction effect is active.
  bool get isPrayerAttractionActive => _prayerAttractionTimer > 0;

  /// Activates the 30-second prayer-attraction window.
  ///
  /// Called by the player component whenever a prayer is released.
  void activatePrayerAttraction() {
    _prayerAttractionTimer = prayerAttractionDuration;
    _log.fine('Prayer attraction activated');
  }

  // Modifier support – injected by the ModifierManager
  double modifierSpreadMultiplier = 1.0; // Wachstum modifier
  double modifierDecayReduction = 0.0; // Bewahrung modifier

  @override
  void update(double dt) {
    super.update(dt);
    if (_prayerAttractionTimer > 0) {
      _prayerAttractionTimer -= dt;
      if (_prayerAttractionTimer < 0) _prayerAttractionTimer = 0;
    }
    _timer += dt;
    if (_timer >= tickInterval) {
      _timer = 0.0;
      _tick();
    }

    // ── Continuous spawn while in the invisible world ─────────────────────────
    if (game.isSpiritualWorld) {
      _continuousSpawnTimer += dt;
      if (_continuousSpawnTimer >= _nextSpawnInterval) {
        _continuousSpawnTimer = 0.0;
        _nextSpawnInterval = _continuousSpawnMin +
            _rng.nextDouble() * (_continuousSpawnMax - _continuousSpawnMin);
        _maybeContinuousSpawn();
      }
    }
  }

  void _tick() {
    final chunks = game.grid.getLoadedChunks();

    // We compute deltas first to avoid order-dependent updates.
    final Map<CityCell, double> deltas = {};

    for (final chunk in chunks) {
      for (int y = 0; y < CityChunk.chunkSize; y++) {
        for (int x = 0; x < CityChunk.chunkSize; x++) {
          final cell = chunk.cells['$x,$y'];
          if (cell == null) continue;

          double delta = 0.0;

          // 1. Neighbour influence (4-directional)
          double neighborSum = 0.0;
          int neighborCount = 0;
          int strongDarkNeighborCount = 0;
          for (final dir in _dirs) {
            final neighbor =
                game.grid.getCell(cell.x + dir[0], cell.y + dir[1]);
            if (neighbor != null) {
              neighborSum += neighbor.spiritualState;
              neighborCount++;
              if (neighbor.spiritualState < _darkBastion) {
                strongDarkNeighborCount++;
              }
            }
          }
          if (neighborCount > 0) {
            final avgNeighbor = neighborSum / neighborCount;
            // Nudge toward the average of neighbours
            delta += (avgNeighbor - cell.spiritualState) *
                spreadFactor *
                modifierSpreadMultiplier;
          }

          // 1b. Dark seepage: each strongly-dark neighbour pushes the cell
          //     a little more negative, regardless of the neighbour average.
          //     This makes darkness slowly seep into border areas.
          if (strongDarkNeighborCount > 0) {
            delta -= strongDarkNeighborCount * darkSeepageFactor;
          }

          // 2. Church cells act as anchors of positivity
          if (cell.data is BuildingData) {
            final bData = cell.data as BuildingData;
            if (bData.type == BuildingType.church ||
                bData.type == BuildingType.cathedral) {
              delta += churchBonus;
            }
          }

          // 3. Natural fallback – areas not actively supported drift negative
          //    (represents ongoing spiritual "pressure" in a fallen world)
          if (cell.spiritualState > -0.05) {
            delta -= fallbackRate * (1.0 - modifierDecayReduction);
          }

          // 4. Decay toward neutral for very weakly-held cells
          if (cell.spiritualState.abs() < 0.08) {
            delta += -cell.spiritualState * (1.0 - decayRate);
          }

          deltas[cell] = delta;
        }
      }
    }

    // Apply all deltas at once
    int updates = 0;
    for (final entry in deltas.entries) {
      var d = entry.value;

      // Resistance: dark bastions are hard to push back toward the light.
      // Only the positive component of the delta is reduced.
      if (entry.key.spiritualState < _darkBastion && d > 0) {
        d *= darkResistanceFactor;
      }

      final newState = (entry.key.spiritualState + d).clamp(-1.0, 1.0);
      if ((newState - entry.key.spiritualState).abs() > 1e-6) {
        entry.key.spiritualState = newState;
        updates++;
      }
    }

    _log.fine('Spiritual tick: $updates cells updated');

    // Spawn daemons in strongly negative regions
    _maybeSpawnDaemons(chunks);
  }

  void _maybeSpawnDaemons(List<CityChunk> chunks) {
    // Difficulty-scaled daemon cap, then adapted to player progression.
    final baseMaxDaemons = switch (game.difficulty) {
      Difficulty.easy => _maxDaemonsEasy,
      Difficulty.normal => _maxDaemonsNormal,
      Difficulty.hard => _maxDaemonsHard,
    };
    final progressionScale = _daemonProgressionScale();
    final maxDaemons =
        ((baseMaxDaemons * progressionScale).round().clamp(4, 32)).toInt();

    int existingDaemons =
        game.world.children.whereType<DaemonComponent>().length;
    if (existingDaemons >= maxDaemons) return;

    // Difficulty-scaled base spawn chance.
    final baseChance = switch (game.difficulty) {
      Difficulty.easy => _daemonSpawnChanceEasy,
      Difficulty.normal => _daemonSpawnChanceNormal,
      Difficulty.hard => _daemonSpawnChanceHard,
    };
    final scaledBaseChance = (baseChance * progressionScale).clamp(0.04, 0.45);

    // Spawn chance boosted when the player has recently prayed (Issue #31)
    final spawnChance = isPrayerAttractionActive
        ? scaledBaseChance * (1 + prayerAttractionSpawnBonus)
        : scaledBaseChance;

    outer:
    for (final chunk in chunks) {
      for (int y = 0; y < CityChunk.chunkSize; y += 4) {
        for (int x = 0; x < CityChunk.chunkSize; x += 4) {
          if (existingDaemons >= maxDaemons) break outer;
          final cell = chunk.cells['$x,$y'];
          if (cell == null) continue;
          if (cell.spiritualState < -0.8 && _rng.nextDouble() < spawnChance) {
            _spawnDaemon(cell);
            existingDaemons++;
          }
        }
      }
    }
  }

  void _spawnDaemon(CityCell cell) {
    final id = 'daemon_${_daemonIdCounter++}';
    final spawnPos = Vector2(
      cell.x * CellComponent.cellSize + CellComponent.cellSize / 2,
      cell.y * CellComponent.cellSize + CellComponent.cellSize / 2,
    );
    final model =
        DaemonModel(id: id, position: spawnPos, energy: _initialEnergy());
    final component = DaemonComponent(model);
    game.world.add(component);
    _log.fine('Spawned daemon $id at (${cell.x}, ${cell.y})');
  }

  /// Spawns a single daemon near the player, weighted by cell darkness.
  ///
  /// Called every [_nextSpawnInterval] seconds while the player is in the
  /// invisible world.  Dark cells (state < −0.3) are preferred so daemons
  /// tend to emerge from shadow rather than light.
  void _maybeContinuousSpawn() {
    final baseMaxDaemons = switch (game.difficulty) {
      Difficulty.easy => _maxDaemonsEasy,
      Difficulty.normal => _maxDaemonsNormal,
      Difficulty.hard => _maxDaemonsHard,
    };
    final maxDaemons =
        ((baseMaxDaemons * _daemonProgressionScale()).round().clamp(4, 32))
            .toInt();
    if (game.world.children.whereType<DaemonComponent>().length >= maxDaemons) {
      return;
    }

    final playerPos = game.player.position;
    final pgx = (playerPos.x / CellComponent.cellSize).floor();
    final pgy = (playerPos.y / CellComponent.cellSize).floor();

    // Collect candidate cells weighted by darkness within a 20-cell radius.
    final List<CityCell> candidates = [];
    final List<double> weights = [];
    const int searchR = 20;

    for (int dy = -searchR; dy <= searchR; dy += 2) {
      for (int dx = -searchR; dx <= searchR; dx += 2) {
        if (dx * dx + dy * dy > searchR * searchR) continue;
        final cell = game.grid.getCell(pgx + dx, pgy + dy);
        if (cell == null) continue;
        if (cell.spiritualState < -0.3) {
          candidates.add(cell);
          weights.add(-cell.spiritualState); // darker → higher weight
        }
      }
    }

    if (candidates.isEmpty) return;

    // Weighted random pick.
    double totalWeight = weights.fold(0.0, (a, b) => a + b);
    double pick = _rng.nextDouble() * totalWeight;
    CityCell chosen = candidates.last;
    for (int i = 0; i < candidates.length; i++) {
      pick -= weights[i];
      if (pick <= 0) {
        chosen = candidates[i];
        break;
      }
    }

    _spawnDaemon(chosen);
    _log.fine('Continuous spawn at (${chosen.x}, ${chosen.y})');
  }

  /// Returns difficulty-scaled initial energy for a newly spawned daemon.
  double _initialEnergy() => switch (game.difficulty) {
        Difficulty.easy => _daemonEnergyEasy * _daemonProgressionScale(),
        Difficulty.normal => _daemonEnergyNormal * _daemonProgressionScale(),
        Difficulty.hard => _daemonEnergyHard * _daemonProgressionScale(),
      };

  /// Spawns [count] daemons in a random ring (100–300 px) around the player.
  ///
  /// Called when the player enters the invisible world so that daemons are
  /// immediately visible rather than waiting for the next tick.
  void spawnDaemonsAroundPlayer(int count) {
    final playerPos = game.player.position;
    const double minDist = 100.0;
    const double maxDist = 300.0;
    final energy = _initialEnergy();

    final effectiveCount =
        ((count * _daemonProgressionScale()).round().clamp(1, 12)).toInt();

    for (int i = 0; i < effectiveCount; i++) {
      // Spread daemons evenly around the player (+ small random jitter)
      final baseAngle = (i / effectiveCount) * math.pi * 2;
      final angle =
          baseAngle + (_rng.nextDouble() - 0.5) * (math.pi / effectiveCount);
      final dist = minDist + _rng.nextDouble() * (maxDist - minDist);

      final spawnPos = Vector2(
        playerPos.x + math.cos(angle) * dist,
        playerPos.y + math.sin(angle) * dist,
      );

      final id = 'daemon_entry_${_daemonIdCounter++}';
      final model = DaemonModel(id: id, position: spawnPos, energy: energy);
      final component = DaemonComponent(model);
      game.world.add(component);
      _log.fine('Entry-spawned daemon $id around player');
    }
  }

  double _daemonProgressionScale() {
    final entries = game.progress.spiritualWorldEntries.toDouble();
    final entryPressure = (entries * 0.07).clamp(0.0, 1.2);
    final profile = game.progress.combatProfile;
    var totalUpgradeLevels = profile.shieldLevel + profile.helmLevel;
    for (final set in profile.modes.values) {
      totalUpgradeLevels += set.radiusLevel +
          set.strengthLevel +
          set.durationLevel +
          set.speedLevel;
    }
    final upgradePower =
        (totalUpgradeLevels.toDouble() * 0.025).clamp(0.0, 0.7);
    return (1.0 + entryPressure - upgradePower).clamp(0.8, 2.0);
  }

  static const List<List<int>> _dirs = [
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1],
  ];
}
