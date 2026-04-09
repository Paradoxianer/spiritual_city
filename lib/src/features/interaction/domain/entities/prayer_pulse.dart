import 'package:flame/components.dart';

class PrayerPulse {
  final Vector2 position;
  final double radius;
  final double maxRadius;
  final bool isActive;

  PrayerPulse({
    required this.position,
    this.radius = 0.0,
    this.maxRadius = 200.0,
    this.isActive = false,
  });

  PrayerPulse copyWith({
    Vector2? position,
    double? radius,
    double? maxRadius,
    bool? isActive,
  }) =>
      PrayerPulse(
        position: position ?? this.position,
        radius: radius ?? this.radius,
        maxRadius: maxRadius ?? this.maxRadius,
        isActive: isActive ?? this.isActive,
      );
}
