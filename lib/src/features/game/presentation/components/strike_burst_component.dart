import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A daemon reached the pastor (playtest 2026-11-15: "an explosion at the
/// pastor, that is where you look in a fight"): a bright flash, a fireball
/// and a shock ring burst right on the pastor, red shards fly out from where
/// the daemon was, and the ground it blots out glows dark red. Purely
/// visual – the damage and the red ground are done by `DaemonComponent`.
class StrikeBurstComponent extends PositionComponent {
  /// Where the daemon burst (world position).
  final Vector2 daemonAt;

  /// How far the red spreads (px) – the area painted dark red.
  final double radius;

  static const double _duration = 1.0;
  double _t = 0;

  final List<double> _angles;
  final Paint _fill = Paint();
  final Paint _ring = Paint()..style = PaintingStyle.stroke;
  final Paint _shard = Paint();

  StrikeBurstComponent({required Vector2 position, required this.daemonAt, required this.radius})
      : _angles = List.generate(16, (i) => i / 16 * math.pi * 2 + (i.isEven ? 0.15 : -0.1)),
        super(position: position, anchor: Anchor.center, priority: 125);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / _duration).clamp(0.0, 1.0);
    final fade = 1 - p;
    final out = Curves.easeOut.transform(p);
    final r = radius * (0.2 + 0.8 * out);

    // The blotted-out ground: dark red, fading slowly.
    _fill
      ..color = const Color(0xFF7F0000).withValues(alpha: 0.5 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset.zero, r, _fill);

    // The fireball on the pastor: orange-red, quickly growing and fading.
    final ball = 18 + 46 * Curves.easeOut.transform((p * 2).clamp(0.0, 1.0));
    _fill
      ..color = const Color(0xFFFF5722).withValues(alpha: 0.85 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, ball, _fill);

    // The white-hot flash of the first moment.
    if (p < 0.3) {
      _fill
        ..color = Colors.white.withValues(alpha: 0.95 * (1 - p / 0.3))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset.zero, 26 + 30 * p, _fill);
    }

    // Two shock rings.
    for (final lag in const [0.0, 0.18]) {
      final q = ((p - lag) / (1 - lag)).clamp(0.0, 1.0);
      if (q <= 0) continue;
      _ring
        ..strokeWidth = 7 * (1 - q) + 1
        ..color = const Color(0xFFE53935).withValues(alpha: 0.95 * (1 - q));
      canvas.drawCircle(Offset.zero, radius * Curves.easeOut.transform(q), _ring);
    }

    // The daemon breaking apart: shards fly out from where it was.
    final origin = (daemonAt - position).toOffset();
    final fly = 90 * out;
    _shard.color = const Color(0xFFFF5252).withValues(alpha: fade);
    for (final a in _angles) {
      final c = origin + Offset(math.cos(a), math.sin(a)) * fly;
      canvas.drawCircle(c, 5 * fade + 1, _shard);
    }
  }
}
