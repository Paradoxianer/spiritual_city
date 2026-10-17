import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/core/utils/seed_manager.dart';

void main() {
  group('SeedManager.resolveWorldSeed', () {
    test('a stored worldSeed always wins', () {
      expect(
        SeedManager.resolveWorldSeed(
          savedWorldSeed: 1234,
          hasSavedProgress: true,
          saveSeed: 99,
        ),
        1234,
      );
    });

    test('legacy save with progress but no worldSeed keeps world 42', () {
      expect(
        SeedManager.resolveWorldSeed(
          hasSavedProgress: true,
          saveSeed: 555, // random seed the old menu stored but never used
        ),
        SeedManager.legacyWorldSeed,
      );
    });

    test('brand-new save uses the seed chosen in the menu', () {
      expect(
        SeedManager.resolveWorldSeed(hasSavedProgress: false, saveSeed: 777),
        777,
      );
    });

    test('brand-new save without a seed falls back to the legacy seed', () {
      expect(
        SeedManager.resolveWorldSeed(hasSavedProgress: false),
        SeedManager.legacyWorldSeed,
      );
    });
  });

  group('SeedManager', () {
    test('same seed yields the same random sequence', () {
      final a = SeedManager(7).nextRandom().nextInt(1 << 30);
      final b = SeedManager(7).nextRandom().nextInt(1 << 30);
      expect(a, b);
    });

    test('different seeds yield different random sequences', () {
      final a = SeedManager(7).nextRandom().nextInt(1 << 30);
      final b = SeedManager(8).nextRandom().nextInt(1 << 30);
      expect(a, isNot(b));
    });
  });
}
