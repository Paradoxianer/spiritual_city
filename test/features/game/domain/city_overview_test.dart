import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/city_layout.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/city_overview.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/district_selector.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/special_building_registry.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/quarter.dart';
import 'package:spiritual_city/src/features/menu/domain/models/city_size.dart';

void main() {
  tearDown(() => CityLayout.current = CityLayout(CitySize.metropolis));

  // Playtest 2026-11-13: a city of every size has what the game needs.
  for (final size in CitySize.values) {
    test('$size: home in the suburbs, the start on a street, mentors in reach', () {
      final o = CityOverview.build((42, size));
      final layout = CityLayout.current;
      final d = DistrictSelector(seed: 42);
      final (hx, hy) = layout.pastorHouseCell;
      expect(d.getDistrictType(hx, hy), DistrictType.suburbs);
      expect(layout.spawnCell.$2 % 32, 0, reason: 'a boulevard');
      final types = o.landmarks.map((m) => m.$3).toSet();
      for (final t in [
        BuildingType.pastorHouse,
        BuildingType.cityHall,
        BuildingType.cathedral,
        BuildingType.church,
        BuildingType.hospital,
        BuildingType.library,
      ]) {
        expect(types, contains(t), reason: '$size $t');
      }
    });
  }

  test('the neighbourhoods of each size', () {
    final counts = {for (final s in CitySize.values) s: CityLayout(s).quarters.length};
    expect(counts[CitySize.village], inInclusiveRange(10, 20));
    expect(counts[CitySize.smallTown], inInclusiveRange(30, 50));
    expect(counts[CitySize.town], inInclusiveRange(70, 110));
    expect(counts[CitySize.metropolis], greaterThan(500));
    for (final size in CitySize.values) {
      final l = CityLayout(size);
      final (hx, hy) = l.pastorHouseCell;
      expect(l.quarters, contains(Quarter.ofCell(hx, hy)), reason: 'the home of $size');
    }
    // The big city stays as it was.
    final big = CityLayout(CitySize.metropolis);
    expect(big.pastorHouseCell, (220, 222));
    expect(big.mapRadius, 720);
  });

  test('the city map has every pixel and the main landmarks', () {
    final o = CityOverview.build((42, CitySize.metropolis));
    expect(o.pixels.length, CityOverview.size * CityOverview.size * 4);
    final types = o.landmarks.map((m) => m.$3).toSet();
    expect(types, contains(BuildingType.pastorHouse));
    expect(types, contains(BuildingType.church));
    expect(types, contains(BuildingType.hospital));
    expect(o.landmarks.where((m) => m.$3 == BuildingType.church).length, greaterThan(20));
  });

  test('every listed landmark is what the registry places there', () {
    const seed = 42;
    final reg = SpecialBuildingRegistry(seed: seed);
    final d = DistrictSelector(seed: seed);
    for (final (x, y, t) in reg.all(300, d.getDistrictType)) {
      expect(reg.getSpecialBuilding(x, y, d.getDistrictType(x, y)), t);
    }
  });
}
