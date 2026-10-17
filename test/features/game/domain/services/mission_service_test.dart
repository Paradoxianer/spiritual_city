import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/building_model.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/mission_model.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_model.dart';
import 'package:spiritual_city/src/features/game/domain/services/mission_service.dart';

NPCModel _npc(String id, {bool isConverted = false}) => NPCModel(
      id: id,
      name: id,
      type: NPCType.citizen,
      homePosition: Vector2.zero(),
      isConverted: isConverted,
    );

BuildingModel _house(String id) => BuildingModel(
      buildingId: id,
      type: BuildingType.house,
    );

void main() {
  group('MissionService.assignStartMissions (Issue #175)', () {
    test('assigns up to 4 missions when nothing is active yet', () {
      final service = MissionService(seed: 1);
      final npcs = List.generate(6, (i) => _npc('npc$i'));
      final buildings = List.generate(3, (i) => _house('house$i'));

      service.assignStartMissions(npcs, buildings);

      final activeCount = npcs.where((n) => n.activeMission != null).length +
          buildings.where((b) => b.activeMission != null).length;
      expect(activeCount, 4);
    });

    test('is idempotent: calling it again after a save/load does not add '
        'more missions or touch existing ones', () {
      final service = MissionService(seed: 2);
      final npcs = List.generate(6, (i) => _npc('npc$i'));
      final buildings = List.generate(3, (i) => _house('house$i'));

      service.assignStartMissions(npcs, buildings);
      final assignedIds = {
        for (final n in npcs)
          if (n.activeMission != null) n.id: n.activeMission!.id,
        for (final b in buildings)
          if (b.activeMission != null) b.id: b.activeMission!.id,
      };
      expect(assignedIds.length, 4);

      // Simulate re-entering onLoad() after a save/load cycle: the exact
      // same NPC/building instances (as if restored) are passed in again.
      service.assignStartMissions(npcs, buildings);

      final activeCount = npcs.where((n) => n.activeMission != null).length +
          buildings.where((b) => b.activeMission != null).length;
      expect(activeCount, 4, reason: 'must not grow beyond the target count');

      final idsAfterReload = {
        for (final n in npcs)
          if (n.activeMission != null) n.id: n.activeMission!.id,
        for (final b in buildings)
          if (b.activeMission != null) b.id: b.activeMission!.id,
      };
      expect(idsAfterReload, assignedIds,
          reason: 'existing missions/progress must not be overwritten');
    });

    test('tops up to the target when fewer missions are active than the '
        'target (e.g. a partially-restored save)', () {
      final service = MissionService(seed: 3);
      final npcs = List.generate(6, (i) => _npc('npc$i'));
      final buildings = List.generate(3, (i) => _house('house$i'));

      // Pretend one mission already survived a save/load.
      npcs.first.activeMission = MissionModel(
        id: 'restored',
        actionType: ActionType.npcConversation,
        description: 'restored mission',
        targetCount: 3,
        rewardFaith: 10,
        insightReward: 1,
      );

      service.assignStartMissions(npcs, buildings);

      final activeCount = npcs.where((n) => n.activeMission != null).length +
          buildings.where((b) => b.activeMission != null).length;
      expect(activeCount, 4);
      expect(npcs.first.activeMission!.id, 'restored',
          reason: 'the restored mission itself must be left untouched');
    });
  });

  group('MissionService gospel-share eligibility (Issue #163)', () {
    test('never assigns the gospel-share mission to an already-converted '
        'NPC, across many seeds', () {
      for (int seed = 0; seed < 30; seed++) {
        final service = MissionService(seed: seed);
        final npcs = List.generate(4, (i) => _npc('npc$i', isConverted: true));

        service.assignStartMissions(npcs, const []);

        for (final npc in npcs) {
          expect(
            npc.activeMission?.actionType,
            isNot(ActionType.npcGospelShare),
            reason: 'seed=$seed assigned gospel-share to a converted NPC',
          );
        }
      }
    });

    test('can still assign the gospel-share mission to a non-converted NPC',
        () {
      // With only NPC targets and enough attempts across seeds, the
      // large-difficulty gospel-share template must be reachable at all.
      var sawGospelShare = false;
      for (int seed = 0; seed < 30 && !sawGospelShare; seed++) {
        final service = MissionService(seed: seed);
        final npcs = List.generate(4, (i) => _npc('npc$i'));
        service.assignStartMissions(npcs, const []);
        sawGospelShare = npcs.any(
          (n) => n.activeMission?.actionType == ActionType.npcGospelShare,
        );
      }
      expect(sawGospelShare, isTrue);
    });
  });
}
