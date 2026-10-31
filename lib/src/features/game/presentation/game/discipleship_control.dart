part of '../spirit_world_game.dart';

/// 🌱 Discipleship (#193): teaching Christians a prayer gift with 📖.
extension GameDiscipleship on SpiritWorldGame {
  /// Teaches [npc] one step of [mode]; returns the reaction for the chat.
  String teachDisciple(NPCModel npc, PrayerMode mode) {
    final blocker = discipleBlocker(npc, mode, progress.insight, dayStats.day);
    if (blocker != null) {
      GameSound.play(Sfx.denied);
      return blocker;
    }
    progress.spendInsight(Discipleship.teachCost(npc.discipleLevel));
    npc.discipleGift = mode;
    npc.discipleLevel++;
    npc.discipleTaughtDay = dayStats.day;
    npc.currentSessionInteractions++;
    GameSound.play(Sfx.learned, volume: 0.7);
    return '🌱${mode.icon}${Discipleship.stars(npc.discipleLevel)}';
  }

  /// Disciples somewhere in the city (loaded ones).
  int get discipleCount => chunkManager.allNPCModels.where((n) => n.isDisciple).length;
}

/// Lets disciples near the pastor pray along in the invisible world: each
/// sends a small wave of its gift every few seconds.
class DisciplePrayer extends Component with HasGameReference<SpiritWorldGame> {
  final Map<String, double> _timers = {};
  final Random _rng = Random();
  List<NPCComponent> _praying = const [];
  double _scan = 0;

  /// Seconds between two looks for the nearest disciples.
  static const double _scanInterval = 0.5;

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isSpiritualWorld || game.interior != null) return;
    _scan -= dt;
    if (_scan <= 0) {
      _scan = _scanInterval;
      _praying = _nearest();
    }
    for (final c in _praying) {
      final npc = c.model;
      if (!npc.isDisciple) continue;
      // Start out of step, so they do not all pray at the same moment.
      var t = _timers[npc.id] ?? _rng.nextDouble() * Discipleship.interval(npc.discipleLevel);
      t += dt;
      if (t >= Discipleship.interval(npc.discipleLevel)) {
        t = 0;
        _wave(c);
      }
      _timers[npc.id] = t;
    }
  }

  List<NPCComponent> _nearest() {
    final me = game.player.position;
    const r2 = Discipleship.prayRange * Discipleship.prayRange;
    final near = [
      for (final c in game.chunkManager.allActiveNPCs)
        if (c.model.isDisciple && c.position.distanceToSquared(me) <= r2) c,
    ]..sort((a, b) => a.position.distanceToSquared(me).compareTo(b.position.distanceToSquared(me)));
    return near.take(Discipleship.maxPraying).toList();
  }

  void _wave(NPCComponent c) {
    final mode = c.model.discipleGift!;
    final level = c.model.discipleLevel;
    game.world.add(ShockwaveComponent(
      position: c.position.clone(),
      maxRadius: Discipleship.radius(level),
      strength: Discipleship.strength(level),
      duration: 1.0,
      speed: 70,
      color: mode.color.withValues(alpha: 0.7),
      mode: mode,
    ));
  }
}
