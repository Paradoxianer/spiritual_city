import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_model.dart';
import 'package:spiritual_city/src/features/game/domain/services/interaction_variance_service.dart';

NPCModel _npcWithNeed(NpcNeed target) {
  for (int i = 0; i < 500; i++) {
    final npc = NPCModel(
      id: 'npc_building_$i',
      name: 'npc_building_$i',
      type: NPCType.citizen,
      homePosition: Vector2.zero(),
    );
    if (npc.need == target) return npc;
  }
  fail('No NPC with need $target found in the scanned id range');
}

void main() {
  group('InteractionVarianceService.repeatFactorFor', () {
    test('1st use = 1.0x, 2nd = 0.6x, 3rd+ = 0.35x', () {
      expect(InteractionVarianceService.repeatFactorFor(0), 1.0);
      expect(InteractionVarianceService.repeatFactorFor(1), 0.6);
      expect(InteractionVarianceService.repeatFactorFor(2), 0.35);
      expect(InteractionVarianceService.repeatFactorFor(3), 0.35);
      expect(InteractionVarianceService.repeatFactorFor(50), 0.35);
    });
  });

  group('InteractionVarianceService.multiplierFor', () {
    test('first-ever action on an NPC gets no variance bonus (nothing to '
        'switch away from) but the full repeat and need factors', () {
      final npc = _npcWithNeed(NpcNeed.seeking); // bible = strong
      final mult = InteractionVarianceService.multiplierFor(npc, 'bible');
      expect(mult, 1.0 * 1.0 * InteractionVarianceService.needStrongMultiplier);
    });

    test('repeating the same action drops the multiplier via repeat decay',
        () {
      final npc = _npcWithNeed(NpcNeed.seeking);
      npc.recordAction('bible'); // 1st use recorded
      final mult = InteractionVarianceService.multiplierFor(npc, 'bible');
      expect(
        mult,
        InteractionVarianceService.repeatFactorSecondUse *
            1.0 * // same as last action -> no variance bonus
            InteractionVarianceService.needStrongMultiplier,
      );
    });

    test('switching action type grants the variance bonus', () {
      final npc = _npcWithNeed(NpcNeed.seeking);
      npc.recordAction('talk');
      final mult = InteractionVarianceService.multiplierFor(npc, 'bible');
      expect(
        mult,
        1.0 * // first use of 'bible' specifically
            InteractionVarianceService.varianceBonus *
            InteractionVarianceService.needStrongMultiplier,
      );
    });

    test('an action that does not match the NPC need is weak', () {
      final npc = _npcWithNeed(NpcNeed.lonely); // only 'talk' is strong
      final mult = InteractionVarianceService.multiplierFor(npc, 'bible');
      expect(mult, 1.0 * 1.0 * InteractionVarianceService.needWeakMultiplier);
    });
  });

  group('Acceptance: 5x the same action is measurably worse than a mixed '
      'rotation (Issue #171)', () {
    test('5x bible on a non-seeking NPC scores lower than a 5-action mix '
        'including the NPC\'s actual need', () {
      // An NPC whose need is NOT bible, so pure bible-spam gets the weak
      // need multiplier on top of the repeat decay – the worst case for the
      // old "always read the Bible" strategy.
      final npc = _npcWithNeed(NpcNeed.doubting); // counsel = strong

      // Need is derived from the id, so comparing two strategies means
      // running each sequence against the *same* `npc`, resetting its
      // session in between so both start from the same fresh state.
      double totalMultiplierOverFiveUses(List<String> actions) {
        double total = 0;
        for (final action in actions) {
          total += InteractionVarianceService.multiplierFor(npc, action);
          npc.recordAction(action);
        }
        return total;
      }

      npc.resetSession();
      final bibleSpamTotal =
          totalMultiplierOverFiveUses(List.filled(5, 'bible'));

      npc.resetSession();
      final mixedRotationTotal = totalMultiplierOverFiveUses(
        ['talk', 'counsel', 'bible', 'help', 'counsel'],
      );

      expect(bibleSpamTotal, lessThan(mixedRotationTotal));
    });
  });
}
