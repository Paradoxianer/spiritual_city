import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/actions/building_actions.dart';
import 'package:spiritual_city/src/features/game/domain/interior/interior_layout.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';

Set<(int, int)> _reachable(InteriorLayout l) {
  final seen = <(int, int)>{l.door};
  final queue = [l.door];
  while (queue.isNotEmpty) {
    final (x, y) = queue.removeLast();
    for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
      final n = (x + dx, y + dy);
      if (!l.isWalkable(n.$1, n.$2) || !seen.add(n)) continue;
      queue.add(n);
    }
  }
  return seen;
}

void main() {
  test('every building type gets a walkable room with all its stations', () {
    for (final type in BuildingType.values) {
      final actions = [
        for (final a in BuildingActions.forType(type)) a.type,
        if (type == BuildingType.pastorHouse) ...[
          InteriorLayout.churchOverview,
          InteriorLayout.upgrades,
        ],
      ];
      for (var i = 0; i < 40; i++) {
        final l = InteriorLayout.generate(
          buildingId: 'b_${i * 8}_${i * 16}',
          type: type,
          actions: actions,
          residents: 3,
        );
        final reach = _reachable(l);
        expect(reach.contains(l.entry), isTrue, reason: '$type #$i entry');
        expect(reach.contains(l.find), isTrue, reason: '$type #$i find');
        for (final a in actions.toSet()) {
          final st = l.stations.where((f) => f.action == a);
          expect(st, isNotEmpty, reason: '$type #$i station $a');
          final f = st.first;
          final near = reach.any((c) => f.distanceTo(c.$1 + 0.5, c.$2 + 0.5) < 1.0);
          expect(near, isTrue, reason: '$type #$i station $a reachable');
        }
        for (final s in l.residentSpots) {
          expect(reach.contains(s), isTrue, reason: '$type #$i resident');
        }
      }
    }
  });

  test('the same building always gets the same room', () {
    InteriorLayout gen() => InteriorLayout.generate(
        buildingId: 'b_40_80', type: BuildingType.house, actions: const ['pray', 'houseVisit']);
    final a = gen(), b = gen();
    expect(a.width, b.width);
    expect([for (final f in a.furniture) '${f.kind}${f.x},${f.y}'],
        [for (final f in b.furniture) '${f.kind}${f.x},${f.y}']);
  });
}
