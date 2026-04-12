import 'dart:math';
import 'package:flame/components.dart';
import 'models/npc_model.dart';
import '../presentation/components/cell_component.dart';
import 'models/city_chunk.dart';
import 'models/cell_object.dart';

class NPCRegistry {
  final Map<String, List<NPCModel>> _chunkNPCs = {};
  final Random _random;

  NPCRegistry({int? seed}) : _random = Random(seed ?? 42);

  List<NPCModel> getNPCsInChunk(int cx, int cy, {CityChunk? chunk}) {
    final key = '$cx,$cy';
    if (_chunkNPCs.containsKey(key)) {
      return _chunkNPCs[key]!;
    }

    if (chunk != null) {
      final npcs = _generateNPCsForChunk(chunk);
      _chunkNPCs[key] = npcs;
      return npcs;
    }

    return [];
  }

  List<NPCModel> _generateNPCsForChunk(CityChunk chunk) {
    final List<NPCModel> npcs = [];

    // ── Step 1: collect unique buildings and all their cells ─────────────────
    // Map from buildingId → (buildingType, list of local [x,y] coords)
    final Map<String, _BuildingInfo> buildings = {};
    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;
        final data = cell.data;
        if (data is BuildingData) {
          buildings.putIfAbsent(
            data.buildingId,
            () => _BuildingInfo(data.type, data.buildingId),
          ).cells.add([x, y]);
        }
      }
    }

    // ── Step 2: for each building spawn N NPCs at a walkable start position ──
    for (final bInfo in buildings.values) {
      final count = _npcCountForType(bInfo.type);
      if (count == 0) continue;

      // Find a walkable spawn position: look for a road or open cell adjacent
      // to any cell of this building.
      final spawnCell = _findWalkableNeighbour(chunk, bInfo.cells);
      if (spawnCell == null) continue; // building is landlocked – skip

      final spawnWx = chunk.getWorldX(spawnCell[0]);
      final spawnWy = chunk.getWorldY(spawnCell[1]);
      final spawnPos = Vector2(
        spawnWx * CellComponent.cellSize + CellComponent.cellSize / 2,
        spawnWy * CellComponent.cellSize + CellComponent.cellSize / 2,
      );

      for (int i = 0; i < count; i++) {
        final id = 'npc_${bInfo.buildingId}_$i';
        npcs.add(NPCModel(
          id: id,
          name: _getRandomName(),
          type: _getNPCTypeForBuilding(bInfo.type),
          homePosition: spawnPos.clone(),
          homeBuildingId: bInfo.buildingId,
          faith: -60.0 + _random.nextDouble() * 80.0,
        ));
      }
    }

    return npcs;
  }

  /// How many NPCs live/work in a building of [type].
  int _npcCountForType(BuildingType type) {
    switch (type) {
      case BuildingType.house:
        return 2 + _random.nextInt(3);        // 2–4
      case BuildingType.apartment:
        return 5 + _random.nextInt(6);        // 5–10
      case BuildingType.church:
      case BuildingType.cathedral:
        return 2 + _random.nextInt(3);        // 2–4
      case BuildingType.shop:
      case BuildingType.supermarket:
        return 1 + _random.nextInt(3);        // 1–3
      case BuildingType.mall:
        return 4 + _random.nextInt(5);        // 4–8
      case BuildingType.office:
      case BuildingType.skyscraper:
        return 2 + _random.nextInt(4);        // 2–5
      case BuildingType.school:
      case BuildingType.university:
        return 3 + _random.nextInt(4);        // 3–6
      case BuildingType.hospital:
        return 2 + _random.nextInt(3);        // 2–4
      case BuildingType.policeStation:
      case BuildingType.fireStation:
      case BuildingType.postOffice:
        return 1 + _random.nextInt(2);        // 1–2
      case BuildingType.trainStation:
        return 3 + _random.nextInt(4);        // 3–6
      case BuildingType.cityHall:
        return 2 + _random.nextInt(3);        // 2–4
      case BuildingType.library:
      case BuildingType.museum:
        return 1 + _random.nextInt(2);        // 1–2
      case BuildingType.stadium:
        return 4 + _random.nextInt(6);        // 4–9
      case BuildingType.factory:
      case BuildingType.warehouse:
      case BuildingType.powerPlant:
        return 1 + _random.nextInt(2);        // 1–2
      case BuildingType.cemetery:
        return 0;
    }
  }

  NPCType _getNPCTypeForBuilding(BuildingType type) {
    switch (type) {
      case BuildingType.church:
      case BuildingType.cathedral:
        return NPCType.priest;
      case BuildingType.shop:
      case BuildingType.supermarket:
      case BuildingType.mall:
        return _random.nextDouble() < 0.5 ? NPCType.merchant : NPCType.citizen;
      case BuildingType.policeStation:
        return NPCType.officer;
      default:
        return NPCType.citizen;
    }
  }

  /// Searches the direct neighbours of every cell in [buildingCells] for a
  /// walkable (non-building) cell inside [chunk].  Returns its [x, y] local
  /// coordinates, or null if none is found.
  List<int>? _findWalkableNeighbour(CityChunk chunk, List<List<int>> buildingCells) {
    const dirs = [
      [0, 1], [0, -1], [1, 0], [-1, 0],
    ];
    for (final cell in buildingCells) {
      for (final d in dirs) {
        final nx = cell[0] + d[0];
        final ny = cell[1] + d[1];
        if (nx < 0 || ny < 0 || nx >= CityChunk.chunkSize || ny >= CityChunk.chunkSize) {
          continue;
        }
        final neighbour = chunk.cells['$nx,$ny'];
        if (neighbour == null) continue;
        // Accept road cells or empty (null-data) cells; reject other buildings
        final data = neighbour.data;
        if (data is RoadData || data is NatureData) return [nx, ny];
      }
    }
    return null;
  }

  String _getRandomName() {
    final firstNames = ['Lukas', 'Maria', 'Johannes', 'Sarah', 'Peter', 'Anna', 'Thomas', 'Elisabeth', 'Matthias', 'Martha'];
    final lastNames = ['Müller', 'Schmidt', 'Schneider', 'Fischer', 'Weber', 'Meyer', 'Wagner', 'Becker', 'Schulz', 'Hoffmann'];
    return '${firstNames[_random.nextInt(firstNames.length)]} ${lastNames[_random.nextInt(lastNames.length)]}';
  }

  List<NPCModel> getNPCsNear(Vector2 position, double radius) {
    return [];
  }
}

class _BuildingInfo {
  final BuildingType type;
  final String buildingId;
  final List<List<int>> cells = [];
  _BuildingInfo(this.type, this.buildingId);
}

