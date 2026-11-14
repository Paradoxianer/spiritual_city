import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:logging/logging.dart';
import '../../../../core/utils/game_time.dart';
import '../../../menu/domain/models/difficulty.dart';
import '../spirit_world_game.dart';
import '../../domain/models/city_chunk.dart';
import '../../domain/models/city_cell.dart';
import '../../domain/models/daemon_kind.dart';
import '../../domain/models/daemon_model.dart';
import '../../domain/services/world_simulation.dart';
import '../../domain/services/daemon_combat_rules.dart';
import '../../domain/services/spirit_waves.dart';
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
class SpiritualDynamicsSystem extends Component with HasGameReference<SpiritWorldGame> {
  static final _log = Logger('SpiritualDynamicsSystem');

  /// How often (in real seconds) the spiritual world updates.
  /// 60 s = one "game day" – matches [GameTime.gameDaySeconds].
  static const double tickInterval = GameTime.gameDaySeconds;

  // The rules of the ground, people and houses live in WorldSimulation
  // (domain, #194); this component only runs the day and spawns daemons.

  double _timer = 0.0;

  /// Counts up while the player is in the invisible world.
  double _continuousSpawnTimer = 0.0;

  /// Next daemon of a wave after this many real seconds (re-randomised on
  /// each spawn).
  double _nextSpawnInterval = SpiritWaves.spawnMax;

  /// How often the tutorial looks whether its daemon got away.
  static const double _continuousSpawnMin = 3.0; // s

  // ── Daemon spawning ───────────────────────────────────────────────────────

  static const int _maxDaemonsEasy   = 10;
  static const int _maxDaemonsNormal = 15;
  static const int _maxDaemonsHard   = 20;

  /// Spawn chance per tick per strongly-negative region – scales with difficulty.
  static const double _daemonSpawnChanceEasy   = 0.08;
  static const double _daemonSpawnChanceNormal = 0.15;
  static const double _daemonSpawnChanceHard   = 0.28;

  /// Initial daemon energy by difficulty (negative; closer to 0 = weaker daemon).
  /// Tripled vs. original values so daemons persist long enough to feel threatening.
  static const double _daemonEnergyEasy   = -180.0;
  static const double _daemonEnergyNormal = -300.0;
  static const double _daemonEnergyHard   = -420.0;

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
  double modifierSpreadMultiplier = 1.0;  // Wachstum modifier
  double modifierDecayReduction = 0.0;    // Bewahrung modifier

  @override
  void update(double dt) {
    super.update(dt);
    if (_prayerAttractionTimer > 0) {
      _prayerAttractionTimer -= dt;
      if (_prayerAttractionTimer < 0) _prayerAttractionTimer = 0;
    }
    _continueDay();
    game.continueCatchUp();
    _timer += dt;
    if (_timer >= tickInterval) {
      _timer = 0.0;
      _tick();
    }

    // ── In the invisible world: the tutorial daemon, or the 🌊 waves ─────────
    if (game.isSpiritualWorld) {
      if (game.tutorialCalmSpirit) {
        _continuousSpawnTimer += dt;
        if (_continuousSpawnTimer >= _continuousSpawnMin) {
          _continuousSpawnTimer = 0.0;
          _keepTutorialDaemon();
        }
      } else {
        _updateWaves(dt);
      }
    }
  }

  // ── 🌊 Waves (playtest 2026-11-14, SpiritWaves) ───────────────────────────

  /// The waves of this visit to the invisible world.
  final SpiritWaves waves = SpiritWaves();

  /// Seconds until the next look whether the wave is beaten.
  double _waveCheck = 0.0;

  /// On entering: 🌊1, [entry] of its daemons appear around the pastor at
  /// once. Daemons left from an earlier visit belong to no wave any more.
  void startWaves(int entry) {
    for (final d in game.world.children.whereType<DaemonComponent>()) {
      d.model.wave = 0;
    }
    waves.start(_rng);
    final n = math.min(entry, SpiritWaves.size(1, game.difficulty));
    spawnDaemonsAroundPlayer(n, wave: 1);
    waves.spawned = n;
    _continuousSpawnTimer = 0.0;
  }

  void _updateWaves(double dt) {
    if (waves.pause > 0) {
      waves.pause -= dt;
      if (waves.pause <= 0) game.onWaveStarted(waves.wave);
      return;
    }
    if (!waves.spawnedAll(game.difficulty)) {
      _continuousSpawnTimer += dt;
      if (_continuousSpawnTimer >= _nextSpawnInterval) {
        _continuousSpawnTimer = 0.0;
        _nextSpawnInterval =
            SpiritWaves.spawnMin + _rng.nextDouble() * (SpiritWaves.spawnMax - SpiritWaves.spawnMin);
        _spawnWaveDaemon();
      }
      return;
    }
    // All of it is out: beaten once none of it is left.
    _waveCheck -= dt;
    if (_waveCheck > 0) return;
    _waveCheck = 0.5;
    final left = game.world.children
        .whereType<DaemonComponent>()
        .any((d) => d.model.wave == waves.wave && !d.model.dissolved);
    if (left) return;
    final beaten = waves.wave;
    waves.cleared(_rng);
    game.onWaveCleared(beaten);
  }

  int get _maxDaemons => switch (game.difficulty) {
        Difficulty.easy => _maxDaemonsEasy,
        Difficulty.normal => _maxDaemonsNormal,
        Difficulty.hard => _maxDaemonsHard,
      };

  /// One more daemon of the running wave – out of the dark near the
  /// pastor, or (all green around) from somewhere around them.
  void _spawnWaveDaemon() {
    if (game.world.children.whereType<DaemonComponent>().length >= _maxDaemons) return;
    final cell = _darkCellNearPlayer();
    final Vector2 pos;
    if (cell != null) {
      pos = Vector2(
        cell.x * CellComponent.cellSize + CellComponent.cellSize / 2,
        cell.y * CellComponent.cellSize + CellComponent.cellSize / 2,
      );
    } else {
      final p = game.player.position;
      final a = _rng.nextDouble() * math.pi * 2;
      final d = 200.0 + _rng.nextDouble() * 120.0;
      pos = Vector2(p.x + math.cos(a) * d, p.y + math.sin(a) * d);
    }
    final id = 'daemon_wave_${_daemonIdCounter++}';
    game.world.add(DaemonComponent(_newDaemon(id, pos,
        kind: waves.kinds[_rng.nextInt(waves.kinds.length)], wave: waves.wave)));
    waves.spawned++;
  }

  /// The day being simulated, a few chunks per frame.
  WorldDay? _day;

  /// Chunks of the ground simulated per frame (≈ 1–2 ms on a phone).
  static const int _chunksPerFrame = 24;

  /// One day of the invisible world for everything generated so far –
  /// near the pastor or not (#194, rules in [WorldSimulation]). Started
  /// here, finished over the next frames in [_continueDay].
  void _tick() {
    _day?.step(1 << 30); // a day still running finishes first
    game.worldDay++;
    _day = WorldDay(
      game.grid,
      chunks: game.grid.getLoadedChunks(),
      residents: game.residents(),
      anchors: game.houseAnchors(),
      tuning: game.worldTuning,
    );
    if (!game.tutorialCalmSpirit) _maybeSpawnDaemons(game.grid.getLoadedChunks());
  }

  void _continueDay() {
    final day = _day;
    if (day == null) return;
    if (day.step(_chunksPerFrame)) _day = null;
  }

  void _maybeSpawnDaemons(List<CityChunk> chunks) {
    // Difficulty-scaled daemon cap
    final maxDaemons = switch (game.difficulty) {
      Difficulty.easy   => _maxDaemonsEasy,
      Difficulty.normal => _maxDaemonsNormal,
      Difficulty.hard   => _maxDaemonsHard,
    };

    int existingDaemons = game.world.children.whereType<DaemonComponent>().length;
    if (existingDaemons >= maxDaemons) return;

    // Difficulty-scaled base spawn chance
    final baseChance = switch (game.difficulty) {
      Difficulty.easy   => _daemonSpawnChanceEasy,
      Difficulty.normal => _daemonSpawnChanceNormal,
      Difficulty.hard   => _daemonSpawnChanceHard,
    };

    // Spawn chance boosted when the player has recently prayed (Issue #31)
    final spawnChance = isPrayerAttractionActive
        ? baseChance * (1 + prayerAttractionSpawnBonus)
        : baseChance;

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
    game.world.add(DaemonComponent(_newDaemon(id, spawnPos)));
    _log.fine('Spawned daemon $id at (${cell.x}, ${cell.y})');
  }

  /// A dark cell near the player, picked weighted by darkness (null when
  /// all is light around). Dark cells (state < −0.3) are preferred so
  /// daemons emerge from shadow rather than light.
  CityCell? _darkCellNearPlayer() {
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

    if (candidates.isEmpty) return null;

    // Weighted random pick.
    double totalWeight = weights.fold(0.0, (a, b) => a + b);
    double pick = _rng.nextDouble() * totalWeight;
    for (int i = 0; i < candidates.length; i++) {
      pick -= weights[i];
      if (pick <= 0) return candidates[i];
    }
    return candidates.last;
  }

  /// Returns difficulty-scaled initial energy for a newly spawned daemon.
  double _initialEnergy() => switch (game.difficulty) {
    Difficulty.easy   => _daemonEnergyEasy,
    Difficulty.normal => _daemonEnergyNormal,
    Difficulty.hard   => _daemonEnergyHard,
  };

  /// A new daemon of a random kind (#178). Its tier follows the player's
  /// grace-delayed power; one in four spawns is a tier weaker, so a fight
  /// always mixes strengths a little.
  /// A daemon of a 🌊 [wave] is stronger the later the wave.
  DaemonModel _newDaemon(String id, Vector2 position, {DaemonKind? kind, String? host, int wave = 0}) {
    final k = kind ?? DaemonKind.randomSpawn(_rng);
    var tier = game.daemonTier;
    if (tier > 1 && _rng.nextDouble() < 0.25) tier--;
    return DaemonModel(
      id: id,
      position: position,
      energy: _initialEnergy() *
          k.energyFactor *
          DaemonCombatRules.tierEnergy(tier) *
          (wave > 0 ? SpiritWaves.energy(wave) : 1.0),
      kind: k,
      tier: tier,
      hostNpcId: host,
      wave: wave,
    );
  }

  /// The first fight in the tutorial (playtest 2026-10-19): one slow 🪨
  /// with little energy instead of a swarm, so a new player can learn to
  /// hold ✝️ and hit it.
  void spawnTutorialDaemon() {
    final p = game.player.position;
    final a = _rng.nextDouble() * math.pi * 2;
    final pos = Vector2(p.x + math.cos(a) * 170, p.y + math.sin(a) * 170);
    game.world.add(DaemonComponent(DaemonModel(
      id: 'daemon_tutorial_${_daemonIdCounter++}',
      position: pos,
      energy: _initialEnergy() * 0.3,
      kind: DaemonKind.brute,
    )));
  }

  /// While the tutorial fight is due, a new one appears if it got away.
  void _keepTutorialDaemon() {
    if (game.world.children.whereType<DaemonComponent>().isEmpty) spawnTutorialDaemon();
  }

  /// Spawns a stronghold guard of [kind] at [position] (#125).
  void spawnGuard(Vector2 position, DaemonKind kind) {
    final id = 'daemon_guard_${_daemonIdCounter++}';
    game.world.add(DaemonComponent(_newDaemon(id, position.clone(), kind: kind)));
  }

  /// Spawns a 👁️ possessor at [position] that belongs to the possessed NPC
  /// [hostNpcId] (npc_influence.md).
  void spawnPossessor(Vector2 position, String hostNpcId) {
    final id = 'daemon_host_${_daemonIdCounter++}';
    game.world.add(DaemonComponent(
        _newDaemon(id, position.clone(), kind: DaemonKind.possessor, host: hostNpcId)));
  }

  /// Spawns [count] daemons in a random ring (100–300 px) around the player.
  ///
  /// Called when the player enters the invisible world so that daemons are
  /// immediately visible rather than waiting for the next tick.
  void spawnDaemonsAroundPlayer(int count, {int wave = 0}) {
    final playerPos = game.player.position;
    const double minDist = 100.0;
    const double maxDist = 300.0;
    for (int i = 0; i < count; i++) {
      // Spread daemons evenly around the player (+ small random jitter)
      final baseAngle = (i / count) * math.pi * 2;
      final angle = baseAngle + (_rng.nextDouble() - 0.5) * (math.pi / count);
      final dist = minDist + _rng.nextDouble() * (maxDist - minDist);

      final spawnPos = Vector2(
        playerPos.x + math.cos(angle) * dist,
        playerPos.y + math.sin(angle) * dist,
      );

      final id = 'daemon_entry_${_daemonIdCounter++}';
      game.world.add(DaemonComponent(_newDaemon(id, spawnPos, wave: wave)));
      _log.fine('Entry-spawned daemon $id around player');
    }
  }

}
