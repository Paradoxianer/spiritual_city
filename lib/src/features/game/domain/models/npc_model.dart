import 'package:flame/components.dart';

enum NPCType {
  citizen,
  merchant,
  priest,
  officer,
}

class NPCModel {
  final String id;
  final String name;
  final NPCType type;
  final Vector2 homePosition;
  final double faith; // -1.0 to 1.0

  NPCModel({
    required this.id,
    required this.name,
    required this.type,
    required this.homePosition,
    this.faith = 0.0,
  });
}
