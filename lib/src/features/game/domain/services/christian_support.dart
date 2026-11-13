/// Converted people protect liberated ground (#180, npc_influence.md §4):
/// cells with Christians nearby fall back towards darkness more slowly.
/// Several Christians stack with diminishing returns so nothing explodes.
abstract final class ChristianSupport {
  /// Cells within this radius (in cells) of a new Christian are supported.
  static const int radius = 2;

  /// A firm Christian protects further (playtest 2026-11-13: care should
  /// pay off): [radius] at stability 0 up to 5 cells at 0.9.
  static int radiusFor(double stability) => radius + (stability.clamp(0.0, 1.0) * 3.4).floor();

  /// Never protects more than this share of the natural fallback.
  static const double minFallbackFactor = 0.15;

  /// Multiplier for the natural fallback of a cell with [christians]
  /// Christians in reach: 1 → 0.57, 2 → 0.4, 4 → 0.25, never below 0.15.
  static double fallbackFactor(int christians) {
    if (christians <= 0) return 1.0;
    return (1.0 / (1.0 + 0.75 * christians)).clamp(minFallbackFactor, 1.0);
  }
}
