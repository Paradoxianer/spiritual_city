import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/core/utils/seed_manager.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/city_generator.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_grid.dart';
import 'package:spiritual_city/src/features/game/domain/npc_registry.dart';

// Playtest 2026-11-17: a house with nobody in it could never become a
// Christian household – its 🔒✝️ actions stayed locked for good. The road
// in its chunk only ran along the edge, so no "safe" spawn cell was found.
void main() {
  test('every house and apartment has residents', () {
    for (var seed = 1; seed <= 10; seed++) {
      final grid = CityGrid();
      final gen = CityGenerator(SeedManager(seed));
      final registry = NPCRegistry(seed: seed);
      for (var cy = 10; cy <= 16; cy++) {
        for (var cx = 10; cx <= 16; cx++) {
          gen.generateChunk(grid.getOrCreateChunk(cx, cy));
        }
      }
      final homes = <String>{};
      final lived = <String>{};
      for (var cy = 11; cy <= 15; cy++) {
        for (var cx = 11; cx <= 15; cx++) {
          final chunk = grid.getOrCreateChunk(cx, cy);
          for (final cell in chunk.cells.values) {
            final d = cell.data;
            if (d is BuildingData && (d.type == BuildingType.house || d.type == BuildingType.apartment)) {
              homes.add(d.buildingId);
            }
          }
          for (final npc in registry.getNPCsInChunk(cx, cy, chunk: chunk)) {
            lived.add(npc.homeBuildingId!);
          }
        }
      }
      expect(homes.difference(lived), isEmpty, reason: 'seed $seed');
    }
  });
}
