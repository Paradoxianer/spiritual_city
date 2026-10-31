import 'npc_model.dart';
import 'prayer_combat.dart';
import 'skills.dart';
import '../services/combat_abilities.dart';

/// One of the four upgrades of a prayer mode (as in the ⚔️ panel).
enum CombatStat {
  radius('🎯'),
  strength('⚡'),
  duration('⏱️'),
  speed('💨');

  final String emoji;
  const CombatStat(this.emoji);

  int of(CombatModifierSet s) => switch (this) {
        radius => s.radiusLevel,
        strength => s.strengthLevel,
        duration => s.durationLevel,
        speed => s.speedLevel,
      };

  double valueOf(CombatModifierSet s) => switch (this) {
        radius => s.radius,
        strength => s.strength,
        duration => s.duration,
        speed => s.speed,
      };

  void raise(CombatModifierSet s) => switch (this) {
        radius => s.radiusLevel++,
        strength => s.strengthLevel++,
        duration => s.durationLevel++,
        speed => s.speedLevel++,
      };
}

/// 🌱 Discipleship (#193, playtests 2026-10-31): the pastor passes on to
/// Christians what they have learned themselves – the same ⚔️ upgrades,
/// paid with 📖, but never beyond the pastor's own level ("what you have
/// heard from me … entrust to faithful people", 2 Tim 2:2). In the
/// invisible world a disciple near the pastor prays along with small waves
/// of what they know. Possible in every neighbourhood.
abstract final class Discipleship {
  /// Prayer modes the pastor can pass on: only what they can pray.
  static List<PrayerMode> teachable(LearnedSkills learned) =>
      [for (final m in PrayerMode.values) if (CombatAbilities.canUse(m, learned)) m];

  /// Modes a disciple prays (any upgrade in it).
  static List<PrayerMode> praying(CombatProfile p) =>
      [for (final m in PrayerMode.values) if (CombatAbilities.modeLevel(p.getFor(m)) > 0) m];

  /// Total of all upgrades (ring thickness).
  static int totalLevel(CombatProfile p) =>
      PrayerMode.values.fold(0, (sum, m) => sum + CombatAbilities.modeLevel(p.getFor(m)));

  /// Why [stat] of [mode] cannot be taught to [npc] now (emoji), or null.
  static String? blocker(
    NPCModel npc,
    PrayerMode mode,
    CombatStat stat, {
    required CombatProfile pastor,
    required LearnedSkills learned,
    required int insight,
  }) {
    if (!npc.isChristian) return '✝️🔒';
    if (!CombatAbilities.canUse(mode, learned)) return '🎓';
    final level = stat.of(npc.discipleProfile.getFor(mode));
    if (level >= stat.of(pastor.getFor(mode))) return '🔒⚔️';
    if (insight < upgradeInsightCost(level)) return '🚫📖';
    return null;
  }

  // ── Their prayer in the invisible world ──────────────────────────────────

  /// Only disciples this close to the pastor pray (on screen, and the
  /// battle never plays itself far away).
  static const double prayRange = 700;

  /// At most this many disciples pray at once (the nearest).
  static const int maxPraying = 8;

  /// Seconds between two waves of one disciple (modes take turns).
  static const double interval = 5;

  /// A disciple's wave compared with the pastor's (radius 140, strength
  /// 25 at full faith, speed 90, all × the upgrades).
  static double radius(CombatModifierSet s) => 70 * s.radius;
  static double strength(CombatModifierSet s) => 6 * s.strength;
  static double speed(CombatModifierSet s) => 70 * s.speed;
  static double duration(CombatModifierSet s) => s.duration;
}
