import 'dart:typed_data';

import '../models/cell_object.dart';
import 'district_selector.dart';
import 'special_building_registry.dart';

/// The whole city at a glance for the city map (playtest 2026-10-18): the
/// plan is computed from the same noise as the generator, so the map shows
/// places the pastor has never been to without generating their chunks.
class CityOverview {
  /// Half the side of the map in cells (city edge ~690 cells).
  static const int radius = 720;

  /// Cells per map pixel.
  static const int step = 4;

  static const int size = radius * 2 ~/ step;

  /// RGBA pixels, [size] × [size]; pixel (0,0) is cell (-radius, -radius).
  final Uint8List pixels;

  /// Special buildings: (cell x, cell y, type).
  final List<(int, int, BuildingType)> landmarks;

  CityOverview(this.pixels, this.landmarks);

  /// Heavy (~130 000 noise samples): run it off the UI thread.
  static CityOverview build(int seed) {
    final districts = DistrictSelector(seed: seed);
    final px = Uint8List(size * size * 4);
    for (int j = 0; j < size; j++) {
      for (int i = 0; i < size; i++) {
        final wx = -radius + i * step + step ~/ 2;
        final wy = -radius + j * step + step ~/ 2;
        final c = districts.isWater(wx, wy) ? _water : _colors[districts.getDistrictType(wx, wy)]!;
        final o = (j * size + i) * 4;
        px[o] = (c >> 16) & 0xFF;
        px[o + 1] = (c >> 8) & 0xFF;
        px[o + 2] = c & 0xFF;
        px[o + 3] = 0xFF;
      }
    }
    final registry = SpecialBuildingRegistry(seed: seed);
    final marks = registry
        .all(radius, districts.getDistrictType)
        .where((m) => !districts.isWater(m.$1, m.$2))
        .toList();
    return CityOverview(px, marks);
  }

  static const int _water = 0x2F6FB0;
  static const Map<DistrictType, int> _colors = {
    DistrictType.downtown: 0x8E8A99,
    DistrictType.commercial: 0xA39A8C,
    DistrictType.suburbs: 0xA9805F,
    DistrictType.outskirts: 0x7E9A62,
    DistrictType.industrial: 0x6F6A5E,
    DistrictType.waterfront: 0xC8B48A,
    DistrictType.park: 0x4F8A45,
    DistrictType.slums: 0x7A5844,
  };
}
