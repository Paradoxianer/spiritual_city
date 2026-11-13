import '../models/prayer_combat.dart';
import '../models/skills.dart';

/// Abilities per prayer mode (#179, progression_and_unlocks.md §2): instead
/// of only +10 % per upgrade, a mode's level (sum of its four upgrades)
/// unlocks a new ability at [milestones]. Shown as emoji in the ⚔️ panel.
abstract final class CombatAbilities {
  static const List<int> milestones = [3, 6];

  /// Skill that makes [mode] usable (🕊️ Liberation is always there).
  static Skill? modeSkill(PrayerMode mode) => switch (mode) {
        PrayerMode.liberation => null,
        PrayerMode.rebuke => Skill.spiritualWarfare,
        PrayerMode.slow => Skill.binding,
        PrayerMode.drain => Skill.disarming,
      };

  static bool canUse(PrayerMode mode, LearnedSkills learned) {
    final s = modeSkill(mode);
    return s == null || learned.has(s);
  }

  /// The skill that names [mode]'s mastery lessons (⭐, ⭐⭐, …).
  static Skill masteryKey(PrayerMode mode) => switch (mode) {
        PrayerMode.liberation => Skill.liberationMastery1,
        PrayerMode.rebuke => Skill.rebukeMastery1,
        PrayerMode.slow => Skill.slowMastery1,
        PrayerMode.drain => Skill.drainMastery1,
      };

  /// The prayer mode whose mastery lessons [s] names, if any.
  static PrayerMode? masteryMode(Skill s) =>
      PrayerMode.values.where((m) => masteryKey(m) == s).firstOrNull;

  /// Mastery lessons of [mode] passed so far.
  static int masteryStage(PrayerMode mode, LearnedSkills learned) =>
      learned.masteryOf(masteryKey(mode));

  /// Highest mode level after [stage] mastery lessons: 3, 5, 10, 15, 20 …
  /// – no top, but every step needs the next lesson from a mentor
  /// (playtest 2026-11-13: buying on and on without learning was not the
  /// plan). Up to 3 without a mentor.
  static int capFor(int stage) => stage == 0 ? 3 : (stage == 1 ? 5 : 5 * stage);

  static int levelCap(PrayerMode mode, LearnedSkills learned) =>
      capFor(masteryStage(mode, learned));

  /// Mode level = sum of its radius/strength/duration/speed upgrades.
  static int modeLevel(CombatModifierSet s) =>
      s.radiusLevel + s.strengthLevel + s.durationLevel + s.speedLevel;

  /// Unlocked abilities of a mode: 0, 1 or 2.
  static int tier(CombatModifierSet s) {
    final l = modeLevel(s);
    return milestones.where((m) => l >= m).length;
  }

  /// Emoji of the two abilities per mode.
  static const Map<PrayerMode, List<String>> emoji = {
    // 1: a kill cleanses a wider area · 2: waves liberate more strongly
    PrayerMode.liberation: ['🕊️💥', '🕊️✨'],
    // 1: pushes harder · 2: rebuke also hurts
    PrayerMode.rebuke: ['🫸💪', '🫸⚡'],
    // 1: holds longer · 2: held daemons take more damage
    PrayerMode.slow: ['⏳⏳', '⏳💥'],
    // 1: a drain kill gives double faith · 2: drain hurts more
    PrayerMode.drain: ['🪫🙏', '🪫⚡'],
  };

  // Values (Startwerte)
  static const int liberationCleanseRadius = 5; // was 3
  static const double liberationCellFactor = 1.3;
  static const double rebukeKnockback = 1.3;
  static const double rebukeDamage = 4.0; // 0.05 → 0.2 of a wave
  static const double slowDuration = 1.5;
  static const double slowedDamage = 1.3;
  static const double drainKillFaith = 2.0;
  static const double drainDamage = 1.3;
}
