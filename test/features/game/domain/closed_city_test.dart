import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/core/utils/seed_manager.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/city_generator.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/city_layout.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_grid.dart';
import 'package:spiritual_city/src/features/game/domain/models/quarter.dart';
import 'package:spiritual_city/src/features/menu/domain/models/city_size.dart';

void main() {
  tearDown(() => CityLayout.current = CityLayout(CitySize.metropolis));

  // Playtest 2026-11-20: the city is closed – beyond its neighbourhoods
  // only forest and a river, nobody walks there, nobody lives there.
  test('beyond the city: forest with a river, not walkable, no houses', () {
    final layout = CityLayout.current = CityLayout(CitySize.village);
    final grid = CityGrid();
    final gen = CityGenerator(SeedManager(42));
    var water = 0, forest = 0;
    for (var cy = -10; cy < 10; cy++) {
      for (var cx = -10; cx < 10; cx++) {
        gen.generateChunk(grid.getOrCreateChunk(cx, cy));
      }
    }
    for (var y = -160; y < 160; y++) {
      for (var x = -160; x < 160; x++) {
        if (layout.containsCell(x, y)) continue;
        final data = grid.getCell(x, y)!.data;
        expect(data, isA<NatureData>(), reason: '$x,$y');
        expect(grid.isWalkable(x, y), isFalse, reason: '$x,$y');
        if ((data as NatureData).type == NatureType.water) water++;
        if (data.type == NatureType.forest) forest++;
      }
    }
    expect(water, greaterThan(0));
    expect(forest, greaterThan(water));
  });

  test('the border follows the neighbourhoods', () {
    final layout = CityLayout(CitySize.village);
    expect(layout.quarters, hasLength(16));
    expect(layout.containsCell(0, 0), isTrue);
    expect(layout.edgeDistance(0, 0), 0);
    expect(layout.edgeDistance(96, 0), 1); // first cell beyond quarter (1,0)
    expect(layout.edgeDistance(100, 10), 5);
    expect(layout.isBorderRiver(100, 10), isTrue);
    expect(layout.edgeDistance(96 + Quarter.sizeCells * 2, 0), Quarter.sizeCells);
    expect(layout.containsNpcId('npc_b_10_-20_0'), isTrue);
    expect(layout.containsNpcId('npc_b_120_72_3'), isFalse);
    expect(layout.containsQuarterKey('2,1'), isFalse);
    expect(layout.containsQuarterKey('-2,-2'), isTrue);
  });
}
