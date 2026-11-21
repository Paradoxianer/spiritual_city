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
    expect(w.current, hasLength(2));
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
    expect(plan, hasLength(6));
    expect(plan.toSet(), SpiritWaves.joining.toSet());
    expect(SpiritWaves.size(9, Difficulty.normal), 18);
    expect(SpiritWaves.energy(9), greaterThan(2.4));
  });

  test('waves grow ever steeper (playtest 2026-11-18)', () {
    int step(int w) => SpiritWaves.size(w + 1, Difficulty.normal) - SpiritWaves.size(w, Difficulty.normal);
    expect(step(10), greaterThan(step(4)));
    expect(SpiritWaves.energy(10) - SpiritWaves.energy(9),
        greaterThan(SpiritWaves.energy(3) - SpiritWaves.energy(2)));
  });

  test('the breakthrough grows without a cap', () {
    expect(SpiritWaves.breakthroughCells(20), greaterThan(SpiritWaves.breakthroughCells(10)));
    expect(SpiritWaves.breakthroughStrength(20), greaterThan(SpiritWaves.breakthroughStrength(10)));
    expect(SpiritWaves.openness(20), greaterThan(SpiritWaves.openness(10)));
  });

  test('every beaten wave gives more wisdom, without a cap', () {
    expect(SpiritWaves.insight(1), closeTo(0.7, 1e-9));
    expect(SpiritWaves.insight(9), closeTo(18.9, 1e-9));
    expect(SpiritWaves.insight(30), greaterThan(SpiritWaves.insight(20)));
  });

  test('🪫 tires within a visit, down to 5 %, and costs 🍞', () {
    expect(CombatAbilities.drainFatigue(0), 1.0);
    expect(CombatAbilities.drainFatigue(5), closeTo(0.44, 0.01));
    expect(CombatAbilities.drainFatigue(100), 0.05);
    expect(CombatAbilities.drainHunger, greaterThan(0));
  });

  // Playtest 2026-11-21: draining stayed endless while starving.
  test('🪫 draws nothing on an empty stomach, starving hurts', () {
    expect(CombatAbilities.drainFed(CombatAbilities.drainHunger), isTrue);
    expect(CombatAbilities.drainFed(2), isFalse);
    expect(160 / CombatAbilities.starveHealthPerSecond, lessThan(6 * 60));
  });

  // Playtest 2026-11-20: high waves strike far harder, look darker, and
  // calling one early costs.
  test('later waves strike harder and look darker', () {
    expect(SpiritWaves.might(1), 1.0);
    expect(SpiritWaves.might(9), closeTo(3.06, 0.01));
    expect(SpiritWaves.might(12), greaterThan(4.5));
    expect(SpiritWaves.darkness(1), 0.0);
    expect(SpiritWaves.darkness(12), 1.0);
    expect(SpiritWaves.darkness(40), 1.0);
    expect(SpiritWaves.callCost(10), greaterThan(SpiritWaves.callCost(2)));
  });
}
