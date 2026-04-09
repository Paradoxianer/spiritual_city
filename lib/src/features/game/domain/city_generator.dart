import 'dart:math';
import 'package:flame_noise/flame_noise.dart';
import '../../../core/utils/seed_manager.dart';
import 'models/city_cell.dart';
import 'models/city_chunk.dart';
import 'models/cell_object.dart';

/// Distrikt-Typen für unterschiedliche Bebauungslogiken und Atmosphären
enum DistrictType { downtown, suburbs, slums, park, industrial, waterfront }

/// Ein hochmoderner City-Generator, der Stadtplanung simuliert.
/// Erzeugt komplexe, deterministische Strukturen mit Fokus auf betretbare Gebäude.
class CityGenerator {
  final SeedManager seedManager;

  CityGenerator(this.seedManager);

  void generateChunk(CityChunk chunk) {
    // Verschiedene Noise-Instanzen für unterschiedliche Ebenen (Samen-Verschiebung für Unabhängigkeit)
    final riverNoise = PerlinNoise(seed: seedManager.seed + 1);
    final districtNoise = PerlinNoise(seed: seedManager.seed + 2);
    final detailNoise = PerlinNoise(seed: seedManager.seed + 3);

    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final worldX = chunk.getWorldX(x);
        final worldY = chunk.getWorldY(y);
        
        // Lokaler Zufall für zellspezifische Details
        final cellRand = Random(seedManager.seed ^ (worldX * 374761393) ^ (worldY * 668265263));
        
        // 1. GEOGRAPHIE: Wasser & Land
        final double riverVal = riverNoise.noise2(worldX * 0.01, worldY * 0.01);
        if (riverVal > 0.6) {
          chunk.cells['$x,$y'] = _createNatureCell(worldX, worldY, NatureType.water, 0.2);
          continue;
        }

        // 2. DISTRIKT BESTIMMEN
        final double dVal = (districtNoise.noise2(worldX * 0.005, worldY * 0.005) + 1) / 2;
        final district = _getDistrictType(dVal, riverVal);
        
        // 3. STRASSENNETZ (Hierarchie)
        final roadData = _getRoadData(worldX, worldY, district, cellRand);
        
        if (roadData != null) {
          chunk.cells['$x,$y'] = CityCell(
            x: worldX,
            y: worldY,
            data: roadData,
            density: 1.0,
            crime: _calculateCrime(district, dVal, 0.0),
            spiritualState: _calculateSpiritualInitialState(roadData, 0.0, dVal),
          );
          continue;
        }

        // 4. BEBAUUNG & PARZELLIERUNG
        final lotContent = _generateLotContent(worldX, worldY, district, cellRand, detailNoise);
        
        chunk.cells['$x,$y'] = CityCell(
          x: worldX,
          y: worldY,
          data: lotContent,
          density: _getDensityByDistrict(district),
          crime: _calculateCrime(district, dVal, detailNoise.noise2(worldX * 0.1, worldY * 0.1)),
          spiritualState: _calculateSpiritualInitialState(lotContent, 0.0, dVal),
        );
      }
    }
  }

  /// Bestimmt den Distrikt-Typ basierend auf Noise-Werten.
  DistrictType _getDistrictType(double dVal, double rVal) {
    if (rVal > 0.5) return DistrictType.waterfront;
    if (dVal > 0.8) return DistrictType.downtown;
    if (dVal > 0.6) return DistrictType.industrial;
    if (dVal > 0.4) return DistrictType.suburbs;
    if (dVal > 0.2) return DistrictType.slums;
    return DistrictType.park;
  }

  /// Erzeugt ein hierarchisches Straßennetz.
  RoadData? _getRoadData(int wx, int wy, DistrictType district, Random rand) {
    // Boulevards (Hauptverkehrsadern) - Alle 32 Felder, sehr stabil
    if (wx % 32 == 0 || wy % 32 == 0) {
      return RoadData(type: RoadType.big, isIntersection: wx % 32 == 0 && wy % 32 == 0);
    }

    // Streets (Nebenstraßen) - Gitterweite variiert je nach Distrikt
    int interval = 8;
    if (district == DistrictType.park) return null; // Keine Straßen im Park, nur Wege (später)
    if (district == DistrictType.slums) interval = 6;
    
    // Kleiner Jitter für organischere Straßen in Vororten/Slums
    int jitterX = (district == DistrictType.suburbs || district == DistrictType.slums) ? (wx % 32 > 16 ? 1 : 0) : 0;
    
    if ((wx + jitterX) % interval == 0 || wy % interval == 0) {
      return RoadData(type: RoadType.small);
    }

    return null;
  }

  /// Logik für den Inhalt einer Parzelle (Lot).
  CellData? _generateLotContent(int wx, int wy, DistrictType district, Random rand, PerlinNoise detail) {
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
    BuildingType bType = _getBuildingType(district, rand, detail.noise2(wx * 0.1, wy * 0.1));
    
    // Eindeutige ID für das Gebäude (Zentrum der Parzelle)
    final rootX = (wx ~/ grid) * grid;
    final rootY = (wy ~/ grid) * grid;
    final String bId = 'b_${rootX}_$rootY';

    // EINGANGS-LOGIK: Der Eingang ist immer an der Seite, die zur Straße zeigt.
    // In diesem Raster-Modell setzen wir ihn auf eine feste Position relativ zum Lot-Zentrum.
    final bool isEntrance = (modX == grid ~/ 2 && modY == 1);

    return BuildingData(
      type: bType,
      buildingId: bId,
      hasInterior: true, // Alle neuen Gebäude sind betretbar
      floorCount: _getFloorCount(bType, district, rand),
      isEntrance: isEntrance,
    );
  }

  BuildingType _getBuildingType(DistrictType district, Random rand, double noise) {
    if (noise > 0.8) return BuildingType.church; // Kirchen als Landmarks

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

  CityCell _createNatureCell(int wx, int wy, NatureType type, double spirit) {
    return CityCell(
      x: wx,
      y: wy,
      data: NatureData(type: type),
      density: 0.0,
      spiritualState: spirit,
    );
  }

  int _getFloorCount(BuildingType type, DistrictType district, Random rand) {
    if (type == BuildingType.skyscraper) return 10 + rand.nextInt(15);
    if (district == DistrictType.slums) return 1;
    return 1 + rand.nextInt(3);
  }

  double _getDensityByDistrict(DistrictType district) {
    switch (district) {
      case DistrictType.downtown: return 0.9;
      case DistrictType.slums: return 0.8;
      case DistrictType.suburbs: return 0.4;
      case DistrictType.park: return 0.1;
      default: return 0.5;
    }
  }

  double _calculateCrime(DistrictType district, double dVal, double detail) {
    double base = 0.1;
    if (district == DistrictType.slums) base = 0.7;
    if (district == DistrictType.industrial) base = 0.4;
    return (base + detail.abs() * 0.2).clamp(0.0, 1.0);
  }

  double _calculateSpiritualInitialState(CellData? data, double detail, double dVal) {
    if (data is BuildingData && data.type == BuildingType.church) return 0.85;
    if (data is NatureData && data.type == NatureType.water) return 0.4;
    return (dVal - 0.5) * 2.0; // Mapped auf -1.0 bis 1.0
  }
}
