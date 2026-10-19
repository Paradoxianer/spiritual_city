import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';

/// Kenney "RPG Urban Pack" figures (CC0, assets/LICENSES.md) for the pastor
/// and the people of the city (#13/#18, release_roadmap.md §3.7).
///
/// Sheet layout (16 px tiles): the four rightmost columns hold 6 figures,
/// each 3 rows (idle, step, step) × 4 directions (left, down, up, right).
abstract final class CharacterSprites {
  static const String asset = 'kenney/rpg_urban_pack/tilemap_packed.png';
  static const int figures = 6;

  /// The grey-haired, bearded figure is the pastor.
  static const int pastor = 2;

  static Image? _sheet;
  static final Map<int, Sprite> _cache = {};
  static final Paint _paint = Paint()..filterQuality = FilterQuality.none;

  static bool get ready => _sheet != null;

  static Future<void> load(Images images) async {
    if (_sheet != null) return;
    try {
      _sheet = await images.load(asset);
    } catch (_) {
      _sheet = null; // components fall back to their drawn shapes
    }
  }

  /// Figure for a person (never the pastor's), deterministic from [hash].
  static int figureFor(int hash) {
    const others = [0, 1, 3, 4, 5];
    return others[hash.abs() % others.length];
  }

  static Sprite? _sprite(int figure, int dir, int frame) {
    final sheet = _sheet;
    if (sheet == null) return null;
    final key = figure * 100 + dir * 10 + frame;
    return _cache.putIfAbsent(
      key,
      () => Sprite(
        sheet,
        srcPosition: Vector2(368.0 + dir * 16, (figure * 3 + frame) * 16.0),
        srcSize: Vector2.all(16),
      ),
    );
  }

  /// Draws [figure] into a box of [size] at the origin; false if not loaded.
  static bool render(Canvas canvas, int figure, CharacterAnimator anim, Vector2 size) {
    final s = _sprite(figure, anim.dir, anim.frame);
    if (s == null) return false;
    s.render(canvas, size: size, overridePaint: _paint);
    return true;
  }
}

/// Facing and walk frame from how a component actually moved.
class CharacterAnimator {
  /// 0 left, 1 down, 2 up, 3 right.
  int dir = 1;

  /// 0 idle, 1/2 walking.
  int frame = 0;

  double _t = 0;
  final Vector2 _last = Vector2.zero();
  bool _init = false;

  void update(double dt, Vector2 position) {
    if (!_init) {
      _last.setFrom(position);
      _init = true;
    }
    final dx = position.x - _last.x;
    final dy = position.y - _last.y;
    _last.setFrom(position);
    final moving = dx * dx + dy * dy > 0.0001;
    if (!moving) {
      frame = 0;
      _t = 0;
      return;
    }
    if (dx.abs() > dy.abs()) {
      dir = dx < 0 ? 0 : 3;
    } else {
      dir = dy < 0 ? 2 : 1;
    }
    _t += dt;
    frame = 1 + ((_t / 0.18).floor() % 2);
  }
}
