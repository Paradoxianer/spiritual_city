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

class CityGenerator {
  final SeedManager seedManager;
  final DistrictSelector _districtSelector;
  final RoadGenerator _roadGenerator;
  final LotGenerator _lotGenerator;
  final PerlinNoise _detailNoise;
  final PerlinNoise _spiritualNoise;

  CityGenerator(this.seedManager)
      : _districtSelector = DistrictSelector(seed: seedManager.seed),
        _roadGenerator = RoadGenerator(),
        _lotGenerator = LotGenerator(
          seed: seedManager.seed,
          registry: SpecialBuildingRegistry(seed: seedManager.seed),
        ),
        _detailNoise = PerlinNoise(seed: seedManager.seed + 3),
        _spiritualNoise = PerlinNoise(seed: seedManager.seed + 77);

  void generateChunk(CityChunk chunk) {
    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final worldX = chunk.getWorldX(x);
        final worldY = chunk.getWorldY(y);
        
        final cellRand = Random(seedManager.seed ^ (worldX * 374761393) ^ (worldY * 668265263));
        
        if (_districtSelector.isWater(worldX, worldY)) {
          chunk.cells['$x,$y'] = _createNatureCell(worldX, worldY, NatureType.water);
          continue;
        }

        final district = _districtSelector.getDistrictType(worldX, worldY);
        final roadData = _roadGenerator.getRoadData(worldX, worldY, district, cellRand);
        
        if (roadData != null) {
          chunk.cells['$x,$y'] = _createCell(worldX, worldY, roadData, district, 1.0);
          continue;
        }

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
      spiritualState: _calculateInitialSpiritualState(wx, wy, data, district),
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

  /// Initialisierung der geistlichen Welt laut Lastenheft 5.3
  double _calculateInitialSpiritualState(int wx, int wy, CellData? data, DistrictType district) {
    // 1. Kirchen und Pastorat sind positive Inseln
    if (data is BuildingData) {
      if (data.type == BuildingType.church || data.type == BuildingType.cathedral) {
        return 0.5; // +50 Grün
      }
      // Pastorat (angenommen bei 0,0 für den Start)
      if (wx.abs() < 5 && wy.abs() < 5) return 0.2; // +20 Grün
    }

    // 2. Perlin Noise für ungleichmäßige Verteilung (Lavalampen-Basis)
    // Wir skalieren den Noise so, dass ca. 80% der Stadt negativ (rot) starten
    final noise = _spiritualNoise.getNoise2(wx * 0.05, wy * 0.05);
    
    // Bias in Richtung Negativ (-0.3 Verschiebung sorgt für ~80% Rot)
    double state = noise - 0.3;

    // Slums sind tendenziell etwas dunkler
    if (district == DistrictType.slums) {
      state -= 0.2;
    }

    return state.clamp(-1.0, 1.0);
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
}
