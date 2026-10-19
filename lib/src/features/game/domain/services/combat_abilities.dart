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

  /// Mastery lessons of [mode] (⭐, ⭐⭐).
  static (Skill, Skill) mastery(PrayerMode mode) => switch (mode) {
        PrayerMode.liberation => (Skill.liberationMastery1, Skill.liberationMastery2),
        PrayerMode.rebuke => (Skill.rebukeMastery1, Skill.rebukeMastery2),
        PrayerMode.slow => (Skill.slowMastery1, Skill.slowMastery2),
        PrayerMode.drain => (Skill.drainMastery1, Skill.drainMastery2),
      };

  /// Highest mode level the pastor may buy (sum of the four upgrades):
  /// 2 without a mentor, 5 after ⭐, 10 after ⭐⭐ (playtest 2026-10-18).
  static const List<int> levelCaps = [2, 5, 10];

  static int levelCap(PrayerMode mode, LearnedSkills learned) {
    final (m1, m2) = mastery(mode);
    if (learned.has(m2)) return levelCaps[2];
    if (learned.has(m1)) return levelCaps[1];
    return levelCaps[0];
  }

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
