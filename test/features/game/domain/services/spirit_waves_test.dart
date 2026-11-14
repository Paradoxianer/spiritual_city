import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/discipleship.dart';
import 'package:spiritual_city/src/features/game/domain/models/quarter.dart';
import 'package:spiritual_city/src/features/game/domain/services/spirit_waves.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

void main() {
  group('🌊 waves (playtest 2026-11-14)', () {
    test('each wave is bigger and stronger than the one before', () {
      for (final d in Difficulty.values) {
        expect(SpiritWaves.size(2, d), greaterThan(SpiritWaves.size(1, d)));
      }
      expect(SpiritWaves.size(1, Difficulty.easy), lessThan(SpiritWaves.size(1, Difficulty.hard)));
      expect(SpiritWaves.energy(1), 1.0);
      expect(SpiritWaves.energy(3), greaterThan(SpiritWaves.energy(2)));
    });

    test('the breakthrough grows the longer you hold out – up to about a neighbourhood', () {
      expect(SpiritWaves.breakthroughCells(2), greaterThan(SpiritWaves.breakthroughCells(1)));
      expect(SpiritWaves.breakthroughStrength(2), greaterThan(SpiritWaves.breakthroughStrength(1)));
      expect(SpiritWaves.openness(2), greaterThan(SpiritWaves.openness(1)));
      expect(SpiritWaves.breakthroughCells(100), Quarter.sizeCells ~/ 2);
      expect(SpiritWaves.breakthroughStrength(100), 100);
    });

    test('wave 1 is one kind, wave 2 two, then all three', () {
      final rng = Random(1);
      expect(SpiritWaves.kindsFor(1, rng).length, 1);
      expect(SpiritWaves.kindsFor(2, rng).toSet().length, 2);
      expect(SpiritWaves.kindsFor(5, rng).toSet().length, 3);
    });

    test('a beaten wave gives a breath, then the next; entering starts at 🌊1', () {
      final rng = Random(2);
      final w = SpiritWaves()..start(rng);
      expect(w.wave, 1);
      w.spawned = SpiritWaves.size(1, Difficulty.normal);
      expect(w.spawnedAll(Difficulty.normal), isTrue);
      w.cleared(rng);
      expect(w.wave, 2);
      expect(w.spawned, 0);
      expect(w.pause, SpiritWaves.pauseSeconds);
      w.start(rng);
      expect(w.wave, 1);
      expect(w.pause, 0);
    });
  });

  test('a cared-for disciple is hardly shaken by daemons', () {
    expect(Discipleship.daemonTouchLoss(0), Discipleship.daemonTouchFaith);
    expect(Discipleship.daemonTouchLoss(0.9), closeTo(Discipleship.daemonTouchFaith / 10, 1e-9));
    expect(Discipleship.daemonTouchLoss(0.45), lessThan(Discipleship.daemonTouchLoss(0.1)));
  });
}
