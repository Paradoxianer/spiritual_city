/// Converted people protect liberated ground (#180, npc_influence.md §4):
/// red presses much more weakly on cells with Christians nearby.
/// Several Christians stack with diminishing returns so nothing explodes.
abstract final class ChristianSupport {
  /// Cells within this radius (in cells) of a new Christian are supported.
  static const int radius = 2;

  /// A firm Christian protects further (playtests 2026-11-13 and -20: care
  /// and what the pastor taught them should pay off strongly): [radius] at
  /// stability 0 up to 9 cells at 0.9 (WorldSimulation.baseStability –
  /// care, life challenges, church, discipleship).
  static int radiusFor(double stability) => radius + (stability.clamp(0.0, 1.0) * 8).floor();

  /// Never lets less than this share of the red pressure through.
  static const double minFallbackFactor = 0.05;

  /// Share of the red pressure on a cell with [christians] Christians in
  /// reach: 1 → 0.33, 2 → 0.2, 4 → 0.11, never below 0.05 (playtest
  /// 2026-11-20: "very strong protection").
  static double fallbackFactor(int christians) {
    if (christians <= 0) return 1.0;
    return (1.0 / (1.0 + 2 * christians)).clamp(minFallbackFactor, 1.0);
  }
}
