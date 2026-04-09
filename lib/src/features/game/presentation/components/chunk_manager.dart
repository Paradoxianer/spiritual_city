import 'package:flame/components.dart';
import '../../domain/models/city_grid.dart';
import '../../domain/city_generator.dart';
import '../../domain/models/city_chunk.dart';
import 'cell_component.dart';

class ChunkManager extends Component with HasGameRef {
  final CityGrid grid;
  final CityGenerator generator;
  final PositionComponent target; // Der Spieler

  final Map<String, List<CellComponent>> _renderedChunks = {};
  final int renderDistance = 2; // Radius in Chunks um den Spieler

  // Track last chunk position so we only rebuild when the player crosses a
  // chunk boundary – not on every single frame. Null means "not yet set".
  int? _lastChunkX;
  int? _lastChunkY;

  ChunkManager({
    required this.grid,
    required this.generator,
    required this.target,
  });

  @override
  void update(double dt) {
    super.update(dt);

    final currentChunkX =
        (target.position.x / (CityChunk.chunkSize * CellComponent.cellSize))
            .floor();
    final currentChunkY =
        (target.position.y / (CityChunk.chunkSize * CellComponent.cellSize))
            .floor();

    // Only re-evaluate chunks when the player enters a new chunk.
    if (currentChunkX == _lastChunkX && currentChunkY == _lastChunkY) return;
    _lastChunkX = currentChunkX;
    _lastChunkY = currentChunkY;
    _updateChunks(currentChunkX, currentChunkY);
  }

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

    // Unload chunks that are too far away
    final keysToRemove =
        _renderedChunks.keys.where((k) => !activeKeys.contains(k)).toList();
    for (final key in keysToRemove) {
      for (final comp in _renderedChunks[key]!) {
        comp.removeFromParent();
      }
      _renderedChunks.remove(key);
    }
  }

  void _loadChunk(int cx, int cy) {
    final chunk = grid.getOrCreateChunk(cx, cy);

    // Generate cells only once per chunk
    if (chunk.cells.isEmpty) {
      generator.generateChunk(chunk);
    }

    final components = <CellComponent>[];
    for (final cell in chunk.cells.values) {
      final comp = CellComponent(cell);
      components.add(comp);
      parent?.add(comp);
    }
    _renderedChunks[chunk.id] = components;
  }
}
