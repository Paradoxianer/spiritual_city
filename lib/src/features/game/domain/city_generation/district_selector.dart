import 'dart:math';
import 'package:flame_noise/flame_noise.dart';

enum DistrictType {
  /// Central business district – skyscrapers, offices, civic buildings.
  downtown,
  /// Inner commercial ring – shops, offices, dense apartments.
  commercial,
  /// Residential suburbs – houses, apartments, local services.
  suburbs,
  /// Outer low-density areas – sparse housing, large lots.
  outskirts,
  /// Industrial zones – factories, warehouses.
  industrial,
  /// Waterfront / river edge.
  waterfront,
  /// Parks and green areas.
  park,
  /// Slum / deprived area.
  slums,
}

/// Determines the district type for any world cell.
///
/// Strategy (inspired by real city structure and procedural city generators):
///   1. Distance from world-centre defines the base ring
///      (downtown → commercial → suburbs → outskirts → rural).
///   2. Perlin noise adds organic variation so ring edges are not perfectly
///      circular.
///   3. River / water noise is laid on top; cells near a "river" become
///      waterfront or water.
///   4. Industrial clusters are carved out of the mid-ring using a separate
///      noise field.
///   5. Park pockets are scattered via another noise field.
class DistrictSelector {
  // ---- Noise fields -------------------------------------------------------
  final PerlinNoise _ringNoise;      // Organic edge variation for rings
  final PerlinNoise _riverNoise;     // River / water bodies
  final PerlinNoise _industrialNoise;// Industrial cluster placement
  final PerlinNoise _parkNoise;      // Park pocket placement
  final PerlinNoise _slumsNoise;     // Slum pocket placement

  // ---- Ring radii (in world cells, 1 cell ≈ 10 m) -------------------------
  // A 500 000-inhabitant city has roughly 125–170 km² ≈ radius ~6.5 km
  // → ~650 cells radius.  We size rings proportionally:
  static const double _downtownRadius    =  80.0;  // ~0.8 km
  static const double _commercialRadius  = 200.0;  // ~2 km
  static const double _suburbsRadius     = 420.0;  // ~4.2 km
  static const double _outskirtsRadius   = 650.0;  // ~6.5 km

  // Noise amplitude that "blurs" ring boundaries (in cells)
  static const double _ringNoiseAmp      = 40.0;

  DistrictSelector({required int seed})
      : _ringNoise       = PerlinNoise(seed: seed + 2),
        _riverNoise      = PerlinNoise(seed: seed + 1),
        _industrialNoise = PerlinNoise(seed: seed + 7),
        _parkNoise       = PerlinNoise(seed: seed + 11),
        _slumsNoise      = PerlinNoise(seed: seed + 13);

  // ---- Public API ---------------------------------------------------------

  DistrictType getDistrictType(int wx, int wy) {
    // 1. Water check (rivers / coast)
    if (_isRiverCell(wx, wy)) return DistrictType.waterfront;

    // 2. Effective distance from city centre with organic noise offset
    final double dist = _effectiveDist(wx, wy);

    // 3. Industrial pockets in mid-ring (commercial → suburbs band)
    if (dist > _downtownRadius && dist < _suburbsRadius) {
      final double iVal = _industrialNoise.getNoise2(wx * 0.008, wy * 0.008);
      if (iVal > 0.55) return DistrictType.industrial;
    }

    // 4. Park pockets – scattered everywhere outside downtown
    if (dist > _commercialRadius) {
      final double pVal = _parkNoise.getNoise2(wx * 0.012, wy * 0.012);
      if (pVal > 0.6) return DistrictType.park;
    }

    // 5. Slum pockets in the commercial-to-suburbs transition
    if (dist > _commercialRadius && dist < _suburbsRadius + 50) {
      final double sVal = _slumsNoise.getNoise2(wx * 0.01, wy * 0.01);
      if (sVal > 0.58) return DistrictType.slums;
    }

    // 6. Basic ring assignment
    if (dist <= _downtownRadius)   return DistrictType.downtown;
    if (dist <= _commercialRadius) return DistrictType.commercial;
    if (dist <= _suburbsRadius)    return DistrictType.suburbs;
    if (dist <= _outskirtsRadius)  return DistrictType.outskirts;
    return DistrictType.park; // Beyond city edge → countryside / green
  }

  bool isWater(int wx, int wy) {
    // True open water: higher threshold than waterfront
    return _riverNoise.getNoise2(wx * 0.008, wy * 0.008) > 0.72;
  }

  // ---- Helpers ------------------------------------------------------------

  double _effectiveDist(int wx, int wy) {
    final double baseDist = sqrt(wx * wx + wy * wy);
    // Low-frequency noise shifts the rings organically
    final double offset =
        _ringNoise.getNoise2(wx * 0.004, wy * 0.004) * _ringNoiseAmp;
    return (baseDist + offset).clamp(0.0, double.infinity);
  }

  bool _isRiverCell(int wx, int wy) {
    return _riverNoise.getNoise2(wx * 0.008, wy * 0.008) > 0.65;
  }
}
