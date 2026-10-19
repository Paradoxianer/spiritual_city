import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/actions/building_actions.dart';
import 'package:spiritual_city/src/features/game/domain/models/building_model.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_model.dart';

NPCModel _npc(String id, double faith) =>
    NPCModel(id: id, name: id, type: NPCType.citizen, homePosition: Vector2.zero())..faith = faith;

void main() {
  test('residents\' faith brightens the house (#168)', () {
    final b = BuildingModel(buildingId: 'b', type: BuildingType.house, residents: [_npc('a', 0), _npc('b', 0)]);
    expect(b.holiness, 0);
    final dark = b.accessChance(50);
    b.residents.first.faith = 80;
    b.residents.last.faith = 80;
    expect(b.holiness, 40);
    expect(b.accessChance(50), greaterThan(dark));
  });

  test('bigger efforts count more interactions', () {
    expect(BuildingModel.effortBonus(faithCost: 0, seconds: 2), 0);
    expect(BuildingModel.effortBonus(faithCost: 30, seconds: 0), 1);
    expect(BuildingModel.effortBonus(faithCost: 0, seconds: 12), 2);
  });

  test('every building type offers a way to raise its faith', () {
    for (final type in BuildingType.values) {
      final kinds = BuildingActions.forType(type).map((a) => a.type).toSet();
      expect(kinds.isNotEmpty, isTrue, reason: type.name);
    }
    expect(BuildingActions.forType(BuildingType.trainStation).map((a) => a.type), contains('pray'));
  });
}
