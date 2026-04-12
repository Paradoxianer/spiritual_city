import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/building_model.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_model.dart';
import 'package:spiritual_city/src/features/game/domain/services/building_interaction_service.dart';

void main() {
  // ── BuildingModel tests ──────────────────────────────────────────────────

  group('BuildingModel', () {
    group('category', () {
      test('house and apartment are residential', () {
        expect(
          BuildingModel(buildingId: 'h1', type: BuildingType.house).category,
          BuildingCategory.residential,
        );
        expect(
          BuildingModel(buildingId: 'a1', type: BuildingType.apartment).category,
          BuildingCategory.residential,
        );
      });

      test('shop, office, skyscraper are commercial', () {
        for (final t in [
          BuildingType.shop,
          BuildingType.office,
          BuildingType.skyscraper,
          BuildingType.factory,
          BuildingType.warehouse,
        ]) {
          expect(
            BuildingModel(buildingId: 'b', type: t).category,
            BuildingCategory.commercial,
          );
        }
      });

      test('church and cathedral are church category', () {
        for (final t in [BuildingType.church, BuildingType.cathedral]) {
          expect(
            BuildingModel(buildingId: 'c', type: t).category,
            BuildingCategory.church,
          );
        }
      });

      test('other types fall into other category', () {
        expect(
          BuildingModel(buildingId: 'x', type: BuildingType.hospital).category,
          BuildingCategory.other,
        );
      });
    });

    group('isAlwaysOpen', () {
      test('residential buildings are NOT always open', () {
        final m = BuildingModel(buildingId: 'h', type: BuildingType.house);
        expect(m.isAlwaysOpen, isFalse);
      });

      test('commercial buildings are always open', () {
        final m = BuildingModel(buildingId: 's', type: BuildingType.shop);
        expect(m.isAlwaysOpen, isTrue);
      });

      test('church buildings are always open', () {
        final m = BuildingModel(buildingId: 'c', type: BuildingType.church);
        expect(m.isAlwaysOpen, isTrue);
      });
    });

    group('accessChance', () {
      late BuildingModel house;
      setUp(() => house = BuildingModel(buildingId: 'h', type: BuildingType.house));

      test('always 1.0 for non-residential', () {
        final shop = BuildingModel(buildingId: 's', type: BuildingType.shop);
        expect(shop.accessChance(0), 1.0);
        expect(shop.accessChance(-100), 1.0);
      });

      test('faith > 30 → 0.85', () {
        expect(house.accessChance(31), 0.85);
        expect(house.accessChance(100), 0.85);
      });

      test('faith -30..+30 → 0.50', () {
        expect(house.accessChance(0), 0.50);
        expect(house.accessChance(30), 0.50);
        expect(house.accessChance(-30), 0.50);
      });

      test('faith < -30 → 0.15', () {
        expect(house.accessChance(-31), 0.15);
        expect(house.accessChance(-100), 0.15);
      });

      test('+30 % bonus after 3+ conversations, capped at 1.0', () {
        house.totalConversations = 3;
        // 0.85 + 0.30 = 1.0 (capped)
        expect(house.accessChance(100), 1.0);
        // 0.50 + 0.30 = 0.80
        expect(house.accessChance(0), 0.80);
        // 0.15 + 0.30 = 0.45
        expect(house.accessChance(-100), 0.45);
      });

      test('bonus does NOT apply before 3 conversations', () {
        house.totalConversations = 2;
        expect(house.accessChance(0), 0.50);
      });
    });

    group('influenceResidents', () {
      test('applies faith delta to all residents', () {
        final npc1 = NPCModel(
          id: 'n1', name: 'Alice', type: NPCType.citizen,
          homePosition: Vector2.zero(), faith: 10.0,
        );
        final npc2 = NPCModel(
          id: 'n2', name: 'Bob', type: NPCType.citizen,
          homePosition: Vector2.zero(), faith: -20.0,
        );
        final building = BuildingModel(
          buildingId: 'h', type: BuildingType.house,
          residents: [npc1, npc2],
        );

        building.influenceResidents(5.0);

        expect(npc1.faith, closeTo(15.0, 0.001));
        expect(npc2.faith, closeTo(-15.0, 0.001));
      });

      test('clamps at ±100', () {
        final npc = NPCModel(
          id: 'n', name: 'Eve', type: NPCType.citizen,
          homePosition: Vector2.zero(), faith: 98.0,
        );
        final building = BuildingModel(
          buildingId: 'h', type: BuildingType.house, residents: [npc],
        );
        building.influenceResidents(10.0);
        expect(npc.faith, 100.0);
      });
    });
  });

  // ── BuildingInteractionService tests ─────────────────────────────────────

  group('BuildingInteractionService', () {
    BuildingModel residential() =>
        BuildingModel(buildingId: 'h', type: BuildingType.house);

    BuildingModel commercial() =>
        BuildingModel(buildingId: 's', type: BuildingType.shop);

    BuildingModel church() =>
        BuildingModel(buildingId: 'c', type: BuildingType.church);

    group('attemptAccess', () {
      test('always succeeds for commercial buildings', () {
        final svc = BuildingInteractionService(rng: Random(0));
        expect(svc.attemptAccess(commercial(), -100), isTrue);
      });

      test('always succeeds for church buildings', () {
        final svc = BuildingInteractionService(rng: Random(0));
        expect(svc.attemptAccess(church(), -100), isTrue);
      });

      test('residential: high faith → mostly granted', () {
        // With faith=100 (85 % chance) over 100 trials, at least 70 should pass.
        int successes = 0;
        for (int i = 0; i < 100; i++) {
          final svc = BuildingInteractionService(rng: Random(i));
          if (svc.attemptAccess(residential(), 100.0)) successes++;
        }
        expect(successes, greaterThan(70));
      });

      test('residential: very negative faith → mostly denied', () {
        // With faith=-100 (15 % chance) most attempts should fail.
        int successes = 0;
        for (int i = 0; i < 100; i++) {
          final svc = BuildingInteractionService(rng: Random(i));
          if (svc.attemptAccess(residential(), -100.0)) successes++;
        }
        expect(successes, lessThan(35));
      });
    });

    group('performAction – residential', () {
      test('talk: +5 faith, increments resident conversationCount', () {
        final npc = NPCModel(
          id: 'n1', name: 'Maria', type: NPCType.citizen,
          homePosition: Vector2.zero(), faith: 0.0,
        );
        final b = BuildingModel(
          buildingId: 'h', type: BuildingType.house, residents: [npc],
        );
        final svc = BuildingInteractionService();
        final result = svc.performAction('talk', b, 0.0);
        expect(result.playerFaithDelta, 5.0);
        expect(npc.conversationCount, 1);
        expect(result.success, isTrue);
      });

      test('pray: +15 faith, +5 materials, residents influenced', () {
        final npc = NPCModel(
          id: 'n', name: 'X', type: NPCType.citizen,
          homePosition: Vector2.zero(), faith: 0.0,
        );
        final b = BuildingModel(
          buildingId: 'h', type: BuildingType.house, residents: [npc],
        );
        final svc = BuildingInteractionService();
        final result = svc.performAction('pray', b, 0.0);
        expect(result.playerFaithDelta, 15.0);
        expect(result.playerMaterialsDelta, 5.0);
        expect(npc.faith, greaterThan(0));
      });

      test('help: -10 materials, +10 faith, NPC faith +5', () {
        final npc = NPCModel(
          id: 'n', name: 'X', type: NPCType.citizen,
          homePosition: Vector2.zero(), faith: 0.0,
        );
        final b = BuildingModel(
          buildingId: 'h', type: BuildingType.house, residents: [npc],
        );
        final svc = BuildingInteractionService();
        final result = svc.performAction('help', b, 0.0);
        expect(result.playerFaithDelta, 10.0);
        expect(result.playerMaterialsDelta, -10.0);
        expect(npc.faith, 5.0);
      });

      test('bible: +10 faith, family faith +2', () {
        final npc = NPCModel(
          id: 'n', name: 'X', type: NPCType.citizen,
          homePosition: Vector2.zero(), faith: 0.0,
        );
        final b = BuildingModel(
          buildingId: 'h', type: BuildingType.house, residents: [npc],
        );
        final svc = BuildingInteractionService();
        final result = svc.performAction('bible', b, 0.0);
        expect(result.playerFaithDelta, 10.0);
        expect(npc.faith, 2.0);
      });

      test('totalConversations incremented on every action', () {
        final b = residential();
        final svc = BuildingInteractionService();
        svc.performAction('talk', b, 0.0);
        svc.performAction('pray', b, 0.0);
        expect(b.totalConversations, 2);
      });

      test('unknown action type returns failure', () {
        final svc = BuildingInteractionService();
        final result = svc.performAction('unknown', residential(), 0.0);
        expect(result.success, isFalse);
      });
    });

    group('performAction – commercial', () {
      test('worker: +5 faith', () {
        final svc = BuildingInteractionService();
        final result = svc.performAction('worker', commercial(), 0.0);
        expect(result.playerFaithDelta, 5.0);
      });

      test('prayBusiness: +10 faith', () {
        final svc = BuildingInteractionService();
        final result = svc.performAction('prayBusiness', commercial(), 0.0);
        expect(result.playerFaithDelta, 10.0);
      });

      test('distribute: -5 materials, +15 faith, residents +3 faith', () {
        final npc = NPCModel(
          id: 'n', name: 'W', type: NPCType.citizen,
          homePosition: Vector2.zero(), faith: 0.0,
        );
        final b = BuildingModel(
          buildingId: 's', type: BuildingType.shop, residents: [npc],
        );
        final svc = BuildingInteractionService();
        final result = svc.performAction('distribute', b, 0.0);
        expect(result.playerFaithDelta, 15.0);
        expect(result.playerMaterialsDelta, -5.0);
        expect(npc.faith, 3.0);
      });

      test('donate: returns 20-40 materials on success', () {
        // Use a manager NPC with high faith to maximize success chance.
        final manager = NPCModel(
          id: 'm', name: 'Manager', type: NPCType.merchant,
          homePosition: Vector2.zero(), faith: 100.0,
        );
        final b = BuildingModel(
          buildingId: 's', type: BuildingType.shop, residents: [manager],
        );
        // Run many trials – with faith=100 most should succeed.
        int successes = 0;
        for (int i = 0; i < 50; i++) {
          final svc = BuildingInteractionService(rng: Random(i));
          final result = svc.performAction('donate', b, 0.0);
          if (result.success) {
            successes++;
            expect(
              result.playerMaterialsDelta,
              inInclusiveRange(20.0, 40.0),
            );
          }
        }
        expect(successes, greaterThan(30));
      });
    });

    group('performAction – church', () {
      test('readBible: +10 faith', () {
        final svc = BuildingInteractionService();
        final result = svc.performAction('readBible', church(), 0.0);
        expect(result.playerFaithDelta, 10.0);
      });

      test('pray: +15 faith, residents influenced', () {
        final priest = NPCModel(
          id: 'p', name: 'Pfarrer', type: NPCType.priest,
          homePosition: Vector2.zero(), faith: 50.0,
        );
        final b = BuildingModel(
          buildingId: 'c', type: BuildingType.church, residents: [priest],
        );
        final svc = BuildingInteractionService();
        final result = svc.performAction('pray', b, 0.0);
        expect(result.playerFaithDelta, 15.0);
        expect(priest.faith, greaterThan(50.0));
      });

      test('worship: +20 faith, residents +10 faith', () {
        final priest = NPCModel(
          id: 'p', name: 'Pfarrer', type: NPCType.priest,
          homePosition: Vector2.zero(), faith: 0.0,
        );
        final b = BuildingModel(
          buildingId: 'c', type: BuildingType.cathedral, residents: [priest],
        );
        final svc = BuildingInteractionService();
        final result = svc.performAction('worship', b, 0.0);
        expect(result.playerFaithDelta, 20.0);
        expect(priest.faith, 10.0);
      });
    });
  });
}

// ignore_for_file: prefer_const_constructors
