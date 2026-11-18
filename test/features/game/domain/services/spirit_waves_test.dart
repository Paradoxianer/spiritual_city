import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/daemon_kind.dart';
import 'package:spiritual_city/src/features/game/domain/services/combat_abilities.dart';
import 'package:spiritual_city/src/features/game/domain/services/spirit_waves.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

// Playtest 2026-11-15: waves readable like missions, the first very easy,
// later harder – and the breakthrough grows without a cap.
void main() {
  test('the first wave is small, one kind and weak', () {
    final w = SpiritWaves()..start(Difficulty.normal, Random(1));
    expect(w.wave, 1);
    expect(w.current, hasLength(3));
    expect(w.current.toSet(), {DaemonKind.brute});
    expect(SpiritWaves.energy(1), lessThan(0.5));
  });

  test('the preview is the wave that comes next', () {
    final w = SpiritWaves()..start(Difficulty.easy, Random(2));
    final preview = w.next;
    w.cleared(Difficulty.easy, Random(3));
    expect(w.wave, 2);
    expect(w.current, preview);
    expect(w.pause, SpiritWaves.pauseSeconds);
  });

  test('later waves are bigger, stronger and mixed', () {
    final plan = SpiritWaves.plan(5, Difficulty.normal, Random(4));
    expect(plan, hasLength(7));
    expect(plan.toSet(), SpiritWaves.joining.toSet());
    expect(SpiritWaves.energy(5), closeTo(1.0, 1e-9));
    expect(SpiritWaves.energy(9), greaterThan(SpiritWaves.energy(5)));
  });

  test('the breakthrough grows without a cap', () {
    expect(SpiritWaves.breakthroughCells(20), greaterThan(SpiritWaves.breakthroughCells(10)));
    expect(SpiritWaves.breakthroughStrength(20), greaterThan(SpiritWaves.breakthroughStrength(10)));
    expect(SpiritWaves.openness(20), greaterThan(SpiritWaves.openness(10)));
  });

  test('every beaten wave gives more wisdom, without a cap', () {
    expect(SpiritWaves.insight(1), 0.25);
    expect(SpiritWaves.insight(9), 2.25);
    expect(SpiritWaves.insight(30), greaterThan(SpiritWaves.insight(20)));
  });

  test('🪫 tires within a visit, down to 40 %', () {
    expect(CombatAbilities.drainFatigue(0), 1.0);
    expect(CombatAbilities.drainFatigue(10), closeTo(0.6, 0.01));
    expect(CombatAbilities.drainFatigue(100), 0.4);
  });
}
