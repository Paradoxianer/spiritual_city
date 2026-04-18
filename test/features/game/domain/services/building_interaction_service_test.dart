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

      test('all non-residential types are category other', () {
        for (final t in [
          BuildingType.shop,
          BuildingType.office,
          BuildingType.skyscraper,
          BuildingType.factory,
          BuildingType.warehouse,
          BuildingType.church,
          BuildingType.cathedral,
          BuildingType.hospital,
          BuildingType.school,
          BuildingType.trainStation,
          BuildingType.cemetery,
        ]) {
          expect(
            BuildingModel(buildingId: 'b', type: t).category,
            BuildingCategory.other,
            reason: '$t should be other',
          );
        }
      });
    });

    group('isAlwaysOpen', () {
      test('residential buildings are NOT always open', () {
        expect(BuildingModel(buildingId: 'h', type: BuildingType.house).isAlwaysOpen, isFalse);
        expect(BuildingModel(buildingId: 'a', type: BuildingType.apartment).isAlwaysOpen, isFalse);
      });

      test('all other types are always open', () {
        for (final t in [
          BuildingType.shop, BuildingType.church, BuildingType.hospital,
          BuildingType.factory, BuildingType.school, BuildingType.cemetery,
        ]) {
          expect(
            BuildingModel(buildingId: 'b', type: t).isAlwaysOpen,
            isTrue,
            reason: '$t should be always open',
          );
        }
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
        expect(house.accessChance(100), 1.0);   // 0.85 + 0.30 capped
        expect(house.accessChance(0), 0.80);    // 0.50 + 0.30
        expect(house.accessChance(-100), 0.45); // 0.15 + 0.30
      });

      test('bonus does NOT apply before 3 conversations', () {
        house.totalConversations = 2;
        expect(house.accessChance(0), 0.50);
      });
    });

    group('influenceResidents', () {
      test('applies faith delta to all residents', () {
        final npc1 = NPCModel(id: 'n1', name: 'Alice', type: NPCType.citizen,
            homePosition: Vector2.zero(), faith: 10.0);
        final npc2 = NPCModel(id: 'n2', name: 'Bob', type: NPCType.citizen,
            homePosition: Vector2.zero(), faith: -20.0);
        final building = BuildingModel(
          buildingId: 'h', type: BuildingType.house, residents: [npc1, npc2],
        );
        building.influenceResidents(5.0);
        expect(npc1.faith, closeTo(15.0, 0.001));
        expect(npc2.faith, closeTo(-15.0, 0.001));
      });

      test('clamps at ±100', () {
        final npc = NPCModel(id: 'n', name: 'Eve', type: NPCType.citizen,
            homePosition: Vector2.zero(), faith: 98.0);
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
    NPCModel npc({double faith = 0.0}) => NPCModel(
      id: 'n', name: 'X', type: NPCType.citizen,
      homePosition: Vector2.zero(), faith: faith,
    );
    BuildingModel house({List<NPCModel>? residents}) =>
        BuildingModel(buildingId: 'h', type: BuildingType.house, residents: residents);
    BuildingModel shop({List<NPCModel>? residents}) =>
        BuildingModel(buildingId: 's', type: BuildingType.shop, residents: residents);
    BuildingModel church() =>
        BuildingModel(buildingId: 'c', type: BuildingType.church);
    BuildingModel hospital({List<NPCModel>? residents}) =>
        BuildingModel(buildingId: 'h', type: BuildingType.hospital, residents: residents);
    BuildingModel school({List<NPCModel>? residents}) =>
        BuildingModel(buildingId: 'sc', type: BuildingType.school, residents: residents);
    BuildingModel cemetery() =>
        BuildingModel(buildingId: 'cem', type: BuildingType.cemetery);
    BuildingModel factory({List<NPCModel>? residents}) =>
        BuildingModel(buildingId: 'f', type: BuildingType.factory, residents: residents);

    group('attemptAccess', () {
      test('always succeeds for non-residential buildings', () {
        final svc = BuildingInteractionService(rng: Random(0));
        for (final b in [shop(), church(), hospital(), factory(), cemetery()]) {
          expect(svc.attemptAccess(b, -100), isTrue, reason: '${b.type} should be always open');
        }
      });

      test('residential: high faith → mostly granted', () {
        int successes = 0;
        for (int i = 0; i < 100; i++) {
          if (BuildingInteractionService(rng: Random(i)).attemptAccess(house(), 100.0)) successes++;
        }
        expect(successes, greaterThan(70));
      });

      test('residential: very negative faith → mostly denied', () {
        int successes = 0;
        for (int i = 0; i < 100; i++) {
          if (BuildingInteractionService(rng: Random(i)).attemptAccess(house(), -100.0)) successes++;
        }
        expect(successes, lessThan(35));
      });
    });

    group('performAction – residential', () {
      test('talk: +5 faith, increments resident conversationCount', () {
        final resident = npc();
        final b = house(residents: [resident]);
        final result = BuildingInteractionService().performAction('talk', b, 0.0);
        expect(result.playerFaithDelta, 5.0);
        expect(resident.conversationCount, 1);
      });

      test('pray: +15 faith, +5 materials, residents influenced', () {
        final resident = npc();
        final b = house(residents: [resident]);
        final result = BuildingInteractionService().performAction('pray', b, 0.0);
        expect(result.playerFaithDelta, 15.0);
        expect(result.playerMaterialsDelta, 5.0);
        expect(resident.faith, greaterThan(0));
      });

      test('help: -10 materials, +10 faith, NPC faith +5', () {
        final resident = npc();
        final b = house(residents: [resident]);
        final result = BuildingInteractionService().performAction('help', b, 0.0);
        expect(result.playerFaithDelta, 10.0);
        expect(result.playerMaterialsDelta, -10.0);
        expect(resident.faith, 5.0);
      });

      test('bible: +10 faith, family faith +2', () {
        final resident = npc();
        final b = house(residents: [resident]);
        final result = BuildingInteractionService().performAction('bible', b, 0.0);
        expect(result.playerFaithDelta, 10.0);
        expect(resident.faith, 2.0);
      });

      test('totalConversations incremented on every action', () {
        final b = house();
        final svc = BuildingInteractionService();
        svc.performAction('talk', b, 0.0);
        svc.performAction('pray', b, 0.0);
        expect(b.totalConversations, 2);
      });

      test('unknown action returns failure', () {
        expect(BuildingInteractionService().performAction('unknown', house(), 0.0).success, isFalse);
      });
    });

    group('performAction – commercial', () {
      test('worker: +5 faith', () {
        expect(BuildingInteractionService().performAction('worker', shop(), 0.0).playerFaithDelta, 5.0);
      });

      test('prayBusiness: +10 faith', () {
        expect(BuildingInteractionService().performAction('prayBusiness', shop(), 0.0).playerFaithDelta, 10.0);
      });

      test('distribute: -5 materials, +15 faith, residents +3 faith', () {
        final resident = npc();
        final b = shop(residents: [resident]);
        final result = BuildingInteractionService().performAction('distribute', b, 0.0);
        expect(result.playerFaithDelta, 15.0);
        expect(result.playerMaterialsDelta, -5.0);
        expect(resident.faith, 3.0);
      });

      test('donate: returns 20-40 materials on success with high-faith manager', () {
        final manager = NPCModel(id: 'm', name: 'Mgr', type: NPCType.merchant,
            homePosition: Vector2.zero(), faith: 100.0);
        final b = shop(residents: [manager]);
        int successes = 0;
        for (int i = 0; i < 50; i++) {
          final result = BuildingInteractionService(rng: Random(i)).performAction('donate', b, 0.0);
          if (result.success) {
            successes++;
            expect(result.playerMaterialsDelta, inInclusiveRange(20.0, 40.0));
          }
        }
        expect(successes, greaterThan(30));
      });
    });

    group('performAction – church', () {
      test('readBible: +10 faith', () {
        expect(BuildingInteractionService().performAction('readBible', church(), 0.0).playerFaithDelta, 10.0);
      });

      test('pray: +15 faith, residents influenced', () {
        final priest = NPCModel(id: 'p', name: 'Pfarrer', type: NPCType.priest,
            homePosition: Vector2.zero(), faith: 50.0);
        final b = BuildingModel(buildingId: 'c', type: BuildingType.church, residents: [priest]);
        final result = BuildingInteractionService().performAction('pray', b, 0.0);
        expect(result.playerFaithDelta, 15.0);
        expect(priest.faith, greaterThan(50.0));
      });

      test('worship: +20 faith, residents +10 faith', () {
        final priest = NPCModel(id: 'p', name: 'Pfarrer', type: NPCType.priest,
            homePosition: Vector2.zero(), faith: 0.0);
        final b = BuildingModel(buildingId: 'c', type: BuildingType.cathedral, residents: [priest]);
        final result = BuildingInteractionService().performAction('worship', b, 0.0);
        expect(result.playerFaithDelta, 20.0);
        expect(priest.faith, 10.0);
      });
    });

    group('performAction – hospital', () {
      test('visitSick: +12 faith, residents +4 faith', () {
        final resident = npc();
        final b = hospital(residents: [resident]);
        final result = BuildingInteractionService().performAction('visitSick', b, 0.0);
        expect(result.playerFaithDelta, 12.0);
        expect(resident.faith, 4.0);
      });

      test('pray: +10 faith, residents +3 faith', () {
        final resident = npc();
        final b = hospital(residents: [resident]);
        final result = BuildingInteractionService().performAction('pray', b, 0.0);
        expect(result.playerFaithDelta, 10.0);
        expect(resident.faith, 3.0);
      });

      test('heal: -10 materials, +20 faith, no NPC effect', () {
        final resident = npc();
        final b = hospital(residents: [resident]);
        final result = BuildingInteractionService().performAction('heal', b, 0.0);
        expect(result.playerFaithDelta, 20.0);
        expect(result.playerMaterialsDelta, -10.0);
        expect(result.success, isTrue);
        expect(resident.faith, 0.0, reason: 'heal only benefits the player');
      });

      test('distribute: -8 materials, +8 faith, residents +2 faith', () {
        final resident = npc();
        final b = hospital(residents: [resident]);
        final result = BuildingInteractionService().performAction('distribute', b, 0.0);
        expect(result.playerFaithDelta, 8.0);
        expect(result.playerMaterialsDelta, -8.0);
        expect(resident.faith, 2.0);
      });
    });

    group('performAction – school', () {
      test('teach: +8 faith, residents +5 faith', () {
        final resident = npc();
        final b = school(residents: [resident]);
        final result = BuildingInteractionService().performAction('teach', b, 0.0);
        expect(result.playerFaithDelta, 8.0);
        expect(resident.faith, 5.0);
      });

      test('pray: +10 faith, residents +2 faith', () {
        final resident = npc();
        final b = school(residents: [resident]);
        final result = BuildingInteractionService().performAction('pray', b, 0.0);
        expect(result.playerFaithDelta, 10.0);
        expect(resident.faith, 2.0);
      });
    });

    group('performAction – cemetery', () {
      test('pray: +18 faith', () {
        expect(BuildingInteractionService().performAction('pray', cemetery(), 0.0).playerFaithDelta, 18.0);
      });

      test('comfort: +10 faith, residents +6 faith', () {
        final resident = npc();
        final b = BuildingModel(buildingId: 'cem', type: BuildingType.cemetery, residents: [resident]);
        final result = BuildingInteractionService().performAction('comfort', b, 0.0);
        expect(result.playerFaithDelta, 10.0);
        expect(resident.faith, 6.0);
      });
    });

    group('performAction – generic (factory, civic, etc.)', () {
      test('pray: +8 faith, residents +2 faith', () {
        final resident = npc();
        final b = factory(residents: [resident]);
        final result = BuildingInteractionService().performAction('pray', b, 0.0);
        expect(result.playerFaithDelta, 8.0);
        expect(resident.faith, 2.0);
      });

      test('witness: +10 faith, residents +4 faith', () {
        final resident = npc();
        final b = factory(residents: [resident]);
        final result = BuildingInteractionService().performAction('witness', b, 0.0);
        expect(result.playerFaithDelta, 10.0);
        expect(resident.faith, 4.0);
      });

      test('distribute: -8 materials, +12 faith, residents +3 faith', () {
        final resident = npc();
        final b = factory(residents: [resident]);
        final result = BuildingInteractionService().performAction('distribute', b, 0.0);
        expect(result.playerFaithDelta, 12.0);
        expect(result.playerMaterialsDelta, -8.0);
        expect(resident.faith, 3.0);
      });

      test('unknown action returns failure', () {
        expect(BuildingInteractionService().performAction('unknown', factory(), 0.0).success, isFalse);
      });
    });

    group('performAction – pastorHouse', () {
      BuildingModel pastorHouse() => BuildingModel(
        buildingId: 'ph', type: BuildingType.pastorHouse, isHomebase: true,
      );

      test('is always open (no knock required)', () {
        expect(BuildingModel(buildingId: 'ph', type: BuildingType.pastorHouse).isAlwaysOpen, isTrue);
      });

      test('readBible: +20 faith, −5 health', () {
        final result = BuildingInteractionService().performAction('readBible', pastorHouse(), 0.0);
        expect(result.playerFaithDelta, 20.0);
        expect(result.playerHealthDelta, -5.0);
        expect(result.success, isTrue);
      });

      test('eat: +50 hunger, −5 materials', () {
        final result = BuildingInteractionService().performAction('eat', pastorHouse(), 0.0);
        expect(result.playerHungerDelta, 50.0);
        expect(result.playerMaterialsDelta, -5.0);
        expect(result.success, isTrue);
      });

      test('sleep: +50 health', () {
        final result = BuildingInteractionService().performAction('sleep', pastorHouse(), 0.0);
        expect(result.playerHealthDelta, 50.0);
        expect(result.success, isTrue);
      });

      test('pray: +15 faith, −5 health', () {
        final result = BuildingInteractionService().performAction('pray', pastorHouse(), 0.0);
        expect(result.playerFaithDelta, 15.0);
        expect(result.playerHealthDelta, -5.0);
        expect(result.success, isTrue);
      });

      test('readBible: blocked after 3 uses per session', () {
        final ph = pastorHouse();
        final svc = BuildingInteractionService();
        for (var i = 0; i < 3; i++) {
          expect(svc.performAction('readBible', ph, 0.0).success, isTrue);
        }
        expect(svc.performAction('readBible', ph, 0.0).success, isFalse);
      });

      test('eat: blocked after 2 uses per session', () {
        final ph = pastorHouse();
        final svc = BuildingInteractionService();
        for (var i = 0; i < 2; i++) {
          expect(svc.performAction('eat', ph, 0.0).success, isTrue);
        }
        expect(svc.performAction('eat', ph, 0.0).success, isFalse);
      });

      test('sleep: blocked after 1 use per session', () {
        final ph = pastorHouse();
        final svc = BuildingInteractionService();
        expect(svc.performAction('sleep', ph, 0.0).success, isTrue);
        expect(svc.performAction('sleep', ph, 0.0).success, isFalse);
      });

      test('pray: blocked after 3 uses per session', () {
        final ph = pastorHouse();
        final svc = BuildingInteractionService();
        for (var i = 0; i < 3; i++) {
          expect(svc.performAction('pray', ph, 0.0).success, isTrue);
        }
        expect(svc.performAction('pray', ph, 0.0).success, isFalse);
      });

      test('session limits reset after resetSession()', () {
        final ph = pastorHouse();
        final svc = BuildingInteractionService();
        // Use up sleep limit
        expect(svc.performAction('sleep', ph, 0.0).success, isTrue);
        expect(svc.performAction('sleep', ph, 0.0).success, isFalse);
        // Reset session (simulates re-entering the building)
        ph.resetSession();
        expect(svc.performAction('sleep', ph, 0.0).success, isTrue);
      });

      test('unknown action returns failure', () {
        expect(BuildingInteractionService().performAction('unknown', pastorHouse(), 0.0).success, isFalse);
      });
    });
  });
}

// ignore_for_file: prefer_const_constructors
