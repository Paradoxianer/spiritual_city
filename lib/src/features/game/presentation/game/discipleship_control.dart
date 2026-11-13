part of '../spirit_world_game.dart';

/// 🌱 Discipleship (#193): passing on the pastor's ⚔️ upgrades to
/// Christians with 📖.
extension GameDiscipleship on SpiritWorldGame {
  String? discipleBlocker(NPCModel npc, PrayerMode mode, CombatStat stat) =>
      Discipleship.blocker(npc, mode, stat,
          pastor: progress.combatProfile, learned: progress.skills, insight: progress.insight);

  /// 📢🎺 An open-air meeting calls the disciples around [at] together:
  /// they come and stay with the pastor as a prayer circle. Returns how
  /// many came.
  int gatherDisciples(Vector2 at) {
    const r2 = Discipleship.gatherRadius * Discipleship.gatherRadius;
    var n = 0;
    for (final c in chunkManager.allActiveNPCs) {
      if (!c.model.isDisciple || c.model.isShakenChristian) continue; // ✝️💔 needs care first
      if (c.position.distanceToSquared(at) > r2) continue;
      c.gatherLeft = Discipleship.gatherSeconds;
      n++;
    }
    return n;
  }

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

/// Lets disciples near the pastor pray along in the invisible world, each
/// with the one mode the pastor built up most in them. On their own every
/// few seconds; gathered by an open-air meeting, together with each of the
/// pastor's waves.
class DisciplePrayer extends Component with HasGameReference<SpiritWorldGame> {
  final Map<String, double> _timers = {};
  final Map<String, double> _lastChorus = {};
  final Random _rng = Random();
  List<NPCComponent> _praying = const [];
  double _scan = 0;
  double _clock = 0;

  /// Seconds between two looks for the nearest disciples.
  static const double _scanInterval = 0.5;

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
    if (!game.isSpiritualWorld || game.interior != null) return;
    _scan -= dt;
    if (_scan <= 0) {
      _scan = _scanInterval;
      _praying = _nearest();
    }
    for (final c in _praying) {
      if (c.isGathered) continue; // they pray with the pastor
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

  /// The pastor just sent a wave: the gathered disciples pray with it.
  void joinPastorWave() {
    for (final c in game.chunkManager.allActiveNPCs) {
      if (!c.isGathered || !c.model.isDisciple || c.model.isShakenChristian) continue;
      final last = _lastChorus[c.model.id] ?? -999;
      if (_clock - last < Discipleship.chorusInterval) continue;
      _lastChorus[c.model.id] = _clock;
      _wave(c, factor: Discipleship.chorusFactor);
    }
  }

  /// Gathered disciples, then the nearest others up to the limit.
  List<NPCComponent> _nearest() {
    final me = game.player.position;
    const r2 = Discipleship.prayRange * Discipleship.prayRange;
    final near = [
      for (final c in game.chunkManager.allActiveNPCs)
        if (c.model.isDisciple &&
            !c.model.isShakenChristian &&
            !c.isGathered &&
            c.position.distanceToSquared(me) <= r2)
          c,
    ]..sort((a, b) => a.position.distanceToSquared(me).compareTo(b.position.distanceToSquared(me)));
    return near.take(Discipleship.maxPraying).toList();
  }

  void _wave(NPCComponent c, {double factor = 1.0}) {
    final mode = Discipleship.strongest(c.model.discipleProfile);
    if (mode == null) return;
    final s = c.model.discipleProfile.getFor(mode);
    game.world.add(ShockwaveComponent(
      position: c.position.clone(),
      maxRadius: Discipleship.radius(s),
      strength: Discipleship.strength(s) * factor,
      duration: Discipleship.duration(s),
      speed: Discipleship.speed(s),
      color: mode.color.withValues(alpha: 0.7),
      mode: mode,
      source: 'disciple:${c.model.id}',
    ));
  }
}
