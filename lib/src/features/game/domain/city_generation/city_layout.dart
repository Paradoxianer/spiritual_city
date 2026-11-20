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

  late final Set<Quarter> _quarterSet = quarters.toSet();

  /// [q] is one of the city's neighbourhoods.
  bool containsQuarter(Quarter q) => _quarterSet.contains(q);

  /// The cell lies in the city – beyond it only forest and the river
  /// around it (playtest 2026-11-20: discovered land without people could
  /// never be won and lowered the progress).
  bool containsCell(int x, int y) => containsQuarter(Quarter.ofCell(x, y));

  /// The chunk belongs to the city (a neighbourhood is whole chunks).
  bool containsChunk(int cx, int cy) => containsQuarter(Liberation.quarterOfChunk(cx, cy));

  /// A neighbourhood key `'qx,qy'` of the city.
  bool containsQuarterKey(String key) {
    final parts = key.split(',');
    if (parts.length != 2) return false;
    final qx = int.tryParse(parts[0]), qy = int.tryParse(parts[1]);
    return qx != null && qy != null && containsQuarter(Quarter(qx, qy));
  }

  /// A person lives in the city: their id names their house
  /// (`npc_b_<x>_<y>_<i>`); other ids count as in it.
  bool containsNpcId(String id) {
    final m = _npcHome.firstMatch(id);
    if (m == null) return true;
    return containsCell(int.parse(m[1]!), int.parse(m[2]!));
  }

  static final RegExp _npcHome = RegExp(r'^npc_b_(-?\d+)_(-?\d+)_');

  /// Cells from the cell to the nearest cell of the city (0 inside it),
  /// at most [Quarter.sizeCells] – for the border's river.
  int edgeDistance(int x, int y) {
    final q = Quarter.ofCell(x, y);
    if (containsQuarter(q)) return 0;
    const n = Quarter.sizeCells;
    var best = n;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final o = Quarter(q.qx + dx, q.qy + dy);
        if (!containsQuarter(o)) continue;
        final ox = x - x.clamp(o.qx * n, o.qx * n + n - 1);
        final oy = y - y.clamp(o.qy * n, o.qy * n + n - 1);
        best = min(best, max(ox.abs(), oy.abs()));
      }
    }
    return best;
  }

  /// The river around the city, a few cells into the forest (Ps 125,2).
  bool isBorderRiver(int x, int y) {
    final d = edgeDistance(x, y);
    return d >= 3 && d <= 6;
  }

  static bool _inCity(Quarter q, double edge) {
    final (cx, cy) = q.centerCell;
    return cx * cx + cy * cy <= edge * edge;
  }

  /// Half the side of the city map in cells (a multiple of 4).
  int get mapRadius => ((outskirtsRadius + ringNoiseAmp + 30) / 4).ceil() * 4;
}
