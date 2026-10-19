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

  // Noise thresholds. The noises run at frequency 1 so the coordinate
  // factors below are the real scales; values spread about ±0.9 (fixed
  // 2026-10-18 – before, fast_noise's default frequency 0.01 shrank them to
  // ±0.1 and no river, park, industry or slum ever appeared).
  static const double _riverThreshold      = 0.40; // ~6 % waterfront + water
  static const double _waterThreshold      = 0.48; // ~3 % open water
  static const double _industrialThreshold = 0.33; // ~10 % of the mid ring
  static const double _parkThreshold       = 0.33; // ~10 % outside the centre
  static const double _slumsThreshold      = 0.36; // ~8 % of the transition

  /// No water at the pastor's house and the spawn point.
  static bool _nearHome(int wx, int wy) {
    final dx = wx - 220, dy = wy - 223;
    return dx * dx + dy * dy < 24 * 24;
  }

  DistrictSelector({required int seed})
      : _ringNoise       = PerlinNoise(seed: seed + 2, frequency: 1),
        _riverNoise      = PerlinNoise(seed: seed + 1, frequency: 1),
        _industrialNoise = PerlinNoise(seed: seed + 7, frequency: 1),
        _parkNoise       = PerlinNoise(seed: seed + 11, frequency: 1),
        _slumsNoise      = PerlinNoise(seed: seed + 13, frequency: 1);

  // ---- Public API ---------------------------------------------------------

  DistrictType getDistrictType(int wx, int wy) {
    // 0. The pastor's home stands in a calm suburb: a full lot with roof
    //    and cross, never cut by slum lots, industry, a park or water.
    if (_nearHome(wx, wy)) return DistrictType.suburbs;

    // 1. Water check (rivers / coast)
    if (_isRiverCell(wx, wy)) return DistrictType.waterfront;

    // 2. Effective distance from city centre with organic noise offset
    final double dist = _effectiveDist(wx, wy);

    // 3. Industrial pockets in mid-ring (commercial → suburbs band)
    if (dist > _downtownRadius && dist < _suburbsRadius) {
      final double iVal = _industrialNoise.getNoise2(wx * 0.008, wy * 0.008);
      if (iVal > _industrialThreshold) return DistrictType.industrial;
    }

    // 4. Park pockets – scattered everywhere outside downtown
    if (dist > _commercialRadius) {
      final double pVal = _parkNoise.getNoise2(wx * 0.012, wy * 0.012);
      if (pVal > _parkThreshold) return DistrictType.park;
    }

    // 5. Slum pockets in the commercial-to-suburbs transition
    if (dist > _commercialRadius && dist < _suburbsRadius + 50) {
      final double sVal = _slumsNoise.getNoise2(wx * 0.01, wy * 0.01);
      if (sVal > _slumsThreshold) return DistrictType.slums;
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
    if (_nearHome(wx, wy)) return false;
    return _riverNoise.getNoise2(wx * 0.008, wy * 0.008) > _waterThreshold;
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
    if (_nearHome(wx, wy)) return false;
    return _riverNoise.getNoise2(wx * 0.008, wy * 0.008) > _riverThreshold;
  }
}
