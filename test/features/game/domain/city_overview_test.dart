import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/city_overview.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/district_selector.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/special_building_registry.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';

void main() {
  test('the city map has every pixel and the main landmarks', () {
    final o = CityOverview.build(42);
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
