/// Converted people protect liberated ground (#180, npc_influence.md §4):
/// cells with Christians nearby fall back towards darkness more slowly.
/// Several Christians stack with diminishing returns so nothing explodes.
abstract final class ChristianSupport {
  /// Cells within this radius (in cells) of a Christian are supported.
  static const int radius = 2;

  /// Never protects more than this share of the natural fallback.
  static const double minFallbackFactor = 0.3;

  /// Multiplier for the natural fallback of a cell with [christians]
  /// Christians in reach: 1 → ⅔, 2 → ½, 4 → ⅓, never below 0.3.
  static double fallbackFactor(int christians) {
    if (christians <= 0) return 1.0;
    return (1.0 / (1.0 + 0.5 * christians)).clamp(minFallbackFactor, 1.0);
  }
}
