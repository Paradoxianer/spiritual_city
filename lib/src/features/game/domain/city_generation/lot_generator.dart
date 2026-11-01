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

  final int _lotSeed;

  LotGenerator({required int seed, required SpecialBuildingRegistry registry})
      : _registry = registry,
        _lotSeed = seed * 2654435761,
        _spiritNoise = PerlinNoise(seed: seed + 99, frequency: 1);

  CellData? generateLotContent(
      int wx, int wy, DistrictType district, Random rand) {
    // ---- 1. Lot grid: carve sidewalk buffers ----------------------------
    // Grid pitch varies by district for visual variety
    final int grid = _gridPitch(district);
    final int modX = wx % grid;
    final int modY = wy % grid;
    // Lot root (top-left corner of this grid block)
    final int rootX = wx - modX;
    final int rootY = wy - modY;

    // Check if THIS exact cell is a special building.
    // Special cells bypass the sidewalk filter so they are never dropped.
    final BuildingType? exactSpecial =
        _registry.getSpecialBuilding(wx, wy, district);
    if (exactSpecial != null) {
      // The whole lot is one building: the pastor house wins over a zoned
      // special that happens to fall into the same lot (playtest
      // 2026-10-31: a supermarket swallowed the home in some cities).
      final lot = _lotSpecial(rootX, rootY, grid, district) ?? exactSpecial;
      return _buildingData(lot, rootX, rootY, grid, modX, modY, district, rand);
    }

    // Row/column 0 of each grid block = sidewalk (empty).
    if (modX == 0 || modY == 0) return null;

    // ---- 2. Lot-wide special building scan --------------------------------
    // If any cell in this lot block is a special building, ALL non-sidewalk
    // cells in the lot use that type so the whole building renders correctly
    // (e.g. the pastor house appears amber/gold on every cell, not just one).
    final lotSpecial = _lotSpecial(rootX, rootY, grid, district);
    if (lotSpecial != null) {
      return _buildingData(lotSpecial, rootX, rootY, grid, modX, modY, district, rand);
    }

    // ---- 3. One decision per lot (#18 playtest) ---------------------------
    // Built or not, building type and footprint are decided once per lot,
    // so a lot shows one coherent building instead of a patchwork of
    // random cells.
    final lotRand = Random(_lotSeed ^ (rootX * 73856093) ^ (rootY * 19349663));
    if (lotRand.nextDouble() > _buildChance(district)) {
      return _generateNature(district, rand);
    }

    // ---- 4. Ordinary building type from district rules ------------------
    final double sVal =
        (_spiritNoise.getNoise2(rootX * 0.1, rootY * 0.1) + 1) / 2;
    final BuildingType bType =
        _ordinaryBuildingType(district, lotRand, sVal);

    // Low-rise buildings stand in a garden: one ring of green inside the lot.
    final int inset = _gardenInset(bType, district);
    if (modX <= inset || modY <= inset || modX >= grid - inset || modY >= grid - inset) {
      return NatureData(type: rand.nextDouble() < 0.2 ? NatureType.tree : NatureType.park);
    }
    return _buildingData(bType, rootX, rootY, grid, modX, modY, district, rand);
  }

  /// The special building of the lot rooted at ([rootX], [rootY]): the
  /// pastor house if it is in the lot, otherwise the first one found.
  BuildingType? _lotSpecial(int rootX, int rootY, int grid, DistrictType district) {
    BuildingType? first;
    for (int dy = 0; dy < grid; dy++) {
      for (int dx = 0; dx < grid; dx++) {
        final s = _registry.getSpecialBuilding(rootX + dx, rootY + dy, district);
        if (s == BuildingType.pastorHouse) return s;
        first ??= s;
      }
    }
    return first;
  }

  int _gardenInset(BuildingType type, DistrictType district) {
    if (district == DistrictType.slums) return 0;
    return switch (type) {
      BuildingType.house || BuildingType.shop => 1,
      BuildingType.apartment when district != DistrictType.downtown => 1,
      _ => 0,
    };
  }

  // ---- Building data factory -------------------------------------------

  BuildingData _buildingData(
    BuildingType type,
    int rootX,
    int rootY,
    int grid,
    int modX,
    int modY,
    DistrictType district,
    Random rand,
  ) {
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

  /// Lot size. Every pitch divides [lotBlock], and every street runs on a
  /// multiple of it, so a street never cuts through a lot (playtest
  /// 2026-11-01: houses were "cut").
  static int gridPitch(DistrictType district) => district == DistrictType.slums ? 4 : lotBlock;
  int _gridPitch(DistrictType district) => gridPitch(district);

  /// The block whose district decides its lots – the district at its
  /// centre, so a district border never splits a building.
  static const int lotBlock = 8;
  static (int, int) blockCentre(int wx, int wy) =>
      (wx - wx % lotBlock + lotBlock ~/ 2, wy - wy % lotBlock + lotBlock ~/ 2);

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
    // Mostly lawn with some trees: open green instead of a solid forest.
    final treeChance = district == DistrictType.park ? 0.35 : 0.25;
    return NatureData(
        type: rand.nextDouble() < treeChance ? NatureType.tree : NatureType.park);
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
