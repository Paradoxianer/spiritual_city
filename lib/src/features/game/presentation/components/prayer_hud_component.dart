import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../spirit_world_game.dart';

class PrayerHudComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  PrayerHudComponent() : super(priority: 100);

  @override
  void render(Canvas canvas) {
    if (!game.isSpiritualWorld || !game.player.isChargingFaith) return;

    final player = game.player;
    final size = game.size;
    
    // Positionierung im unteren Drittel, über den Buttons
    final hudWidth = 250.0;
    final hudHeight = 80.0;
    final x = (size.x - hudWidth) / 2;
    final y = size.y - 200;

    final rect = Rect.fromLTWH(x, y, hudWidth, hudHeight);
    
    // Hintergrund
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(15)),
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    _drawBar(
      canvas, 
      x + 20, y + 15, 
      hudWidth - 40, 20, 
      'POWER', 
      player.faithPulse, 
      player.faithPulse >= 0.7 ? Colors.greenAccent : Colors.amberAccent
    );

    _drawBar(
      canvas, 
      x + 20, y + 45, 
      hudWidth - 40, 20, 
      'ZONE', 
      player.zoneSize, 
      Colors.blueAccent
    );
  }

  void _drawBar(Canvas canvas, double x, double y, double w, double h, String label, double progress, Color color) {
    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(x, y - 12));

    // Bar Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(5)),
      Paint()..color = Colors.white24,
    );

    // Progress
    if (progress > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w * progress, h), const Radius.circular(5)),
        Paint()..color = color,
      );
    }
    
    // Percent Text
    final percentPainter = TextPainter(
      text: TextSpan(
        text: '${(progress * 100).toInt()}%',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    percentPainter.paint(canvas, Offset(x + w - 30, y - 12));
  }
}
