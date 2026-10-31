import 'npc_model.dart';
import 'prayer_combat.dart';
import 'skills.dart';
import '../services/combat_abilities.dart';

/// 🌱 Discipleship (#193, playtest 2026-10-31): the pastor teaches
/// Christians one prayer gift with 📖 insight ("what you have heard from
/// me … entrust to faithful people who will be able to teach others",
/// 2 Tim 2:2). In the invisible world a disciple near the pastor sends out
/// small waves of that gift – weaker than the pastor's, but many of them
/// make awakened neighbourhoods strongholds of prayer. Possible in every
/// neighbourhood: disciples help wherever they live.
abstract final class Discipleship {

  /// Deepest a gift can grow: ⭐ ⭐⭐ ⭐⭐⭐.
  static const int maxLevel = 3;

  /// 📖 for the next step from [level] (0 = not taught yet).
  static int teachCost(int level) => const [5, 10, 20][level.clamp(0, maxLevel - 1)];

  /// Gifts the pastor can pass on: only what they can pray themselves.
  static List<PrayerMode> teachable(LearnedSkills learned) =>
      [for (final m in PrayerMode.values) if (CombatAbilities.canUse(m, learned)) m];

  /// Whether [mode] at [level] can be taught one step further.
  static bool canDeepen(PrayerMode? gift, int level, PrayerMode mode) =>
      (gift == null || gift == mode) && level < maxLevel;

  // ── Their prayer in the invisible world ──────────────────────────────────

  /// Only disciples this close to the pastor pray (on screen, and the
  /// battle never plays itself far away).
  static const double prayRange = 700;

  /// At most this many disciples pray at once (the nearest).
  static const int maxPraying = 8;

  /// Seconds between two waves of one disciple.
  static double interval(int level) => 7.0 - level;

  /// Wave radius in pixels (the pastor's starts at 140).
  static double radius(int level) => 60.0 + 20.0 * level;

  /// Wave strength (the pastor's starts at 25 with full faith).
  static double strength(int level) => 3.0 + 2.0 * level;

  static String stars(int level) => '⭐' * level;
}

/// Why [npc] cannot be taught [mode] right now (emoji), or null.
/// One step per day – discipleship is a relationship, not a course.
String? discipleBlocker(NPCModel npc, PrayerMode mode, int insight, int day) {
  if (!npc.isChristian) return '✝️🔒';
  if (!Discipleship.canDeepen(npc.discipleGift, npc.discipleLevel, mode)) return '✅';
  if (npc.discipleTaughtDay == day) return '📅';
  if (insight < Discipleship.teachCost(npc.discipleLevel)) return '🚫📖';
  return null;
}
