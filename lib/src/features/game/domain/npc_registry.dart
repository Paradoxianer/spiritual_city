import 'dart:math';
import 'package:flame/components.dart';
import 'package:logging/logging.dart';
import 'models/npc_model.dart';
import '../presentation/components/cell_component.dart';
import 'models/city_chunk.dart';
import 'models/cell_object.dart';

class NPCRegistry {
  static final _log = Logger('NPCRegistry');
  static const int _maxDistanceSentinel = 1 << 30;

  final Map<String, List<NPCModel>> _chunkNPCs = {};

  /// Base seed used to derive per-chunk random seeds.  Using a per-chunk seed
  /// (computed from cx/cy) ensures that the same chunk always generates the
  /// same NPCs regardless of which other chunks were loaded before it.  Without
  /// this guarantee the load order of chunks would advance the shared RNG
  /// differently between sessions, producing different NPC counts / IDs for
  /// the same building and breaking save-state restoration.
  final int _seed;

  NPCRegistry({int? seed}) : _seed = seed ?? 42;

  List<NPCModel> getNPCsInChunk(int cx, int cy, {CityChunk? chunk}) {
    final key = '$cx,$cy';
    if (_chunkNPCs.containsKey(key)) {
      return _chunkNPCs[key]!;
    }

    if (chunk != null) {
      final npcs = _generateNPCsForChunk(chunk, cx, cy);
      _chunkNPCs[key] = npcs;
      return npcs;
    }

    return [];
  }

  /// Produces a deterministic seed for chunk [cx],[cy] by mixing the base
  /// seed with the chunk coordinates using large primes (spatial hash).
  int _chunkSeed(int cx, int cy) {
    // Primes 73856093 and 19349663 are from the spatial hashing technique
    // described in "Optimized Spatial Hashing for Collision Detection of
    // Deformable Objects" (Teschner et al., 2003).  They spread small integer
    // coordinate values across the full int range to reduce hash collisions.
    // Dart int arithmetic wraps silently on overflow (no exception thrown).
    return _seed ^ (cx * 73856093) ^ (cy * 19349663);
  }

  List<NPCModel> _generateNPCsForChunk(CityChunk chunk, int cx, int cy) {
    // Each chunk gets its own RNG seeded deterministically from its coordinates.
    // This isolates chunks from each other so that loading chunk A before B
    // produces the same NPCs as loading B before A.
    final rng = Random(_chunkSeed(cx, cy));
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
          buildings
              .putIfAbsent(
                data.buildingId,
                () => _BuildingInfo(data.type, data.buildingId),
              )
              .cells
              .add([x, y]);
        }
      }
    }

    // ── Step 2: for each building spawn N NPCs at a road start position ──
    for (final bInfo in buildings.values) {
      final count = _npcCountForType(bInfo.type, rng);
      if (count == 0) continue;

      // Find a road spawn position close to this building.
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
        // ~3 % of NPCs are pre-converted Christians (Übergabegebet already
        // prayed before the game starts).  Church/cathedral residents have a
        // higher chance (25 %) because they are already part of a congregation.
        final isChurchWorker = bInfo.type == BuildingType.church ||
            bInfo.type == BuildingType.cathedral;
        final preConvertedChance = isChurchWorker ? 0.25 : 0.03;
        final isConverted = rng.nextDouble() < preConvertedChance;
        final faith = isConverted
            ? 65.0 + rng.nextDouble() * 35.0 // 65–100 for Christians
            : -60.0 + rng.nextDouble() * 80.0; // –60 to +20 otherwise
        if (isConverted) {
          _log.fine(
            'Chunk ($cx,$cy): pre-converted NPC $id generated '
            '(faith=${faith.toStringAsFixed(1)})',
          );
        }
        npcs.add(NPCModel(
          id: id,
          name: _getRandomName(rng),
          type: _getNPCTypeForBuilding(bInfo.type, rng),
          homePosition: spawnPos.clone(),
          homeBuildingId: bInfo.buildingId,
          faith: faith,
          isConverted: isConverted,
        ));
      }
    }

    _log.fine('Chunk ($cx,$cy): generated ${npcs.length} NPCs');
    return npcs;
  }

  /// NPC density per building type: `(min, extra)`.
  /// Total = min + random.nextInt(extra), so (1, 2) yields 1 or 2 NPCs.
  /// extra = 0 means exactly min NPCs.
  static const Map<BuildingType, (int, int)> _buildingNPCDensity = {
    BuildingType.house: (1, 2), // 1–2
    BuildingType.apartment: (2, 3), // 2–4
    BuildingType.church: (1, 2), // 1–2
    BuildingType.cathedral: (1, 2), // 1–2
    BuildingType.shop: (1, 1), // 1
    BuildingType.supermarket: (1, 2), // 1–2
    BuildingType.mall: (2, 3), // 2–4
    BuildingType.office: (1, 2), // 1–2
    BuildingType.skyscraper: (1, 2), // 1–2
    BuildingType.school: (1, 2), // 1–2
    BuildingType.university: (2, 2), // 2–3
    BuildingType.hospital: (1, 2), // 1–2
    BuildingType.policeStation: (1, 1), // 1
    BuildingType.fireStation: (1, 1), // 1
    BuildingType.postOffice: (1, 1), // 1
    BuildingType.trainStation: (1, 2), // 1–2
    BuildingType.cityHall: (1, 2), // 1–2
    BuildingType.library: (1, 1), // 1
    BuildingType.museum: (1, 1), // 1
    BuildingType.stadium: (2, 3), // 2–4
    BuildingType.factory: (1, 1), // 1
    BuildingType.warehouse: (1, 1), // 1
    BuildingType.powerPlant: (1, 1), // 1
    BuildingType.cemetery: (0, 0), // 0
  };

  /// How many NPCs live/work in a building of [type].
  int _npcCountForType(BuildingType type, Random rng) {
    final (min, extra) = _buildingNPCDensity[type] ?? (1, 1);
    return min + (extra > 0 ? rng.nextInt(extra) : 0);
  }

  NPCType _getNPCTypeForBuilding(BuildingType type, Random rng) {
    switch (type) {
      case BuildingType.church:
      case BuildingType.cathedral:
        return NPCType.priest;
      case BuildingType.shop:
      case BuildingType.supermarket:
      case BuildingType.mall:
        return rng.nextDouble() < 0.5 ? NPCType.merchant : NPCType.citizen;
      case BuildingType.policeStation:
        return NPCType.officer;
      default:
        return NPCType.citizen;
    }
  }

  /// Searches the direct neighbours of every cell in [buildingCells] for a
  /// road and sufficiently open spawn cell inside [chunk].
  ///
  /// The chosen cell must be reachable for wandering NPC AI:
  /// - road tile
  /// - at least 2 road cardinal neighbours
  /// - not tightly enclosed by buildings (minimum free Moore-neighbour space)
  ///
  /// Among all valid cells, the nearest to the building footprint is picked so
  /// NPCs still spawn close to their home/work place.
  List<int>? _findWalkableNeighbour(
      CityChunk chunk, List<List<int>> buildingCells) {
    List<int>? bestCell;
    var bestDistance = _maxDistanceSentinel;
    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        if (!_isSafeSpawnCell(chunk, x, y)) continue;
        final distance = _distanceToNearestBuildingCell(x, y, buildingCells);
        if (distance < bestDistance) {
          bestDistance = distance;
          bestCell = [x, y];
        }
      }
    }
    return bestCell;
  }

  bool _isSafeSpawnCell(CityChunk chunk, int x, int y) {
    final cell = chunk.cells['$x,$y'];
    if (cell == null) return false;

    final data = cell.data;
    if (data is! RoadData) return false;

    const dirs = [
      [0, 1],
      [0, -1],
      [1, 0],
      [-1, 0],
    ];
    var roadNeighbours = 0;
    for (final d in dirs) {
      final nx = x + d[0];
      final ny = y + d[1];
      if (nx < 0 ||
          ny < 0 ||
          nx >= CityChunk.chunkSize ||
          ny >= CityChunk.chunkSize) {
        continue;
      }
      if (_isRoadChunkCell(chunk, nx, ny)) roadNeighbours++;
    }
    if (roadNeighbours < 2) return false;

    var openMooreNeighbours = 0;
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 ||
            ny < 0 ||
            nx >= CityChunk.chunkSize ||
            ny >= CityChunk.chunkSize) {
          continue;
        }
        if (_isRoadChunkCell(chunk, nx, ny)) {
          openMooreNeighbours++;
        }
      }
    }
    return openMooreNeighbours >= 4;
  }

  bool _isRoadChunkCell(CityChunk chunk, int x, int y) {
    final cell = chunk.cells['$x,$y'];
    if (cell == null) return false;
    return cell.data is RoadData;
  }

  int _distanceToNearestBuildingCell(
      int x, int y, List<List<int>> buildingCells) {
    var minDistance = _maxDistanceSentinel;
    for (final c in buildingCells) {
      final dist = (x - c[0]).abs() + (y - c[1]).abs();
      if (dist < minDistance) minDistance = dist;
    }
    return minDistance;
  }

  String _getRandomName(Random rng) {
    final firstNames = [
      'Lukas',
      'Maria',
      'Johannes',
      'Sarah',
      'Peter',
      'Anna',
      'Thomas',
      'Elisabeth',
      'Matthias',
      'Martha'
    ];
    final lastNames = [
      'Müller',
      'Schmidt',
      'Schneider',
      'Fischer',
      'Weber',
      'Meyer',
      'Wagner',
      'Becker',
      'Schulz',
      'Hoffmann'
    ];
    return '${firstNames[rng.nextInt(firstNames.length)]} ${lastNames[rng.nextInt(lastNames.length)]}';
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
