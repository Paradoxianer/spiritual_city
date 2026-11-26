import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/services/daemon_combat_rules.dart';

void main() {
  // Playtest 2026-11-26: three hits in 🌊1 cost about one point of 160.
  test('a hit takes a real share of the pastor, also when weakened', () {
    final full = DaemonCombatRules.strikeShare(strength: 1, amp: 1, might: 1);
    final weak = DaemonCombatRules.strikeShare(strength: 0, amp: 1, might: 1);
    expect(full, closeTo(0.10, 1e-9));
    expect(weak, closeTo(0.05, 1e-9));
    // Easy (0.67) and a small 🐍 (0.8): three hits still cost over a tenth.
    expect(3 * DaemonCombatRules.strikeShare(strength: 0.5, amp: 0.67 * 0.8, might: 1), greaterThan(0.1));
    // Late waves hurt more, but one hit never takes more than about a third.
    expect(DaemonCombatRules.strikeShare(strength: 1, amp: 2.8, might: 5), 0.35);
  });
}
