import 'dart:ui';

import 'package:flame/cache.dart';

import '../../domain/city_generation/district_selector.dart';
import '../../domain/models/cell_object.dart';
import '../../domain/models/city_cell.dart';

/// Draws the physical city with the Kenney "Roguelike Modern City" tiles
/// (CC0, assets/LICENSES.md; #18).
///
/// Each lot is one building (all its cells share a `buildingId`), so the
/// renderer looks at the four neighbours of a cell and composes:
/// - a continuous roof with a rim along the building's outline (from the
///   sheet's 2×2 roof block, split into 8 px quarters),
/// - one row of facade at the building's south side (3/4 view) with
///   windows and a door,
/// - one landmark symbol per special building (✝, hospital cross, …).
///
/// Roads become asphalt, lot borders become pavement, nature becomes grass
/// with trees. If the sheet failed to load, [CityTileRenderer] stays the
/// fallback.
abstract final class KenneyCityRenderer {
  static const String asset = 'kenney/roguelike_modern_city/tilemap_packed.png';
  static const double _t = 16; // source tile size

  static Image? _sheet;
  static bool get ready => _sheet != null;

  static final Paint _paint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  static Future<void> load(Images images) async {
    if (_sheet != null) return;
    try {
      _sheet = await images.load(asset);
    } catch (_) {
      _sheet = null;
    }
  }

  // ── Sheet coordinates (column, row) ──────────────────────────────────────

  static const (int, int) _pavement = (1, 20);
  static const (int, int) _asphalt = (10, 20);
  static const (int, int) _grass = (0, 24);
  static const List<(int, int)> _bushes = [(31, 13), (32, 13), (33, 13), (34, 13), (36, 13)];
  static const (int, int) _tombstone = (28, 7);
  static const List<(int, int)> _roofDecor = [(25, 14), (26, 14), (27, 14)];

  static const _Material _red = _Material(roof: (4, 2), plain: (6, 0), wall: [0, 1, 2, 3]);
  static const _Material _grey = _Material(roof: (12, 2), plain: (14, 0), wall: [4, 5, 6, 7]);
  static const _Material _light = _Material(roof: (20, 2), plain: (22, 0), wall: [4, 5, 6, 7]);
  static const _Material _sand = _Material(roof: (28, 2), plain: (30, 0), wall: [8, 9, 10, 11]);

  static _Material _materialFor(BuildingType t) => switch (t) {
        BuildingType.house || BuildingType.pastorHouse || BuildingType.church || BuildingType.school => _red,
        BuildingType.apartment || BuildingType.library || BuildingType.museum || BuildingType.cathedral => _sand,
        BuildingType.shop || BuildingType.supermarket || BuildingType.mall || BuildingType.postOffice => _sand,
        BuildingType.skyscraper ||
        BuildingType.office ||
        BuildingType.hospital ||
        BuildingType.cityHall ||
        BuildingType.university ||
        BuildingType.trainStation =>
          _light,
        _ => _grey,
      };

  /// Window drawn on a facade cell (brown frame on brick, grey elsewhere).
  static (int, int) _windowFor(_Material m, int h) =>
      identical(m, _red) ? (h.isEven ? (25, 16) : (25, 15)) : (h.isEven ? (25, 19) : (25, 18));

  static (int, int) _doorFor(BuildingType t) => switch (t) {
        BuildingType.house || BuildingType.pastorHouse || BuildingType.apartment => (20, 27),
        BuildingType.shop || BuildingType.supermarket || BuildingType.mall => (23, 27),
        BuildingType.church || BuildingType.cathedral || BuildingType.school => (26, 27),
        _ => (23, 21),
      };

  // ── Public API ────────────────────────────────────────────────────────────

  /// Renders the cell at world position ([wx], [wy]) into [rect].
  ///
  /// [lookup] returns neighbouring cells (also across chunk borders);
  /// [typeOf] the type the game uses for a building (one per lot).
  static void renderCell(
    Canvas canvas,
    Rect rect,
    CityCell cell,
    int wx,
    int wy,
    CityCell? Function(int wx, int wy) lookup,
    BuildingType Function(BuildingData data) typeOf,
  ) {
    final data = cell.data;
    if (data == null) {
      _tile(canvas, _pavement, rect);
    } else if (data is RoadData) {
      _road(canvas, rect, data);
    } else if (data is NatureData) {
      _nature(canvas, rect, data, wx, wy);
    } else if (data is BuildingData) {
      _building(canvas, rect, cell, data, wx, wy, lookup, typeOf(data));
    }
  }

  // ── Ground ────────────────────────────────────────────────────────────────

  static final Paint _laneLine = Paint()..color = const Color(0xFFE8E8E8);
  static final Paint _water = Paint()..color = const Color(0xFF4FA4D9);
  static final Paint _waterRipple = Paint()..color = const Color(0x55FFFFFF);

  static void _road(Canvas canvas, Rect r, RoadData road) {
    _tile(canvas, _asphalt, r);
    if (road.type == RoadType.small || road.isIntersection) return;
    final c = road.connections;
    final vertical = (c & 5) != 0 && (c & 10) == 0;
    final horizontal = (c & 10) != 0 && (c & 5) == 0;
    final u = r.width / 16;
    if (vertical) {
      canvas.drawRect(Rect.fromLTWH(r.center.dx - u / 2, r.top + 3 * u, u, 10 * u), _laneLine);
    } else if (horizontal) {
      canvas.drawRect(Rect.fromLTWH(r.left + 3 * u, r.center.dy - u / 2, 10 * u, u), _laneLine);
    }
  }

  static void _nature(Canvas canvas, Rect r, NatureData n, int wx, int wy) {
    final h = _hash(wx, wy);
    switch (n.type) {
      case NatureType.water:
        canvas.drawRect(r, _water);
        final u = r.width / 16;
        canvas.drawRect(Rect.fromLTWH(r.left + (h % 8) * u, r.top + 4 * u, 4 * u, u), _waterRipple);
        canvas.drawRect(Rect.fromLTWH(r.left + ((h >> 3) % 8 + 4) * u, r.top + 11 * u, 3 * u, u), _waterRipple);
      case NatureType.tree:
        _tile(canvas, _grass, r);
        _tile(canvas, _bushes[h % _bushes.length], r);
      case NatureType.park:
        _tile(canvas, _grass, r);
        if (h % 12 == 0) _tile(canvas, _bushes[(h >> 4) % _bushes.length], r);
    }
  }

  // ── Buildings ─────────────────────────────────────────────────────────────

  static final Paint _goldRim = Paint()
    ..color = const Color(0xFFFFC107)
    ..style = PaintingStyle.stroke;
  static final Paint _pitchLine = Paint()..color = const Color(0xCCFFFFFF);
  static final Paint _stripe = Paint()..color = const Color(0x22000000);

  static void _building(
    Canvas canvas,
    Rect r,
    CityCell cell,
    BuildingData data,
    int wx,
    int wy,
    CityCell? Function(int wx, int wy) lookup,
    BuildingType type,
  ) {
    bool same(int dx, int dy) {
      final d = lookup(wx + dx, wy + dy)?.data;
      return d is BuildingData && d.buildingId == data.buildingId;
    }

    final n = same(0, -1), s = same(0, 1), w = same(-1, 0), e = same(1, 0);
    final h = _hash(wx, wy);

    // Open-air lots: grass with their own furniture.
    if (type == BuildingType.cemetery) {
      _tile(canvas, _grass, r);
      if ((wx + wy).isEven) _tile(canvas, _tombstone, r);
      return;
    }
    if (type == BuildingType.stadium) {
      _tile(canvas, _grass, r);
      if (wx.isEven) canvas.drawRect(r, _stripe);
      final u = r.width / 16;
      if (!n) canvas.drawRect(Rect.fromLTWH(r.left, r.top + u, r.width, u), _pitchLine);
      if (!s) canvas.drawRect(Rect.fromLTWH(r.left, r.bottom - 2 * u, r.width, u), _pitchLine);
      if (!w) canvas.drawRect(Rect.fromLTWH(r.left + u, r.top, u, r.height), _pitchLine);
      if (!e) canvas.drawRect(Rect.fromLTWH(r.right - 2 * u, r.top, u, r.height), _pitchLine);
      return;
    }

    final m = _materialFor(type);
    final pitch = _lotPitch(cell.district);
    final (rootX, rootY) = _lotRoot(data.buildingId, wx, wy, pitch);
    final isFacade = !s && n; // south side of a building at least 2 deep

    if (isFacade) {
      // Facade row: wall tiles with a pavement base, windows, one door.
      final fw = same(-1, 0) && !same(-1, 1);
      final fe = same(1, 0) && !same(1, 1);
      final col = switch ((fw, fe)) {
        (false, false) => m.wall[0],
        (false, true) => m.wall[1],
        (true, true) => m.wall[2],
        (true, false) => m.wall[3],
      };
      _tile(canvas, (col, 10), r);
      if (wx - rootX == pitch ~/ 2) {
        _tile(canvas, _doorFor(type), r);
      } else {
        _tile(canvas, _windowFor(m, h), r.deflate(r.width * 0.12).translate(0, -r.height * 0.1));
      }
      return;
    }

    // Roof: the rim follows the outline; a facade below closes it.
    final top = !n, left = !w, right = !e;
    final bottom = !s || !same(0, 2); // below is the facade row
    _roof(canvas, r, m, top: top, left: left, right: right, bottom: bottom);
    if (!top && !left && !right && !bottom && h % 9 == 0) {
      _tile(canvas, _roofDecor[(h >> 4) % _roofDecor.length], r);
    }

    if (type == BuildingType.pastorHouse) {
      // Golden rim along the outline: the home base stands out.
      final u = r.width / 16;
      _goldRim.strokeWidth = 1.5 * u;
      final g = r.deflate(0.75 * u);
      if (top) canvas.drawLine(g.topLeft, g.topRight, _goldRim);
      if (left) canvas.drawLine(g.topLeft, g.bottomLeft, _goldRim);
      if (right) canvas.drawLine(g.topRight, g.bottomRight, _goldRim);
    }

    // One landmark symbol in the middle of the roof.
    if (wx - rootX == pitch ~/ 2 && wy - rootY == (pitch - 1) ~/ 2) {
      _landmark(canvas, r, type);
    }
  }

  /// Composes a roof cell from the quarters of the material's 2×2 block so
  /// the rim appears exactly on the requested sides.
  static void _roof(Canvas canvas, Rect r, _Material m,
      {required bool top, required bool left, required bool right, required bool bottom}) {
    final (bx, by) = m.roof;
    final half = r.width / 2;
    // (source tile, source quarter) per destination quarter, or plain.
    void q(int qx, int qy, bool rimH, bool rimV) {
      final dst = Rect.fromLTWH(r.left + qx * half, r.top + qy * half, half, half);
      if (!rimH && !rimV) {
        _src(canvas, m.plain.$1 * _t + qx * 8, m.plain.$2 * _t + qy * 8, dst);
        return;
      }
      // Tile of the 2×2 block that holds this corner/edge.
      final tx = bx + qx, ty = by + qy;
      // Quarter inside that tile: the rim side if present, else the inner side.
      final sx = rimH ? qx : 1 - qx;
      final sy = rimV ? qy : 1 - qy;
      _src(canvas, tx * _t + sx * 8, ty * _t + sy * 8, dst);
    }

    q(0, 0, left, top);
    q(1, 0, right, top);
    q(0, 1, left, bottom);
    q(1, 1, right, bottom);
  }

  static final Paint _symbolGold = Paint()..color = const Color(0xFFFFC107);
  static final Paint _symbolRed = Paint()..color = const Color(0xFFE53935);
  static final Paint _symbolWhite = Paint()..color = const Color(0xFFFFFFFF);
  static final Paint _symbolBlue = Paint()..color = const Color(0xFF1E3A8A);
  static final Paint _symbolShadow = Paint()..color = const Color(0x66000000);

  static void _landmark(Canvas canvas, Rect r, BuildingType type) {
    final u = r.width / 16;
    void cross(Paint p, {double tall = 14}) {
      final c = r.center;
      final v = Rect.fromCenter(center: c, width: 3 * u, height: tall * u);
      final hz = Rect.fromCenter(center: c.translate(0, -tall * u * 0.18), width: 9 * u, height: 3 * u);
      canvas.drawRect(v.translate(u, u), _symbolShadow);
      canvas.drawRect(hz.translate(u, u), _symbolShadow);
      canvas.drawRect(v, p);
      canvas.drawRect(hz, p);
    }

    switch (type) {
      case BuildingType.pastorHouse:
      case BuildingType.church:
      case BuildingType.cathedral:
        cross(_symbolGold, tall: type == BuildingType.cathedral ? 16 : 14);
      case BuildingType.hospital:
        canvas.drawRect(Rect.fromCenter(center: r.center, width: 14 * u, height: 14 * u), _symbolWhite);
        canvas.drawRect(Rect.fromCenter(center: r.center, width: 4 * u, height: 11 * u), _symbolRed);
        canvas.drawRect(Rect.fromCenter(center: r.center, width: 11 * u, height: 4 * u), _symbolRed);
      case BuildingType.policeStation:
        canvas.drawCircle(r.center, 6 * u, _symbolBlue);
        canvas.drawCircle(r.center, 3 * u, _symbolGold);
      case BuildingType.fireStation:
        canvas.drawCircle(r.center, 6 * u, _symbolRed);
      default:
        break;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Lot pitch per district (mirrors `LotGenerator._gridPitch`).
  /// Whether the facade at ([wx], [wy]) shows the lot's door – walking
  /// into it enters the building (playtest 2026-10-18).
  static bool isDoor(CityCell? Function(int wx, int wy) lookup, int wx, int wy) {
    final cell = lookup(wx, wy);
    final data = cell?.data;
    if (cell == null || data is! BuildingData) return false;
    if (data.type == BuildingType.cemetery || data.type == BuildingType.stadium) return false;
    bool same(int dy) {
      final d = lookup(wx, wy + dy)?.data;
      return d is BuildingData && d.buildingId == data.buildingId;
    }

    if (same(1) || !same(-1)) return false; // not the facade row
    final pitch = _lotPitch(cell.district);
    final (rootX, _) = _lotRoot(data.buildingId, wx, wy, pitch);
    return wx - rootX == pitch ~/ 2;
  }

  static int _lotPitch(DistrictType? d) => switch (d) {
        DistrictType.slums => 6,
        DistrictType.outskirts => 10,
        _ => 8,
      };

  /// Lot root from the building id (`b_<x>_<y>`), else from the pitch.
  static (int, int) _lotRoot(String id, int wx, int wy, int pitch) {
    final parts = id.split('_');
    if (parts.length == 3) {
      final x = int.tryParse(parts[1]), y = int.tryParse(parts[2]);
      if (x != null && y != null) return (x, y);
    }
    return ((wx ~/ pitch) * pitch, (wy ~/ pitch) * pitch);
  }

  /// Well-mixed per-cell hash (neighbouring cells differ).
  static int _hash(int x, int y) {
    var h = (x * 73856093) ^ (y * 19349663);
    h = (h ^ (h >> 13)) * 1274126177;
    return (h ^ (h >> 16)) & 0x7fffffff;
  }

  static void _tile(Canvas canvas, (int, int) t, Rect dst) =>
      _src(canvas, t.$1 * _t, t.$2 * _t, dst, size: _t);

  static void _src(Canvas canvas, double sx, double sy, Rect dst, {double size = 8}) {
    canvas.drawImageRect(_sheet!, Rect.fromLTWH(sx, sy, size, size), dst, _paint);
  }
}

class _Material {
  /// Top-left tile of the 2×2 roof block.
  final (int, int) roof;

  /// A plain roof tile for the inside.
  final (int, int) plain;

  /// Facade columns: single, left, middle, right (row 10).
  final List<int> wall;

  const _Material({required this.roof, required this.plain, required this.wall});
}
