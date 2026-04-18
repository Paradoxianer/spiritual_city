import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/presentation/components/loot_system.dart';

void main() {
  // ── LootType reward values ────────────────────────────────────────────────

  group('LootType rewards', () {
    test('small gives +5 MP', () {
      expect(LootType.small.reward, 5.0);
    });

    test('normal gives +10 MP', () {
      expect(LootType.normal.reward, 10.0);
    });

    test('large gives +15 MP', () {
      expect(LootType.large.reward, 15.0);
    });
  });

  // ── LootTypeExt.random probability distribution ───────────────────────────

  group('LootTypeExt.random probability', () {
    test('60 % small, 30 % normal, 10 % large over 10,000 samples', () {
      final rng = Random(42);
      int small = 0, normal = 0, large = 0;
      const samples = 10000;

      for (int i = 0; i < samples; i++) {
        switch (LootTypeExt.random(rng)) {
          case LootType.small:
            small++;
          case LootType.normal:
            normal++;
          case LootType.large:
            large++;
        }
      }

      // Allow ±3 % tolerance around the target probabilities.
      expect(small / samples, closeTo(0.60, 0.03),
          reason: 'small should appear ~60 %');
      expect(normal / samples, closeTo(0.30, 0.03),
          reason: 'normal should appear ~30 %');
      expect(large / samples, closeTo(0.10, 0.03),
          reason: 'large should appear ~10 %');
    });

    test('always returns one of the three types', () {
      final rng = Random(0);
      for (int i = 0; i < 1000; i++) {
        final type = LootTypeExt.random(rng);
        expect(LootType.values.contains(type), isTrue);
      }
    });
  });
}
