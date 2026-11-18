import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/services/combat_abilities.dart';

// Playtest 2026-11-18: a row of ten stars ran out of the window on a phone.
void main() {
  test('few stars stay a row, many become ⭐×n', () {
    expect(CombatAbilities.stars(3), '⭐⭐⭐');
    expect(CombatAbilities.stars(10), '⭐×10');
  });
}
