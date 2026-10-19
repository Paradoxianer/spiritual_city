import 'dart:math';
import 'dart:ui' show Color;

import 'prayer_combat.dart';

/// Daemon types (docs/game_design/daemons_and_combat.md §3, #178). Each has
/// its own look, size and trail and exactly one weakness.
enum DaemonKind {
  /// Fast, little energy, comes in numbers; thin trail. Weak to Slow.
  lurker(
    glyph: '🐍',
    color: Color(0xFF2E7D32),
    weakness: PrayerMode.slow,
    energyFactor: 0.6,
    speedFactor: 1.5,
    sizeFactor: 0.8,
    trailFactor: 0.6,
  ),

  /// Slow, lots of energy, wide trail. Weak to Rebuke.
  brute(
    glyph: '🪨',
    color: Color(0xFF6D4C41),
    weakness: PrayerMode.rebuke,
    energyFactor: 1.8,
    speedFactor: 0.6,
    sizeFactor: 1.4,
    trailFactor: 1.6,
  ),

  /// Pulls faith from the pastor while close. Weak to Drain.
  leech(
    glyph: '🦇',
    color: Color(0xFF6A1B9A),
    weakness: PrayerMode.drain,
    energyFactor: 1.0,
    speedFactor: 1.0,
    sizeFactor: 1.0,
    trailFactor: 1.0,
  ),

  /// Sits in a possessed person and spawns from there (npc_influence.md).
  /// Only beatable once the person was cared for in the real world.
  possessor(
    glyph: '👁️',
    color: Color(0xFF263238),
    weakness: PrayerMode.liberation,
    energyFactor: 1.4,
    speedFactor: 0.8,
    sizeFactor: 1.2,
    trailFactor: 1.2,
  );

  final String glyph;
  final Color color;
  final PrayerMode weakness;
  final double energyFactor;
  final double speedFactor;
  final double sizeFactor;
  final double trailFactor;

  const DaemonKind({
    required this.glyph,
    required this.color,
    required this.weakness,
    required this.energyFactor,
    required this.speedFactor,
    required this.sizeFactor,
    required this.trailFactor,
  });

  /// Random kind for an ordinary spawn (no possessors): 40 % lurker,
  /// 25 % brute, 35 % leech.
  static DaemonKind randomSpawn(Random rng) {
    final r = rng.nextDouble();
    if (r < 0.40) return lurker;
    if (r < 0.65) return brute;
    return leech;
  }
}
