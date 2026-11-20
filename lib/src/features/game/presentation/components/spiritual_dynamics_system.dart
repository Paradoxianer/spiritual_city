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

  /// Counts up while the tutorial fight runs in the invisible world.
  double _continuousSpawnTimer = 0.0;

  /// How often the tutorial looks whether its daemon got away.
  static const double _tutorialCheck = 3.0; // s

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
        if (_continuousSpawnTimer >= _tutorialCheck) {
          _continuousSpawnTimer = 0.0;
          _keepTutorialDaemon();
        }
      } else {
        _updateWaves(dt);
      }
    }
  }

  // ── 🌊 Waves (playtest 2026-11-15, SpiritWaves) ───────────────────────────

  /// The waves of this visit to the invisible world.
  final SpiritWaves waves = SpiritWaves();

  /// Seconds until the next look at what is left of the wave.
  double _waveCheck = 0.0;

  /// On entering: 🌊1 comes at once. Daemons left from earlier belong to
  /// no wave.
  void startWaves() {
    for (final d in game.world.children.whereType<DaemonComponent>()) {
      d.model.wave = 0;
    }
    waves.start(game.difficulty, _rng);
    _spawnWave();
    _waveCheck = 0.0;
  }

  /// Leaving: the waves end; the next visit starts at 🌊1.
  void endWaves() {
    waves.current = const [];
    game.waveStatus.value = null;
  }

  void _updateWaves(double dt) {
    // The tutorial fight just ended inside: the waves begin.
    if (waves.current.isEmpty) return startWaves();
    if (waves.pause > 0) {
      final before = waves.pause.ceil();
      waves.pause -= dt;
      if (waves.pause <= 0) {
        waves.pause = 0;
        _spawnWave();
        game.onWaveStarted(waves.wave);
      } else if (waves.pause.ceil() != before) {
        _publish(0);
      }
      return;
    }
    _waveCheck -= dt;
    if (_waveCheck > 0) return;
    _waveCheck = 0.5;
    final left = game.world.children
        .whereType<DaemonComponent>()
        .where((d) => d.model.wave == waves.wave && !d.model.dissolved)
        .length;
    if (left > 0) {
      _publish(left);
      return;
    }
    final beaten = waves.wave;
    waves.cleared(game.difficulty, _rng);
    _publish(0);
    game.onWaveCleared(beaten);
  }

  /// Tapping the 🌊 badge (playtest 2026-11-20): in the pause the wave
  /// comes at once; while one runs, the next comes now – what is left of
  /// the skipped one stays and its breakthrough and 📖
  /// are forfeit.
  void callNextWave() {
    if (waves.current.isEmpty) return;
    if (waves.pause > 0) {
      waves.pause = 0.001; // spawned on the next update
      return;
    }
    // The left-overs keep their wave (and strength) but no longer count.
    waves.cleared(game.difficulty, _rng);
    waves.pause = 0;
    _spawnWave();
    game.onWaveStarted(waves.wave);
    _waveCheck = 0.0;
  }

  /// Tells the HUD: while a wave runs the next one is the preview, in the
  /// pause the one coming.
  void _publish(int left) {
    final pausing = waves.pause > 0;
    game.waveStatus.value = WaveStatus(
      waves.wave,
      left,
      waves.current.length,
      pausing ? waves.current : waves.next,
      pausing ? waves.pause.ceil() : 0,
    );
  }

  /// All daemons of the wave at once, spread around the pastor.
  void _spawnWave() {
    final p = game.player.position;
    final n = waves.current.length;
    final turn = _rng.nextDouble() * math.pi * 2;
    for (var i = 0; i < n; i++) {
      final a = turn + i / n * math.pi * 2;
      final d = 220.0 + _rng.nextDouble() * 100.0;
      final pos = Vector2(p.x + math.cos(a) * d, p.y + math.sin(a) * d);
      final id = 'daemon_wave_${_daemonIdCounter++}';
      game.world.add(DaemonComponent(
          _newDaemon(id, pos, kind: waves.current[i], wave: waves.wave)));
    }
    _publish(n);
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
      chunks: game.cityChunks,
      residents: game.residents(),
      anchors: game.houseAnchors(),
      tuning: game.worldTuning,
    );
    // During the 🌊 waves nothing comes from outside – only the wave.
    if (!game.tutorialCalmSpirit && !game.isSpiritualWorld) {
      _maybeSpawnDaemons(game.cityChunks);
    }
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

  /// Returns difficulty-scaled initial energy for a newly spawned daemon.
  double _initialEnergy() => switch (game.difficulty) {
    Difficulty.easy   => _daemonEnergyEasy,
    Difficulty.normal => _daemonEnergyNormal,
    Difficulty.hard   => _daemonEnergyHard,
  };

  /// A new daemon of a random kind (#178). Its tier follows the player's
  /// grace-delayed power; one in four spawns is a tier weaker, so a fight
  /// always mixes strengths a little.
  /// A daemon of a 🌊 [wave] is weaker in the first waves, stronger later.
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
}
