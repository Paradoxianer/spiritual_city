import 'dart:math';
import 'package:flame_noise/flame_noise.dart';
import '../models/cell_object.dart';
import 'district_selector.dart';
import 'special_building_registry.dart';

/// Determines what occupies each non-road cell (building or nature).
///
/// Realistic building-type distribution per district (research summary):
///  • Downtown / Commercial:  skyscrapers, offices, shops, apartments
///  • Suburbs:                houses, apartments, small shops, civic services
///  • Outskirts:              houses, some agriculture / parks
///  • Industrial:             factories, warehouses, occasional office/office
///  • Slums:                  dense housing, small shops, neglected lots
///  • Waterfront:             apartments, hotels (shops), leisure
///  • Park:                   trees, open green – no buildings
class LotGenerator {
  final SpecialBuildingRegistry _registry;
  final PerlinNoise _spiritNoise;

  LotGenerator({required int seed, required SpecialBuildingRegistry registry})
      : _registry = registry,
        _spiritNoise = PerlinNoise(seed: seed + 99);

  CellData? generateLotContent(
      int wx, int wy, DistrictType district, Random rand) {
    // ---- 1. Lot grid: carve sidewalk buffers ----------------------------
    // Grid pitch varies by district for visual variety
    final int grid = _gridPitch(district);
    final int modX = wx % grid;
    final int modY = wy % grid;

    // Row/column 0 of each grid block = sidewalk (empty).
    // Exception: special buildings are always placed regardless of their
    // position within the grid block so they can never be silently dropped.
    final BuildingType? special = _registry.getSpecialBuilding(wx, wy, district);
    if (special != null) {
      return _buildingData(special, wx, wy, grid, modX, modY, district, rand);
    }

    if (modX == 0 || modY == 0) return null;

    // ---- 2. Chance to leave lot unpaved (nature / gap) ------------------
    final double buildChance = _buildChance(district);
    if (rand.nextDouble() > buildChance) {
      return _generateNature(district, rand);
    }

    // ---- 4. Ordinary building type from district rules ------------------
    final double sVal =
        (_spiritNoise.getNoise2(wx * 0.1, wy * 0.1) + 1) / 2;
    final BuildingType bType =
        _ordinaryBuildingType(district, rand, sVal);
    return _buildingData(bType, wx, wy, grid, modX, modY, district, rand);
  }

  // ---- Building data factory -------------------------------------------

  BuildingData _buildingData(
    BuildingType type,
    int wx,
    int wy,
    int grid,
    int modX,
    int modY,
    DistrictType district,
    Random rand,
  ) {
    final int rootX = (wx ~/ grid) * grid;
    final int rootY = (wy ~/ grid) * grid;
    final String bId = 'b_${rootX}_$rootY';
    final bool isEntrance = (modX == grid ~/ 2 && modY == 1);
    // House number: deterministic from root coordinates.
    // odd rootX → odd numbers (1, 3, …), even rootX → even numbers (2, 4, …).
    final int num = ((rootX.abs() + rootY.abs()) % 99) * 2 + (rootX.isOdd ? 1 : 0);
    return BuildingData(
      type: type,
      buildingId: bId,
      hasInterior: true,
      floorCount: _floorCount(type, district, rand),
      isEntrance: isEntrance,
      houseNumber: num,
    );
  }

  // ---- District rules -----------------------------------------------------

  int _gridPitch(DistrictType district) {
    switch (district) {
      case DistrictType.slums:
        return 6; // tight, irregular
      case DistrictType.outskirts:
        return 10; // spacious lots
      default:
        return 8;
    }
  }

  double _buildChance(DistrictType district) {
    switch (district) {
      case DistrictType.park:
        return 0.0; // no buildings in parks
      case DistrictType.outskirts:
        return 0.35;
      case DistrictType.suburbs:
        return 0.65;
      case DistrictType.slums:
        return 0.80;
      case DistrictType.downtown:
      case DistrictType.commercial:
        return 0.92;
      case DistrictType.industrial:
        return 0.75;
      case DistrictType.waterfront:
        return 0.55;
    }
  }

  /// Returns an ordinary (non-special) building type appropriate for the
  /// district.  The distribution intentionally keeps hospitals, churches, etc.
  /// *out* of this method – they are handled exclusively by the registry.
  BuildingType _ordinaryBuildingType(
      DistrictType district, Random rand, double sVal) {
    switch (district) {
      // ---- Downtown: skyscrapers dominate, some offices/shops/apartments --
      case DistrictType.downtown:
        final double r = rand.nextDouble();
        if (r < 0.45) return BuildingType.skyscraper;
        if (r < 0.75) return BuildingType.office;
        if (r < 0.90) return BuildingType.shop;
        return BuildingType.apartment;

      // ---- Commercial ring: offices, shops, apartments, malls -------------
      case DistrictType.commercial:
        final double r = rand.nextDouble();
        if (r < 0.30) return BuildingType.office;
        if (r < 0.55) return BuildingType.shop;
        if (r < 0.75) return BuildingType.apartment;
        if (r < 0.85) return BuildingType.skyscraper;
        return BuildingType.house;

      // ---- Suburbs: mostly housing ----------------------------------------
      case DistrictType.suburbs:
        final double r = rand.nextDouble();
        if (r < 0.50) return BuildingType.house;
        if (r < 0.75) return BuildingType.apartment;
        if (r < 0.90) return BuildingType.shop;
        return BuildingType.office;

      // ---- Outskirts: very sparse, mostly houses --------------------------
      case DistrictType.outskirts:
        return rand.nextDouble() < 0.80
            ? BuildingType.house
            : BuildingType.shop;

      // ---- Industrial: factories and warehouses ---------------------------
      case DistrictType.industrial:
        return rand.nextDouble() < 0.60
            ? BuildingType.factory
            : BuildingType.warehouse;

      // ---- Slums: dense low-quality housing + small shops -----------------
      case DistrictType.slums:
        return rand.nextDouble() < 0.75
            ? BuildingType.house
            : BuildingType.shop;

      // ---- Waterfront: apartments + leisure shops -------------------------
      case DistrictType.waterfront:
        return rand.nextDouble() < 0.55
            ? BuildingType.apartment
            : BuildingType.shop;

      case DistrictType.park:
        return BuildingType.house; // fallback; buildChance=0 prevents this
    }
  }

  CellData _generateNature(DistrictType district, Random rand) {
    if (district == DistrictType.park) {
      return NatureData(
          type: rand.nextDouble() > 0.4 ? NatureType.tree : NatureType.park);
    }
    return NatureData(type: NatureType.tree);
  }

  int _floorCount(BuildingType type, DistrictType district, Random rand) {
    switch (type) {
      case BuildingType.skyscraper:
        return 15 + rand.nextInt(20);
      case BuildingType.apartment:
        return 4 + rand.nextInt(8);
      case BuildingType.office:
        return 3 + rand.nextInt(7);
      case BuildingType.cityHall:
      case BuildingType.cathedral:
      case BuildingType.museum:
      case BuildingType.university:
      case BuildingType.trainStation:
        return 2 + rand.nextInt(3);
      case BuildingType.mall:
      case BuildingType.hospital:
      case BuildingType.stadium:
        return 2 + rand.nextInt(2);
      case BuildingType.factory:
      case BuildingType.warehouse:
      case BuildingType.powerPlant:
        return 1 + rand.nextInt(2);
      case BuildingType.house:
        return district == DistrictType.slums ? 1 : 1 + rand.nextInt(2);
      default:
        return 1;
    }
  }
}
