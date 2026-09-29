import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_model.dart';

NPCModel _npc(String id) => NPCModel(
      id: id,
      name: id,
      type: NPCType.citizen,
      homePosition: Vector2.zero(),
    );

void main() {
  group('NPCModel.need (Issue #171)', () {
    test('is deterministic: the same id always yields the same need', () {
      final a = _npc('npc_house_1_0').need;
      final b = _npc('npc_house_1_0').need;
      expect(a, b);
    });

    test('survives being derived again after a fresh NPCModel instance '
        '(simulates the NPC being regenerated from the same seed after a '
        'save/load, since need is never persisted)', () {
      final first = _npc('npc_church_3_2');
      final need = first.need;
      final regenerated = _npc('npc_church_3_2');
      expect(regenerated.need, need);
    });

    test('different ids can yield different needs (sanity: not a constant)',
        () {
      final needs = {
        for (int i = 0; i < 200; i++) _npc('npc_building_$i').need,
      };
      expect(needs.length, greaterThan(1),
          reason: '200 different NPC ids all landed on the same need – '
              'the hash is not spreading at all');
    });

    test('all four needs are reachable across a reasonably large id set',
        () {
      final needs = {
        for (int i = 0; i < 500; i++) _npc('npc_building_$i').need,
      };
      expect(needs, NpcNeed.values.toSet());
    });
  });

  group('NPCModel.needMatchesAction', () {
    test('lonely NPCs need talk, nothing else', () {
      final lonely = _findNpcWith(NpcNeed.lonely);
      expect(lonely.needMatchesAction('talk'), isTrue);
      for (final other in ['counsel', 'bible', 'pray', 'help']) {
        expect(lonely.needMatchesAction(other), isFalse, reason: other);
      }
    });

    test('doubting NPCs need counsel, nothing else', () {
      final doubting = _findNpcWith(NpcNeed.doubting);
      expect(doubting.needMatchesAction('counsel'), isTrue);
      for (final other in ['talk', 'bible', 'pray', 'help']) {
        expect(doubting.needMatchesAction(other), isFalse, reason: other);
      }
    });

    test('seeking NPCs need bible, nothing else', () {
      final seeking = _findNpcWith(NpcNeed.seeking);
      expect(seeking.needMatchesAction('bible'), isTrue);
      for (final other in ['talk', 'counsel', 'pray', 'help']) {
        expect(seeking.needMatchesAction(other), isFalse, reason: other);
      }
    });

    test('needy NPCs need pray OR help, nothing else', () {
      final needy = _findNpcWith(NpcNeed.needy);
      expect(needy.needMatchesAction('pray'), isTrue);
      expect(needy.needMatchesAction('help'), isTrue);
      for (final other in ['talk', 'counsel', 'bible']) {
        expect(needy.needMatchesAction(other), isFalse, reason: other);
      }
    });
  });

  group('NPCModel session action tracking (Issue #171)', () {
    test('sessionCountFor starts at 0 and increments per recordAction call',
        () {
      final npc = _npc('id');
      expect(npc.sessionCountFor('bible'), 0);
      npc.recordAction('bible');
      expect(npc.sessionCountFor('bible'), 1);
      npc.recordAction('bible');
      expect(npc.sessionCountFor('bible'), 2);
      // A different action type is tracked independently.
      expect(npc.sessionCountFor('talk'), 0);
    });

    test('recordAction updates lastActionType', () {
      final npc = _npc('id');
      expect(npc.lastActionType, isNull);
      npc.recordAction('pray');
      expect(npc.lastActionType, 'pray');
      npc.recordAction('help');
      expect(npc.lastActionType, 'help');
    });

    test('resetSession clears both the counts and lastActionType', () {
      final npc = _npc('id');
      npc.recordAction('bible');
      npc.recordAction('bible');
      npc.resetSession();
      expect(npc.sessionCountFor('bible'), 0);
      expect(npc.lastActionType, isNull);
    });
  });
}

/// Finds (and returns) an [NPCModel] whose deterministic [NPCModel.need]
/// equals [target], by scanning a bounded range of synthetic ids.  The
/// "all four needs reachable" test above guarantees this terminates well
/// within the scanned range.
NPCModel _findNpcWith(NpcNeed target) {
  for (int i = 0; i < 500; i++) {
    final npc = _npc('npc_building_$i');
    if (npc.need == target) return npc;
  }
  fail('No NPC with need $target found in the scanned id range');
}
