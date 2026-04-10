import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../spirit_world_game.dart';

class PrayerZoneComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  double sizeFactor = 0.0;
  Vector2 direction = Vector2.zero();
  double pulseValue = 0.0;
  bool isActive = false;

  static const double maxRadius = 150.0;

  PrayerZoneComponent() : super(anchor: Anchor.center, priority: 110);

  @override
  void update(double dt) {
    super.update(dt);
    if (!isActive) return;
    
    // Position immer auf den Spieler zentrieren
    position = game.player.position;
  }

  @override
  void render(Canvas canvas) {
    if (!isActive || sizeFactor <= 0) return;

    final radius = sizeFactor * maxRadius;
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Farbe basierend auf dem Pulsing-Value (Faith Intensity)
    // Von zartem Blau zu intensivem Gold
    final color = Color.lerp(
      Colors.blueAccent.withValues(alpha: 0.3),
      Colors.amber.withValues(alpha: 0.7),
      pulseValue,
    )!;

    paint.color = color;
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + (pulseValue * 10));

    if (direction.isZero()) {
      // Gleichmäßiger Ring
      canvas.drawCircle(Offset.zero, radius, paint);
    } else {
      // "Flammige" Zone in Richtung Joystick
      _drawFlamingZone(canvas, radius, direction, paint);
    }
  }

  void _drawFlamingZone(Canvas canvas, double radius, Vector2 dir, Paint paint) {
    final path = Path();
    final angle = atan2(dir.y, dir.x);
    
    // Wir zeichnen eine Tropfenform/Flamme, die sich in die Richtung streckt
    // Einfache Implementierung: Ein Oval, das in Richtung verschoben ist
    final center = Offset(dir.x * radius * 0.5, dir.y * radius * 0.5);
    
    canvas.save();
    canvas.rotate(angle);
    
    // Zeichne eine Ellipse, die in X-Richtung (lokal) gestreckt ist
    final rect = Rect.fromCenter(
      center: Offset(radius * 0.4, 0), 
      width: radius * 1.5, 
      height: radius * 0.8,
    );
    canvas.drawOval(rect, paint);
    
    canvas.restore();
  }
}
