import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';

class PlayerComponent extends PositionComponent 
    with HasGameReference<SpiritWorldGame>, KeyboardHandler {
  static const double playerSize = 24.0;
  final JoystickComponent joystick;
  
  // Back to 100 speed for testing.
  final double speed = 100.0;

  PlayerComponent({required this.joystick})
      : super(
          size: Vector2.all(playerSize),
          anchor: Anchor.center,
          priority: 100,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.blueAccent;
    canvas.drawCircle((size / 2).toOffset(), size.x / 2, paint);
    
    // Cross
    paint.color = Colors.white;
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(size.x / 2, size.y * 0.2), Offset(size.x / 2, size.y * 0.8), paint);
    canvas.drawLine(Offset(size.x * 0.3, size.y * 0.4), Offset(size.x * 0.7, size.y * 0.4), paint);
  }

  final Vector2 _keyboardDirection = Vector2.zero();

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keyboardDirection.setZero();
    if (keysPressed.contains(LogicalKeyboardKey.keyW) || keysPressed.contains(LogicalKeyboardKey.arrowUp)) _keyboardDirection.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyS) || keysPressed.contains(LogicalKeyboardKey.arrowDown)) _keyboardDirection.y += 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft)) _keyboardDirection.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight)) _keyboardDirection.x += 1;

    if (!_keyboardDirection.isZero()) _keyboardDirection.normalize();
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    Vector2 direction = Vector2.zero();
    if (!joystick.delta.isZero()) {
      direction = joystick.relativeDelta;
    } else if (!_keyboardDirection.isZero()) {
      direction = _keyboardDirection;
    }

    if (!direction.isZero()) {
      // --- SUB-STEPPING FOR SMOOTHNESS ---
      // 20 steps per frame = 1200 updates per second at 60fps.
      const int steps = 20;
      final Vector2 frameDelta = direction * speed * dt;
      final Vector2 subStep = frameDelta / steps.toDouble();

      for (int i = 0; i < steps; i++) {
        _applySubStep(subStep);
      }
    }
  }

  void _applySubStep(Vector2 delta) {
    final Vector2 nextPos = position + delta;
    final int gx = (nextPos.x / CellComponent.cellSize).floor();
    final int gy = (nextPos.y / CellComponent.cellSize).floor();

    if (game.grid.isWalkable(gx, gy)) {
      position.setFrom(nextPos);
      game.closeMenu();
    } else {
      // Sliding per sub-step
      _slidingSubStep(delta);
    }
  }

  void _slidingSubStep(Vector2 delta) {
    final Vector2 nextX = position + Vector2(delta.x, 0);
    if (game.grid.isWalkable((nextX.x / CellComponent.cellSize).floor(), (position.y / CellComponent.cellSize).floor())) {
      position.setFrom(nextX);
    } else {
      final Vector2 nextY = position + Vector2(0, delta.y);
      if (game.grid.isWalkable((position.x / CellComponent.cellSize).floor(), (nextY.y / CellComponent.cellSize).floor())) {
        position.setFrom(nextY);
      }
    }
  }
}
