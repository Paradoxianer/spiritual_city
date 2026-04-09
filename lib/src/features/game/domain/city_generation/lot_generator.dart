import 'dart:math';
import 'package:flame_noise/flame_noise.dart';
import '../models/cell_object.dart';
import 'district_selector.dart';

class LotGenerator {
  final PerlinNoise _spiritNoise;

  LotGenerator({required int seed}) : _spiritNoise = PerlinNoise(seed: seed + 99);

  CellData? generateLotContent(int wx, int wy, DistrictType district, Random rand) {
    final int grid = (district == DistrictType.slums) ? 6 : 8;
    final int modX = wx % grid;
    final int modY = wy % grid;

    // Gehweg-Puffer um Gebäude
    if (modX == 0 || modY == 0) return null;

    // Distrikt-spezifische Bebauungschance
    double buildChance = 0.8;
    if (district == DistrictType.park) buildChance = 0.05;
    if (district == DistrictType.suburbs) buildChance = 0.6;

    if (rand.nextDouble() > buildChance) return _generateNature(district, rand);

    // Gebäude-Typ-Auswahl
    final double sVal = (_spiritNoise.noise2(wx * 0.1, wy * 0.1) + 1) / 2;
    BuildingType bType = _getBuildingType(district, rand, sVal);
    
    // Eindeutige ID für das Gebäude (Zentrum der Parzelle)
    final rootX = (wx ~/ grid) * grid;
    final rootY = (wy ~/ grid) * grid;
    final String bId = 'b_${rootX}_$rootY';

    // EINGANGS-LOGIK: Der Eingang ist immer an der Seite, die zur Straße zeigt.
    final bool isEntrance = (modX == grid ~/ 2 && modY == 1);

    return BuildingData(
      type: bType,
      buildingId: bId,
      hasInterior: true,
      floorCount: _getFloorCount(bType, district, rand),
      isEntrance: isEntrance,
    );
  }

  BuildingType _getBuildingType(DistrictType district, Random rand, double sVal) {
    if (sVal > 0.85 && rand.nextDouble() > 0.7) return BuildingType.church;

    switch (district) {
      case DistrictType.downtown:
        return rand.nextDouble() > 0.4 ? BuildingType.skyscraper : BuildingType.shop;
      case DistrictType.industrial:
        return BuildingType.shop;
      case DistrictType.suburbs:
        return rand.nextDouble() > 0.1 ? BuildingType.house : BuildingType.hospital;
      case DistrictType.slums:
        return BuildingType.house;
      case DistrictType.waterfront:
        return rand.nextDouble() > 0.5 ? BuildingType.shop : BuildingType.house;
      default:
        return BuildingType.house;
    }
  }

  CellData _generateNature(DistrictType district, Random rand) {
    if (district == DistrictType.park) {
      return NatureData(type: rand.nextDouble() > 0.4 ? NatureType.tree : NatureType.park);
    }
    return NatureData(type: NatureType.tree);
  }

  int _getFloorCount(BuildingType type, DistrictType district, Random rand) {
    if (type == BuildingType.skyscraper) return 10 + rand.nextInt(15);
    if (district == DistrictType.slums) return 1;
    return 1 + rand.nextInt(3);
  }
}
