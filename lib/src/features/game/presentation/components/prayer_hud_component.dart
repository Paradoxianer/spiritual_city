import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../spirit_world_game.dart';

class PrayerHudComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  PrayerHudComponent() : super(priority: 200);

  @override
  void render(Canvas canvas) {
    // 1. RESOURCE BARS (Oben Links)
    _drawResourceBars(canvas);

    if (!game.isSpiritualWorld) return;

    final player = game.player;
    
    // 2. COMBAT HUD (Unten Mitte)
    final hudWidth = 240.0;
    final hudHeight = 80.0;
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

  void _drawResourceBars(Canvas canvas) {
    const double x = 14;
    const double y = 14;
    const double barW = 130;
    const double barH = 10;
    const double spacing = 20.0;
    const double bgPad = 8;
    const double totalH = spacing * 4 + bgPad * 2;

    // Background panel
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - bgPad, y - bgPad, barW + 70, totalH),
        const Radius.circular(10),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    _drawResourceBar(canvas, x, y,              barW, barH, '❤️', 'HP',       game.health,    game.maxHealth,    Colors.redAccent);
    _drawResourceBar(canvas, x, y + spacing,     barW, barH, '🍞', 'Hunger',   game.hunger,    game.maxHunger,    Colors.orange);
    _drawResourceBar(canvas, x, y + spacing * 2, barW, barH, '🙏', 'Faith',    game.faith,     game.maxFaith,     Colors.purpleAccent);
    _drawResourceBar(canvas, x, y + spacing * 3, barW, barH, '📦', 'Supplies', game.materials, game.maxMaterials, Colors.blueGrey);
  }

  void _drawResourceBar(Canvas canvas, double x, double y, double w, double h,
      String icon, String label, double value, double max, Color color) {
    final progress = (value / max).clamp(0.0, 1.0);
    final val = value.toInt();
    final maxVal = max.toInt();

    // Icon
    TextPainter(
      text: TextSpan(text: icon, style: const TextStyle(fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout()..paint(canvas, Offset(x, y - 1));

    // Label + value text
    TextPainter(
      text: TextSpan(
        text: '$label $val/$maxVal',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout()..paint(canvas, Offset(x + 18, y - 1));

    // Bar background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + 18, y + 10, w, h), const Radius.circular(3)),
      Paint()..color = Colors.white12,
    );

    // Bar fill
    if (progress > 0.0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x + 18, y + 10, w * progress, h), const Radius.circular(3)),
        Paint()..color = color,
      );
    }
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
