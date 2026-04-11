import 'package:flame/components.dart';

/// A simple grid-based spatial partitioning structure.
///
/// Divides world space into fixed-size cells and groups [PositionComponent]s
/// by cell, allowing O(1) lookup of nearby entities instead of O(n) iteration.
///
/// [T] can be any [PositionComponent] subtype (e.g. [NPCComponent]).
class SpatialGrid<T extends PositionComponent> {
  final int cellSize;
  final Map<String, List<T>> _cellMap = {};

  SpatialGrid({this.cellSize = 256});

  String _cellKey(Vector2 pos) =>
      '${(pos.x / cellSize).floor()},${(pos.y / cellSize).floor()}';

  /// Rebuilds the grid from the current list of [entities].
  ///
  /// Call once per frame after all entity positions have been updated.
  void update(List<T> entities) {
    _cellMap.clear();
    for (final entity in entities) {
      final key = _cellKey(entity.position);
      _cellMap.putIfAbsent(key, () => []).add(entity);
    }
  }

  /// Returns all entities whose grid cell overlaps within [range] world units
  /// of [pos].  The search is conservative (cell-level), so results may
  /// include entities slightly outside the exact circular range.
  List<T> getNearby(Vector2 pos, double range) {
    final result = <T>[];
    final cellRange = (range / cellSize).ceil();

    final cx = (pos.x / cellSize).floor();
    final cy = (pos.y / cellSize).floor();

    for (int dx = -cellRange; dx <= cellRange; dx++) {
      for (int dy = -cellRange; dy <= cellRange; dy++) {
        final key = '${cx + dx},${cy + dy}';
        final entities = _cellMap[key];
        if (entities != null) {
          result.addAll(entities);
        }
      }
    }
    return result;
  }

  /// Total number of cells currently occupied.
  int get occupiedCells => _cellMap.length;
}
