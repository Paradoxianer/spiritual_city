import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/services/faith_calculator_service.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

void main() {
  group('FaithCalculatorService', () {
    // Use a fixed seed so results are deterministic across runs.
    Random seededRng(int seed) => Random(seed);

    group('calculateConversationGain', () {
      test('normal difficulty: gain in range [0, 2]', () {
        final calc = FaithCalculatorService(difficulty: Difficulty.normal, rng: seededRng(0));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateConversationGain();
          expect(gain, inInclusiveRange(0, 2));
        }
      });

      test('easy difficulty: gain in range [0, 3] (+50%)', () {
        final calc = FaithCalculatorService(difficulty: Difficulty.easy, rng: seededRng(1));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateConversationGain();
          expect(gain, inInclusiveRange(0, 3));
        }
      });

      test('hard difficulty: gain in range [0, 1] (-50%)', () {
        final calc = FaithCalculatorService(difficulty: Difficulty.hard, rng: seededRng(2));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateConversationGain();
          expect(gain, inInclusiveRange(0, 1));
        }
      });

      test('easy yields same or more than normal for non-zero base', () {
        // base = 2 → normal: 2, easy: ceil(3.0) = 3
        final normalCalc = FaithCalculatorService(difficulty: Difficulty.normal, rng: seededRng(99));
        final easyCalc = FaithCalculatorService(difficulty: Difficulty.easy, rng: seededRng(99));
        // Both use the same seed so they draw the same base values
        bool easyEverHigher = false;
        for (int i = 0; i < 50; i++) {
          final normalGain = normalCalc.calculateConversationGain();
          final easyGain = easyCalc.calculateConversationGain();
          expect(easyGain, greaterThanOrEqualTo(normalGain));
          if (easyGain > normalGain) easyEverHigher = true;
        }
        expect(easyEverHigher, isTrue, reason: 'Easy should yield more faith than normal for base > 0');
      });
    });

    group('calculateGiftGain', () {
      test('normal difficulty: gain in range [1, 3]', () {
        final calc = FaithCalculatorService(difficulty: Difficulty.normal, rng: seededRng(3));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateGiftGain();
          expect(gain, inInclusiveRange(1, 3));
        }
      });

      test('easy difficulty: gain in range [2, 5]', () {
        // base=1 → ceil(1.5)=2; base=3 → ceil(4.5)=5
        final calc = FaithCalculatorService(difficulty: Difficulty.easy, rng: seededRng(4));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateGiftGain();
          expect(gain, inInclusiveRange(2, 5));
        }
      });

      test('hard difficulty: gain in range [1, 2]', () {
        // base=1 → ceil(0.5)=1; base=3 → ceil(1.5)=2
        final calc = FaithCalculatorService(difficulty: Difficulty.hard, rng: seededRng(5));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateGiftGain();
          expect(gain, inInclusiveRange(1, 2));
        }
      });
    });

    group('calculatePrayerGain', () {
      test('normal difficulty: gain in range [2, 5]', () {
        final calc = FaithCalculatorService(difficulty: Difficulty.normal, rng: seededRng(6));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculatePrayerGain();
          expect(gain, inInclusiveRange(2, 5));
        }
      });

      test('easy difficulty: gain in range [3, 8]', () {
        // base=2 → ceil(3.0)=3; base=5 → ceil(7.5)=8
        final calc = FaithCalculatorService(difficulty: Difficulty.easy, rng: seededRng(7));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculatePrayerGain();
          expect(gain, inInclusiveRange(3, 8));
        }
      });

      test('hard difficulty: gain in range [1, 3]', () {
        // base=2 → ceil(1.0)=1; base=5 → ceil(2.5)=3
        final calc = FaithCalculatorService(difficulty: Difficulty.hard, rng: seededRng(8));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculatePrayerGain();
          expect(gain, inInclusiveRange(1, 3));
        }
      });
    });

    group('calculateDarknessLoss', () {
      test('normal: returns 1', () {
        final calc = FaithCalculatorService(difficulty: Difficulty.normal);
        expect(calc.calculateDarknessLoss(), 1);
      });

      test('easy: returns 1 (reduced influence)', () {
        final calc = FaithCalculatorService(difficulty: Difficulty.easy);
        expect(calc.calculateDarknessLoss(), 1);
      });

      test('hard: returns 2 (double influence)', () {
        final calc = FaithCalculatorService(difficulty: Difficulty.hard);
        expect(calc.calculateDarknessLoss(), 2);
      });
    });

    group('calculateCounselingGain', () {
      test('normal difficulty: gain in range [1, 3]', () {
        final calc = FaithCalculatorService(difficulty: Difficulty.normal, rng: seededRng(10));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateCounselingGain();
          expect(gain, inInclusiveRange(1, 3));
        }
      });

      test('easy difficulty: gain in range [2, 5]', () {
        // base=1 → ceil(1.5)=2; base=3 → ceil(4.5)=5
        final calc = FaithCalculatorService(difficulty: Difficulty.easy, rng: seededRng(11));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateCounselingGain();
          expect(gain, inInclusiveRange(2, 5));
        }
      });

      test('hard difficulty: gain in range [1, 2]', () {
        final calc = FaithCalculatorService(difficulty: Difficulty.hard, rng: seededRng(12));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateCounselingGain();
          expect(gain, inInclusiveRange(1, 2));
        }
      });
    });

    group('calculateBibleReadingPlayerGain', () {
      test('normal difficulty: gain in range [3, 6]', () {
        final calc = FaithCalculatorService(difficulty: Difficulty.normal, rng: seededRng(13));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateBibleReadingPlayerGain();
          expect(gain, inInclusiveRange(3, 6));
        }
      });

      test('easy difficulty: gain in range [5, 9]', () {
        // base=3 → ceil(4.5)=5; base=6 → ceil(9.0)=9
        final calc = FaithCalculatorService(difficulty: Difficulty.easy, rng: seededRng(14));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateBibleReadingPlayerGain();
          expect(gain, inInclusiveRange(5, 9));
        }
      });
    });

    group('calculateBibleReadingNPCGain', () {
      test('normal difficulty: gain in range [1, 3]', () {
        final calc = FaithCalculatorService(difficulty: Difficulty.normal, rng: seededRng(15));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateBibleReadingNPCGain();
          expect(gain, inInclusiveRange(1, 3));
        }
      });
    });

    group('calculateProphecyGain', () {
      test('normal difficulty: gain in range [20, 30]', () {
        final calc = FaithCalculatorService(difficulty: Difficulty.normal, rng: seededRng(16));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateProphecyGain();
          expect(gain, inInclusiveRange(20, 30));
        }
      });

      test('easy difficulty: gain in range [30, 45]', () {
        // base=20 → ceil(30.0)=30; base=30 → ceil(45.0)=45
        final calc = FaithCalculatorService(difficulty: Difficulty.easy, rng: seededRng(17));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateProphecyGain();
          expect(gain, inInclusiveRange(30, 45));
        }
      });

      test('hard difficulty: gain in range [10, 15]', () {
        // base=20 → ceil(10.0)=10; base=30 → ceil(15.0)=15
        final calc = FaithCalculatorService(difficulty: Difficulty.hard, rng: seededRng(18));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateProphecyGain();
          expect(gain, inInclusiveRange(10, 15));
        }
      });
    });

    group('calculateHealingGain', () {
      test('normal difficulty: gain in range [15, 20]', () {
        final calc = FaithCalculatorService(difficulty: Difficulty.normal, rng: seededRng(19));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateHealingGain();
          expect(gain, inInclusiveRange(15, 20));
        }
      });

      test('easy difficulty: gain in range [23, 30]', () {
        // base=15 → ceil(22.5)=23; base=20 → ceil(30.0)=30
        final calc = FaithCalculatorService(difficulty: Difficulty.easy, rng: seededRng(20));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateHealingGain();
          expect(gain, inInclusiveRange(23, 30));
        }
      });

      test('hard difficulty: gain in range [8, 10]', () {
        // base=15 → ceil(7.5)=8; base=20 → ceil(10.0)=10
        final calc = FaithCalculatorService(difficulty: Difficulty.hard, rng: seededRng(21));
        for (int i = 0; i < 100; i++) {
          final gain = calc.calculateHealingGain();
          expect(gain, inInclusiveRange(8, 10));
        }
      });
    });
  });
}
