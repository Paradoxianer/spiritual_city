import 'package:flame/components.dart';

class Npc {
  final String id;
  final String name;
  final double spiritualState;
  final Vector2 position;
  final bool hasActiveMission;

  const Npc({
    required this.id,
    required this.name,
    required this.spiritualState,
    required this.position,
    this.hasActiveMission = false,
  });

  Npc copyWith({
    String? id,
    String? name,
    double? spiritualState,
    Vector2? position,
    bool? hasActiveMission,
  }) =>
      Npc(
        id: id ?? this.id,
        name: name ?? this.name,
        spiritualState: spiritualState ?? this.spiritualState,
        position: position ?? this.position,
        hasActiveMission: hasActiveMission ?? this.hasActiveMission,
      );
}
