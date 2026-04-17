import 'package:flame/components.dart';
import 'package:logging/logging.dart';
import '../../domain/models/building_model.dart';
import '../../domain/models/cell_object.dart';
import '../../domain/models/city_grid.dart';
import '../../domain/city_generator.dart';
import '../../domain/models/city_chunk.dart';
import '../../domain/models/npc_model.dart';
import '../../domain/models/spatial_grid.dart';
import '../../domain/npc_registry.dart';
import '../../domain/services/performance_monitor.dart';
import 'building_component.dart';
import 'cell_component.dart';
import 'chunk_component.dart';
import 'npc_component.dart';
import '../spirit_world_game.dart';

class ChunkManager extends Component with HasGameReference<SpiritWorldGame> {
  static final _log = Logger('ChunkManager');

  final CityGrid grid;
  final CityGenerator generator;
  final PositionComponent target;
  final NPCRegistry npcRegistry = NPCRegistry();

  final Map<String, ChunkComponent> _renderedChunks = {};

  /// All NPC components ever created – they live in the world permanently.
  final List<NPCComponent> _allNPCs = [];

  /// All building components ever created – persist like NPCs.
  final List<BuildingComponent> _allBuildings = [];

  /// Persistent map of buildingId → BuildingModel across all loaded chunks.
  final Map<String, BuildingModel> _buildingModels = {};

  /// Chunks that have already had their NPCs created (to avoid duplicates).
  final Set<String> _chunksWithNPCs = {};

  /// Spatial grid for efficient distance queries (LOD assignment).
  final SpatialGrid<NPCComponent> _spatialGrid = SpatialGrid(cellSize: 256);

  /// Performance tracker.
  final PerformanceMonitor _perfMonitor = PerformanceMonitor();

  /// How many chunks in each direction to render around the target.
  final int renderDistance = 2;

  /// One extra ring of chunks preloaded ahead of renderDistance.
  final int preloadDistance = 3;

  int? _lastChunkX;
  int? _lastChunkY;

  /// Whether an async chunk-load pass is currently in flight.
  bool _loadInProgress = false;

  /// Center coordinates of the most-recently requested preload pass.
  /// If the player moves while a preload is in-flight, the next pass will
  /// start with the updated center once the current one finishes.
  int _preloadCenterX = 0;
  int _preloadCenterY = 0;

  /// Throttle timer for LOD + spatial-grid refresh.
  double _lodSpatialTimer = 0.0;

  /// How often (seconds) LOD levels and the spatial grid are refreshed.
  /// 10 Hz is plenty – NPCs move slowly and LOD doesn't need frame accuracy.
  static const double _lodSpatialInterval = 0.1;

  ChunkManager({
    required this.grid,
    required this.generator,
    required this.target,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _perfMonitor.startFrame();

    final currentChunkX =
        (target.position.x / (CityChunk.chunkSize * CellComponent.cellSize))
            .floor();
    final currentChunkY =
        (target.position.y / (CityChunk.chunkSize * CellComponent.cellSize))
            .floor();

    if (currentChunkX != _lastChunkX || currentChunkY != _lastChunkY) {
      _lastChunkX = currentChunkX;
      _lastChunkY = currentChunkY;
      _updateChunks(currentChunkX, currentChunkY);
      _preloadCenterX = currentChunkX;
      _preloadCenterY = currentChunkY;
      if (!_loadInProgress) {
        _preloadChunksAsync(currentChunkX, currentChunkY);
      }
    }

    // LOD + spatial grid: skipped entirely in the spiritual world (NPCs are
    // frozen there, so these operations are wasted work that creates dt spikes
    // and makes daemon orbital movement appear jerky).
    // Outside the spiritual world, throttle to 10 Hz – LOD doesn't need
    // frame-rate accuracy.
    if (!game.isSpiritualWorld) {
      _lodSpatialTimer += dt;
      if (_lodSpatialTimer >= _lodSpatialInterval) {
        _lodSpatialTimer = 0.0;
        _updateNPCDetailLevels();
        _spatialGrid.update(_allNPCs);
      }
    }

    _perfMonitor.updateCounters(
      activeNPCs: _allNPCs.length,
      loadedChunks: _renderedChunks.length,
    );
    _perfMonitor.endFrame(dt);
  }

  // ─── Synchronous chunk management ─────────────────────────────────────────

  void _updateChunks(int centerX, int centerY) {
    final Set<String> activeKeys = {};

    for (int x = centerX - renderDistance; x <= centerX + renderDistance; x++) {
      for (int y = centerY - renderDistance; y <= centerY + renderDistance; y++) {
        final key = '$x,$y';
        activeKeys.add(key);
        if (!_renderedChunks.containsKey(key)) {
          _loadChunk(x, y);
        }
      }
    }

    final keysToRemove =
        _renderedChunks.keys.where((k) => !activeKeys.contains(k)).toList();
    for (final key in keysToRemove) {
      _unloadChunk(key);
    }
  }

  void _loadChunk(int cx, int cy) {
    final chunk = grid.getOrCreateChunk(cx, cy);

    if (chunk.cells.isEmpty) {
      generator.generateChunk(chunk);
      // Apply any saved spiritual-state overrides for these cells.
      game.applySavedCellStatesToChunk(chunk);
    }

    final chunkComp = ChunkComponent(chunk);
    _renderedChunks[chunk.id] = chunkComp;
    parent?.add(chunkComp);

    // Create NPC components only the first time this chunk is loaded.
    // They stay in the world permanently and walk around.
    if (!_chunksWithNPCs.contains(chunk.id)) {
      _chunksWithNPCs.add(chunk.id);
      final npcs = npcRegistry.getNPCsInChunk(cx, cy, chunk: chunk);

      // Restore saved NPC states (faith, conversation counts, etc.).
      for (final npcModel in npcs) {
        game.applySavedNPCState(npcModel);
      }

      // Group NPCs by their home building for BuildingModel construction.
      final Map<String, List<NPCModel>> npcsByBuilding = {};
      for (final npc in npcs) {
        if (npc.homeBuildingId != null) {
          npcsByBuilding
              .putIfAbsent(npc.homeBuildingId!, () => [])
              .add(npc);
        }
      }

      // Spawn NPC components.
      for (final npcModel in npcs) {
        final npcComp = NPCComponent(model: npcModel);
        _allNPCs.add(npcComp);
        parent?.add(npcComp);
      }

      // Spawn building entrance components.
      _spawnBuildingComponents(chunk, npcsByBuilding);

      _log.fine('Created ${npcs.length} NPCs for chunk (${chunk.id})');
    }
  }

  void _unloadChunk(String key) {
    // Only remove the visual tile chunk – NPCs stay in the world.
    _renderedChunks[key]?.removeFromParent();
    _renderedChunks.remove(key);
  }

  // ── Building spawning ─────────────────────────────────────────────────────

  /// Creates [BuildingComponent] instances for every unique building in
  /// [chunk] the first time that chunk is loaded.
  ///
  /// Prefers placing the component at the nearest walkable (road) cell so that
  /// the player detects it while walking along the street.  Falls back to the
  /// building's footprint centre if no road neighbour is found.
  void _spawnBuildingComponents(
    CityChunk chunk,
    Map<String, List<NPCModel>> npcsByBuilding,
  ) {
    // Collect the footprint cells of every unique building in the chunk.
    final Map<String, _ChunkBuildingInfo> buildings = {};
    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;
        final data = cell.data;
        if (data is BuildingData) {
          buildings
              .putIfAbsent(
                data.buildingId,
                () => _ChunkBuildingInfo(data.type, data.buildingId),
              )
              .cells
              .add([x, y]);
        }
      }
    }

    for (final bInfo in buildings.values) {
      // Skip buildings that already have a component (e.g. spanning two chunks).
      if (_buildingModels.containsKey(bInfo.buildingId)) continue;

      // Prefer an entrance on the adjacent road; fall back to footprint centre.
      final Vector2 pos;
      final entrance = _findWalkableNeighbour(chunk, bInfo.cells);
      if (entrance != null) {
        final wx = chunk.getWorldX(entrance[0]);
        final wy = chunk.getWorldY(entrance[1]);
        pos = Vector2(
          wx * CellComponent.cellSize + CellComponent.cellSize / 2,
          wy * CellComponent.cellSize + CellComponent.cellSize / 2,
        );
      } else {
        // Fallback: use the building cell closest to any chunk boundary, since
        // the road entrance is most likely in the adjacent chunk.  This keeps
        // the interaction point at the building wall rather than deep inside.
        final edgeCell = bInfo.cells
            .reduce((a, b) => _distToChunkEdge(a) <= _distToChunkEdge(b) ? a : b);
        final wx = chunk.getWorldX(edgeCell[0]);
        final wy = chunk.getWorldY(edgeCell[1]);
        pos = Vector2(
          wx * CellComponent.cellSize + CellComponent.cellSize / 2,
          wy * CellComponent.cellSize + CellComponent.cellSize / 2,
        );
      }

      final residents = npcsByBuilding[bInfo.buildingId] ?? [];
      final model = BuildingModel(
        buildingId: bInfo.buildingId,
        type: bInfo.type,
        residents: residents,
        isHomebase: bInfo.type == BuildingType.pastorHouse,
      );
      _buildingModels[bInfo.buildingId] = model;

      final comp = BuildingComponent(buildingModel: model, position: pos);
      _allBuildings.add(comp);
      parent?.add(comp);
    }
  }

  /// Finds the first walkable (road / nature) cell adjacent to any cell in
  /// [buildingCells] within [chunk].
  List<int>? _findWalkableNeighbour(
    CityChunk chunk,
    List<List<int>> buildingCells,
  ) {
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
        final data = neighbour.data;
        if (data is RoadData || data is NatureData) return [nx, ny];
      }
    }
    return null;
  }

  /// Returns the minimum Manhattan distance from [cell] (chunk-local [x, y])
  /// to any edge of the chunk.  Used to find the building cell most likely to
  /// be adjacent to a road in a neighbouring chunk.
  static int _distToChunkEdge(List<int> cell) {
    final x = cell[0];
    final y = cell[1];
    final s = CityChunk.chunkSize - 1;
    return [x, s - x, y, s - y].reduce((m, v) => v < m ? v : m);
  }

  // ─── Async predictive preloading ──────────────────────────────────────────

  /// Generates (but does not yet render) chunks in the preload ring so that
  /// chunk data is ready when the player enters the adjacent render zone.
  /// Uses [Future.microtask] so each chunk yields to the event loop,
  /// preventing the game-loop from being blocked.
  ///
  /// If the player moves to a new chunk centre while a preload is in flight,
  /// this method restarts with the updated centre coordinates once the
  /// current pass completes.
  Future<void> _preloadChunksAsync(int centerX, int centerY) async {
    _loadInProgress = true;
    try {
      for (int x = centerX - preloadDistance;
          x <= centerX + preloadDistance;
          x++) {
        for (int y = centerY - preloadDistance;
            y <= centerY + preloadDistance;
            y++) {
          // If the player has moved, abort this pass – a new one will start.
          if (x != centerX || y != centerY) {
            if (_preloadCenterX != centerX || _preloadCenterY != centerY) {
              _log.fine(
                  'Preload pass ($centerX,$centerY) abandoned – player moved');
              return;
            }
          }

          // Skip the inner ring – already loaded synchronously
          if ((x - centerX).abs() <= renderDistance &&
              (y - centerY).abs() <= renderDistance) {
            continue;
          }

          final chunk = grid.getOrCreateChunk(x, y);
          if (chunk.cells.isEmpty) {
            // Yield to event loop between each chunk generation
            await Future.microtask(() {
              generator.generateChunk(chunk);
              // Apply saved cell states so they are ready before the chunk renders.
              game.applySavedCellStatesToChunk(chunk);
            });
            _log.fine('Preloaded chunk ($x,$y)');
          }
        }
      }
    } finally {
      _loadInProgress = false;
      // If the centre moved while we were running, start a fresh pass now.
      if (_preloadCenterX != centerX || _preloadCenterY != centerY) {
        _preloadChunksAsync(_preloadCenterX, _preloadCenterY);
      }
    }
  }

  // ─── LOD assignment ───────────────────────────────────────────────────────

  /// Distance thresholds (world units) for LOD transitions.
  static const double _lodHighThreshold = 200.0;
  static const double _lodMediumThreshold = 500.0;

  void _updateNPCDetailLevels() {
    final playerPos = target.position;
    for (final npc in _allNPCs) {
      final d = npc.position.distanceTo(playerPos);
      if (d < _lodHighThreshold) {
        npc.detailLevel = NPCDetailLevel.high;
      } else if (d < _lodMediumThreshold) {
        npc.detailLevel = NPCDetailLevel.medium;
      } else {
        npc.detailLevel = NPCDetailLevel.low;
      }
    }
  }

  // ─── Accessors (for tests / UI) ───────────────────────────────────────────

  /// All NPC components currently active in the world.
  List<NPCComponent> get allActiveNPCs => List.unmodifiable(_allNPCs);

  /// All NPC *models* currently tracked in the world (for save-state capture).
  List<NPCModel> get allNPCModels =>
      List.unmodifiable(_allNPCs.map((c) => c.model));

  /// Number of NPCs created so far.
  int get npcCount => _allNPCs.length;

  /// All building components currently active in the world.
  List<BuildingComponent> get allActiveBuildings =>
      List.unmodifiable(_allBuildings);

  /// Returns the [BuildingModel] registered under [buildingId], or null.
  BuildingModel? getBuildingModel(String buildingId) =>
      _buildingModels[buildingId];
}

// ── Private helper ────────────────────────────────────────────────────────────

class _ChunkBuildingInfo {
  final BuildingType type;
  final String buildingId;
  final List<List<int>> cells = [];
  _ChunkBuildingInfo(this.type, this.buildingId);
}
