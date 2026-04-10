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
  
  // Reduced speed for more "game-like" feel
  final double speed = 150.0;

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

  final Vector2 _keyboardDelta = Vector2.zero();

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keyboardDelta.setZero();
    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      _keyboardDelta.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      _keyboardDelta.y += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      _keyboardDelta.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      _keyboardDelta.x += 1;
    }

    if (_keyboardDelta.length > 0) {
      _keyboardDelta.normalize();
    }
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    Vector2 delta = Vector2.zero();
    
    // Joystick input
    if (!joystick.delta.isZero()) {
      delta = joystick.relativeDelta;
    } 
    // Keyboard input (if no joystick delta)
    else if (!_keyboardDelta.isZero()) {
      delta = _keyboardDelta;
    }

    if (!delta.isZero()) {
      final Vector2 movement = delta * speed * dt;
      final Vector2 nextPosition = position + movement;

      final int gridX = (nextPosition.x / CellComponent.cellSize).floor();
      final int gridY = (nextPosition.y / CellComponent.cellSize).floor();

      if (game.grid.isWalkable(gridX, gridY)) {
        position.setFrom(nextPosition);
        game.closeMenu();
      } else {
        // Sliding logic
        final Vector2 nextX = position + Vector2(movement.x, 0);
        final int gridXonly = (nextX.x / CellComponent.cellSize).floor();
        final int currentGridY = (position.y / CellComponent.cellSize).floor();
        
        if (game.grid.isWalkable(gridXonly, currentGridY)) {
          position.setFrom(nextX);
          game.closeMenu();
        } else {
          final Vector2 nextY = position + Vector2(0, movement.y);
          final int currentGridX = (position.x / CellComponent.cellSize).floor();
          final int gridYonly = (nextY.y / CellComponent.cellSize).floor();
          
          if (game.grid.isWalkable(currentGridX, gridYonly)) {
            position.setFrom(nextY);
            game.closeMenu();
          }
        }
      }
    }
  }
}
