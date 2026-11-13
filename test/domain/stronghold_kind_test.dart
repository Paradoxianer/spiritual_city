import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/district_selector.dart';
import 'package:spiritual_city/src/features/game/domain/models/quarter.dart';
import 'package:spiritual_city/src/features/game/domain/models/stronghold_kind.dart';

void main() {
  const home = (500, 500);
  const hall = (0, 0);

  StrongholdKind kindIn(DistrictType d, Quarter q) =>
      StrongholdKind.of(q, district: (x, y) => d, homeCell: home, cityHallCell: hall);

  test('home quarter is always a plain fort', () {
    final q = Quarter.ofCell(home.$1, home.$2);
    expect(kindIn(DistrictType.downtown, q), StrongholdKind.fort);
  });

  test('city hall quarter is a great fortress', () {
    final q = Quarter.ofCell(hall.$1, hall.$2);
    expect(kindIn(DistrictType.suburbs, q), StrongholdKind.greatFortress);
  });

  test('downtown and slums are great fortresses, business quarters bulwarks', () {
    final q = Quarter.ofCell(200, -200);
    expect(kindIn(DistrictType.downtown, q), StrongholdKind.greatFortress);
    expect(kindIn(DistrictType.slums, q), StrongholdKind.greatFortress);
    expect(kindIn(DistrictType.commercial, q), StrongholdKind.bulwark);
    expect(kindIn(DistrictType.industrial, q), StrongholdKind.bulwark);
    expect(kindIn(DistrictType.suburbs, q), StrongholdKind.fort);
  });

  test('stronger kinds need more people praying together', () {
    expect(StrongholdKind.fort.unityNeeded, 1);
    expect(StrongholdKind.bulwark.unityNeeded, 2);
    expect(StrongholdKind.greatFortress.unityNeeded, 3);
    expect(StrongholdKind.greatFortress.energy, greaterThan(StrongholdKind.bulwark.energy));
    expect(StrongholdKind.bulwark.energy, greaterThan(StrongholdKind.fort.energy));
  });

  test('each further person praying adds damage', () {
    expect(StrongholdKind.unityFactor(1), 1.0);
    expect(StrongholdKind.unityFactor(3), closeTo(1.3, 1e-9));
  });
}
