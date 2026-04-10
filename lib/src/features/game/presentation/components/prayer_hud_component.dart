import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../spirit_world_game.dart';

class PrayerHudComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  PrayerHudComponent() : super(priority: 200); // Höchste Priorität im HUD

  @override
  void render(Canvas canvas) {
    if (!game.isSpiritualWorld) return;

    final player = game.player;
    final size = game.size;
    
    // Positionierung im unteren Bereich
    final hudWidth = 220.0;
    final hudHeight = 70.0;
    final x = (size.x - hudWidth) / 2;
    final y = size.y - 180;

    final rect = Rect.fromLTWH(x, y, hudWidth, hudHeight);
    
    // Hintergrund mit Glas-Effekt
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(15)),
      Paint()..color = Colors.black.withValues(alpha: 0.7),
    );

    // 1. POWER BAR (Faith Pulse)
    final pulse = player.faithPulse;
    Color pulseColor = Colors.cyanAccent;
    if (pulse > 0.8) pulseColor = Colors.white;
    else if (pulse > 0.6) pulseColor = Colors.amberAccent;

    _drawBar(
      canvas, 
      x + 20, y + 15, 
      hudWidth - 40, 12, 
      'FAITH POWER', 
      pulse, 
      pulseColor,
      hasMarker: true,
    );

    // 2. ZONE BAR (Radius)
    _drawBar(
      canvas, 
      x + 20, y + 40, 
      hudWidth - 40, 12, 
      'ZONE RADIUS', 
      player.zoneSize, 
      Colors.blueAccent,
    );
  }

  void _drawBar(Canvas canvas, double x, double y, double w, double h, String label, double progress, Color color, {bool hasMarker = false}) {
    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(x, y - 12));

    // Bar Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(4)),
      Paint()..color = Colors.white10,
    );

    // Progress
    if (progress > 0.02) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w * progress, h), const Radius.circular(4)),
        Paint()..color = color,
      );
      
      // Glanz-Effekt auf dem Balken
      canvas.drawRect(
        Rect.fromLTWH(x, y, w * progress, h * 0.3),
        Paint()..color = Colors.white.withValues(alpha: 0.2),
      );
    }

    // "Perfect" Marker für den Power-Balken
    if (hasMarker) {
      final markerX = x + (w * 0.8);
      canvas.drawLine(
        Offset(markerX, y - 2),
        Offset(markerX, y + h + 2),
        Paint()..color = Colors.greenAccent.withValues(alpha: 0.5)..strokeWidth = 2,
      );
    }
  }
}
