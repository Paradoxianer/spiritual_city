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
  
  // Adjusted speed for a more controlled feel. 
  // Lower speed allows for sub-pixel precision to be more apparent.
  final double speed = 50.0;

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
    
    // Cross symbol
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

  final Vector2 _keyboardDirection = Vector2.zero();

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keyboardDirection.setZero();
    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      _keyboardDirection.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      _keyboardDirection.y += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      _keyboardDirection.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      _keyboardDirection.x += 1;
    }

    if (!_keyboardDirection.isZero()) {
      _keyboardDirection.normalize();
    }
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    Vector2 direction = Vector2.zero();
    
    // Joystick takes precedence
    if (!joystick.delta.isZero()) {
      direction = joystick.relativeDelta;
    } 
    // Keyboard input fallback
    else if (!_keyboardDirection.isZero()) {
      direction = _keyboardDirection;
    }

    if (!direction.isZero()) {
      // Precise movement delta (Sub-pixel precise thanks to 'dt')
      final Vector2 movementDelta = direction * speed * dt;
      final Vector2 targetPos = position + movementDelta;

      // Check collision at the grid level
      final int gridX = (targetPos.x / CellComponent.cellSize).floor();
      final int gridY = (targetPos.y / CellComponent.cellSize).floor();

      if (game.grid.isWalkable(gridX, gridY)) {
        position.setFrom(targetPos);
        game.closeMenu();
      } else {
        // Sliding logic to keep movement fluid near walls
        _applySlidingMovement(movementDelta);
      }
    }
  }

  void _applySlidingMovement(Vector2 delta) {
    // Try horizontal sliding
    final Vector2 nextX = position + Vector2(delta.x, 0);
    final int gx = (nextX.x / CellComponent.cellSize).floor();
    final int gy = (position.y / CellComponent.cellSize).floor();
    
    if (game.grid.isWalkable(gx, gy)) {
      position.setFrom(nextX);
      game.closeMenu();
    } else {
      // Try vertical sliding
      final Vector2 nextY = position + Vector2(0, delta.y);
      final int vgx = (position.x / CellComponent.cellSize).floor();
      final int vgy = (nextY.y / CellComponent.cellSize).floor();
      
      if (game.grid.isWalkable(vgx, vgy)) {
        position.setFrom(nextY);
        game.closeMenu();
      }
    }
  }
}
