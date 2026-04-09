import 'dart:math';
import 'package:flame_noise/flame_noise.dart';
import '../../../../core/utils/seed_manager.dart';
import '../models/city_cell.dart';
import '../models/city_chunk.dart';
import '../models/cell_object.dart';
import 'district_selector.dart';
import 'road_generator.dart';
import 'lot_generator.dart';
import 'special_building_registry.dart';

/// Zentraler Koordinator für die prozedurale Stadtgenerierung.
/// Teilt die Arbeit in spezialisierte Prozessoren auf.
class CityGenerator {
  final SeedManager seedManager;
  final DistrictSelector _districtSelector;
  final RoadGenerator _roadGenerator;
  final LotGenerator _lotGenerator;
  final PerlinNoise _detailNoise;

  CityGenerator(this.seedManager)
      : _districtSelector = DistrictSelector(seed: seedManager.seed),
        _roadGenerator = RoadGenerator(),
        _lotGenerator = LotGenerator(
          seed: seedManager.seed,
          registry: SpecialBuildingRegistry(seed: seedManager.seed),
        ),
        _detailNoise = PerlinNoise(seed: seedManager.seed + 3);

  void generateChunk(CityChunk chunk) {
    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final worldX = chunk.getWorldX(x);
        final worldY = chunk.getWorldY(y);
        
        final cellRand = Random(seedManager.seed ^ (worldX * 374761393) ^ (worldY * 668265263));
        
        // 1. Geographie-Check (Wasser)
        if (_districtSelector.isWater(worldX, worldY)) {
          chunk.cells['$x,$y'] = _createNatureCell(worldX, worldY, NatureType.water);
          continue;
        }

        // 2. Distrikt bestimmen
        final district = _districtSelector.getDistrictType(worldX, worldY);
        
        // 3. Straßennetz
        final roadData = _roadGenerator.getRoadData(worldX, worldY, district, cellRand);
        
        if (roadData != null) {
          chunk.cells['$x,$y'] = _createCell(worldX, worldY, roadData, district, 1.0);
          continue;
        }

        // 4. Parzellierung & Bebauung
        final lotContent = _lotGenerator.generateLotContent(worldX, worldY, district, cellRand);
        chunk.cells['$x,$y'] = _createCell(worldX, worldY, lotContent, district, _getDensity(district));
      }
    }
  }

  CityCell _createCell(int wx, int wy, CellData? data, DistrictType district, double density) {
    final detail = _detailNoise.getNoise2(wx.toDouble() * 0.1, wy.toDouble() * 0.1);
    return CityCell(
      x: wx,
      y: wy,
      data: data,
      density: density,
      crime: _calculateCrime(district, detail),
      spiritualState: _calculateSpiritualState(data, detail),
    );
  }

  CityCell _createNatureCell(int wx, int wy, NatureType type) {
    return CityCell(
      x: wx,
      y: wy,
      data: NatureData(type: type),
      density: 0.0,
      spiritualState: type == NatureType.water ? 0.4 : 0.0,
    );
  }

  double _getDensity(DistrictType district) {
    switch (district) {
      case DistrictType.downtown:   return 0.95;
      case DistrictType.commercial: return 0.80;
      case DistrictType.slums:      return 0.85;
      case DistrictType.suburbs:    return 0.50;
      case DistrictType.outskirts:  return 0.25;
      case DistrictType.industrial: return 0.60;
      case DistrictType.park:       return 0.05;
      case DistrictType.waterfront: return 0.40;
    }
  }

  double _calculateCrime(DistrictType district, double detail) {
    double base = 0.1;
    if (district == DistrictType.slums)      base = 0.7;
    if (district == DistrictType.industrial) base = 0.35;
    if (district == DistrictType.outskirts)  base = 0.2;
    return (base + detail.abs() * 0.2).clamp(0.0, 1.0);
  }

  double _calculateSpiritualState(CellData? data, double detail) {
    if (data is BuildingData) {
      switch (data.type) {
        case BuildingType.cathedral: return 0.95;
        case BuildingType.church:    return 0.85;
        case BuildingType.cityHall:  return 0.70;
        case BuildingType.hospital:  return 0.60;
        case BuildingType.museum:    return 0.50;
        case BuildingType.library:   return 0.45;
        case BuildingType.university:return 0.40;
        default:                     break;
      }
    }
    return detail;
  }
}
