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

  /// Mastery lessons once lifted a level cap; there is no cap any more –
  /// every level just costs more (playtest 2026-11-12). Kept empty so old
  /// saves and texts still resolve.
  static List<Skill> mastery(PrayerMode mode) => const [];

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
