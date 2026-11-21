import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/services/open_air_harvest.dart';

// Playtest 2026-11-21: at an open-air meeting the ready come to faith –
// a little harder than in a talk, carried by the pastor's faith and the
// Christians around.
void main() {
  test('only the ready, a little harder than a talk', () {
    expect(OpenAirHarvest.ready(55, 0), isFalse, reason: 'a talk would win them, the meeting not yet');
    expect(OpenAirHarvest.ready(65, 0), isTrue);
    expect(OpenAirHarvest.ready(45, 0.5), isTrue, reason: 'liberated ground helps');
    expect(OpenAirHarvest.ready(-20, 1), isFalse);
  });

  test('more faith and more Christians, more come to faith', () {
    expect(OpenAirHarvest.chance(340, 20), closeTo(0.68, 0.001));
    expect(OpenAirHarvest.chance(100, 20), lessThan(OpenAirHarvest.chance(340, 20)));
    expect(OpenAirHarvest.chance(340, 0), lessThan(OpenAirHarvest.chance(340, 20)));
    expect(OpenAirHarvest.chance(1000, 1000), 0.9);
  });
}
