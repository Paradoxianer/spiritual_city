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

      test('+2 % per interaction (continuous scaling)', () {
        house.interactionCount = 3;
        // base=0.85 (faith>30) + 3*0.02 = 0.91
        expect(house.accessChance(100), closeTo(0.91, 0.001));
        // base=0.50 (neutral) + 3*0.02 = 0.56
        expect(house.accessChance(0), closeTo(0.56, 0.001));
        // base=0.15 (very negative) + 3*0.02 = 0.21
        expect(house.accessChance(-100), closeTo(0.21, 0.001));
      });

      test('at 20+ interactions → always 1.0', () {
        house.interactionCount = 20;
        expect(house.accessChance(100), 1.0);
        expect(house.accessChance(0), 1.0);
        expect(house.accessChance(-100), 1.0);

        house.interactionCount = 50;
        expect(house.accessChance(-100), 1.0);
      });

      test('incremental scaling at 10 interactions', () {
        house.interactionCount = 10;
        // base=0.50 + 10*0.02 = 0.70
        expect(house.accessChance(0), closeTo(0.70, 0.001));
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

    group('baseSessionInteractions per building type', () {
      test('residential buildings start at 2', () {
        expect(BuildingModel(buildingId: 'h', type: BuildingType.house).baseSessionInteractions, 2);
        expect(BuildingModel(buildingId: 'a', type: BuildingType.apartment).baseSessionInteractions, 2);
      });

      test('commercial buildings start at 4', () {
        for (final t in [
          BuildingType.shop,
          BuildingType.supermarket,
          BuildingType.mall,
          BuildingType.office,
          BuildingType.skyscraper,
        ]) {
          expect(
            BuildingModel(buildingId: 'b', type: t).baseSessionInteractions,
            4,
            reason: '$t should have base 4',
          );
        }
      });

      test('church/cathedral start at 3', () {
        expect(BuildingModel(buildingId: 'c', type: BuildingType.church).baseSessionInteractions, 3);
        expect(BuildingModel(buildingId: 'cd', type: BuildingType.cathedral).baseSessionInteractions, 3);
      });

      test('civic/public buildings start at 3', () {
        for (final t in [
          BuildingType.hospital,
          BuildingType.school,
          BuildingType.university,
          BuildingType.trainStation,
        ]) {
          expect(
            BuildingModel(buildingId: 'b', type: t).baseSessionInteractions,
            3,
            reason: '$t should have base 3',
          );
        }
      });

      test('pastor house (homebase) has effectively unlimited limit', () {
        final ph = BuildingModel(buildingId: 'ph', type: BuildingType.pastorHouse, isHomebase: true);
        expect(ph.baseSessionInteractions, greaterThan(100));
        expect(ph.isReadyToLeave, isFalse);
      });
    });

    group('maxSessionInteractions grows with interactionCount', () {
      test('residential: 0 interactions → 2', () {
        final b = BuildingModel(buildingId: 'h', type: BuildingType.house);
        expect(b.maxSessionInteractions, 2);
      });

      test('residential: 6 interactions → 3', () {
        final b = BuildingModel(buildingId: 'h', type: BuildingType.house, interactionCount: 6);
        expect(b.maxSessionInteractions, 3);
      });

      test('shop: 0 interactions → 4', () {
        final b = BuildingModel(buildingId: 's', type: BuildingType.shop);
        expect(b.maxSessionInteractions, 4);
      });

      test('shop: 6 interactions → 5', () {
        final b = BuildingModel(buildingId: 's', type: BuildingType.shop, interactionCount: 6);
        expect(b.maxSessionInteractions, 5);
      });

      test('shop: 12 interactions → 6', () {
        final b = BuildingModel(buildingId: 's', type: BuildingType.shop, interactionCount: 12);
        expect(b.maxSessionInteractions, 6);
      });
    });

    group('isReadyToLeave for buildings', () {
      test('not ready before limit', () {
        final b = BuildingModel(buildingId: 'h', type: BuildingType.house);
        b.currentSessionInteractions = 1;
        expect(b.isReadyToLeave, isFalse);
      });

      test('ready at limit', () {
        final b = BuildingModel(buildingId: 'h', type: BuildingType.house);
        b.currentSessionInteractions = 2;
        expect(b.isReadyToLeave, isTrue);
      });

      test('shop not ready at 3 (base=4)', () {
        final b = BuildingModel(buildingId: 's', type: BuildingType.shop);
        b.currentSessionInteractions = 3;
        expect(b.isReadyToLeave, isFalse);
      });

      test('shop ready at 4 (base=4)', () {
        final b = BuildingModel(buildingId: 's', type: BuildingType.shop);
        b.currentSessionInteractions = 4;
        expect(b.isReadyToLeave, isTrue);
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
      test('practicalHelp: −10 materials, +5 interactionCount', () {
        final b = house();
        final result = BuildingInteractionService().performAction('practicalHelp', b, 0.0);
        expect(result.playerMaterialsDelta, -10.0);
        expect(result.success, isTrue);
        expect(b.interactionCount, 5);
      });

      test('practicalHelp: small influence applied to building', () {
        final b = house();
        BuildingInteractionService().performAction('practicalHelp', b, 0.0);
        expect(b.faith, greaterThan(0));
      });

      test('pray: costs 10 faith (playerFaithDelta = −10)', () {
        final b = house();
        final result = BuildingInteractionService().performAction('pray', b, 0.0);
        expect(result.playerFaithDelta, -10.0);
      });

      test('pray: increments interactionCount', () {
        final b = house();
        BuildingInteractionService().performAction('pray', b, 0.0);
        expect(b.interactionCount, greaterThanOrEqualTo(1));
      });

      test('houseVisit: blocked when interactionCount ≤ 5', () {
        final b = house();
        b.interactionCount = 5;
        final result = BuildingInteractionService().performAction('houseVisit', b, 0.0);
        expect(result.success, isFalse);
      });

      test('houseVisit: succeeds when interactionCount > 5, refills health/hunger', () {
        final b = house();
        b.interactionCount = 6;
        final result = BuildingInteractionService().performAction('houseVisit', b, 0.0);
        expect(result.success, isTrue);
        expect(result.playerHealthDelta, greaterThan(0));
        expect(result.playerHungerDelta, greaterThan(0));
        expect(result.actionDurationSeconds, greaterThan(0));
      });

      test('discipleshipGroup: blocked without converted resident', () {
        final b = house();
        b.interactionCount = 25;
        final result = BuildingInteractionService().performAction('discipleshipGroup', b, 0.0);
        expect(result.success, isFalse);
      });

      test('discipleshipGroup: blocked when interactionCount ≤ 20', () {
        final resident = NPCModel(id: 'n', name: 'X', type: NPCType.citizen,
            homePosition: Vector2.zero(), faith: 0.0, isConverted: true);
        final b = house(residents: [resident]);
        b.interactionCount = 20;
        final result = BuildingInteractionService().performAction('discipleshipGroup', b, 0.0);
        expect(result.success, isFalse);
      });

      test('discipleshipGroup (house): succeeds with >20 interactions + converted resident, +0.2 insight, has duration', () {
        final resident = NPCModel(id: 'n', name: 'X', type: NPCType.citizen,
            homePosition: Vector2.zero(), faith: 80.0, isConverted: true);
        final b = house(residents: [resident]);
        b.interactionCount = 21;
        final result = BuildingInteractionService().performAction('discipleshipGroup', b, 0.0);
        expect(result.success, isTrue);
        expect(result.playerFaithDelta, 0.0);
        expect(result.playerInsightDelta, 0.2);
        expect(result.actionDurationSeconds, greaterThan(0));
      });

      test('discipleshipGroup (apartment): gives +0.3 insight', () {
        final resident = NPCModel(id: 'n', name: 'X', type: NPCType.citizen,
            homePosition: Vector2.zero(), faith: 80.0, isConverted: true);
        final b = BuildingModel(
          buildingId: 'a',
          type: BuildingType.apartment,
          residents: [resident],
        );
        b.interactionCount = 21;
        final result = BuildingInteractionService().performAction('discipleshipGroup', b, 0.0);
        expect(result.success, isTrue);
        expect(result.playerInsightDelta, 0.3);
      });

      test('blessHousehold: increments all resident interactionCounts', () {
        final npc1 = npc(faith: 0.0);
        final npc2 = npc(faith: 0.0);
        final b = BuildingModel(buildingId: 'a', type: BuildingType.apartment, residents: [npc1, npc2]);
        BuildingInteractionService().performAction('blessHousehold', b, 0.0);
        expect(npc1.interactionCount, 1);
        expect(npc2.interactionCount, 1);
      });

      test('unknown action returns failure', () {
        expect(BuildingInteractionService().performAction('unknown', house(), 0.0).success, isFalse);
      });
    });

    group('performAction – commercial', () {
      test('talkBoss: +3 interactionCount, has duration', () {
        final b = shop();
        final result = BuildingInteractionService().performAction('talkBoss', b, 0.0);
        expect(result.success, isTrue);
        expect(b.interactionCount, 3);
        expect(result.actionDurationSeconds, greaterThan(0));
      });

      test('shopping: −5 materials, +20 hunger, +10 health', () {
        final b = shop();
        final result = BuildingInteractionService().performAction('shopping', b, 0.0);
        expect(result.playerMaterialsDelta, -5.0);
        expect(result.playerHungerDelta, 20.0);
        expect(result.playerHealthDelta, 10.0);
      });

      test('bless: −15 faith, +2 interactionCount, influence applied', () {
        final b = shop();
        final result = BuildingInteractionService().performAction('bless', b, 0.0);
        expect(result.playerFaithDelta, -15.0);
        expect(b.interactionCount, 2);
        expect(b.faith, greaterThan(0));
      });

      test('requestDonation: blocked when interactionCount ≤ 3', () {
        final b = shop();
        b.interactionCount = 3;
        final result = BuildingInteractionService().performAction('requestDonation', b, 0.0);
        expect(result.success, isFalse);
      });

      test('requestDonation: success returns materials + faith, uses health/hunger', () {
        // High faith building → guaranteed success
        final b = BuildingModel(buildingId: 's', type: BuildingType.shop, faith: 100.0);
        b.interactionCount = 50;
        int successes = 0;
        for (int i = 0; i < 50; i++) {
          final result = BuildingInteractionService(rng: Random(i)).performAction('requestDonation', b, 0.0);
          if (result.success) {
            successes++;
            expect(result.playerMaterialsDelta, greaterThan(0));
            expect(result.playerFaithDelta, 8.0);
            expect(result.playerHealthDelta, -10.0);
            expect(result.playerHungerDelta, -10.0);
          }
        }
        expect(successes, greaterThan(30));
      });
    });

    group('performAction – church', () {
      test('sundayService: −50 materials, −60 health, massive AOE influence', () {
        final b = church();
        final result = BuildingInteractionService().performAction('sundayService', b, 0.0);
        expect(result.playerMaterialsDelta, -50.0);
        expect(result.playerHealthDelta, -60.0);
        expect(result.actionDurationSeconds, greaterThan(0));
        expect(b.faith, greaterThan(0));
      });

      test('worship: faith gain is 3× duration (3/sec), timed', () {
        final b = church();
        final result = BuildingInteractionService().performAction('worship', b, 0.0);
        expect(result.playerFaithDelta, greaterThan(0));
        expect(result.actionDurationSeconds, greaterThan(0));
        expect(result.playerFaithDelta, closeTo(result.actionDurationSeconds * 3.0, 0.001));
        expect(b.faith, greaterThan(0));
      });

      test('worship: residents influenced', () {
        final priest = NPCModel(id: 'p', name: 'Pfarrer', type: NPCType.priest,
            homePosition: Vector2.zero(), faith: 0.0);
        final b = BuildingModel(buildingId: 'c', type: BuildingType.cathedral, residents: [priest]);
        BuildingInteractionService().performAction('worship', b, 0.0);
        expect(priest.faith, greaterThan(0.0));
      });

      test('pastorHouse pray: gives +22 faith and costs 5 health', () {
        final b = BuildingModel(
          buildingId: 'ph',
          type: BuildingType.pastorHouse,
          isHomebase: true,
        );
        final result = BuildingInteractionService().performAction('pray', b, 0.0);
        expect(result.playerFaithDelta, 22.0);
        expect(result.playerHealthDelta, -5.0);
      });
    });

    group('performAction – hospital', () {
      test('medicalHelp: −15 materials, refills health and hunger to 100', () {
        final b = hospital();
        final result = BuildingInteractionService().performAction('medicalHelp', b, 0.0);
        expect(result.playerMaterialsDelta, -15.0);
        expect(result.playerHealthDelta, 100.0);
        expect(result.playerHungerDelta, 100.0);
        expect(result.success, isTrue);
      });

      test('counseling: blocked when interactionCount ≤ 3', () {
        final b = hospital();
        b.interactionCount = 3;
        expect(BuildingInteractionService().performAction('counseling', b, 0.0).success, isFalse);
      });

      test('counseling: succeeds when interactionCount > 3, has duration', () {
        final b = hospital();
        b.interactionCount = 4;
        final result = BuildingInteractionService().performAction('counseling', b, 0.0);
        expect(result.success, isTrue);
        expect(result.actionDurationSeconds, greaterThan(0));
      });

      test('chapelService: blocked when interactionCount ≤ 10', () {
        final b = hospital();
        b.interactionCount = 10;
        expect(BuildingInteractionService().performAction('chapelService', b, 0.0).success, isFalse);
      });

      test('chapelService: −30 faith, NPCs +15 faith when interactionCount > 10', () {
        final resident = npc();
        final b = hospital(residents: [resident]);
        b.interactionCount = 11;
        final result = BuildingInteractionService().performAction('chapelService', b, 0.0);
        expect(result.playerFaithDelta, -30.0);
        expect(resident.faith, 15.0);
        expect(result.success, isTrue);
      });
    });

    group('performAction – school', () {
      test('letterToManagement: −5 materials, +2 interactionCount', () {
        final b = school();
        final result = BuildingInteractionService().performAction('letterToManagement', b, 0.0);
        expect(result.playerMaterialsDelta, -5.0);
        expect(b.interactionCount, 2);
      });

      test('talkDirector: blocked when interactionCount ≤ 5', () {
        final b = school();
        b.interactionCount = 5;
        expect(BuildingInteractionService().performAction('talkDirector', b, 0.0).success, isFalse);
      });

      test('talkDirector: unlocks lecture when interactionCount > 5', () {
        final b = school();
        b.interactionCount = 6;
        final result = BuildingInteractionService().performAction('talkDirector', b, 0.0);
        expect(result.success, isTrue);
        expect(b.isLecturePrepared, isTrue);
        expect(result.actionDurationSeconds, greaterThan(0));
      });

      test('valueLecture: blocked without director talk', () {
        final b = school();
        b.interactionCount = 20;
        expect(BuildingInteractionService().performAction('valueLecture', b, 0.0).success, isFalse);
      });

      test('valueLecture: succeeds after talkDirector and >15 interactions', () {
        final b = school();
        b.interactionCount = 16;
        b.isLecturePrepared = true;
        final result = BuildingInteractionService().performAction('valueLecture', b, 0.0);
        expect(result.success, isTrue);
        expect(result.actionDurationSeconds, greaterThan(0));
      });

      test('prayerCircle: blocked when interactionCount ≤ 30', () {
        final b = school();
        b.interactionCount = 30;
        expect(BuildingInteractionService().performAction('prayerCircle', b, 0.0).success, isFalse);
      });

      test('prayerCircle: −60 faith, +0.5 insight when interactionCount > 30', () {
        final b = school();
        b.interactionCount = 31;
        final result = BuildingInteractionService().performAction('prayerCircle', b, 0.0);
        expect(result.playerFaithDelta, -60.0);
        expect(result.playerInsightDelta, 0.5);
        expect(result.success, isTrue);
      });
    });

    group('performAction – cemetery', () {
      test('funeral: timed, sets hasFuneralCompleted = true', () {
        final b = cemetery();
        final result = BuildingInteractionService().performAction('funeral', b, 0.0);
        expect(result.success, isTrue);
        expect(b.hasFuneralCompleted, isTrue);
        expect(result.actionDurationSeconds, greaterThan(0));
      });

      test('comfort: blocked before funeral', () {
        final b = cemetery();
        expect(BuildingInteractionService().performAction('comfort', b, 0.0).success, isFalse);
      });

      test('comfort: −75 health, −75 hunger, resets hasFuneralCompleted after use', () {
        final b = cemetery();
        b.hasFuneralCompleted = true;
        final result = BuildingInteractionService().performAction('comfort', b, 0.0);
        expect(result.success, isTrue);
        expect(result.playerHealthDelta, -75.0);
        expect(result.playerHungerDelta, -75.0);
        expect(b.hasFuneralCompleted, isFalse);
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

      test('readBible: +20 faith, −5 health, has duration', () {
        final result = BuildingInteractionService().performAction('readBible', pastorHouse(), 0.0);
        expect(result.playerFaithDelta, 20.0);
        expect(result.playerHealthDelta, -5.0);
        expect(result.actionDurationSeconds, greaterThan(0));
        expect(result.success, isTrue);
      });

      test('eat: +50 hunger, no material cost, has duration', () {
        final result = BuildingInteractionService().performAction('eat', pastorHouse(), 0.0);
        expect(result.playerHungerDelta, 50.0);
        expect(result.playerMaterialsDelta, 0.0);
        expect(result.actionDurationSeconds, greaterThan(0));
        expect(result.success, isTrue);
      });

      test('sleep: +50 health, has duration', () {
        final result = BuildingInteractionService().performAction('sleep', pastorHouse(), 0.0);
        expect(result.playerHealthDelta, 50.0);
        expect(result.actionDurationSeconds, greaterThan(0));
        expect(result.success, isTrue);
      });

      test('pray: +22 faith, −5 health, has duration', () {
        final result = BuildingInteractionService().performAction('pray', pastorHouse(), 0.0);
        expect(result.playerFaithDelta, 22.0);
        expect(result.playerHealthDelta, -5.0);
        expect(result.actionDurationSeconds, greaterThan(0));
        expect(result.success, isTrue);
      });

      test('sleep is repeatable (no per-session limit)', () {
        final ph = pastorHouse();
        final svc = BuildingInteractionService();
        for (var i = 0; i < 5; i++) {
          expect(svc.performAction('sleep', ph, 0.0).success, isTrue,
              reason: 'sleep attempt $i should succeed');
        }
      });

      test('readBible is repeatable (no per-session limit)', () {
        final ph = pastorHouse();
        final svc = BuildingInteractionService();
        for (var i = 0; i < 5; i++) {
          expect(svc.performAction('readBible', ph, 0.0).success, isTrue,
              reason: 'readBible attempt $i should succeed');
        }
      });

      test('unknown action returns failure', () {
        expect(BuildingInteractionService().performAction('unknown', pastorHouse(), 0.0).success, isFalse);
      });
    });

    group('performAction – policeStation', () {
      BuildingModel police() =>
          BuildingModel(buildingId: 'p', type: BuildingType.policeStation);

      test('blessPolice: −15 faith, influence applied', () {
        final b = police();
        final result = BuildingInteractionService().performAction('blessPolice', b, 0.0);
        expect(result.playerFaithDelta, -15.0);
        expect(result.success, isTrue);
        expect(b.faith, greaterThan(0));
      });

      test('unknown police action falls through to generic', () {
        final result = BuildingInteractionService().performAction('pray', police(), 0.0);
        expect(result.success, isTrue);
      });
    });

    group('performAction – cityHall', () {
      BuildingModel cityHall() =>
          BuildingModel(buildingId: 'ch', type: BuildingType.cityHall);

      test('mayorAudience: +3 interactionCount, timed', () {
        final b = cityHall();
        final result = BuildingInteractionService().performAction('mayorAudience', b, 0.0);
        expect(result.success, isTrue);
        expect(b.interactionCount, 3);
        expect(result.actionDurationSeconds, greaterThan(0));
      });

      test('prayForPoliticians: blocked when interactionCount ≤ 20', () {
        final b = cityHall();
        b.interactionCount = 20;
        expect(BuildingInteractionService().performAction('prayForPoliticians', b, 0.0).success, isFalse);
      });

      test('prayForPoliticians: −100 faith, −50 health, −50 hunger when interactionCount > 20', () {
        final b = cityHall();
        b.interactionCount = 21;
        final result = BuildingInteractionService().performAction('prayForPoliticians', b, 0.0);
        expect(result.playerFaithDelta, -100.0);
        expect(result.playerHealthDelta, -50.0);
        expect(result.playerHungerDelta, -50.0);
        expect(result.success, isTrue);
        expect(result.actionDurationSeconds, greaterThan(0));
      });
    });

    group('performAction – trainStation', () {
      BuildingModel station() =>
          BuildingModel(buildingId: 'ts', type: BuildingType.trainStation);

      test('travel: −10 materials', () {
        final b = station();
        final result = BuildingInteractionService().performAction('travel', b, 0.0);
        expect(result.playerMaterialsDelta, -10.0);
        expect(result.success, isTrue);
      });
    });

    group('performAction – stadium', () {
      BuildingModel stadium() =>
          BuildingModel(buildingId: 'st', type: BuildingType.stadium);

      test('majorEvent: blocked when interactionCount ≤ 50', () {
        final b = stadium();
        b.interactionCount = 50;
        expect(BuildingInteractionService().performAction('majorEvent', b, 0.0).success, isFalse);
      });

      test('majorEvent: −100 faith, −100 materials, +0.5 insight when interactionCount > 50', () {
        final b = stadium();
        b.interactionCount = 51;
        final result = BuildingInteractionService().performAction('majorEvent', b, 0.0);
        expect(result.playerFaithDelta, -100.0);
        expect(result.playerMaterialsDelta, -100.0);
        expect(result.playerInsightDelta, 0.5);
        expect(result.success, isTrue);
      });
    });
  });
}

// ignore_for_file: prefer_const_constructors
