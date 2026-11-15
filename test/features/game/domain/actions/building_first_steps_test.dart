import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/actions/building_actions.dart';
import 'package:spiritual_city/src/features/game/domain/actions/game_action.dart';
import 'package:spiritual_city/src/features/game/domain/actions/resource.dart';
import 'package:spiritual_city/src/features/game/domain/models/building_model.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/services/building_interaction_service.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

/// Playtest 2026-11-15: in the hospital 👂 needed four visits first, but
/// there was nothing to do without 📦 – every building must offer a first
/// step on the very first visit, open and without 📦, that actually counts.
/// Plenty of everything – but no 📦.
class _NoMaterials implements ResourceWallet {
  @override
  double amountOf(Resource r) => r == Resource.materials ? 0 : 1000;
}

void main() {
  for (final type in BuildingType.values) {
    if (type == BuildingType.pastorHouse) continue;
    test('$type: a first step that is open, needs no 📦 and counts', () {
      final b = BuildingModel(buildingId: 'b', type: type);
      final first = [
        for (final a in BuildingActions.forType(type))
          if (a.needsSkill == null &&
              a.availability(b, _NoMaterials(), Difficulty.normal) is AvailableNow)
            a,
      ];
      expect(first, isNotEmpty, reason: 'nothing to do on the first visit');
      // Each of them really runs in the service and counts as a visit.
      for (final a in first) {
        final fresh = BuildingModel(buildingId: 'b', type: type);
        final r = BuildingInteractionService().performAction(a.type, fresh, 100);
        expect(r.reactionEmoji, isNot('❓'), reason: '${a.type} not handled');
        expect(fresh.interactionCount, greaterThan(0), reason: '${a.type} does not count');
      }
    });
  }
}
