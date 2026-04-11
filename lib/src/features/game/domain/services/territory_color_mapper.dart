import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Maps spiritual-state values (−1.0..+1.0) to overlay colours.
///
/// Colour scheme (Lastenheft §5.1):
///   +0.3..+1.0 – green spectrum (God's presence, Psalm 23,2)
///   −0.3..+0.3 – beige / neutral (contested territory)
///   −1.0..−0.3 – red spectrum  (darkness, Jes 1,18)
class TerritoryColorMapper {
  /// Converts [spiritualState] (−1.0..+1.0) to a fully-opaque [Color].
  Color stateToColor(double spiritualState) {
    final s = spiritualState.clamp(-1.0, 1.0);
    if (s > 0.3) {
      // light-green → lime-green → gold
      final t = ((s - 0.3) / 0.7).clamp(0.0, 1.0);
      if (t < 0.5) {
        return Color.lerp(
          const Color(0xFF90EE90), // lightgreen
          const Color(0xFF32CD32), // limegreen
          t * 2,
        )!;
      }
      return Color.lerp(
        const Color(0xFF32CD32), // limegreen
        const Color(0xFFFFD700), // gold
        (t - 0.5) * 2,
      )!;
    } else if (s < -0.3) {
      // dark-red → crimson → near-black
      final t = ((-s - 0.3) / 0.7).clamp(0.0, 1.0);
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
    return const Color(0xFFF5DEB3); // wheat / beige (neutral)
  }

  /// Returns an alpha multiplier in [0.6, 1.0] that creates a pulsing glow
  /// in strongly negative zones (Jes 1,18).
  /// [animationTime] is cumulative game-seconds.
  double redPulseAlpha(double spiritualState, double animationTime) {
    if (spiritualState < -0.3) {
      final depth = ((-spiritualState - 0.3) / 0.7).clamp(0.0, 1.0);
      final pulse = 0.5 + 0.5 * math.sin(animationTime * 2 * math.pi);
      return 0.6 + 0.4 * pulse * depth;
    }
    return 1.0;
  }

  /// Returns `true` when a sparkle particle should be spawned.
  /// Only fires for cells with [spiritualState] > 0.3.
  /// [random] must be a uniform value in [0, 1).
  bool shouldSpawnSparkle(double spiritualState, double random) {
    if (spiritualState <= 0.3) return false;
    final chance = ((spiritualState - 0.3) / 0.7) * 0.08; // up to 8 % per frame
    return random < chance;
  }
}
