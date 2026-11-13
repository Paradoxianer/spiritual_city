/// How big the city of a new game is (playtest 2026-11-13: the one
/// 500 000-inhabitant city had ~650 neighbourhoods – nobody can pray all of
/// them free). The goal of a game is every neighbourhood prayed free.
enum CitySize {
  /// 🏡 ~16 neighbourhoods – about an evening.
  village('🏡', 90),

  /// 🏘️ ~44 neighbourhoods – the default.
  smallTown('🏘️', 160),

  /// 🏙️ ~90 neighbourhoods.
  town('🏙️', 240),

  /// 🌆 the old big city, ~600 neighbourhoods (saves from before).
  metropolis('🌆', 690);

  final String emoji;

  /// Distance of the city edge from the centre in cells.
  final int radius;

  const CitySize(this.emoji, this.radius);

  static const CitySize standard = smallTown;
}
