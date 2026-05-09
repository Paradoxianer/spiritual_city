import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_cell.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_chunk.dart';
import 'package:spiritual_city/src/features/game/domain/npc_registry.dart';
import 'package:spiritual_city/src/features/game/presentation/components/cell_component.dart';

void main() {
  group('NPCRegistry safe spawn validation', () {
    test('spawns on roads and avoids narrow trapped gaps', () {
      final chunk = _filledChunkWithWater();
      _setBuilding(chunk, 5, 5, 'house_a');
      _setBuilding(chunk, 5, 4, 'block_north');
      _setBuilding(chunk, 5, 6, 'block_south');
      _setBuilding(chunk, 4, 5, 'block_west');
      _setBuilding(chunk, 7, 5, 'house_b');
      _setNature(chunk, 6, 5, NatureType.park); // narrow trapped gap
      _setNature(chunk, 6, 4, NatureType.park);
      _setNature(chunk, 6, 6, NatureType.park);
      for (int y = 8; y <= 12; y++) {
        for (int x = 8; x <= 12; x++) {
          _setRoad(chunk, x, y);
        }
      }

      final registry = NPCRegistry(seed: 7);
      final npcs = registry.getNPCsInChunk(0, 0, chunk: chunk);
      final houseNpcs = npcs.where((npc) => npc.homeBuildingId == 'house_a');

      expect(houseNpcs, isNotEmpty);
      for (final npc in houseNpcs) {
        final cell = _worldPosToCell(npc.homePosition.x, npc.homePosition.y);
        expect(cell, isNot(equals((6, 5))));
        final spawnedCellData = chunk.cells['${cell.$1},${cell.$2}']?.data;
        expect(spawnedCellData, isA<RoadData>());
      }
    });

    test('skips NPC spawn when no valid safe tile exists', () {
      final chunk = _filledChunkWithWater();
      _setBuilding(chunk, 5, 5, 'landlocked_house');
      _setNature(
          chunk, 6, 5, NatureType.park); // only walkable tile, still trapped

      final registry = NPCRegistry(seed: 9);
      final npcs = registry.getNPCsInChunk(0, 0, chunk: chunk);
      final landlockedNpcs = npcs.where(
        (npc) => npc.homeBuildingId == 'landlocked_house',
      );

      expect(landlockedNpcs, isEmpty);
    });
  });
}

CityChunk _filledChunkWithWater() {
  final chunk = CityChunk(chunkX: 0, chunkY: 0);
  for (int y = 0; y < CityChunk.chunkSize; y++) {
    for (int x = 0; x < CityChunk.chunkSize; x++) {
      _setNature(chunk, x, y, NatureType.water);
    }
  }
  return chunk;
}

void _setBuilding(CityChunk chunk, int x, int y, String id) {
  chunk.cells['$x,$y'] = CityCell(
    x: x,
    y: y,
    data: BuildingData(type: BuildingType.house, buildingId: id),
  );
}

void _setNature(CityChunk chunk, int x, int y, NatureType type) {
  chunk.cells['$x,$y'] = CityCell(x: x, y: y, data: NatureData(type: type));
}

void _setRoad(CityChunk chunk, int x, int y) {
  chunk.cells['$x,$y'] =
      CityCell(x: x, y: y, data: RoadData(type: RoadType.small));
}

(int, int) _worldPosToCell(double x, double y) {
  final cx = (x / CellComponent.cellSize).floor();
  final cy = (y / CellComponent.cellSize).floor();
  return (cx, cy);
}
