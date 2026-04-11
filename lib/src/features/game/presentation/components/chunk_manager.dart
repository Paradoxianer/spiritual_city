import 'package:flame/components.dart';
import 'package:logging/logging.dart';
import '../../domain/models/city_grid.dart';
import '../../domain/city_generator.dart';
import '../../domain/models/city_chunk.dart';
import '../../domain/models/spatial_grid.dart';
import '../../domain/npc_registry.dart';
import '../../domain/services/performance_monitor.dart';
import 'cell_component.dart';
import 'chunk_component.dart';
import 'npc_component.dart';
import 'npc_pool.dart';
import '../spirit_world_game.dart';

class ChunkManager extends Component with HasGameReference<SpiritWorldGame> {
  static final _log = Logger('ChunkManager');

  final CityGrid grid;
  final CityGenerator generator;
  final PositionComponent target;
  final NPCRegistry npcRegistry = NPCRegistry();

  final Map<String, ChunkComponent> _renderedChunks = {};
  final Map<String, List<NPCComponent>> _activeNPCs = {};

  /// Object pool to avoid per-spawn allocations.
  final NPCPool _npcPool = NPCPool(maxSize: 150);

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

    // Update LOD for all active NPCs based on distance to target
    _updateNPCDetailLevels();

    // Refresh spatial grid with current NPC positions
    final allNPCs = _activeNPCs.values.expand((list) => list).toList();
    _spatialGrid.update(allNPCs);

    _perfMonitor.updateCounters(
      activeNPCs: allNPCs.length,
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
    }

    final chunkComp = ChunkComponent(chunk);
    _renderedChunks[chunk.id] = chunkComp;
    parent?.add(chunkComp);

    // Spawn NPCs using the object pool
    final npcs = npcRegistry.getNPCsInChunk(cx, cy, chunk: chunk);
    final npcComponents = <NPCComponent>[];
    for (final npcModel in npcs) {
      final npcComp = _npcPool.borrow(npcModel);
      npcComponents.add(npcComp);
      parent?.add(npcComp);
    }
    _activeNPCs[chunk.id] = npcComponents;
  }

  void _unloadChunk(String key) {
    _renderedChunks[key]?.removeFromParent();
    _renderedChunks.remove(key);

    final npcs = _activeNPCs[key];
    if (npcs != null) {
      for (final npc in npcs) {
        _npcPool.returnNPC(npc);
      }
      _activeNPCs.remove(key);
    }
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
            await Future.microtask(() => generator.generateChunk(chunk));
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
    for (final npcList in _activeNPCs.values) {
      for (final npc in npcList) {
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
  }

  // ─── Accessors (for tests / UI) ───────────────────────────────────────────

  /// All NPC components currently active in the world.
  List<NPCComponent> get allActiveNPCs =>
      _activeNPCs.values.expand((list) => list).toList();

  /// Current pool statistics.
  int get poolAvailable => _npcPool.available;
}
