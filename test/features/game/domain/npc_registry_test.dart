import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_backstory.dart';
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

  group('NPCRegistry.hasGeneratedChunk (Issue #176)', () {
    test('is false before a chunk has been requested', () {
      final registry = NPCRegistry(seed: 11);
      expect(registry.hasGeneratedChunk(3, 4), isFalse);
    });

    test('becomes true once getNPCsInChunk has generated that chunk', () {
      final registry = NPCRegistry(seed: 11);
      final chunk = _filledChunkWithWater();
      registry.getNPCsInChunk(3, 4, chunk: chunk);

      expect(registry.hasGeneratedChunk(3, 4), isTrue);
      // A different, never-requested chunk must remain unaffected.
      expect(registry.hasGeneratedChunk(3, 5), isFalse);
    });

    test('a second call for the same chunk does not regenerate it (cached)',
        () {
      final registry = NPCRegistry(seed: 11);
      final chunk = _filledChunkWithWater();
      _setBuilding(chunk, 5, 5, 'house_a');
      for (int y = 4; y <= 6; y++) {
        for (int x = 4; x <= 6; x++) {
          if (!(x == 5 && y == 5)) _setRoad(chunk, x, y);
        }
      }

      final first = registry.getNPCsInChunk(3, 4, chunk: chunk);
      final second = registry.getNPCsInChunk(3, 4, chunk: chunk);

      // Same cached list instance, not a freshly regenerated one – this is
      // the property Issue #176's win-check relies on to avoid overwriting
      // live NPC state with saved state on repeat scans.
      expect(identical(first, second), isTrue);
    });
  });

  group('NPCRegistry applies the backstory faith offset (npc_backstory)', () {
    // Building id is parameterised so different calls produce NPCs with
    // different ids – and therefore different backstories – rather than
    // repeatedly re-sampling the same one or two fixed ids against a merely
    // varying random base faith.
    CityChunk chunkWithOneHouse([String buildingId = 'house_a']) {
      final chunk = _filledChunkWithWater();
      _setBuilding(chunk, 5, 5, buildingId);
      for (int y = 4; y <= 6; y++) {
        for (int x = 4; x <= 6; x++) {
          if (!(x == 5 && y == 5)) _setRoad(chunk, x, y);
        }
      }
      return chunk;
    }

    test('generated NPC faith always stays within [-100, 100] even after '
        'the backstory offset is added', () {
      final registry = NPCRegistry(seed: 21);
      final npcs = registry.getNPCsInChunk(0, 0, chunk: chunkWithOneHouse());
      for (final npc in npcs) {
        expect(npc.faith, inInclusiveRange(-100.0, 100.0), reason: npc.id);
      }
    });

    test('regenerating with the same seed yields identical faith values '
        '(the backstory offset does not break chunk-generation determinism)',
        () {
      final a = NPCRegistry(seed: 21)
          .getNPCsInChunk(0, 0, chunk: chunkWithOneHouse());
      final b = NPCRegistry(seed: 21)
          .getNPCsInChunk(0, 0, chunk: chunkWithOneHouse());
      expect(a.map((n) => n.faith).toList(), b.map((n) => n.faith).toList());
    });

    test('the offset actually moves at least one NPC\'s faith outside its '
        'pre-backstory spawn range across a range of chunks', () {
      // Pre-backstory spawn faith (npc_registry.dart): 65..100 if converted,
      // -60..20 otherwise. If NPCRegistry never applied backstory.faithOffset
      // at all, every NPC's final faith would always land inside one of
      // these two ranges. Finding at least one NPC outside its range is
      // direct evidence the offset is actually wired in (not just computed
      // and ignored).
      bool sawOffsetEffect = false;
      for (int cx = 0; cx < 200 && !sawOffsetEffect; cx++) {
        final registry = NPCRegistry(seed: 99);
        final npcs = registry.getNPCsInChunk(
          cx,
          0,
          chunk: chunkWithOneHouse('house_$cx'),
        );
        for (final npc in npcs) {
          final inBaseRange = npc.isConverted
              ? npc.faith >= 65.0 && npc.faith <= 100.0
              : npc.faith >= -60.0 && npc.faith <= 20.0;
          if (!inBaseRange) {
            sawOffsetEffect = true;
            break;
          }
        }
      }
      expect(sawOffsetEffect, isTrue,
          reason: 'no NPC across 200 chunks landed outside its pre-backstory '
              'spawn range – the faithOffset does not appear to be applied');
    });
  });

  group('NPCRegistry unlocks the Christ backstory phase for pre-converted '
      'spawns (npc_backstory)', () {
    CityChunk chunkWithOneChurch([String buildingId = 'church_a']) {
      final chunk = _filledChunkWithWater();
      chunk.cells['5,5'] = CityCell(
        x: 5,
        y: 5,
        data: BuildingData(type: BuildingType.church, buildingId: buildingId),
      );
      for (int y = 4; y <= 6; y++) {
        for (int x = 4; x <= 6; x++) {
          if (!(x == 5 && y == 5)) _setRoad(chunk, x, y);
        }
      }
      return chunk;
    }

    test('a pre-converted NPC already has Christ-phase events right after '
        'generation, without any save/load or in-game conversion', () {
      // Church residents are pre-converted 25% of the time (NPCRegistry) –
      // scan enough chunks to reliably find one.
      bool sawPreConverted = false;
      for (int cx = 0; cx < 60 && !sawPreConverted; cx++) {
        final registry = NPCRegistry(seed: 5);
        final npcs = registry.getNPCsInChunk(
          cx,
          0,
          chunk: chunkWithOneChurch('church_$cx'),
        );
        for (final npc in npcs) {
          if (!npc.isConverted) continue;
          sawPreConverted = true;
          expect(
            npc.backstory.events.any((o) => o.phase == LifePhase.christ),
            isTrue,
            reason: '${npc.id} is pre-converted but has no Christ-phase events',
          );
        }
      }
      expect(sawPreConverted, isTrue,
          reason: 'no pre-converted church NPC found in 60 chunks');
    });

    test('a non-converted NPC has no Christ-phase events', () {
      final registry = NPCRegistry(seed: 5);
      final npcs = registry.getNPCsInChunk(0, 0, chunk: chunkWithOneChurch());
      for (final npc in npcs.where((n) => !n.isConverted)) {
        expect(npc.backstory.events.any((o) => o.phase == LifePhase.christ), isFalse);
      }
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
