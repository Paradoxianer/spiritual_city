import 'package:flutter/material.dart';

/// The four modes of prayer combat.
/// Lastenheft §2.3 / Issue #9
enum PrayerMode {
  liberation(
    id: 'liberation',
    color: Colors.white,
    icon: '🙏',
  ),
  rebuke(
    id: 'rebuke',
    color: Colors.redAccent,
    icon: '🔥',
  ),
  slow(
    id: 'slow',
    color: Colors.lightBlueAccent,
    icon: '❄️',
  ),
  drain(
    id: 'drain',
    color: Colors.purpleAccent,
    icon: '✨',
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

/// Set of 4 modifiers for a specific prayer mode.
/// Issue #9
class CombatModifierSet {
  double radius;
  double strength;
  double duration;
  double speed;

  CombatModifierSet({
    this.radius = 1.0,
    this.strength = 1.0,
    this.duration = 1.0,
    this.speed = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'radius': radius,
    'strength': strength,
    'duration': duration,
    'speed': speed,
  };

  factory CombatModifierSet.fromJson(Map<String, dynamic> json) {
    return CombatModifierSet(
      radius: (json['radius'] ?? 1.0).toDouble(),
      strength: (json['strength'] ?? 1.0).toDouble(),
      duration: (json['duration'] ?? 1.0).toDouble(),
      speed: (json['speed'] ?? 1.0).toDouble(),
    );
  }
}

/// Profile holding modifier sets for all prayer modes.
/// Issue #4 / #9
class CombatProfile {
  final Map<PrayerMode, CombatModifierSet> modes;

  CombatProfile({Map<PrayerMode, CombatModifierSet>? modes})
      : modes = modes ?? {
          for (var mode in PrayerMode.values) mode: CombatModifierSet(),
        };

  CombatModifierSet getFor(PrayerMode mode) => modes[mode]!;

  Map<String, dynamic> toJson() => {
    for (var entry in modes.entries) entry.key.id: entry.value.toJson(),
  };

  factory CombatProfile.fromJson(Map<String, dynamic> json) {
    final profile = CombatProfile();
    for (var mode in PrayerMode.values) {
      if (json.containsKey(mode.id)) {
        profile.modes[mode] = CombatModifierSet.fromJson(json[mode.id]);
      }
    }
    return profile;
  }
}
