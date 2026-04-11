import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_model.dart';
import 'package:spiritual_city/src/features/game/domain/services/routine_scheduler.dart';

NPCModel _makeNPC({
  double faith = 0.0,
  NPCPersonality personality = NPCPersonality.friendly,
  Vector2? workLocation,
}) {
  return NPCModel(
    id: 'test_npc',
    name: 'Test Person',
    type: NPCType.citizen,
    homePosition: Vector2.zero(),
    faith: faith,
    personality: personality,
    workLocation: workLocation,
  );
}

void main() {
  const scheduler = RoutineScheduler();

  group('RoutineScheduler.getScheduledRoutine', () {
    test('returns a non-null, valid routine identifier', () {
      final npc = _makeNPC();
      final routine = scheduler.getScheduledRoutine(npc);
      expect(
        ['sleep', 'home', 'work', 'wander', 'church'],
        contains(routine),
      );
    });

    test('unemployed NPC never returns "work"', () {
      // NPC with no workLocation should get 'wander' instead of 'work'
      final npc = _makeNPC(workLocation: null);
      // Run many samples to cover stochastic paths; all must be non-'work'
      for (int i = 0; i < 50; i++) {
        final r = scheduler.getScheduledRoutine(npc);
        expect(r, isNot(equals('work')),
            reason: 'Unemployed NPC should never get "work" routine');
      }
    });

    test('employed NPC can return "work" during daytime hours', () {
      // We can only verify the return is valid; actual "work" depends on
      // DateTime.now() which we cannot stub without a time provider.
      final npc = _makeNPC(workLocation: Vector2(100, 100));
      final r = scheduler.getScheduledRoutine(npc);
      expect(
        ['sleep', 'home', 'work', 'wander', 'church'],
        contains(r),
      );
    });
  });

  group('RoutineScheduler.getRoutineTarget', () {
    test('"home" returns homePosition clone', () {
      final homePos = Vector2(42, 84);
      final npc = NPCModel(
        id: 'x',
        name: 'X',
        type: NPCType.citizen,
        homePosition: homePos,
      );
      final target = scheduler.getRoutineTarget(npc, 'home');
      expect(target, isNotNull);
      expect(target!.x, closeTo(42, 0.001));
      expect(target.y, closeTo(84, 0.001));
    });

    test('"work" returns workLocation when assigned', () {
      final workPos = Vector2(200, 300);
      final npc = _makeNPC(workLocation: workPos);
      final target = scheduler.getRoutineTarget(npc, 'work');
      expect(target, isNotNull);
      expect(target!.x, closeTo(200, 0.001));
    });

    test('"work" returns null when no workLocation', () {
      final npc = _makeNPC(workLocation: null);
      final target = scheduler.getRoutineTarget(npc, 'work');
      expect(target, isNull);
    });

    test('"sleep" always returns null', () {
      final npc = _makeNPC();
      expect(scheduler.getRoutineTarget(npc, 'sleep'), isNull);
    });

    test('"church" falls back to homePosition when no church POI set', () {
      final homePos = Vector2(10, 20);
      final npc = NPCModel(
        id: 'y',
        name: 'Y',
        type: NPCType.citizen,
        homePosition: homePos,
      );
      final target = scheduler.getRoutineTarget(npc, 'church');
      expect(target, isNotNull);
      // Fallback is homePosition
      expect(target!.x, closeTo(10, 0.001));
    });

    test('"wander" falls back to homePosition', () {
      final homePos = Vector2(55, 77);
      final npc = NPCModel(
        id: 'z',
        name: 'Z',
        type: NPCType.citizen,
        homePosition: homePos,
      );
      final target = scheduler.getRoutineTarget(npc, 'wander');
      expect(target, isNotNull);
      expect(target!.x, closeTo(55, 0.001));
    });
  });
}
