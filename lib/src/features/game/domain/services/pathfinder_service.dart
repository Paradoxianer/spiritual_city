import 'package:flame/components.dart';
import '../models/city_grid.dart';

/// Greedy best-first pathfinder that operates on the [CityGrid] walkability map.
///
/// Uses a simple best-first search (greedy by Manhattan distance) with path
/// caching so repeated requests for the same cell pair are O(1).
///
/// This is intentionally simple: for 80–100 NPCs running at 60 FPS a full
/// A* implementation would be premature.  Greedy BFS is fast enough and
/// produces natural-looking city routes.
class PathfinderService {
  /// World-space size of one cell (must match [CellComponent.cellSize]).
  final double cellSize;

  /// Maximum grid steps to explore before giving up.
  static const int _maxSteps = 300;

  /// Maximum number of cached paths before the oldest entry is evicted.
  static const int _maxCacheSize = 200;

  final Map<String, List<Vector2>?> _cache = {};

  PathfinderService({this.cellSize = 32.0});

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Returns a list of world-space waypoints from [from] to [to].
  ///
  /// Returns `null` only when the start and end are the same cell.
  /// Falls back to `[to]` (straight-line) when no path can be found within
  /// [_maxSteps] (e.g. target is in a surrounded building).
  List<Vector2>? findPath(Vector2 from, Vector2 to, CityGrid grid) {
    final sx = (from.x / cellSize).floor();
    final sy = (from.y / cellSize).floor();
    final ex = (to.x / cellSize).floor();
    final ey = (to.y / cellSize).floor();

    if (sx == ex && sy == ey) return null;

    final key = '$sx,$sy→$ex,$ey';
    if (_cache.containsKey(key)) return _cache[key];

    final path = _greedyBFS(sx, sy, ex, ey, grid);

    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = path;
    return path;
  }

  /// Removes all cached paths.  Call after a chunk is regenerated.
  void invalidateCache() => _cache.clear();

  // ─── Internal ─────────────────────────────────────────────────────────────

  int _h(int x, int y, int ex, int ey) => (x - ex).abs() + (y - ey).abs();

  List<Vector2>? _greedyBFS(
      int sx, int sy, int ex, int ey, CityGrid grid) {
    // cameFrom maps 'x,y' → 'px,py' (parent key), null for start
    final cameFrom = <String, String?>{};
    // frontier sorted by heuristic (ascending)
    final frontier = <_Node>[];

    final startKey = '$sx,$sy';
    cameFrom[startKey] = null;
    frontier.add(_Node(sx, sy, _h(sx, sy, ex, ey)));

    int steps = 0;
    while (frontier.isNotEmpty && steps < _maxSteps) {
      frontier.sort((a, b) => a.h.compareTo(b.h));
      final cur = frontier.removeAt(0);
      steps++;

      if (cur.x == ex && cur.y == ey) {
        return _reconstruct(cameFrom, sx, sy, ex, ey);
      }

      for (final d in _dirs) {
        final nx = cur.x + d[0];
        final ny = cur.y + d[1];
        final nKey = '$nx,$ny';
        if (!cameFrom.containsKey(nKey) && grid.isWalkable(nx, ny)) {
          cameFrom[nKey] = '${cur.x},${cur.y}';
          frontier.add(_Node(nx, ny, _h(nx, ny, ex, ey)));
        }
      }
    }

    // Fallback: direct waypoint
    return [_cellCenter(ex, ey)];
  }

  List<Vector2> _reconstruct(
      Map<String, String?> cameFrom, int sx, int sy, int ex, int ey) {
    final keys = <String>[];
    String? cur = '$ex,$ey';
    final startKey = '$sx,$sy';

    while (cur != null && cur != startKey) {
      keys.add(cur);
      cur = cameFrom[cur];
    }

    final path = <Vector2>[];
    for (final k in keys.reversed) {
      final parts = k.split(',');
      path.add(_cellCenter(int.parse(parts[0]), int.parse(parts[1])));
    }
    return path;
  }

  Vector2 _cellCenter(int gx, int gy) =>
      Vector2(gx * cellSize + cellSize / 2, gy * cellSize + cellSize / 2);

  static const List<List<int>> _dirs = [
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1],
  ];
}

class _Node {
  final int x, y, h;
  _Node(this.x, this.y, this.h);
}
