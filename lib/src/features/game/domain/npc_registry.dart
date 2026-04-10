import 'package:flame/components.dart';
import 'models/npc_model.dart';
import '../presentation/components/cell_component.dart';
import 'models/city_chunk.dart';

class NPCRegistry {
  final List<NPCModel> _fixedNPCs = [];

  NPCRegistry() {
    _initFakes();
  }

  void _initFakes() {
    // Beispiel NPCs an festen Positionen
    _fixedNPCs.add(NPCModel(
      id: 'mayor_smith',
      name: 'Bürgermeister Smith',
      type: NPCType.officer,
      homePosition: Vector2(512, 512),
    ));
    
    _fixedNPCs.add(NPCModel(
      id: 'sister_mary',
      name: 'Schwester Mary',
      type: NPCType.priest,
      homePosition: Vector2(256, 256),
    ));

    // Ein paar zufällige Bürger für die Performance-Demo
    for (int i = 0; i < 50; i++) {
       _fixedNPCs.add(NPCModel(
        id: 'citizen_$i',
        name: 'Bürger $i',
        type: NPCType.citizen,
        homePosition: Vector2(100.0 + (i * 150) % 2000, 100.0 + (i * 120) % 2000),
      ));
    }
  }

  List<NPCModel> getNPCsInChunk(int cx, int cy) {
    const chunkSizeInPixels = CityChunk.chunkSize * CellComponent.cellSize;
    final startX = cx * chunkSizeInPixels;
    final startY = cy * chunkSizeInPixels;
    final endX = startX + chunkSizeInPixels;
    final endY = startY + chunkSizeInPixels;

    return _fixedNPCs.where((npc) {
      return npc.homePosition.x >= startX && 
             npc.homePosition.x < endX &&
             npc.homePosition.y >= startY && 
             npc.homePosition.y < endY;
    }).toList();
  }

  List<NPCModel> getNPCsNear(Vector2 position, double radius) {
    return _fixedNPCs.where((npc) => 
      npc.homePosition.distanceTo(position) < radius
    ).toList();
  }
}
