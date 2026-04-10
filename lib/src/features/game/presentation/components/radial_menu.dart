import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../spirit_world_game.dart';

class RadialAction {
  final String label;
  final IconData icon;
  final VoidCallback onSelect;

  RadialAction({
    required this.label,
    required this.icon,
    required this.onSelect,
  });
}

class RadialMenu extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final List<RadialAction> actions;
  final double radius = 60.0;

  RadialMenu({
    required this.actions,
    required Vector2 position,
  }) : super(position: position, anchor: Anchor.center, priority: 200);

  @override
  Future<void> onLoad() async {
    if (actions.isEmpty) {
      removeFromParent();
      return;
    }

    final angleStep = (2 * pi) / actions.length;
    for (int i = 0; i < actions.length; i++) {
      final angle = i * angleStep - (pi / 2); // Start from top
      final action = actions[i];
      
      final iconPos = Vector2(
        cos(angle) * radius,
        sin(angle) * radius,
      );

      add(RadialItem(
        action: action,
        position: iconPos,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, radius, paint);
  }
}

class RadialItem extends PositionComponent with TapCallbacks {
  final RadialAction action;
  static const double itemSize = 44.0;

  RadialItem({
    required this.action,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2.all(itemSize),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    // Circle background
    final paint = Paint()..color = Colors.black.withOpacity(0.7);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
    
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, borderPaint);

    // Label (Emoji)
    final textPainter = TextPainter(
      text: TextSpan(
        text: action.label,
        style: const TextStyle(fontSize: 24),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.x / 2 - textPainter.width / 2, size.y / 2 - textPainter.height / 2),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    action.onSelect();
    parent?.removeFromParent(); // Close menu
  }
}
