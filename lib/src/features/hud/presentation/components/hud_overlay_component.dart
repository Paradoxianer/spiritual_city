import 'dart:ui';
import 'package:flame/components.dart';
import '../../../player/domain/services/player_service.dart';

class HudOverlayComponent extends PositionComponent {
  final PlayerService _playerService;

  static const double _barWidth = 100.0;
  static const double _barHeight = 8.0;
  static const double _barSpacing = 14.0;
  static const double _startX = 10.0;
  static const double _startY = 10.0;

  HudOverlayComponent(this._playerService) : super(priority: 100);

  @override
  void render(Canvas canvas) {
    _drawBar(
      canvas,
      index: 0,
      value: _playerService.state.focus,
      color: const Color(0xFF4CAF50),
    );
    _drawBar(
      canvas,
      index: 1,
      value: _playerService.state.energy,
      color: const Color(0xFF2196F3),
    );
    _drawBar(
      canvas,
      index: 2,
      value: _playerService.state.spiritualStrength,
      color: const Color(0xFF9C27B0),
    );
  }

  void _drawBar(
    Canvas canvas, {
    required int index,
    required double value,
    required Color color,
  }) {
    final y = _startY + index * _barSpacing;
    canvas.drawRect(
      Rect.fromLTWH(_startX, y, _barWidth, _barHeight),
      Paint()..color = const Color(0xFF333333),
    );
    final filledWidth = (value / 100.0).clamp(0.0, 1.0) * _barWidth;
    canvas.drawRect(
      Rect.fromLTWH(_startX, y, filledWidth, _barHeight),
      Paint()..color = color,
    );
  }
}
