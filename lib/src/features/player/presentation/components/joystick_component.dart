import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../../../../core/constants/game_constants.dart';

class PlayerJoystickComponent extends PositionComponent with DragCallbacks {
  static const double _joystickRadius = GameConstants.joystickRadius;
  static const double _knobRadius = GameConstants.joystickKnobRadius;

  Vector2 _knobOffset = Vector2.zero();
  bool isVisible = true;

  Vector2 get direction =>
      _knobOffset.length > 0 ? _knobOffset.normalized() : Vector2.zero();

  PlayerJoystickComponent()
      : super(size: Vector2.all(_joystickRadius * 2));

  @override
  void onDragStart(DragStartEvent event) {
    _knobOffset = Vector2.zero();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _knobOffset += event.localDelta;
    if (_knobOffset.length > _joystickRadius) {
      _knobOffset = _knobOffset.normalized() * _joystickRadius;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    _knobOffset = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;
    final center = Offset(_joystickRadius, _joystickRadius);

    canvas.drawCircle(
      center,
      _joystickRadius,
      Paint()..color = const Color(0x44FFFFFF),
    );

    canvas.drawCircle(
      Offset(center.dx + _knobOffset.x, center.dy + _knobOffset.y),
      _knobRadius,
      Paint()..color = const Color(0x88FFFFFF),
    );
  }
}
