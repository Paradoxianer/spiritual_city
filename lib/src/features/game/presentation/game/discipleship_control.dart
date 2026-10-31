part of '../spirit_world_game.dart';

/// 🌱 Discipleship (#193): passing on the pastor's ⚔️ upgrades to
/// Christians with 📖.
extension GameDiscipleship on SpiritWorldGame {
  String? discipleBlocker(NPCModel npc, PrayerMode mode, CombatStat stat) =>
      Discipleship.blocker(npc, mode, stat,
          pastor: progress.combatProfile, learned: progress.skills, insight: progress.insight);

  /// Teaches [npc] one level of [stat] in [mode]; false when not possible.
  bool teachDisciple(NPCModel npc, PrayerMode mode, CombatStat stat) {
    if (discipleBlocker(npc, mode, stat) != null) {
      GameSound.play(Sfx.denied);
      return false;
    }
    final set = npc.discipleProfile.getFor(mode);
    progress.spendInsight(upgradeInsightCost(stat.of(set)));
    stat.raise(set);
    GameSound.play(Sfx.learned, volume: 0.7);
    return true;
  }
}

/// Lets disciples near the pastor pray along in the invisible world: each
/// sends a small wave every few seconds, taking turns with the prayer
/// modes they know.
class DisciplePrayer extends Component with HasGameReference<SpiritWorldGame> {
  final Map<String, double> _timers = {};
  final Map<String, int> _turn = {};
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
      final id = c.model.id;
      // Start out of step, so they do not all pray at the same moment.
      var t = (_timers[id] ?? _rng.nextDouble() * Discipleship.interval) + dt;
      if (t >= Discipleship.interval) {
        t = 0;
        _wave(c);
      }
      _timers[id] = t;
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
    final modes = Discipleship.praying(c.model.discipleProfile);
    if (modes.isEmpty) return;
    final i = (_turn[c.model.id] ?? 0) % modes.length;
    _turn[c.model.id] = i + 1;
    final mode = modes[i];
    final s = c.model.discipleProfile.getFor(mode);
    game.world.add(ShockwaveComponent(
      position: c.position.clone(),
      maxRadius: Discipleship.radius(s),
      strength: Discipleship.strength(s),
      duration: Discipleship.duration(s),
      speed: Discipleship.speed(s),
      color: mode.color.withValues(alpha: 0.7),
      mode: mode,
    ));
  }
}
