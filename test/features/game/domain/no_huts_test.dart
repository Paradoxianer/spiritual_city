import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/core/utils/seed_manager.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/city_generator.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/city_layout.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_chunk.dart';
import 'package:spiritual_city/src/features/menu/domain/models/city_size.dart';

void main() {
  // Playtest 2026-11-21: a school in a 3×3 slum lot and buildings cut down
  // by a lake looked like huts with a crowd inside.
  test('only houses and small shops are hut-sized', () {
    CityLayout.current = CityLayout(CitySize.village);
    for (final seed in [7, 813398673]) {
      final gen = CityGenerator(SeedManager(seed));
      final cells = <String, int>{};
      final types = <String, BuildingType>{};
      for (var cy = -8; cy < 8; cy++) {
        for (var cx = -8; cx < 8; cx++) {
          final chunk = CityChunk(chunkX: cx, chunkY: cy);
          gen.generateChunk(chunk);
          for (final c in chunk.cells.values) {
            final d = c.data;
            if (d is! BuildingData) continue;
            cells[d.buildingId] = (cells[d.buildingId] ?? 0) + 1;
            types[d.buildingId] = d.type;
          }
        }
      }
      for (final id in cells.keys) {
        final small = types[id] == BuildingType.house || types[id] == BuildingType.shop;
        expect(cells[id], greaterThanOrEqualTo(small ? 9 : 25), reason: 'seed $seed: $id ${types[id]}');
      }
    }
    CityLayout.current = CityLayout(CitySize.metropolis);
  });
}
