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

  // ── LootSystem save / restore ─────────────────────────────────────────────

  group('LootSystem state save/restore', () {
    LootSystem makeLootSystem() => LootSystem(seed: 42);

    test('captureState returns empty list when no pickups exist', () {
      final ls = makeLootSystem();
      expect(ls.captureState(), isEmpty);
    });

    test('round-trip: restoreState → captureState preserves position, type, and flags', () {
      final ls = makeLootSystem();

      final saved = [
        {'x': 100.0, 'y': 200.0, 'type': LootType.small.index,  'isPickedUp': false, 'respawnTimer': -1.0},
        {'x': 300.0, 'y': 400.0, 'type': LootType.normal.index, 'isPickedUp': true,  'respawnTimer': 120.5},
        {'x': 500.0, 'y': 600.0, 'type': LootType.large.index,  'isPickedUp': false, 'respawnTimer': -1.0},
      ];

      ls.restoreState(saved);
      final captured = ls.captureState();

      expect(captured.length, 3);

      expect(captured[0]['x'],            100.0);
      expect(captured[0]['y'],            200.0);
      expect(captured[0]['type'],         LootType.small.index);
      expect(captured[0]['isPickedUp'],   false);

      expect(captured[1]['x'],            300.0);
      expect(captured[1]['y'],            400.0);
      expect(captured[1]['type'],         LootType.normal.index);
      expect(captured[1]['isPickedUp'],   true);
      expect(captured[1]['respawnTimer'], closeTo(120.5, 0.001));

      expect(captured[2]['type'], LootType.large.index);
    });

    test('restoreState clears previous pickups', () {
      final ls = makeLootSystem();

      ls.restoreState([
        {'x': 1.0, 'y': 2.0, 'type': LootType.small.index, 'isPickedUp': false, 'respawnTimer': -1.0},
        {'x': 3.0, 'y': 4.0, 'type': LootType.large.index, 'isPickedUp': false, 'respawnTimer': -1.0},
      ]);
      expect(ls.captureState().length, 2);

      // Second restore with a single item – old entries must be gone.
      ls.restoreState([
        {'x': 9.0, 'y': 8.0, 'type': LootType.normal.index, 'isPickedUp': false, 'respawnTimer': -1.0},
      ]);
      final captured = ls.captureState();
      expect(captured.length, 1);
      expect(captured[0]['x'], 9.0);
    });

    test('restoreState with empty list results in empty captureState', () {
      final ls = makeLootSystem();
      ls.restoreState([]);
      expect(ls.captureState(), isEmpty);
    });
  });
}
