import 'package:flame/components.dart';
import 'city_grid.dart';
import 'cell_object.dart';

/// Lightweight wrapper around [CityGrid] that provides road-aware queries
/// for the pathfinding system.
///
/// NPCs prefer to walk on roads (smoother, more realistic movement), but
/// can fall back to any walkable cell if no road is reachable.
class RoadNetwork {
  final CityGrid grid;

  RoadNetwork(this.grid);

  /// Returns `true` if the given world-grid coordinates contain a road cell.
  bool isRoad(int gx, int gy) {
    final cell = grid.getCell(gx, gy);
    return cell?.data is RoadData;
  }

  /// Returns `true` if an NPC can walk through the given world-grid cell
  /// (i.e. it is not a building or deep water).
  bool isNavigable(int gx, int gy) => grid.isWalkable(gx, gy);

  /// Returns approximate world-space positions of road cells within [radius]
  /// pixels of [pos].  Useful for finding a road to snap an NPC to before
  /// beginning path-navigation.
  List<Vector2> getRoadCellsNear(Vector2 pos, double radius, double cellSize) {
    final result = <Vector2>[];
    final cells = (radius / cellSize).ceil();
    final cx = (pos.x / cellSize).floor();
    final cy = (pos.y / cellSize).floor();

    for (int dx = -cells; dx <= cells; dx++) {
      for (int dy = -cells; dy <= cells; dy++) {
        final gx = cx + dx;
        final gy = cy + dy;
        if (isRoad(gx, gy)) {
          result.add(Vector2(
            gx * cellSize + cellSize / 2,
            gy * cellSize + cellSize / 2,
          ));
        }
      }
    }
    return result;
  }
}
