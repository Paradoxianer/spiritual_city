import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/prayer_combat.dart';
import 'package:spiritual_city/src/features/game/presentation/components/shockwave_component.dart';

void main() {
  group('ShockwaveComponent.cellImpactFactor – modes have distinct jobs', () {
    test('Liberation cleanses cells at full strength', () {
      expect(ShockwaveComponent.cellImpactFactor(PrayerMode.liberation), 1.0);
    });

    test('Rebuke, Slow and Drain liberate cells only marginally', () {
      for (final mode in [PrayerMode.rebuke, PrayerMode.slow, PrayerMode.drain]) {
        final factor = ShockwaveComponent.cellImpactFactor(mode);
        expect(factor, greaterThan(0.0), reason: '$mode should still do *something*');
        expect(factor, lessThanOrEqualTo(0.05),
            reason: '$mode liberating more than 5 % of Liberation would make '
                'Liberation optional');
      }
    });
  });
}
