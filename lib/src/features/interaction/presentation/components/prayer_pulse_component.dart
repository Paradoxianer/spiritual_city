import 'dart:ui';
import 'package:flame/components.dart';
import '../../domain/services/prayer_service.dart';

class PrayerPulseComponent extends PositionComponent {
  final PrayerService _prayerService;
  bool isInSpiritualWorld = false;

  PrayerPulseComponent(this._prayerService);

  @override
  void render(Canvas canvas) {
    if (!isInSpiritualWorld) return;
    final pulse = _prayerService.currentPulse;
    if (pulse == null || !pulse.isActive) return;
    canvas.drawCircle(
      Offset(pulse.position.x, pulse.position.y),
      pulse.radius,
      Paint()
        ..color = const Color(0xAAFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }
}
