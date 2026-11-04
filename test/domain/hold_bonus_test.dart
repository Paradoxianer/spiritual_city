import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/modifier_manager.dart';

void main() {
  test('praying longer grows the prayer, up to a limit', () {
    expect(ModifierManager.holdBonus(0), 1.0);
    expect(ModifierManager.holdBonus(5), closeTo(2.0, 1e-9));
    expect(ModifierManager.holdBonus(60), ModifierManager.maxHoldBonus);
    expect(ModifierManager.maxHoldBonus, closeTo(5.0, 1e-9));
  });
}
