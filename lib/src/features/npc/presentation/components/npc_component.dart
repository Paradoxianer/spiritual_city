import 'dart:ui';
import 'package:flame/components.dart';
import '../../domain/entities/npc.dart';

class NpcComponent extends PositionComponent {
  final Npc _npc;

  NpcComponent(this._npc) : super(size: Vector2.all(8.0)) {
    position = _npc.position.clone();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      const Offset(4, 4),
      4.0,
      Paint()
        ..color = _npc.spiritualState > 0
            ? const Color(0xFF2196F3)
            : const Color(0xFFE91E63),
    );
  }
}
