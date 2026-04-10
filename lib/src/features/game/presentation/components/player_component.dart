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
  bool _isChargingIntensity = false;
  bool _isChargingSize = false;

  // Pulse Times for Oscillators
  double _sizePulseTime = 0.0;
  double _intensityPulseTime = 0.0;

  // ===========================================================================
  // MODIFIER VORBEREITUNG (Für Issue #29 / #32)
  // ===========================================================================
  
  /// Geschwindigkeit des Flächen-Pulses (Joystick/Shift)
  double modifierSizeSpeed = 2.2;      
  
  /// Geschwindigkeit des Kraft-Pulses (Aktionsbutton)
  double modifierIntensitySpeed = 3.5; 
  
  /// Basis-Stärke des Gebets (Faktor für die Umwandlung von Faith in Impact)
  /// HINWEIS: Dies ist der Wert, der später durch Missionen/Upgrades erhöht wird!
  double modifierBasePower = 15.0;     
  
  /// Maximaler Radius der Gebetszone.
  double modifierMaxRadius = 450.0; 

  /// Globaler Widerstand-Multiplikator (Kann durch Missionen gesenkt werden)
  double modifierResistanceFactor = 1.0; 

  // ===========================================================================

  // Getters für das HUD
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

    final paint = Paint()..color = game.isSpiritualWorld ? Colors.amberAccent : Colors.blueAccent;
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
    if (keysPressed.contains(LogicalKeyboardKey.keyW) || keysPressed.contains(LogicalKeyboardKey.arrowUp)) _keyboardDirection.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyS) || keysPressed.contains(LogicalKeyboardKey.arrowDown)) _keyboardDirection.y += 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft)) _keyboardDirection.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight)) _keyboardDirection.x += 1;
    if (!_keyboardDirection.isZero()) _keyboardDirection.normalize();

    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      game.handleActionDown();
    } else if (event is KeyUpEvent && event.logicalKey == LogicalKeyboardKey.space) {
      game.handleActionUp();
    }

    _isChargingSize = keysPressed.contains(LogicalKeyboardKey.shiftLeft) || !joystick.delta.isZero();
    
    if (game.isSpiritualWorld && !_keyboardDirection.isZero()) {
      _isChargingSize = true;
    }

    return true;
  }

  void startChargingIntensity() {
    if (game.faith > 0.1) {
      _isChargingIntensity = true;
    }
  }

  void releasePrayer() {
    if (!_isChargingIntensity) return;
    _executePrayerImpact();
    _isChargingIntensity = false;
    _intensityPulseTime = 0;
  }

  void _executePrayerImpact() {
    // rawIntensity bestimmt NUR, wie viel % des Faiths eingesetzt werden (0.0 bis 1.0).
    final rawIntensity = (math.sin(_intensityPulseTime * modifierIntensitySpeed).abs());
    final radiusFactor = (math.sin(_sizePulseTime * modifierSizeSpeed).abs()).clamp(0.001, 1.0);
    
    // FAITH EINSATZ:
    // Die Nadel (rawIntensity) fungiert als Volumenregler für den Faith-Vorrat.
    double faithToSpend = game.faith * rawIntensity; 
    
    // Wir setzen den gewählten Betrag ein und ziehen ihn vom Vorrat ab.
    game.faith -= faithToSpend;
    
    final radius = radiusFactor * modifierMaxRadius;
    
    // IMPACT BERECHNUNG:
    // Die Kraft resultiert aus (Investierter Glaube / Fläche) * BasisPower.
    // Keine zusätzlichen Timing-Multiplikatoren (diese kommen später durch Modifier).
    final areaUnits = math.pi * math.pow(radius / CellComponent.cellSize, 2.0);
    final impactPower = (faithToSpend * modifierBasePower) / areaUnits.clamp(0.1, 1000.0);

    final center = position;
    final gridX = (center.x / CellComponent.cellSize).floor();
    final gridY = (center.y / CellComponent.cellSize).floor();
    final cellRange = (radius / CellComponent.cellSize).ceil() + 2;

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
            if (dist <= radius * 1.8) {
              final angle = toCell.angleTo(prayerZone.direction);
              if (angle.abs() < math.pi / 4.5) inZone = true;
            }
          }

          if (inZone) {
            final dist = center.distanceTo(cellPos);
            final falloff = 1.0 - (dist / (radius * 1.8)).clamp(0.0, 1.0);
            
            // finalImpact nutzt nur den eingesetzten Faith und die Fläche.
            final finalImpact = (impactPower / 100.0) * falloff / modifierResistanceFactor;
            
            cell.spiritualState = (cell.spiritualState + finalImpact).clamp(-1.0, 1.0);
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
    if (_keyboardDirection.isZero() && joystick.delta.isZero()) return;
    Vector2 moveDir = joystick.delta.isZero() ? _keyboardDirection : joystick.relativeDelta;
    position.add(moveDir * speed * dt);
  }

  void _updatePrayerMechanics(double dt) {
    _isChargingSize = !joystick.delta.isZero() || RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftLeft);
    
    if (_isChargingSize) {
      _sizePulseTime += dt;
      prayerZone.sizeFactor = math.sin(_sizePulseTime * modifierSizeSpeed).abs();
      
      if (!joystick.delta.isZero()) {
        prayerZone.direction = joystick.relativeDelta;
      } else if (!_keyboardDirection.isZero()) {
        prayerZone.direction = _keyboardDirection;
      }
    } else {
      _sizePulseTime = 0;
      prayerZone.sizeFactor = (prayerZone.sizeFactor - dt * 2.5).clamp(0.001, 1.0);
    }

    if (_isChargingIntensity && game.faith > 0.05) {
      _intensityPulseTime += dt;
      prayerZone.pulseValue = math.sin(_intensityPulseTime * modifierIntensitySpeed).abs();
    } else {
      _isChargingIntensity = false;
      _intensityPulseTime = 0;
      prayerZone.pulseValue = 0.05;
    }

    prayerZone.isActive = true; 
    prayerZone.position = position;
  }
}
