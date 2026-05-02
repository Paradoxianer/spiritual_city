import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Upgrade constants (Issue #4) ─────────────────────────────────────────────

/// Multiplier increase per upgrade level for attack modifiers.
const double kCombatUpgradeStep = 0.1;

/// Damage reduction per shield upgrade level (capped at 0.8).
const double kShieldDamageReductionPerLevel = 0.08;

/// Hunger-loss reduction per helm upgrade level (capped at 0.8).
const double kHelmHungerReductionPerLevel = 0.08;

/// Returns the Insight cost to upgrade from [currentLevel] to [currentLevel+1].
/// Formula: max(1, floor(1.5 ^ currentLevel)).
int upgradeInsightCost(int currentLevel) =>
    math.max(1, math.pow(1.5, currentLevel).floor());

/// The four modes of prayer combat.
/// Lastenheft §2.3 / Issue #9
enum PrayerMode {
  liberation(
    id: 'liberation',
    color: Colors.white,
    icon: '🕊️',
  ),
  rebuke(
    id: 'rebuke',
    color: Colors.redAccent,
    icon: '🫸',
  ),
  slow(
    id: 'slow',
    color: Colors.lightBlueAccent,
    icon: '⏳',
  ),
  drain(
    id: 'drain',
    color: Colors.purpleAccent,
    icon: '🪫',
  );

  final String id;
  final Color color;
  final String icon;

  const PrayerMode({
    required this.id,
    required this.color,
    required this.icon,
  });
}

/// Set of 4 upgrade levels for a specific prayer mode.
/// Each level adds [kCombatUpgradeStep] to the base multiplier of 1.0.
/// Issue #4 / #9
class CombatModifierSet {
  int radiusLevel;
  int strengthLevel;
  int durationLevel;
  int speedLevel;

  CombatModifierSet({
    this.radiusLevel = 0,
    this.strengthLevel = 0,
    this.durationLevel = 0,
    this.speedLevel = 0,
  });

  /// Effective radius multiplier (1.0 at level 0, +0.1 per level).
  double get radius => 1.0 + radiusLevel * kCombatUpgradeStep;

  /// Effective strength multiplier.
  double get strength => 1.0 + strengthLevel * kCombatUpgradeStep;

  /// Effective duration multiplier.
  double get duration => 1.0 + durationLevel * kCombatUpgradeStep;

  /// Effective speed multiplier.
  double get speed => 1.0 + speedLevel * kCombatUpgradeStep;

  Map<String, dynamic> toJson() => {
    'radiusLevel': radiusLevel,
    'strengthLevel': strengthLevel,
    'durationLevel': durationLevel,
    'speedLevel': speedLevel,
  };

  factory CombatModifierSet.fromJson(Map<String, dynamic> json) {
    return CombatModifierSet(
      radiusLevel:   (json['radiusLevel']   as num?)?.toInt() ?? 0,
      strengthLevel: (json['strengthLevel'] as num?)?.toInt() ?? 0,
      durationLevel: (json['durationLevel'] as num?)?.toInt() ?? 0,
      speedLevel:    (json['speedLevel']    as num?)?.toInt() ?? 0,
    );
  }
}

/// Profile holding modifier sets for all prayer modes, plus defence levels.
/// Issue #4 / #9
class CombatProfile {
  final Map<PrayerMode, CombatModifierSet> modes;

  /// Shield upgrade level – reduces incoming faith damage.
  int shieldLevel;

  /// Helm upgrade level – reduces incoming hunger damage.
  int helmLevel;

  CombatProfile({Map<PrayerMode, CombatModifierSet>? modes, this.shieldLevel = 0, this.helmLevel = 0})
      : modes = modes ?? {
          for (var mode in PrayerMode.values) mode: CombatModifierSet(),
        };

  CombatModifierSet getFor(PrayerMode mode) => modes[mode]!;

  /// Faith-damage reduction fraction (0.0–0.8) based on [shieldLevel].
  double get shieldDamageReduction =>
      (shieldLevel * kShieldDamageReductionPerLevel).clamp(0.0, 0.8);

  /// Hunger-damage reduction fraction (0.0–0.8) based on [helmLevel].
  double get helmHungerReduction =>
      (helmLevel * kHelmHungerReductionPerLevel).clamp(0.0, 0.8);

  Map<String, dynamic> toJson() => {
    for (var entry in modes.entries) entry.key.id: entry.value.toJson(),
    'shieldLevel': shieldLevel,
    'helmLevel': helmLevel,
  };

  factory CombatProfile.fromJson(Map<String, dynamic> json) {
    final profile = CombatProfile(
      shieldLevel: (json['shieldLevel'] as num?)?.toInt() ?? 0,
      helmLevel:   (json['helmLevel']   as num?)?.toInt() ?? 0,
    );
    for (var mode in PrayerMode.values) {
      if (json.containsKey(mode.id)) {
        final raw = json[mode.id];
        if (raw is Map) {
          profile.modes[mode] = CombatModifierSet.fromJson(raw.cast<String, dynamic>());
        }
      }
    }
    return profile;
  }
}
