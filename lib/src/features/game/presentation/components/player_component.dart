import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';

class PlayerComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  static const double playerSize = 24.0;
  final JoystickComponent joystick;
  final double speed = 200.0;

  PlayerComponent({required this.joystick})
      : super(
          size: Vector2.all(playerSize),
          anchor: Anchor.center,
          priority: 100, // Ensure player is rendered on top of the city
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
      final Vector2 delta = joystick.relativeDelta * speed * dt;
      final Vector2 nextPosition = position + delta;

      // Simple collision check:
      // Convert pixel position to grid coordinates
      final int gridX = (nextPosition.x / CellComponent.cellSize).floor();
      final int gridY = (nextPosition.y / CellComponent.cellSize).floor();

      if (game.grid.isWalkable(gridX, gridY)) {
        position.setFrom(nextPosition);
        // If the player moves, close the menu to avoid "menu trailing"
        game.closeMenu();
      } else {
        // Try sliding (only X or only Y)
        final Vector2 nextX = position + Vector2(delta.x, 0);
        final int gridXonly = (nextX.x / CellComponent.cellSize).floor();
        final int currentGridY = (position.y / CellComponent.cellSize).floor();
        
        if (game.grid.isWalkable(gridXonly, currentGridY)) {
          position.setFrom(nextX);
          game.closeMenu();
        } else {
          final Vector2 nextY = position + Vector2(0, delta.y);
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
