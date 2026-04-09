// Smoke test: verifies the app can be instantiated without crashing.

import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/city/domain/services/city_generator.dart';
import 'package:spiritual_city/src/features/city/domain/entities/cell_type.dart';
import 'package:spiritual_city/src/features/spiritual_world/domain/services/game_of_life_service.dart';
import 'package:spiritual_city/src/features/spiritual_world/domain/entities/spiritual_cell_state.dart';
import 'package:spiritual_city/src/features/player/domain/entities/player_state.dart';
import 'package:spiritual_city/src/core/constants/game_constants.dart';

void main() {
  group('CityGeneratorService', () {
    test('generates a deterministic city from a seed', () {
      final service = CityGeneratorService();
      final grid1 = service.generate(42, 10, 10);
      final grid2 = service.generate(42, 10, 10);
      expect(grid1.width, 10);
      expect(grid1.height, 10);
      // Determinism: same seed => same output
      for (int y = 0; y < grid1.height; y++) {
        for (int x = 0; x < grid1.width; x++) {
          expect(grid1.cellAt(x, y).type, grid2.cellAt(x, y).type);
        }
      }
    });

    test('roads appear at every 6th column and row', () {
      final service = CityGeneratorService();
      final grid = service.generate(1, 12, 12);
      for (int x = 0; x < grid.width; x += 6) {
        expect(grid.cellAt(x, 1).type, CellType.road);
      }
      for (int y = 0; y < grid.height; y += 6) {
        expect(grid.cellAt(1, y).type, CellType.road);
      }
    });

    test('different seeds produce different cities', () {
      final service = CityGeneratorService();
      final gridA = service.generate(42, 10, 10);
      final gridB = service.generate(99, 10, 10);
      bool differ = false;
      outer:
      for (int y = 0; y < 10; y++) {
        for (int x = 0; x < 10; x++) {
          if (gridA.cellAt(x, y).type != gridB.cellAt(x, y).type) {
            differ = true;
            break outer;
          }
        }
      }
      expect(differ, isTrue);
    });
  });

  group('GameOfLifeService', () {
    test('dead cell with 3 live neighbors becomes alive', () {
      final svc = GameOfLifeService();
      // Build a 3x3 grid: center dead, 3 neighbors alive
      final grid = List.generate(3, (y) => List.generate(3, (x) {
        // Activate top-left, top-center, left-center
        final alive = (x == 0 && y == 0) ||
            (x == 1 && y == 0) ||
            (x == 0 && y == 1);
        return SpiritualCellState(lightIntensity: alive ? 1.0 : 0.0, isActive: alive);
      }));
      final next = svc.evolve(grid);
      // Center (1,1) had 3 live neighbors -> should become alive
      expect(next[1][1].isActive, isTrue);
    });

    test('live cell with 2 live neighbors survives', () {
      final svc = GameOfLifeService();
      final grid = List.generate(3, (y) => List.generate(3, (x) {
        final alive = (x == 0 && y == 0) ||
            (x == 1 && y == 0) ||
            (x == 0 && y == 1);
        return SpiritualCellState(lightIntensity: alive ? 1.0 : 0.0, isActive: alive);
      }));
      final next = svc.evolve(grid);
      // (0,0) had 2 live neighbors -> survives
      expect(next[0][0].isActive, isTrue);
    });
  });

  group('PlayerState', () {
    test('starts with full focus and energy', () {
      const state = PlayerState();
      expect(state.focus, 100.0);
      expect(state.energy, 100.0);
      expect(state.spiritualStrength, 0.0);
      expect(state.isInSpiritualWorld, isFalse);
    });

    test('copyWith updates only specified fields', () {
      const state = PlayerState();
      final updated = state.copyWith(focus: 50.0);
      expect(updated.focus, 50.0);
      expect(updated.energy, 100.0); // unchanged
    });
  });

  group('GameConstants', () {
    test('grid dimensions are positive', () {
      expect(GameConstants.gridWidth, greaterThan(0));
      expect(GameConstants.gridHeight, greaterThan(0));
      expect(GameConstants.cellSize, greaterThan(0));
    });
  });
}
