import 'package:flame/components.dart';
import '../../domain/models/city_grid.dart';
import '../../domain/city_generator.dart';
import '../../domain/models/city_chunk.dart';
import 'cell_component.dart';
import 'chunk_component.dart';
import '../spirit_world_game.dart';

class ChunkManager extends Component with HasGameReference<SpiritWorldGame> {
  final CityGrid grid;
  final CityGenerator generator;
  final PositionComponent target; // Der Spieler

  final Map<String, ChunkComponent> _renderedChunks = {};
  
  /// Radius in Chunks um den Spieler. 
  /// 1 = 3x3 Chunks (9)
  /// 2 = 5x5 Chunks (25)
  final int renderDistance = 2;

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

    final keysToRemove =
        _renderedChunks.keys.where((k) => !activeKeys.contains(k)).toList();
    for (final key in keysToRemove) {
      _renderedChunks[key]!.removeFromParent();
      _renderedChunks.remove(key);
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
  }
}
