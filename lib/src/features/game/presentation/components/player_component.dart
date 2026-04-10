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

  // MODIFIER (Vorbereitung für Missionen/Upgrades)
  double modifierSizeSpeed = 3.0;      // Geschwindigkeit des Radius-Pulses
  double modifierIntensitySpeed = 5.0; // Geschwindigkeit des Kraft-Pulses
  double modifierBasePower = 80.0;     // Grundstärke der Gebetsenergie
  double modifierResistanceFactor = 1.0; // Multiplikator für Zell-Widerstand

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
    if (!game.isSpiritualWorld) {
      _keyboardDirection.setZero();
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

    // Shift als Joystick-Ersatz für den Größen-Puls
    _isChargingSize = keysPressed.contains(LogicalKeyboardKey.shiftLeft) || !joystick.delta.isZero();

    return true;
  }

  void startChargingIntensity() => _isChargingIntensity = true;

  void releasePrayer() {
    if (!_isChargingIntensity) return;
    _executePrayerImpact();
    _isChargingIntensity = false;
    _intensityPulseTime = 0;
  }

  void _executePrayerImpact() {
    // Timing Werte abfragen (0.1 bis 1.0)
    final intensity = (math.sin(_intensityPulseTime * modifierIntensitySpeed).abs()).clamp(0.1, 1.0);
    final radiusFactor = (math.sin(_sizePulseTime * modifierSizeSpeed).abs()).clamp(0.05, 1.0);
    
    final radius = radiusFactor * PrayerZoneComponent.maxRadius;
    
    // ENERGIE-VERTEILUNG:
    // Gesamte Gebetsenergie basierend auf dem Stärke-Timing
    final totalEnergy = modifierBasePower * intensity;
    
    // Impact pro Zelle ist umgekehrt proportional zur Fläche
    // Kleine Fläche (radiusFactor nah 0) -> Extrem hoher Impact pro Zelle
    // Große Fläche (radiusFactor nah 1) -> Schwacher Impact verteilt auf viele Zellen
    final areaEffectScale = 1.0 / (radiusFactor * radiusFactor * 10.0).clamp(1.0, 100.0);
    final impactPower = totalEnergy * areaEffectScale;

    final center = position;
    final gridX = (center.x / CellComponent.cellSize).floor();
    final gridY = (center.y / CellComponent.cellSize).floor();
    // Sicherheitsmarge beim Scannen der Zellen
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
            if (dist <= radius * 1.5) {
              final angle = toCell.angleTo(prayerZone.direction);
              if (angle.abs() < math.pi / 4) inZone = true;
            }
          }

          if (inZone) {
            final dist = center.distanceTo(cellPos);
            final falloff = 1.0 - (dist / (radius * 1.5)).clamp(0.0, 1.0);
            
            // Jeder Zelle kann einen individuellen Widerstand haben
            double cellResistance = 1.0; 
            final finalImpact = (impactPower / 100.0) * falloff / (cellResistance * modifierResistanceFactor);
            
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
    Vector2 direction = Vector2.zero();
    if (!joystick.delta.isZero()) {
      direction = joystick.relativeDelta;
    } else if (!_keyboardDirection.isZero()) {
      direction = _keyboardDirection;
    }

    if (!direction.isZero()) {
      position.add(direction * speed * dt);
    }
  }

  void _updatePrayerMechanics(double dt) {
    // 1. Größe & Form (Joystick / Shift)
    // Wenn gedrückt, pulsiert die Größe von Mini bis Super-Groß
    _isChargingSize = !joystick.delta.isZero() || RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftLeft);
    
    if (_isChargingSize) {
      _sizePulseTime += dt;
      prayerZone.sizeFactor = math.sin(_sizePulseTime * modifierSizeSpeed).abs();
      if (!joystick.delta.isZero()) {
        prayerZone.direction = joystick.relativeDelta;
      } else {
        prayerZone.direction = Vector2.zero();
      }
    } else {
      // Beim Loslassen schrumpft die Zone schnell auf ein Minimum
      _sizePulseTime = 0;
      prayerZone.sizeFactor = (prayerZone.sizeFactor - dt * 3.0).clamp(0.01, 1.0);
    }

    // 2. Stärke (Aktionsbutton)
    if (_isChargingIntensity) {
      _intensityPulseTime += dt;
      prayerZone.pulseValue = math.sin(_intensityPulseTime * modifierIntensitySpeed).abs();
    } else {
      _intensityPulseTime = 0;
      prayerZone.pulseValue = 0.1; // Grundleuchten
    }

    prayerZone.isActive = true; 
    prayerZone.position = position;
  }
}
