import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../spirit_world_game.dart';

class PrayerZoneComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  double sizeFactor = 0.0;
  Vector2 direction = Vector2.zero();
  double pulseValue = 0.0; // 0.0 bis 1.0 (wird vom PlayerComponent gesteuert)
  bool isActive = false;

  static const double maxRadius = 150.0;

  PrayerZoneComponent() : super(anchor: Anchor.center, priority: 110);

  @override
  void update(double dt) {
    super.update(dt);
    if (!isActive) return;
    
    // Position wird vom PlayerComponent gesetzt, aber wir stellen sicher, 
    // dass sie synchron bleibt falls nötig.
  }

  @override
  void render(Canvas canvas) {
    if (!isActive || sizeFactor <= 0.05) return;

    final radius = sizeFactor * maxRadius;
    
    // Pulsing Effekt: Wir zeichnen mehrere Layer für ein "Glühen"
    // Je nach pulseValue wird die Farbe intensiver (Goldener)
    
    // Hintergrund-Aura (sanftes Blau/Cyan)
    final auraPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blueAccent.withValues(alpha: 0.15 + (pulseValue * 0.1));
    
    // Kern-Farbe (wird bei hohem Puls goldener/weißer)
    final coreColor = Color.lerp(
      Colors.cyanAccent.withValues(alpha: 0.4),
      Colors.amberAccent.withValues(alpha: 0.8),
      pulseValue,
    )!;

    final corePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = coreColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 + (pulseValue * 15));

    if (direction.isZero()) {
      // Gleichmäßiger Ring um den Pastor
      canvas.drawCircle(Offset.zero, radius * 1.1, auraPaint);
      canvas.drawCircle(Offset.zero, radius, corePaint);
      
      // Optionaler "Timing-Ring" bei hohem Puls
      if (pulseValue > 0.7) {
        final timingPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: (pulseValue - 0.7) * 3);
        canvas.drawCircle(Offset.zero, radius, timingPaint);
      }
    } else {
      // "Flammige" Zone in Richtung Joystick
      _drawFlamingZone(canvas, radius, direction, corePaint, auraPaint);
    }
  }

  void _drawFlamingZone(Canvas canvas, double radius, Vector2 dir, Paint corePaint, Paint auraPaint) {
    final angle = atan2(dir.y, dir.x);
    
    canvas.save();
    canvas.rotate(angle);
    
    // Aura
    final auraRect = Rect.fromCenter(
      center: Offset(radius * 0.5, 0), 
      width: radius * 1.8, 
      height: radius * 1.1,
    );
    canvas.drawOval(auraRect, auraPaint);

    // Kern (Die "Zunge")
    // Die Länge der Zunge kann leicht mit dem Puls variieren
    final pulseLength = radius * (0.4 + (pulseValue * 0.2));
    final coreRect = Rect.fromCenter(
      center: Offset(pulseLength, 0), 
      width: radius * 1.6, 
      height: radius * 0.8,
    );
    canvas.drawOval(coreRect, corePaint);
    
    // "Licht-Spitze" bei hohem Puls
    if (pulseValue > 0.7) {
      final tipPaint = Paint()
        ..color = Colors.white.withValues(alpha: (pulseValue - 0.7) * 2);
      canvas.drawCircle(Offset(radius * 1.2, 0), radius * 0.2 * pulseValue, tipPaint);
    }
    
    canvas.restore();
  }
}
