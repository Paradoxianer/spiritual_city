import 'dart:math';

/// 📢🎺 At an open-air meeting people who are ready come to faith – many at
/// once, like at Pentecost (Acts 2:41, playtest 2026-11-21). Only those a
/// personal talk would win already, and a little more: the meeting harvests
/// what relationships let grow (Mt 9:37), it does not replace them.
abstract final class OpenAirHarvest {
  /// faith + liberated ground × 50 must be above this – a talk needs 50.
  static const double readyAbove = 60;

  static bool ready(double faith, double spiritualState) => faith + spiritualState * 50 > readyAbove;

  /// The pastor's own faith carries: 400 🙏 or more count fully.
  static const double fullFaith = 400;

  /// Chance for each ready listener: the pastor's faith × the Christians
  /// praying along (20 % alone, +3 % each, at most 90 %) – 340 🙏 and 20
  /// Christians ≈ 68 %, 100 🙏 ≈ 20 %.
  static double chance(double pastorFaith, int christians) =>
      (pastorFaith / fullFaith).clamp(0.0, 1.0) * min(0.9, 0.2 + 0.03 * christians);

  /// Share of a talk's 📖 per conversion – a meeting must not become a
  /// wisdom machine.
  static const double insightShare = 0.5;
}
