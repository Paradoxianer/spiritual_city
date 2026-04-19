import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../spirit_world_game.dart';

class PrayerHudComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  PrayerHudComponent() : super(priority: 200);

  @override
  void render(Canvas canvas) {
    if (!game.isSpiritualWorld) return;

    final player = game.player;
    
    // COMBAT HUD (Unten Mitte)
    const hudWidth = 240.0;
    const hudHeight = 80.0;
    final x = (game.size.x - hudWidth) / 2;
    final y = game.size.y - 195;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, hudWidth, hudHeight), const Radius.circular(15)),
      Paint()..color = Colors.black.withValues(alpha: 0.7),
    );

    _drawBar(
      canvas, x + 20, y + 15, hudWidth - 40, 12,
      'PRAYER INTENSITY', player.faithPulse,
      player.faithPulse > 0.7 ? Colors.amberAccent : Colors.cyanAccent,
      hasMarker: true,
    );

    _drawBar(
      canvas, x + 20, y + 45, hudWidth - 40, 12,
      'ZONE RADIUS', player.zoneSize, Colors.blueAccent,
    );
  }

  void _drawBar(Canvas canvas, double x, double y, double w, double h, String label, double progress, Color color, {bool hasMarker = false}) {
    final textPainter = TextPainter(
      text: TextSpan(text: label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(x, y - 12));

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(4)),
      Paint()..color = Colors.white10,
    );

    if (progress > 0.02) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w * progress, h), const Radius.circular(4)),
        Paint()..color = color,
      );
    }

    if (hasMarker) {
      // Optimal window indicator (70-100% = green zone)
      final optimalStart = x + (w * 0.7);
      final optimalPaint = Paint()
        ..color = Colors.greenAccent.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(optimalStart, y - 1, w * 0.3, h + 2), optimalPaint);

      // Marker line at current position
      final markerX = x + (w * progress);
      canvas.drawLine(
        Offset(markerX, y - 2),
        Offset(markerX, y + h + 2),
        Paint()..color = Colors.white.withValues(alpha: 0.9)..strokeWidth = 2,
      );

      // OPTIMAL label
      if (progress >= 0.7) {
        TextPainter(
          text: const TextSpan(
            text: '✓ OPTIMAL',
            style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout()..paint(canvas, Offset(x + w - 48, y - 12));
      }
    }
  }
}
