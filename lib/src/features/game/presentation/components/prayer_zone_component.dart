import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../spirit_world_game.dart';

class PrayerZoneComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  double sizeFactor = 0.0;     // Pulsierend gesteuert durch Joystick/Shift
  double pulseValue = 0.0;     // Pulsierend gesteuert durch Aktions-Button
  Vector2 direction = Vector2.zero();
  bool isActive = false;
  Color? colorOverride;

  /// Maximum radius of the prayer zone in pixels.
  /// Must be kept in sync with [PlayerComponent.modifierMaxRadius].
  static const double maxRadius = 180.0;

  /// The directional beam extends this multiple of the current radius.
  /// Exposed so [PlayerComponent] can use the exact same value for its
  /// collision/impact check, keeping the visual zone and affected area aligned.
  static const double beamLengthMultiplier = 1.6;

  PrayerZoneComponent() : super(anchor: Anchor.center, priority: 110);

  @override
  void render(Canvas canvas) {
    if (!isActive || sizeFactor <= 0.02) return;

    final radius = sizeFactor * maxRadius;
    
    // ENERGIE-VISUALISIERUNG:
    // Wenn die Fläche groß ist, verteilt sich die Energie -> die Sättigung sinkt.
    final energyDensity = (1.0 / (sizeFactor * 2 + 0.5)).clamp(0.2, 1.0);
    
    final auraColor = colorOverride?.withValues(alpha: 0.2 * energyDensity) ?? Color.lerp(
      Colors.blueAccent.withValues(alpha: 0.1 * energyDensity),
      Colors.cyanAccent.withValues(alpha: 0.3 * energyDensity),
      pulseValue,
    )!;
    
    final coreColor = colorOverride?.withValues(alpha: 0.6 * energyDensity) ?? Color.lerp(
      Colors.white.withValues(alpha: 0.4 * energyDensity),
      Colors.amberAccent.withValues(alpha: 0.9 * energyDensity),
      pulseValue,
    )!;

    final paint = Paint()..style = PaintingStyle.fill;

    // Zentrierter Kreis (Ring-Form)
    paint.color = auraColor;
    canvas.drawCircle(Offset.zero, radius * 1.1, paint);
    
    paint.color = coreColor;
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * energyDensity);
    canvas.drawCircle(Offset.zero, radius, paint);
  }
}
