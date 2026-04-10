import 'package:flame/components.dart';
import '../../domain/models/city_grid.dart';
import '../../domain/city_generator.dart';
import '../../domain/models/city_chunk.dart';
import '../../domain/npc_registry.dart';
import 'cell_component.dart';
import 'chunk_component.dart';
import 'npc_component.dart';
import '../spirit_world_game.dart';

class ChunkManager extends Component with HasGameReference<SpiritWorldGame> {
  final CityGrid grid;
  final CityGenerator generator;
  final PositionComponent target; // Der Spieler
  final NPCRegistry npcRegistry = NPCRegistry();

  final Map<String, ChunkComponent> _renderedChunks = {};
  final Map<String, List<NPCComponent>> _activeNPCs = {};
  
  /// Radius in Chunks um den Spieler. 
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

    // NPCs für diesen Chunk laden
    final npcs = npcRegistry.getNPCsInChunk(cx, cy);
    final npcComponents = <NPCComponent>[];
    for (final npcModel in npcs) {
      final npcComp = NPCComponent(model: npcModel);
      npcComponents.add(npcComp);
      parent?.add(npcComp);
    }
    _activeNPCs[chunk.id] = npcComponents;
  }

  void _unloadChunk(String key) {
    // Chunk entfernen
    _renderedChunks[key]?.removeFromParent();
    _renderedChunks.remove(key);

    // NPCs entfernen
    final npcs = _activeNPCs[key];
    if (npcs != null) {
      for (final npc in npcs) {
        npc.removeFromParent();
      }
      _activeNPCs.remove(key);
    }
  }
}
