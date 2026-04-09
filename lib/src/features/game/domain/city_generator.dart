import 'dart:math';
import '../../../core/utils/seed_manager.dart';
import 'models/city_cell.dart';
import 'models/city_grid.dart';

class CityGenerator {
  final SeedManager seedManager;

  CityGenerator(this.seedManager);

  CityGrid generate(int width, int height) {
    final grid = CityGrid(width: width, height: height);
    final random = seedManager.nextRandom();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final cell = _generateCell(x, y, random);
        grid.setCell(x, y, cell);
      }
    }

    return grid;
  }

  CityCell _generateCell(int x, int y, Random random) {
    // Simple deterministic generation for now
    // We can replace this with Perlin Noise later
    final typeValue = random.nextDouble();
    CellType type;
    
    if (typeValue < 0.1) {
      type = CellType.road;
    } else if (typeValue < 0.3) {
      type = CellType.building;
    } else if (typeValue < 0.4) {
      type = CellType.park;
    } else {
      type = CellType.empty;
    }

    return CityCell(
      x: x,
      y: y,
      type: type,
      crime: random.nextDouble(),
      density: random.nextDouble(),
      spiritualState: (random.nextDouble() * 2) - 1.0, // -1.0 to 1.0
    );
  }
}
