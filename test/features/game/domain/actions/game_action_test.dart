import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/actions/building_actions.dart';
import 'package:spiritual_city/src/features/game/domain/actions/game_action.dart';
import 'package:spiritual_city/src/features/game/domain/actions/npc_actions.dart';
import 'package:spiritual_city/src/features/game/domain/actions/practice.dart';
import 'package:spiritual_city/src/features/game/domain/actions/resource.dart';
import 'package:spiritual_city/src/features/game/domain/models/building_model.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_model.dart';
import 'package:spiritual_city/src/features/game/domain/models/player_progress.dart';
import 'package:spiritual_city/src/features/game/domain/services/building_interaction_service.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

class _Wallet implements ResourceWallet {
  final Map<Resource, double> values;
  _Wallet([Map<Resource, double>? v])
      : values = v ?? {for (final r in Resource.values) r: 1000};
  @override
  double amountOf(Resource r) => values[r] ?? 0;
}

NPCModel _npc(String id) =>
    NPCModel(id: id, name: id, type: NPCType.citizen, homePosition: Vector2.zero());

void main() {
  group('ResourceCost', () {
    test('hint lists costs in resource order, emoji only', () {
      const c = ResourceCost({Resource.health: 2, Resource.faith: 5});
      expect(c.hint, '−5🙏−2❤️');
      expect(ResourceCost.none.hint, '');
    });

    test('health may not be spent down to zero, other resources may', () {
      const c = ResourceCost({Resource.health: 10, Resource.faith: 10});
      expect(c.missing(_Wallet({Resource.health: 10, Resource.faith: 10})), Resource.health);
      expect(c.missing(_Wallet({Resource.health: 11, Resource.faith: 10})), isNull);
      expect(c.missing(_Wallet({Resource.health: 11, Resource.faith: 9})), Resource.faith);
    });
  });

  group('NpcActions', () {
    test('chat slots are fixed: 💬 👂 🙏 📖 📦 ✝️🕊️', () {
      expect(NpcActions.chat.map((a) => a.emoji).toList(),
          ['💬', '👂', '🙏', '📖', '📦', '✝️🕊️']);
    });

    test('counsel hint shows the real health cost (was −❤️ at 2, cost 8)', () {
      expect(NpcActions.counsel.hint(Difficulty.normal), '−8❤️→✝️');
      final npc = _npc('a');
      final a = NpcActions.counsel.availability(
          npc, _Wallet({Resource.health: 8}), Difficulty.normal);
      expect(a, isA<CannotAfford>());
      expect(a.reason, '🚫❤️');
    });

    test('📦 only shows when the NPC wants a gift, ✝️🕊️ only for non-Christians', () {
      final npc = _npc('b');
      npc.wantsGift = false;
      expect(NpcActions.help.isVisibleFor(npc), isFalse);
      npc.wantsGift = true;
      expect(NpcActions.help.isVisibleFor(npc), isTrue);
      expect(NpcActions.convert.isVisibleFor(npc), isTrue);
      npc.isConverted = true;
      expect(NpcActions.convert.isVisibleFor(npc), isFalse);
    });

    test('every type resolves back to its action', () {
      for (final a in [...NpcActions.chat, NpcActions.lifeTalk]) {
        expect(NpcActions.byType(a.type), same(a));
      }
    });
  });

  group('BuildingActions', () {
    test('locked actions show how many visits are missing', () {
      final b = BuildingModel(buildingId: 'h', type: BuildingType.house, interactionCount: 3);
      final a = BuildingActions.houseVisit.availability(b, _Wallet(), Difficulty.normal);
      expect(a.reason, '🔒3');
    });

    // The registry is the single source for what the UI shows and checks;
    // the service applies the deltas. They must agree for every action.
    test('registry costs match the deltas of BuildingInteractionService', () {
      for (final type in BuildingType.values) {
        for (final action in BuildingActions.forType(type)) {
          // Handled by the game, not the service: the mission board and
          // learned abilities (🙏🏠 ➖🍞 📢, see GameBuildingActions).
          if (action.type == 'missions' || action.needsSkill != null) continue;
          final christian = _npc('c_${type.name}')..isConverted = true;
          final b = BuildingModel(
            buildingId: 'b_${type.name}',
            type: type,
            residents: [christian],
            isHomebase: type == BuildingType.pastorHouse,
            interactionCount: 100,
          )
            ..isLecturePrepared = true
            ..hasFuneralCompleted = true;
          expect(action.availability(b, _Wallet(), Difficulty.normal).isOk, isTrue,
              reason: '${type.name}/${action.type} should be available');

          final r = BuildingInteractionService(rng: Random(1))
              .performAction(action.type, b, 1000);
          final cost = action.cost(Difficulty.normal);
          double spent(double delta) => delta < 0 ? -delta : 0;
          final where = '${type.name}/${action.type}';
          expect(spent(r.playerFaithDelta), cost.of(Resource.faith), reason: '$where 🙏');
          expect(spent(r.playerHealthDelta), cost.of(Resource.health), reason: '$where ❤️');
          expect(spent(r.playerHungerDelta), cost.of(Resource.hunger), reason: '$where 🍞');
          expect(spent(r.playerMaterialsDelta), cost.of(Resource.materials), reason: '$where 📦');
        }
      }
    });

    test('hints are emoji/number only (no letters to localise)', () {
      final letters = RegExp(r'[A-Za-zÄÖÜäöüß]');
      for (final type in BuildingType.values) {
        for (final a in BuildingActions.forType(type)) {
          expect(letters.hasMatch(a.hint(Difficulty.normal)), isFalse,
              reason: '${a.type}: ${a.hint(Difficulty.normal)}');
        }
      }
    });
  });

  group('Practice', () {
    test('levels at 10/30/80/200/400 uses, +10 % each', () {
      final p = Practice();
      expect(p.multiplier(Discipline.prayer), 1.0);
      var levelUps = 0;
      for (var i = 0; i < 400; i++) {
        if (p.record(Discipline.prayer)) levelUps++;
      }
      expect(levelUps, 5);
      expect(p.level(Discipline.prayer), 5);
      expect(p.multiplier(Discipline.prayer), closeTo(1.5, 1e-9));
      expect(p.multiplier(Discipline.bible), 1.0);
      expect(p.multiplier(null), 1.0);
    });

    test('is saved with PlayerProgress; old saves start at zero', () {
      final a = PlayerProgress();
      for (var i = 0; i < 12; i++) {
        a.practice.record(Discipline.bible);
      }
      final b = PlayerProgress()..loadFromJson(a.toJson());
      expect(b.practice.count(Discipline.bible), 12);
      expect(b.practice.level(Discipline.bible), 1);

      final old = PlayerProgress()..loadFromJson({'insight': 3});
      expect(old.practice.count(Discipline.bible), 0);
    });

    test('relationship bonus follows the session bonus, capped at +50 %', () {
      expect(Relationship.multiplier(0), 1.0);
      expect(Relationship.multiplier(2), closeTo(1.2, 1e-9));
      expect(Relationship.multiplier(7), closeTo(1.5, 1e-9));
    });
  });
}
