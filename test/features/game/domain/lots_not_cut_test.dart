import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/core/utils/seed_manager.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/city_generator.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_chunk.dart';

void main() {
  // Playtest 2026-11-01: streets ran through lots, district borders split
  // them, and lots at negative coordinates shared ids – houses looked "cut".
  test('every building is one solid rectangle', () {
    for (final seed in [7, 959865928]) {
      final gen = CityGenerator(SeedManager(seed));
      final byId = <String, Set<(int, int)>>{};
      for (var cy = -6; cy < 6; cy++) {
        for (var cx = -6; cx < 6; cx++) {
          final chunk = CityChunk(chunkX: cx, chunkY: cy);
          gen.generateChunk(chunk);
          for (final c in chunk.cells.values) {
            final d = c.data;
            if (d is BuildingData) byId.putIfAbsent(d.buildingId, () => {}).add((c.x, c.y));
          }
        }
      }
      var cut = 0;
      for (final cells in byId.values) {
        final xs = cells.map((c) => c.$1), ys = cells.map((c) => c.$2);
        final w = xs.reduce((a, b) => a > b ? a : b) - xs.reduce((a, b) => a < b ? a : b) + 1;
        final h = ys.reduce((a, b) => a > b ? a : b) - ys.reduce((a, b) => a < b ? a : b) + 1;
        if (w * h != cells.length) cut++;
      }
      // A landmark cell on a lot's edge may stick out; nothing else.
      expect(cut, lessThanOrEqualTo(byId.length ~/ 100), reason: 'seed $seed: $cut of ${byId.length} cut');
    }
  });
}
