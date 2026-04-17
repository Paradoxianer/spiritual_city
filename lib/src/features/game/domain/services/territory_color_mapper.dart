import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Maps spiritual-state values (−1.0..+1.0) to overlay colours.
///
/// Colour scheme (Lastenheft §5.1):
///   +0.3..+1.0 – green spectrum (liberated, God's presence, Psalm 23,2)
///   −0.3..+0.3 – grey / neutral (contested territory)
///   −1.0..−0.3 – red spectrum  (demonic darkness, Jes 1,18)
class TerritoryColorMapper {
  /// Threshold above which a cell is considered a positive (green) zone.
  static const double positiveThreshold = 0.3;

  /// Threshold below which a cell is considered a negative (red) zone.
  static const double negativeThreshold = -0.3;

  /// Converts [spiritualState] (−1.0..+1.0) to a fully-opaque [Color].
  Color stateToColor(double spiritualState) {
    final s = spiritualState.clamp(-1.0, 1.0);
    if (s > positiveThreshold) {
      // light-green → dark-green (liberated zone)
      final t = ((s - positiveThreshold) / (1.0 - positiveThreshold)).clamp(0.0, 1.0);
      return Color.lerp(
        const Color(0xFF90EE90), // lightgreen
        const Color(0xFF006400), // darkgreen
        t,
      )!;
    } else if (s < negativeThreshold) {
      // dark-red → crimson → near-black
      final t = ((-s + negativeThreshold) / (1.0 + negativeThreshold)).clamp(0.0, 1.0);
      if (t < 0.5) {
        return Color.lerp(
          const Color(0xFF8B0000), // darkred
          const Color(0xFFDC143C), // crimson
          t * 2,
        )!;
      }
      return Color.lerp(
        const Color(0xFFDC143C), // crimson
        const Color(0xFF330000), // near-black red
        (t - 0.5) * 2,
      )!;
    }
    return const Color(0xFF808080); // grey (neutral)
  }

  /// Returns an alpha multiplier in [0.6, 1.0] that creates a pulsing glow
  /// in strongly negative zones (Jes 1,18).
  /// [animationTime] is cumulative game-seconds.
  double redPulseAlpha(double spiritualState, double animationTime) {
    if (spiritualState < negativeThreshold) {
      final depth = ((-spiritualState + negativeThreshold) / (1.0 + negativeThreshold)).clamp(0.0, 1.0);
      final pulse = 0.5 + 0.5 * math.sin(animationTime * 2 * math.pi);
      return 0.6 + 0.4 * pulse * depth;
    }
    return 1.0;
  }

  /// Returns `true` when a sparkle particle should be spawned.
  /// Only fires for cells with [spiritualState] > 0.3.
  /// [random] must be a uniform value in [0, 1).
  /// [dt] scales the probability so the spawn rate is per-second, not per-frame.
  bool shouldSpawnSparkle(double spiritualState, double random, {double dt = 1.0 / 60.0}) {
    if (spiritualState <= positiveThreshold) return false;
    final chancePerSecond = ((spiritualState - positiveThreshold) / (1.0 - positiveThreshold)) * 8.0; // up to 8 per second
    return random < chancePerSecond * dt;
  }
}
