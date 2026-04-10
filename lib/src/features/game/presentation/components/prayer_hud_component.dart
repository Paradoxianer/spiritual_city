import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../spirit_world_game.dart';

class PrayerHudComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  PrayerHudComponent() : super(priority: 200);

  @override
  void render(Canvas canvas) {
    final size = game.size;
    
    // 1. GLOBAL FAITH BAR (Oben Links)
    _drawGlobalFaith(canvas);

    if (!game.isSpiritualWorld) return;

    final player = game.player;
    
    // 2. COMBAT HUD (Unten Mitte)
    final hudWidth = 220.0;
    final hudHeight = 70.0;
    final x = (size.x - hudWidth) / 2;
    final y = size.y - 180;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, hudWidth, hudHeight), const Radius.circular(15)),
      Paint()..color = Colors.black.withValues(alpha: 0.7),
    );

    _drawBar(
      canvas, x + 20, y + 15, hudWidth - 40, 12, 
      'PRAYER INTENSITY', player.faithPulse, 
      player.faithPulse > 0.7 ? Colors.amberAccent : Colors.cyanAccent,
      hasMarker: true
    );

    _drawBar(
      canvas, x + 20, y + 40, hudWidth - 40, 12, 
      'ZONE RADIUS', player.zoneSize, Colors.blueAccent
    );
  }

  void _drawGlobalFaith(Canvas canvas) {
    const double x = 20;
    const double y = 40;
    const double w = 150;
    const double h = 14;

    final faithProgress = (game.faith / 100.0).clamp(0.0, 1.0);
    
    // BG
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x-5, y-20, w+10, h+30), const Radius.circular(8)),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    TextPainter(
      text: TextSpan(
        text: 'FAITH: ${game.faith.toInt()}/100',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout()..paint(canvas, Offset(x, y - 16));

    // Bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(4)),
      Paint()..color = Colors.white10,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w * faithProgress, h), const Radius.circular(4)),
      Paint()..color = Colors.purpleAccent,
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
      final markerX = x + (w * 0.8);
      canvas.drawLine(Offset(markerX, y - 2), Offset(markerX, y + h + 2), Paint()..color = Colors.greenAccent.withValues(alpha: 0.5)..strokeWidth = 2);
    }
  }
}
