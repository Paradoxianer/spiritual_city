import 'dart:math';
import 'package:flame_noise/flame_noise.dart';
import '../../../core/utils/seed_manager.dart';
import 'models/city_cell.dart';
import 'models/city_chunk.dart';
import 'models/cell_object.dart';

class CityGenerator {
  final SeedManager seedManager;

  CityGenerator(this.seedManager);

  void generateChunk(CityChunk chunk) {
    // In flame_noise v0.1.0 nutzen wir die FastNoise-Klasse, 
    // die alle Algorithmen (Perlin, Simplex etc.) bündelt.
    final densityNoiseGen = FastNoise(
      seed: seedManager.seed,
      frequency: 0.05,
      noiseType: NoiseType.perlin,
    );

    final structureNoiseGen = FastNoise(
      seed: seedManager.seed + 123,
      frequency: 0.1,
      noiseType: NoiseType.perlin,
    );

    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final worldX = chunk.getWorldX(x);
        final worldY = chunk.getWorldY(y);
        
        // Nutzung von getNoise2 für die Generierung
        final densRaw = densityNoiseGen.getNoise2(worldX.toDouble(), worldY.toDouble());
        final dens = (densRaw + 1) / 2;
        
        final struct = structureNoiseGen.getNoise2(worldX.toDouble(), worldY.toDouble());

        CellData? data;
        
        if (struct.abs() < 0.1) {
          data = RoadData(type: dens > 0.6 ? RoadType.big : RoadType.small);
        } else if (struct > 0.3) {
          if (dens > 0.8) {
            data = BuildingData(type: BuildingType.skyscraper);
          } else if (dens > 0.4) {
            final buildingRand = Random(seedManager.seed + worldX * 1000 + worldY);
            if (buildingRand.nextDouble() < 0.05) {
              data = BuildingData(type: BuildingType.church);
            } else if (buildingRand.nextDouble() < 0.02) {
              data = BuildingData(type: BuildingType.hospital);
            } else {
              data = BuildingData(type: BuildingType.house);
            }
          } else {
            data = NatureData(type: NatureType.park);
          }
        } else if (struct < -0.4 && dens < 0.3) {
           data = NatureData(type: NatureType.water);
        }

        chunk.cells['$x,$y'] = CityCell(
          x: worldX,
          y: worldY,
          data: data,
          density: dens,
          crime: (1.0 - dens) * struct.abs(),
          spiritualState: _calculateSpiritualInitialState(data, struct, dens),
        );
      }
    }
  }

  double _calculateSpiritualInitialState(CellData? data, double struct, double dens) {
    if (data is BuildingData && data.type == BuildingType.church) return 0.8;
    if (data is BuildingData && data.type == BuildingType.hospital) return 0.4;
    if (data is NatureData && data.type == NatureType.water) return 0.2;
    return struct * dens;
  }
}
