import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';
import 'prayer_zone_component.dart';

class PlayerComponent extends PositionComponent 
    with HasGameReference<SpiritWorldGame>, KeyboardHandler {
  static const double playerSize = 24.0;
  final JoystickComponent joystick;
  
  final double speed = 100.0;
  
  // Prayer Combat State
  late final PrayerZoneComponent prayerZone;
  double _faithPulseTime = 0.0;
  bool _isChargingFaith = false;
  
  // Getters für das HUD
  bool get isChargingFaith => _isChargingFaith;
  double get faithPulse => prayerZone.pulseValue;
  double get zoneSize => prayerZone.sizeFactor;

  PlayerComponent({required this.joystick})
      : super(
          size: Vector2.all(playerSize),
          anchor: Anchor.center,
          priority: 100,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
    prayerZone = PrayerZoneComponent();
    game.world.add(prayerZone);
  }

  @override
  void render(Canvas canvas) {
    if (!game.isSpiritualWorld) {
      final isNear = game.nearestInteractable != null;
      final auraPaint = Paint()
        ..color = isNear ? Colors.yellow.withValues(alpha: 0.2) : Colors.blueAccent.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      final pulse = 1.0 + (isNear ? (DateTime.now().millisecondsSinceEpoch % 1000 / 5000) : 0);
      canvas.drawCircle((size / 2).toOffset(), SpiritWorldGame.interactionRange * pulse, auraPaint);
    }

    final paint = Paint()..color = Colors.blueAccent;
    canvas.drawCircle((size / 2).toOffset(), size.x / 2, paint);
    
    paint.color = Colors.white;
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(size.x / 2, size.y * 0.2), Offset(size.x / 2, size.y * 0.8), paint);
    canvas.drawLine(Offset(size.x * 0.3, size.y * 0.4), Offset(size.x * 0.7, size.y * 0.4), paint);
  }

  final Vector2 _keyboardDirection = Vector2.zero();

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keyboardDirection.setZero();
    
    if (!game.isSpiritualWorld) {
      if (keysPressed.contains(LogicalKeyboardKey.keyW) || keysPressed.contains(LogicalKeyboardKey.arrowUp)) _keyboardDirection.y -= 1;
      if (keysPressed.contains(LogicalKeyboardKey.keyS) || keysPressed.contains(LogicalKeyboardKey.arrowDown)) _keyboardDirection.y += 1;
      if (keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft)) _keyboardDirection.x -= 1;
      if (keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight)) _keyboardDirection.x += 1;
      if (!_keyboardDirection.isZero()) _keyboardDirection.normalize();
    }

    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      game.handleActionDown();
    } else if (event is KeyUpEvent && event.logicalKey == LogicalKeyboardKey.space) {
      game.handleActionUp();
    }

    return true;
  }

  void startCharging() {
    _isChargingFaith = true;
  }

  void releasePrayer() {
    if (!_isChargingFaith) return;
    _executePrayerImpact();
    _isChargingFaith = false;
    _faithPulseTime = 0;
    // Die Zone bleibt bestehen, schrumpft aber via update()
  }

  void _executePrayerImpact() {
    // Timing Check: pulseValue ist math.sin(...).abs()
    final pulse = prayerZone.pulseValue;
    double multiplier = 0.4;
    if (pulse >= 0.8) multiplier = 1.0; // Perfect Timing
    else if (pulse >= 0.5) multiplier = 0.7; // Good
    
    final impactPower = 60.0 * multiplier;
    final radius = prayerZone.sizeFactor * PrayerZoneComponent.maxRadius;
    if (radius <= 5) return; // Zu klein zum Auslösen

    final center = position;
    final gridX = (center.x / CellComponent.cellSize).floor();
    final gridY = (center.y / CellComponent.cellSize).floor();
    final cellRange = (radius / CellComponent.cellSize).ceil() + 1;

    for (int dy = -cellRange; dy <= cellRange; dy++) {
      for (int dx = -cellRange; dx <= cellRange; dx++) {
        final cell = game.grid.getCell(gridX + dx, gridY + dy);
        if (cell != null) {
          final cellPos = Vector2(
            (gridX + dx) * CellComponent.cellSize + CellComponent.cellSize / 2,
            (gridY + dy) * CellComponent.cellSize + CellComponent.cellSize / 2,
          );
          
          bool inZone = false;
          if (prayerZone.direction.isZero()) {
            inZone = center.distanceTo(cellPos) <= radius;
          } else {
            final toCell = cellPos - center;
            final dist = toCell.length;
            if (dist <= radius * 1.5) {
              final angle = toCell.angleTo(prayerZone.direction);
              if (angle.abs() < math.pi / 3) inZone = true;
            }
          }

          if (inZone) {
            final dist = center.distanceTo(cellPos);
            final falloff = 1.0 - (dist / (radius * 1.6)).clamp(0.0, 1.0);
            cell.spiritualState = (cell.spiritualState + (impactPower / 100.0) * falloff).clamp(-1.0, 1.0);
          }
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (game.isSpiritualWorld) {
      _updatePrayerMechanics(dt);
    } else {
      _updateMovement(dt);
    }
  }

  void _updateMovement(double dt) {
    Vector2 direction = Vector2.zero();
    if (!joystick.delta.isZero()) {
      direction = joystick.relativeDelta;
    } else if (!_keyboardDirection.isZero()) {
      direction = _keyboardDirection;
    }

    if (!direction.isZero()) {
      const int steps = 20;
      final Vector2 frameDelta = direction * speed * dt;
      final Vector2 subStep = frameDelta / steps.toDouble();
      for (int i = 0; i < steps; i++) {
        _applySubStep(subStep);
      }
    }
  }

  void _updatePrayerMechanics(double dt) {
    // 1. Zone Größe (Nur durch Joystick gesteuert)
    if (!joystick.delta.isZero()) {
      prayerZone.sizeFactor = (prayerZone.sizeFactor + dt * 0.7).clamp(0.0, 1.0);
      prayerZone.direction = joystick.relativeDelta;
    } else {
      // Schrumpft langsam, wenn der Joystick losgelassen wird
      prayerZone.sizeFactor = (prayerZone.sizeFactor - dt * 0.3).clamp(0.0, 1.0);
    }

    // 2. Glaubens-Puls (Nur wenn Aktionsbutton gedrückt)
    if (_isChargingFaith) {
      _faithPulseTime += dt;
      // Pulsieren: 0.0 -> 1.0 -> 0.0 mit math.sin
      prayerZone.pulseValue = (math.sin(_faithPulseTime * 6.0).abs());
    } else {
      _faithPulseTime = 0;
      prayerZone.pulseValue = 0.15; // Grund-Glimmen
    }

    prayerZone.isActive = prayerZone.sizeFactor > 0.01;
    prayerZone.position = position;
  }

  void _applySubStep(Vector2 delta) {
    final Vector2 nextPos = position + delta;
    final int gx = (nextPos.x / CellComponent.cellSize).floor();
    final int gy = (nextPos.y / CellComponent.cellSize).floor();

    if (game.grid.isWalkable(gx, gy)) {
      position.setFrom(nextPos);
      game.closeMenu();
    } else {
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
