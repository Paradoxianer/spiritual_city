import '../models/daemon_kind.dart';
import '../models/prayer_combat.dart';
import 'combat_abilities.dart';

/// What one prayer-wave hit does to a daemon.
class DaemonHit {
  /// Energy added to the daemon (positive = towards dissolving).
  final double damage;

  /// How long the mode's effect stays on the daemon (seconds).
  final double effectDuration;

  /// Knockback multiplier for Rebuke (1.0 = normal).
  final double knockbackFactor;

  /// The hit hit the daemon's weakness (shown as a flash).
  final bool weaknessHit;

  /// Rebuke landed on a daemon that is both slowed and drained: the full
  /// Slow → Drain → Rebuke chain ("Kettenblitz").
  final bool chainCompleted;

  const DaemonHit({
    required this.damage,
    required this.effectDuration,
    this.knockbackFactor = 1.0,
    this.weaknessHit = false,
    this.chainCompleted = false,
  });
}

/// Pure combat rules for daemons (docs/game_design/daemons_and_combat.md
/// §3–§5, #178): weaknesses, the Slow → Drain → Rebuke combo and tiers.
abstract final class DaemonCombatRules {
  // ── Mode base factors (unchanged from before #178) ──────────────────────
  static const double drainedDamageFactor = 1.8;
  static const double liberationDamageFactor = 1.2;
  static const double controlDamageFactor = 0.05;

  // ── Weakness ────────────────────────────────────────────────────────────
  /// Slow on a lurker lasts twice as long.
  static const double slowWeaknessDuration = 2.0;

  /// Rebuke on a brute pushes 1.5× as far.
  static const double rebukeWeaknessKnockback = 1.5;

  /// Drain on a leech, or Liberation on a possessor: 1.5× damage.
  static const double damageWeakness = 1.5;

  // ── Combo ───────────────────────────────────────────────────────────────
  /// Drain on a slowed target lasts 25 % longer.
  static const double drainAfterSlowDuration = 1.25;

  /// Rebuke on a drained target pushes 50 % further.
  static const double rebukeAfterDrainKnockback = 1.5;

  /// Completing the chain deals this share of the daemon's starting energy
  /// at once.
  static const double chainBurstShare = 0.5;

  /// Computes one hit of [mode] with raw wave [damage] and effect
  /// [duration] on a daemon of [kind] whose currently active effects are
  /// [active]. [initialEnergy] is the daemon's (negative) starting energy.
  static DaemonHit hit({
    required DaemonKind kind,
    required PrayerMode mode,
    required double damage,
    required double duration,
    required Set<PrayerMode> active,
    required double initialEnergy,
    Map<PrayerMode, int> abilityTier = const {},
  }) {
    int t(PrayerMode m) => abilityTier[m] ?? 0;
    final weak = kind.weakness == mode;
    var dmg = damage;
    var dur = duration;
    var knock = 1.0;
    var chain = false;

    if (active.contains(PrayerMode.drain)) dmg *= drainedDamageFactor;
    if (active.contains(PrayerMode.slow) && t(PrayerMode.slow) >= 2) {
      dmg *= CombatAbilities.slowedDamage;
    }
    switch (mode) {
      case PrayerMode.liberation:
        dmg *= liberationDamageFactor;
        if (weak) dmg *= damageWeakness;
      case PrayerMode.slow:
        dmg *= controlDamageFactor;
        if (weak) dur *= slowWeaknessDuration;
        if (t(PrayerMode.slow) >= 1) dur *= CombatAbilities.slowDuration;
      case PrayerMode.drain:
        if (weak) dmg *= damageWeakness;
        if (t(PrayerMode.drain) >= 2) dmg *= CombatAbilities.drainDamage;
        if (active.contains(PrayerMode.slow)) dur *= drainAfterSlowDuration;
      case PrayerMode.rebuke:
        dmg *= controlDamageFactor;
        if (t(PrayerMode.rebuke) >= 2) dmg *= CombatAbilities.rebukeDamage;
        if (weak) knock *= rebukeWeaknessKnockback;
        if (t(PrayerMode.rebuke) >= 1) knock *= CombatAbilities.rebukeKnockback;
        if (active.contains(PrayerMode.drain)) {
          knock *= rebukeAfterDrainKnockback;
          if (active.contains(PrayerMode.slow)) {
            chain = true;
            dmg += initialEnergy.abs() * chainBurstShare;
          }
        }
    }

    return DaemonHit(
      damage: dmg,
      effectDuration: dur,
      knockbackFactor: knock,
      weaknessHit: weak,
      chainCompleted: chain,
    );
  }

  // ── Tier (visible strength) ─────────────────────────────────────────────
  static const int maxTier = 3;

  /// Size grows by 25 % per tier above 1.
  static double tierSize(int tier) => 1.0 + 0.25 * (tier - 1);

  /// Energy grows by 50 % per tier above 1.
  static double tierEnergy(int tier) => 1.0 + 0.5 * (tier - 1);

  /// Player power at which spawns reach tier 2 / tier 3.
  static const int tier2Power = 8;
  static const int tier3Power = 20;

  /// Spawn tier for a given (grace-delayed) player power.
  static int tierFor(int power) {
    if (power >= tier3Power) return 3;
    if (power >= tier2Power) return 2;
    return 1;
  }
}
