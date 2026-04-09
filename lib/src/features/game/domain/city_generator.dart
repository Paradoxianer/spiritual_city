import 'dart:math';
import 'package:fast_noise/fast_noise.dart';
import '../../../core/utils/seed_manager.dart';
import 'models/city_cell.dart';
import 'models/city_chunk.dart';

class CityGenerator {
  final SeedManager seedManager;

  CityGenerator(this.seedManager);

  void generateChunk(CityChunk chunk) {
    // 1. Dichte-Noise (Großflächig)
    final densityNoise = array2dTo1d(noise2d(
      CityChunk.chunkSize,
      CityChunk.chunkSize,
      seed: seedManager.seed,
      frequency: 0.01, // Sehr niedrige Frequenz für große Stadtviertel
      noiseType: NoiseType.perlin,
      xOffset: chunk.chunkX * CityChunk.chunkSize,
      yOffset: chunk.chunkY * CityChunk.chunkSize,
    ));

    // 2. Struktur-Noise (Straßen/Blöcke)
    final structureNoise = array2dTo1d(noise2d(
      CityChunk.chunkSize,
      CityChunk.chunkSize,
      seed: seedManager.seed + 123,
      frequency: 0.1, 
      noiseType: NoiseType.perlin,
      xOffset: chunk.chunkX * CityChunk.chunkSize,
      yOffset: chunk.chunkY * CityChunk.chunkSize,
    ));

    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final worldX = chunk.getWorldX(x);
        final worldY = chunk.getWorldY(y);
        final index = y * CityChunk.chunkSize + x;
        
        final dens = (densityNoise[index] + 1) / 2; // 0.0 (Rand) bis 1.0 (Zentrum)
        final struct = structureNoise[index];

        CellType type = CellType.empty;
        
        // Einfache Logik für Stadtstruktur
        if (struct.abs() < 0.1) {
          type = CellType.road;
        } else if (struct > 0.3) {
          if (dens > 0.7) {
            type = CellType.buildingLarge; // Zentrum
          } else if (dens > 0.4) {
            type = CellType.buildingSmall; // Wohngebiete
          } else {
            type = CellType.park; // Stadtrand
          }
        }

        // Kirchen-Platzierung (Sehr selten, deterministisch)
        final churchRandom = Random(seedManager.seed + worldX * 1000 + worldY);
        if (type == CellType.buildingSmall && churchRandom.nextDouble() < 0.02) {
          type = CellType.church;
        }

        chunk.cells['$x,$y'] = CityCell(
          x: worldX,
          y: worldY,
          type: type,
          density: dens,
          crime: (1.0 - dens) * struct.abs(),
          spiritualState: type == CellType.church ? 1.0 : (struct * dens),
        );
      }
    }
  }

  List<double> array2dTo1d(List<List<double>> source) {
    return source.expand((element) => element).toList();
  }
}
