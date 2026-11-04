import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/core/utils/seed_manager.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/city_generator.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_grid.dart';

void main() {
  // Playtest 2026-10-31: in some cities a supermarket in the same lot
  // swallowed the pastor house – the home was gone.
  test('every city has its pastor house: the whole lot is the home', () {
    for (var seed = 1; seed <= 150; seed++) {
      final grid = CityGrid();
      final gen = CityGenerator(SeedManager(seed));
      for (var cy = 12; cy <= 14; cy++) {
        for (var cx = 12; cx <= 14; cx++) {
          gen.generateChunk(grid.getOrCreateChunk(cx, cy));
        }
      }
      final home = grid.getCell(220, 222)!.data;
      expect(home, isA<BuildingData>(), reason: 'seed $seed');
      final id = (home as BuildingData).buildingId;
      for (var y = 200; y < 240; y++) {
        for (var x = 200; x < 240; x++) {
          final d = grid.getCell(x, y)?.data;
          if (d is BuildingData && d.buildingId == id) {
            expect(d.type, BuildingType.pastorHouse, reason: 'seed $seed cell $x,$y');
          }
        }
      }
    }
  });
}
