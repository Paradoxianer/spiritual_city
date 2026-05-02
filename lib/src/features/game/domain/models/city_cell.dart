import 'cell_object.dart';

class CityCell {
  final int x;
  final int y;
  
  // The data defining what is in this cell
  CellData? data;
  
  // Real world values (0.0 to 1.0)
  final double crime;
  final double density;
  
  // Spiritual world values (-1.0 to 1.0)
  double spiritualState;

  /// True after a daemon naturally dissolves here, leaving an "ash" imprint.
  bool hasResiduum = false;

  // ── Cell-Glow feedback (Issue #118) ──────────────────────────────────────

  /// Remaining glow time in seconds (> 0 while glowing).
  ///
  /// Set by [InfluenceService] when an AoE effect hits this cell.
  /// Decremented in [ChunkComponent.update] and drives the visible-world
  /// glow overlay colour.
  double glowTimer = 0.0;

  /// Glow sign/magnitude: positive = green (holy), negative = red (dark).
  ///
  /// Magnitude is proportional to the delta that triggered the glow.
  double glowStrength = 0.0;

  CityCell({
    required this.x,
    required this.y,
    this.data,
    this.crime = 0.0,
    this.density = 0.0,
    this.spiritualState = 0.0,
  });
}
