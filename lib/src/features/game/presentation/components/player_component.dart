import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class PlayerComponent extends PositionComponent with HasGameRef {
  static const double playerSize = 24.0;
  final JoystickComponent joystick;
  final double speed = 200.0;

  PlayerComponent({required this.joystick})
      : super(
          size: Vector2.all(playerSize),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.blueAccent;
    canvas.drawCircle(
      (size / 2).toOffset(),
      size.x / 2,
      paint,
    );
    
    // Cross
    paint.color = Colors.white;
    paint.strokeWidth = 2;
    canvas.drawLine(
      Offset(size.x / 2, size.y * 0.2),
      Offset(size.x / 2, size.y * 0.8),
      paint,
    );
    canvas.drawLine(
      Offset(size.x * 0.3, size.y * 0.4),
      Offset(size.x * 0.7, size.y * 0.4),
      paint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!joystick.delta.isZero()) {
      position.add(joystick.relativeDelta * speed * dt);
    }
  }
}
