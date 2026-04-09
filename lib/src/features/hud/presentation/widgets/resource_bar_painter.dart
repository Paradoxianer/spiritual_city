import 'package:flutter/material.dart';

class ResourceBarPainter extends CustomPainter {
  final String label;
  final double value;
  final Color color;
  final double maxValue;

  const ResourceBarPainter({
    required this.label,
    required this.value,
    required this.color,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF333333),
    );
    final filledWidth = (value / maxValue).clamp(0.0, 1.0) * size.width;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, filledWidth, size.height),
      Paint()..color = color,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(2, 0));
  }

  @override
  bool shouldRepaint(ResourceBarPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.maxValue != maxValue;
}
