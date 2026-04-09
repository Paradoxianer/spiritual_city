import 'package:flame_noise/flame_noise.dart';

enum DistrictType { downtown, suburbs, slums, park, industrial, waterfront }

class DistrictSelector {
  final PerlinNoise _districtNoise;
  final PerlinNoise _riverNoise;

  DistrictSelector({required int seed}) 
    : _districtNoise = PerlinNoise(seed: seed + 2),
      _riverNoise = PerlinNoise(seed: seed + 1);

  DistrictType getDistrictType(int wx, int wy) {
    final double rVal = _riverNoise.noise2(wx * 0.01, wy * 0.01);
    final double dVal = (_districtNoise.noise2(wx * 0.005, wy * 0.005) + 1) / 2;

    if (rVal > 0.6) return DistrictType.waterfront;
    if (dVal > 0.8) return DistrictType.downtown;
    if (dVal > 0.6) return DistrictType.industrial;
    if (dVal > 0.4) return DistrictType.suburbs;
    if (dVal > 0.2) return DistrictType.slums;
    return DistrictType.park;
  }

  bool isWater(int wx, int wy) {
    return _riverNoise.noise2(wx * 0.01, wy * 0.01) > 0.6;
  }
}
