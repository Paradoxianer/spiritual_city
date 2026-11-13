import 'dart:math';

import '../../../menu/domain/models/city_size.dart';
import '../models/quarter.dart';

/// The shape of the city for a [CitySize]: its rings, where the pastor
/// lives and which neighbourhoods belong to it. Derived only from the size,
/// so every player of a shared city gets the same one.
class CityLayout {
  final CitySize size;

  CityLayout(this.size);

  /// The city of the running game. Set when a game starts, before the
  /// world is generated; all generators read it.
  static CityLayout current = CityLayout(CitySize.metropolis);

  double get _s => size.radius / CitySize.metropolis.radius;

  // Rings (cells from the centre). The 🌆 big city keeps its old values; in
  // smaller ones the centre keeps room for the landmarks (city hall,
  // cathedral, station, university, museum lie within ~60 cells).
  double get downtownRadius => max(80 * _s, 25);
  double get commercialRadius => max(200 * _s, 62);
  double get suburbsRadius => max(420 * _s, commercialRadius * 1.25);
  double get outskirtsRadius => max(650 * _s, suburbsRadius * 1.15);
  double get ringNoiseAmp => max(40 * _s, 8);

  /// Zones of the civic buildings (hospital, school, …) shrink less than the
  /// city, so a village still has its mentors.
  double get zoneScale => max(sqrt(_s), 0.4);

  /// Where the pastor starts: on a boulevard (every 32nd row is one) in the
  /// middle of the suburbs; the pastor house is two cells north of it.
  (int, int) get spawnCell {
    if (size == CitySize.metropolis) return (220, 224);
    final d = (commercialRadius + suburbsRadius) / 2 / sqrt2;
    final y = max(1, (d / 32).round()) * 32;
    final x = ((d - 4) / 8).round() * 8 + 4; // a lot column, not a street
    return (x, y);
  }

  (int, int) get pastorHouseCell => (spawnCell.$1, spawnCell.$2 - 2);

  /// The neighbourhoods of the city: those that lie mostly in it (centre
  /// at most half a neighbourhood beyond the edge) – the pastor's home
  /// always among them. The goal: everyone in them a Christian.
  late final List<Quarter> quarters = () {
    final edge = outskirtsRadius + Quarter.sizeCells / 2;
    final n = (edge / Quarter.sizeCells).ceil() + 1;
    return [
      for (var qy = -n; qy <= n; qy++)
        for (var qx = -n; qx <= n; qx++)
          if (_inCity(Quarter(qx, qy), edge)) Quarter(qx, qy),
    ];
  }();

  static bool _inCity(Quarter q, double edge) {
    final (cx, cy) = q.centerCell;
    return cx * cx + cy * cy <= edge * edge;
  }

  /// Half the side of the city map in cells (a multiple of 4).
  int get mapRadius => ((outskirtsRadius + ringNoiseAmp + 30) / 4).ceil() * 4;
}
