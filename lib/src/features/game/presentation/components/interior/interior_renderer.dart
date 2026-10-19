import 'dart:ui';

import 'package:flame/cache.dart';

import '../../../domain/interior/interior_layout.dart';

/// Draws an [InteriorLayout] with Kenney's Roguelike Indoors (furniture) and
/// Roguelike RPG Pack (floors, shelves, decor) sheets, both CC0. Walls are
/// drawn in code in the same beige as Kenney's indoor sample.
abstract final class InteriorRenderer {
  static const String indoorAsset = 'kenney/roguelike_indoors/tilesheet.png';
  static const String rpgAsset = 'kenney/roguelike_rpg/tilesheet.png';

  /// Cell size in world pixels (same as the city).
  static const double cell = 32.0;

  static Image? _indoor;
  static Image? _rpg;

  static bool get ready => _indoor != null && _rpg != null;

  static Future<void> load(Images images) async {
    try {
      _indoor = await images.load(indoorAsset);
      _rpg = await images.load(rpgAsset);
    } catch (_) {
      _indoor = null; // the room falls back to plain shapes
      _rpg = null;
    }
  }

  static final Paint _paint = Paint()..filterQuality = FilterQuality.none;
  static final Paint _fill = Paint();

  static const Color _wallTop = Color(0xFFD8C69C);
  static const Color _wallEdge = Color(0xFF8C7350);
  static const Color _wallFace = Color(0xFFF0E4C3);
  static const Color _baseboard = Color(0xFFB59B6E);

  /// Records the whole room once; it never changes while inside.
  static Picture record(InteriorLayout l) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (int y = 0; y < l.height; y++) {
      for (int x = 0; x < l.width; x++) {
        _tile(canvas, l, x, y);
      }
    }
    // Floor-level pieces first, then furniture, then wall decor.
    for (final f in l.furniture.where((f) => !f.kind.blocks && !f.kind.onWall)) {
      _furniture(canvas, f, highlightGreen: f.action == 'prayerCircle');
    }
    for (final f in l.furniture.where((f) => f.kind.blocks && !f.kind.onWall)) {
      _furniture(canvas, f);
    }
    for (final f in l.furniture.where((f) => f.kind.onWall)) {
      _furniture(canvas, f);
    }
    return recorder.endRecording();
  }

  static Rect _rect(int x, int y, [int w = 1, int h = 1]) =>
      Rect.fromLTWH(x * cell, y * cell, w * cell, h * cell);

  static void _tile(Canvas c, InteriorLayout l, int x, int y) {
    final r = _rect(x, y);
    switch (l.tileAt(x, y)) {
      case InteriorTile.floor:
        _floor(c, l.floor, r);
      case InteriorTile.door:
        _floor(c, l.floor, r);
        _fill.color = const Color(0xFF6B4A2B);
        c.drawRect(Rect.fromLTWH(r.left + 3, r.top + 6, r.width - 6, r.height - 10), _fill);
        _fill.color = const Color(0xFF9C7A4E);
        c.drawRect(Rect.fromLTWH(r.left + 6, r.top + 9, r.width - 12, r.height - 16), _fill);
      case InteriorTile.wallFace:
        _fill.color = _wallFace;
        c.drawRect(r, _fill);
        _fill.color = _baseboard;
        c.drawRect(Rect.fromLTWH(r.left, r.bottom - 5, r.width, 5), _fill);
        _fill.color = const Color(0x22000000);
        c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 4), _fill);
      case InteriorTile.wall:
        _fill.color = _wallTop;
        c.drawRect(r, _fill);
        // Dark edge towards the inside of the room.
        _fill.color = _wallEdge;
        bool inside(int dx, int dy) {
          final t = l.tileAt(x + dx, y + dy);
          return t != InteriorTile.wall;
        }
        if (inside(0, 1)) c.drawRect(Rect.fromLTWH(r.left, r.bottom - 3, r.width, 3), _fill);
        if (inside(0, -1)) c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 3), _fill);
        if (inside(1, 0)) c.drawRect(Rect.fromLTWH(r.right - 3, r.top, 3, r.height), _fill);
        if (inside(-1, 0)) c.drawRect(Rect.fromLTWH(r.left, r.top, 3, r.height), _fill);
    }
  }

  static void _floor(Canvas c, FloorStyle style, Rect r) {
    final (col, row) = switch (style) {
      FloorStyle.wood => (8, 2),
      FloorStyle.stone => (7, 2),
      FloorStyle.tiles => (6, 2),
    };
    if (!_sprite(c, _rpg, col, row, 1, 1, r)) {
      _fill.color = const Color(0xFFB08458);
      c.drawRect(r, _fill);
    }
  }

  /// Copies a block of tiles (17-px pitch, 1-px gaps) into [dst].
  static bool _sprite(Canvas c, Image? sheet, int col, int row, int w, int h, Rect dst) {
    if (sheet == null) return false;
    for (int j = 0; j < h; j++) {
      for (int i = 0; i < w; i++) {
        final src = Rect.fromLTWH((col + i) * 17.0, (row + j) * 17.0, 16, 16);
        final d = Rect.fromLTWH(
            dst.left + i * dst.width / w, dst.top + j * dst.height / h, dst.width / w, dst.height / h);
        c.drawImageRect(sheet, src, d, _paint);
      }
    }
    return true;
  }

  static void _furniture(Canvas c, Furniture f, {bool highlightGreen = false}) {
    final k = f.kind;
    final r = _rect(f.x, f.y, k.w, k.h);
    final alt = (f.x + f.y).isEven;
    final ok = switch (k) {
      FurnitureKind.bed => _sprite(c, _indoor, 14, 6, 2, 2, r),
      FurnitureKind.hospitalBed => _sprite(c, _indoor, 12, 6, 2, 2, r),
      FurnitureKind.diningTable => _sprite(c, _indoor, 0, 0, 3, 2, r),
      FurnitureKind.roundTable => _sprite(c, _indoor, 3, 0, 2, 2, r),
      FurnitureKind.chair => _sprite(c, _indoor, 0, 2, 1, 1, r),
      FurnitureKind.armchair => _sprite(c, _indoor, 25, 11, 1, 1, r),
      FurnitureKind.bookshelf => _sprite(c, _rpg, 46, 14, 2, 1, r),
      FurnitureKind.lectern =>
        _sprite(c, _indoor, 7, 0, 1, 1, r) && _sprite(c, _rpg, 51, 15, 1, 1, r),
      FurnitureKind.desk =>
        _sprite(c, _indoor, 4, 4, 2, 1, r) && _sprite(c, _rpg, 41, 15, 1, 1, _rect(f.x, f.y)),
      FurnitureKind.altar => _sprite(c, _indoor, 0, 9, 3, 1, r) &&
          _sprite(c, _rpg, 48, 15, 1, 1, _rect(f.x + 1, f.y)),
      FurnitureKind.pew => _sprite(c, _indoor, 4, 8, 4, 1, r),
      FurnitureKind.piano => _sprite(c, _indoor, 23, 8, 2, 2, r),
      FurnitureKind.counter => _sprite(c, _indoor, 0, 12, 1, 1, r),
      FurnitureKind.stove => _sprite(c, _indoor, 14, 14, 1, 1, r),
      FurnitureKind.sink => _sprite(c, _indoor, 8, 12, 1, 1, r),
      FurnitureKind.goodsShelf =>
        alt ? _sprite(c, _indoor, 5, 12, 1, 1, r) : _sprite(c, _indoor, 6, 13, 1, 1, r),
      FurnitureKind.dresser => _sprite(c, _indoor, 6, 5, 1, 1, r),
      FurnitureKind.plant =>
        alt ? _sprite(c, _indoor, 16, 0, 1, 1, r) : _sprite(c, _indoor, 17, 0, 1, 1, r),
      FurnitureKind.candelabra => _sprite(c, _indoor, 16, 7, 1, 1, r),
      FurnitureKind.barrel => _sprite(c, _rpg, 23, 0, 1, 1, r),
      FurnitureKind.bench => _sprite(c, _indoor, 10, 3, 2, 1, r),
      FurnitureKind.prayerCross => _prayerCross(c, r),
      FurnitureKind.fireplace => _sprite(c, _rpg, 54, 8, 1, 1, r),
      FurnitureKind.rug => _rug(c, r, highlightGreen),
      FurnitureKind.carpet => _carpet(c, r),
      FurnitureKind.painting => _sprite(c, _indoor, 19, 12, 1, 1, r.deflate(3)),
      FurnitureKind.window => _sprite(c, _rpg, 40, 0, 1, 1, r.deflate(2)),
      FurnitureKind.cross => _sprite(c, _rpg, 53, 9, 1, 1, r),
      FurnitureKind.banner => _sprite(c, _rpg, 50, 7, 1, 1, r),
    };
    if (!ok) {
      _fill.color = const Color(0xFF8B6A45);
      c.drawRRect(RRect.fromRectAndRadius(r.deflate(3), const Radius.circular(4)), _fill);
    }
  }

  /// Drawn rug (the sheet's rugs read as tables at this size).
  static bool _rug(Canvas c, Rect r, bool green) {
    final inner = r.deflate(5);
    _fill.color = green ? const Color(0xFF3E8E5A) : const Color(0xFFC0602E);
    c.drawRRect(RRect.fromRectAndRadius(inner, const Radius.circular(3)), _fill);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFF2E3BC);
    c.drawRect(inner.deflate(5), border);
    _fill.color = const Color(0xFFF2E3BC);
    for (double x = inner.left + 2; x < inner.right - 1; x += 4) {
      c.drawRect(Rect.fromLTWH(x, inner.top - 3, 2, 3), _fill);
      c.drawRect(Rect.fromLTWH(x, inner.bottom, 2, 3), _fill);
    }
    return true;
  }

  /// A standing wooden cross on a small step, a candle at its foot.
  static bool _prayerCross(Canvas c, Rect r) {
    _fill.color = const Color(0xFF8C6A45);
    c.drawRect(Rect.fromLTWH(r.left + 6, r.bottom - 7, r.width - 12, 5), _fill);
    _fill.color = const Color(0xFF6B4A2B);
    c.drawRect(Rect.fromLTWH(r.center.dx - 2.5, r.top + 2, 5, r.height - 8), _fill);
    c.drawRect(Rect.fromLTWH(r.left + 8, r.top + 8, r.width - 16, 5), _fill);
    _fill.color = const Color(0xFFB08458);
    c.drawRect(Rect.fromLTWH(r.center.dx - 1.5, r.top + 3, 1.5, r.height - 10), _fill);
    _fill.color = const Color(0xFFFFE082);
    c.drawCircle(Offset(r.left + 7, r.bottom - 10), 2, _fill);
    return true;
  }

  static bool _carpet(Canvas c, Rect r) {
    _fill.color = const Color(0xFFB0322E);
    c.drawRect(Rect.fromLTWH(r.left + 4, r.top, r.width - 8, r.height), _fill);
    _fill.color = const Color(0xFFE2B33C);
    c.drawRect(Rect.fromLTWH(r.left + 4, r.top, 2, r.height), _fill);
    c.drawRect(Rect.fromLTWH(r.right - 6, r.top, 2, r.height), _fill);
    return true;
  }
}
