import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/actions/npc_actions.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_model.dart';
import 'package:spiritual_city/src/features/game/domain/services/npc_interaction_service.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

NPCModel _npc(String id, {double faith = 0}) => NPCModel(
      id: id,
      name: id,
      type: NPCType.citizen,
      homePosition: Vector2.zero(),
      faith: faith,
    );

NpcInteractionResult _run(
  String type,
  NPCModel npc, {
  int seed = 1,
  double faith = 100,
  double health = 100,
  double materials = 100,
  double practice = 1.0,
}) =>
    NpcInteractionService(difficulty: Difficulty.normal, rng: Random(seed)).perform(
      type,
      npc,
      spiritualState: 0,
      playerFaith: faith,
      playerHealth: health,
      playerMaterials: materials,
      practiceMultiplier: practice,
    );

void main() {
  group('NpcInteractionService', () {
    test('💬 uses one session point and counts as a conversation', () {
      final npc = _npc('t');
      final r = _run('talk', npc);
      expect(npc.currentSessionInteractions, 1);
      expect(r.conversationHeld, isTrue);
      expect(r.performed, isTrue);
    });

    test('👂 costs health and two session points', () {
      final npc = _npc('c');
      final r = _run('counsel', npc);
      expect(npc.currentSessionInteractions, 2);
      expect(r.playerHealthDelta, -NpcActions.counselHealthCost(Difficulty.normal));
    });

    test('a refused action gives the session point back', () {
      final npc = _npc('r');
      final r = _run('counsel', npc, health: 5);
      expect(r.reaction, '🚫❤️');
      expect(r.performed, isFalse);
      expect(npc.currentSessionInteractions, 0);

      final h = _run('help', npc..wantsGift = true, materials: 3);
      expect(h.reaction, '🚫📦');
      expect(h.performed, isFalse);
    });

    test('practice makes the same action gain more', () {
      // Same id → same need, so only the practice bonus differs.
      final plain = _npc('p', faith: 10);
      final trained = _npc('p', faith: 10);
      _run('bible', plain, seed: 7);
      _run('bible', trained, seed: 7, practice: 1.5);
      expect(trained.lastNpcFaithDelta, greaterThan(plain.lastNpcFaithDelta));
    });

    test('a known person (relationship) gains more from the same action', () {
      final stranger = _npc('s', faith: 10);
      final friend = _npc('s', faith: 10)..interactionCount = 70; // bonus 4
      _run('bible', stranger, seed: 3);
      _run('bible', friend, seed: 3);
      expect(friend.lastNpcFaithDelta, greaterThan(stranger.lastNpcFaithDelta));
    });

    test('🗣️ with deep trust works two steps per talk', () {
      NPCModel withChallenge(int trust) {
        for (var i = 0; i < 500; i++) {
          final n = _npc('lt_$i')..interactionCount = trust;
          if (n.backstory.currentChallenge != null) return n;
        }
        fail('no NPC with a challenge');
      }

      final stranger = withChallenge(0);
      _run('lifetalk', stranger);
      expect(stranger.backstory.currentChallenge!.workProgress, 1);

      final trusted = withChallenge(30); // session bonus 3
      final before = trusted.backstory.currentChallenge!;
      _run('lifetalk', trusted);
      expect(before.workProgress, 2);
    });

    test('🗣️ costs 5🙏 and 2❤️', () {
      for (var i = 0; i < 500; i++) {
        final n = _npc('lc_$i');
        if (n.backstory.currentChallenge == null) continue;
        final r = _run('lifetalk', n);
        expect(r.playerHealthDelta, -NpcActions.lifeTalkHealthCost);
        expect(r.playerFaithDelta, closeTo(-NpcActions.lifeTalkFaithCost, 1e-9));
        return;
      }
      fail('no NPC with a challenge');
    });

    test('✝️🕊️ converts above score 50, otherwise annoys', () {
      final ready = _npc('cv1', faith: 60);
      final r = _run('convert', ready);
      expect(r.converted, isTrue);
      expect(ready.isConverted, isTrue);
      expect(r.insightDelta, NpcInteractionService.conversionInsightReward);

      final notReady = _npc('cv2', faith: 10);
      final n = _run('convert', notReady);
      expect(n.converted, isFalse);
      expect(notReady.lastNpcFaithDelta, -12.0);
    });
  });
}
