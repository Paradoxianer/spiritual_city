import 'dart:ui';
import 'package:flame/components.dart';
import '../../../../core/constants/game_constants.dart';

class PlayerComponent extends PositionComponent with HasGameRef {
  Vector2 velocity = Vector2.zero();

  PlayerComponent() : super(size: Vector2.all(12.0));

  void setVelocity(Vector2 dir) {
    velocity = dir * GameConstants.playerSpeed;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity * dt);
    position.x = position.x.clamp(0.0, gameRef.size.x - size.x);
    position.y = position.y.clamp(0.0, gameRef.size.y - size.y);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }
}
