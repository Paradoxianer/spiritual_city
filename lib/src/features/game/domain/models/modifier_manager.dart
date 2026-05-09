import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'player_progress.dart';
import 'prayer_combat.dart';

/// Passive modifier that is permanently active once unlocked.
class Modifier {
  final String id;
  final String name;
  final String description;
  bool unlocked;

  Modifier({
    required this.id,
    required this.name,
    required this.description,
    this.unlocked = false,
  });
}

/// Manages all game modifiers.
///
/// Modifiers are unlocked via [checkUnlocks] which is called after each
/// progress counter update. Once unlocked they are applied automatically.
///
/// Lastenheft §5.4
class ModifierManager {
  static final _log = Logger('ModifierManager');

  final PlayerProgress progress;

  // ---- COMBAT MODIFIERS ---------------------------------------------------

  /// Inbrunst: Timing-Fenster +5% breiter (unlocked after 10 prayer combats)
  late final Modifier inbrunst;

  /// Ausdauer: Zone grows 20% faster (unlocked after 5 territories partially taken)
  late final Modifier ausdauer;

  /// Konzentration: Faith-Pulse 15% slower (unlocked after 10 bible readings)
  late final Modifier konzentration;

  /// Kraft: Impact-Power +20% (unlocked after 3 NPCs converted)
  late final Modifier kraft;

  /// Weisheit: Faith cost -10% per combat (unlocked after 20 conversations)
  late final Modifier weisheit;

  // ---- TERRITORY MODIFIERS ------------------------------------------------

  /// Bewahrung: Fallback rate -15% for green cells (1 full territory taken)
  late final Modifier bewahrung;

  /// Wachstum: Green cells influence neighbours +10% stronger (30 conversations)
  late final Modifier wachstum;

  ModifierManager({required this.progress}) {
    inbrunst = Modifier(
        id: 'inbrunst',
        name: 'Inbrunst',
        description: 'Timing-Fenster +5% breiter');
    ausdauer = Modifier(
        id: 'ausdauer',
        name: 'Ausdauer',
        description: 'Gebets-Zone wächst 20% schneller');
    konzentration = Modifier(
        id: 'konzentration',
        name: 'Konzentration',
        description: 'Faith-Pulse 15% langsamer');
    kraft =
        Modifier(id: 'kraft', name: 'Kraft', description: 'Impact-Power +20%');
    weisheit = Modifier(
        id: 'weisheit',
        name: 'Weisheit',
        description: 'Faith-Kosten pro Combat -10%');
    bewahrung = Modifier(
        id: 'bewahrung',
        name: 'Bewahrung',
        description: 'Rückfall-Rate -15% für grüne Zellen');
    wachstum = Modifier(
        id: 'wachstum',
        name: 'Wachstum',
        description: 'Grüne Zellen beeinflussen Nachbarn +10%');
  }

  /// Check all unlock conditions and unlock modifiers as appropriate.
  /// Returns a list of newly-unlocked modifier names (for showing notifications).
  List<String> checkUnlocks() {
    final newlyUnlocked = <String>[];

    void tryUnlock(Modifier m, bool condition) {
      if (!m.unlocked && condition) {
        m.unlocked = true;
        newlyUnlocked.add(m.name);
        _log.info('Modifier unlocked: ${m.name}');
      }
    }

    tryUnlock(inbrunst, progress.prayerCombatsCompleted >= 10);
    tryUnlock(ausdauer, progress.territoriesPartiallyTaken >= 5);
    tryUnlock(konzentration, progress.bibleReadingsCompleted >= 10);
    tryUnlock(kraft, progress.npcsConverted >= 3);
    tryUnlock(weisheit, progress.conversationsHeld >= 20);
    tryUnlock(bewahrung, progress.territoriesFullyTaken >= 1);
    tryUnlock(wachstum, progress.conversationsHeld >= 30);

    return newlyUnlocked;
  }

  // ---- Computed multipliers -----------------------------------------------

  /// Modifier for zone growth speed (applied to modifierSizeSpeed in PlayerComponent)
  double get zoneSizeSpeedMultiplier => ausdauer.unlocked ? 1.2 : 1.0;

  /// Modifier for faith pulse speed (applied to modifierIntensitySpeed) – slower = more control
  double get faithPulseSpeedMultiplier => konzentration.unlocked ? 0.85 : 1.0;

  /// Multiplier applied directly to impact power
  double get impactPowerMultiplier => kraft.unlocked ? 1.2 : 1.0;

  /// Faith cost multiplier per combat
  double get faithCostMultiplier => weisheit.unlocked ? 0.9 : 1.0;

  /// Optimal timing window extension (added to the 0.7 threshold)
  double get optimalWindowExtension => inbrunst.unlocked ? 0.05 : 0.0;

  /// Spread multiplier for green cells (wachstum)
  double get greenSpreadMultiplier => wachstum.unlocked ? 1.1 : 1.0;

  /// Decay reduction (bewahrung)
  double get decayReduction => bewahrung.unlocked ? 0.15 : 0.0;

  // ---- Advanced Combat Calculations (Issue #9) ----------------------------

  /// Calculates the effective stats for a specific prayer shockwave.
  ///
  /// [mode] The active prayer mode.
  /// [holdingTime] Total time the button has been held.
  /// [currentFaith] The player's current faith (0.0 to 100.0+).
  EffectiveCombatStats getEffectiveCombatStats(
    PrayerMode mode,
    double holdingTime,
    double currentFaith,
  ) {
    final base = progress.combatProfile.getFor(mode);
    final faithFactor = (currentFaith / 100.0).clamp(0.1, 2.0);
    final levelStep = switch (mode) {
      PrayerMode.liberation => 0.08,
      PrayerMode.rebuke => 0.14,
      PrayerMode.slow => 0.16,
      PrayerMode.drain => 0.15,
    };

    final radiusLevels = 1.0 + base.radiusLevel * levelStep;
    final strengthLevels = 1.0 + base.strengthLevel * levelStep;
    final durationLevels = 1.0 + base.durationLevel * levelStep;
    final speedLevels = 1.0 + base.speedLevel * levelStep;

    // Holding-time bonus scales slightly stronger for utility modes.
    final holdingStrengthFactor = switch (mode) {
      PrayerMode.liberation => 1.0 + (holdingTime * 0.14),
      PrayerMode.rebuke => 1.0 + (holdingTime * 0.20),
      PrayerMode.slow => 1.0 + (holdingTime * 0.22),
      PrayerMode.drain => 1.0 + (holdingTime * 0.20),
    };

    // Apply global passives
    final radiusMultiplier = zoneSizeSpeedMultiplier; // Ausdauer
    final strengthMultiplier = impactPowerMultiplier; // Kraft

    final modeRadiusBase = switch (mode) {
      PrayerMode.liberation => 125.0,
      PrayerMode.rebuke => 145.0,
      PrayerMode.slow => 145.0,
      PrayerMode.drain => 150.0,
    };
    final modeStrengthBase = switch (mode) {
      PrayerMode.liberation => 20.0,
      PrayerMode.rebuke => 17.0,
      PrayerMode.slow => 16.0,
      PrayerMode.drain => 24.0,
    };
    final modeDurationBase = switch (mode) {
      PrayerMode.liberation => 0.95,
      PrayerMode.rebuke => 1.30,
      PrayerMode.slow => 1.40,
      PrayerMode.drain => 1.30,
    };
    final modeSpeedBase = switch (mode) {
      PrayerMode.liberation => 85.0,
      PrayerMode.rebuke => 95.0,
      PrayerMode.slow => 90.0,
      PrayerMode.drain => 92.0,
    };

    return EffectiveCombatStats(
      radius: radiusLevels * radiusMultiplier * modeRadiusBase,
      strength: strengthLevels *
          strengthMultiplier *
          faithFactor *
          holdingStrengthFactor *
          modeStrengthBase,
      duration:
          durationLevels * modeDurationBase * (1.0 + (holdingTime * 0.10)),
      speed: speedLevels * modeSpeedBase,
      color: mode.color,
    );
  }
}

/// Result of combat calculations.
class EffectiveCombatStats {
  final double radius;
  final double strength;
  final double duration;
  final double speed;
  final Color color;

  EffectiveCombatStats({
    required this.radius,
    required this.strength,
    required this.duration,
    required this.speed,
    required this.color,
  });
}
