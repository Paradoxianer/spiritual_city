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

    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;

        final data = cell.data;

        // Spawn NPCs at building entrances (residents coming / going)
        if (data is BuildingData && data.isEntrance) {
          if (_random.nextDouble() < 0.95) {
            npcs.add(_createRandomNPC(chunk.getWorldX(x), chunk.getWorldY(y), null));
          }
        }

        // Spawn pedestrians on road cells for a lively street life (~15% per cell)
        if (data is RoadData) {
          if (_random.nextDouble() < 0.15) {
            npcs.add(_createRandomNPC(chunk.getWorldX(x), chunk.getWorldY(y), null));
          }
        }
      }
    }
    return npcs;
  }

  NPCModel _createRandomNPC(int wx, int wy, BuildingType? homeType) {
    final id = 'npc_${wx}_$wy';
    final name = _getRandomName();
    final type = _getNPCTypeForBuilding(homeType);

    // Initial faith: mostly sceptical/neutral at game start
    final initialFaith = -60.0 + _random.nextDouble() * 80.0;

    return NPCModel(
      id: id,
      name: name,
      type: type,
      homePosition: Vector2(
        wx * CellComponent.cellSize + CellComponent.cellSize / 2,
        wy * CellComponent.cellSize + CellComponent.cellSize / 2,
      ),
      faith: initialFaith,
    );
  }

  NPCType _getNPCTypeForBuilding(BuildingType? bType) {
    if (bType == null) return NPCType.citizen;
    if (bType == BuildingType.apartment) return NPCType.citizen;
    if (bType == BuildingType.church) return NPCType.citizen;
    if (_random.nextDouble() < 0.2) return NPCType.merchant;
    return NPCType.citizen;
  }

  String _getRandomName() {
    final firstNames = ['Lukas', 'Maria', 'Johannes', 'Sarah', 'Peter', 'Anna', 'Thomas', 'Elisabeth', 'Matthias', 'Martha'];
    final lastNames = ['Müller', 'Schmidt', 'Schneider', 'Fischer', 'Weber', 'Meyer', 'Wagner', 'Becker', 'Schulz', 'Hoffmann'];
    return '${firstNames[_random.nextInt(firstNames.length)]} ${lastNames[_random.nextInt(lastNames.length)]}';
  }

  List<NPCModel> getNPCsNear(Vector2 position, double radius) {
    // Diese Methode müsste für eine Welt-weite Suche optimiert werden, 
    // für den Radius-Check im Umkreis des Spielers reicht es aber oft, 
    // die aktiven Chunks im ChunkManager zu prüfen.
    return [];
  }
}
