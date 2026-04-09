import '../entities/cell_state.dart';
import '../entities/cell_type.dart';
import '../entities/city_grid.dart';
import 'noise_generator.dart';

class CityGeneratorService {
  static const int _crimeNoiseOffset = 100;
  static const int _spiritualStrengthNoiseOffset = 200;

  CityGrid generate(int seed, int width, int height) {
    final noise = SeededNoiseGenerator(seed);
    final cells = List.generate(height, (y) {
      return List.generate(width, (x) {
        if (x % 6 == 0 || y % 6 == 0) {
          return const CellState(type: CellType.road);
        }
        final noiseVal = noise.getValue(x, y);
        final CellType type;
        if (noiseVal < 0.3) {
          type = CellType.water;
        } else if (noiseVal < 0.5) {
          type = CellType.park;
        } else {
          type = CellType.building;
        }
        final crime = noise.getValue(x + _crimeNoiseOffset, y);
        final hope = 1.0 - crime;
        final spiritualStrength =
            noise.getValue(x + _spiritualStrengthNoiseOffset, y);
        final population =
            type == CellType.building ? (noiseVal * 50).round() : 0;
        return CellState(
          type: type,
          crime: crime,
          hope: hope,
          spiritualStrength: spiritualStrength,
          population: population,
        );
      });
    });
    return CityGrid(width: width, height: height, cells: cells);
  }
}
