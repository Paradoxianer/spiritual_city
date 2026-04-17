import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/services/territory_color_mapper.dart';

void main() {
  group('TerritoryColorMapper', () {
    late TerritoryColorMapper mapper;

    setUp(() {
      mapper = TerritoryColorMapper();
    });

    test('positive state maps to green-dominant color', () {
      final color = mapper.stateToColor(0.5);
      expect(color.green, greaterThan(color.red));
    });

    test('negative state maps to red-dominant color', () {
      final color = mapper.stateToColor(-0.5);
      expect(color.red, greaterThan(color.green));
    });

    test('neutral state maps to grey', () {
      final color = mapper.stateToColor(0.0);
      expect(color, const Color(0xFF808080));
    });

    test('values outside range are clamped', () {
      expect(mapper.stateToColor(2.0), mapper.stateToColor(1.0));
      expect(mapper.stateToColor(-2.0), mapper.stateToColor(-1.0));
    });

    test('strongly positive state approaches dark green', () {
      final color = mapper.stateToColor(1.0);
      // dark green (#006400): high green, near-zero red and blue
      expect(color.green, greaterThan(color.red));
      expect(color.green, greaterThan(50));
    });

    test('strongly negative state approaches near-black red', () {
      final color = mapper.stateToColor(-1.0);
      // near-black red (#330000): low r, near-zero g and b
      expect(color.red, lessThan(80));
      expect(color.green, lessThan(20));
    });

    test('redPulseAlpha returns 1.0 for non-negative and mildly negative states', () {
      expect(mapper.redPulseAlpha(0.5, 0.0), 1.0);
      expect(mapper.redPulseAlpha(0.0, 0.0), 1.0);
      expect(mapper.redPulseAlpha(-0.2, 0.0), 1.0);
    });

    test('redPulseAlpha returns value in [0.6, 1.0] for strongly negative state', () {
      for (double t = 0.0; t < 2.0; t += 0.1) {
        final alpha = mapper.redPulseAlpha(-0.8, t);
        expect(alpha, greaterThanOrEqualTo(0.6));
        expect(alpha, lessThanOrEqualTo(1.0));
      }
    });

    test('shouldSpawnSparkle returns false for neutral and negative states', () {
      expect(mapper.shouldSpawnSparkle(0.0, 0.5), false);
      expect(mapper.shouldSpawnSparkle(-0.5, 0.5), false);
      expect(mapper.shouldSpawnSparkle(0.3, 0.5), false); // at boundary (excluded: threshold is exclusive upper bound)
    });

    test('shouldSpawnSparkle returns true for max state with zero random', () {
      expect(mapper.shouldSpawnSparkle(1.0, 0.0), true);
    });

    test('shouldSpawnSparkle returns false when random exceeds spawn chance', () {
      // For state = 0.5, chancePerSecond ≈ 2.286, at default dt=1/60: ~0.038
      // random = 0.5 far exceeds per-frame chance → false
      expect(mapper.shouldSpawnSparkle(0.5, 0.5), false);
    });
  });
}
