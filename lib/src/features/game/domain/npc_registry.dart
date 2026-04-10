import 'package:flame/components.dart';
import 'models/npc_model.dart';

class NPCRegistry {
  final List<NPCModel> _fixedNPCs = [];

  NPCRegistry() {
    _initFakes();
  }

  void _initFakes() {
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
  }

  List<NPCModel> getNPCsNear(Vector2 position, double radius) {
    return _fixedNPCs.where((npc) => 
      npc.homePosition.distanceTo(position) < radius
    ).toList();
  }
}
