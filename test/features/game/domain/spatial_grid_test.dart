import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/spatial_grid.dart';

void main() {
  group('SpatialGrid', () {
    late SpatialGrid<PositionComponent> grid;

    setUp(() {
      grid = SpatialGrid(cellSize: 256);
    });

    PositionComponent makeTestEntity(double x, double y) {
      final e = PositionComponent();
      e.position = Vector2(x, y);
      return e;
    }

    test('returns entities in the same cell as the query point', () {
      final e1 = makeTestEntity(0, 0);
      final e2 = makeTestEntity(10, 10);
      final e3 = makeTestEntity(1000, 1000);

      grid.update([e1, e2, e3]);

      // range covers one cell (256 units), so e1 and e2 are in same cell
      final nearby = grid.getNearby(Vector2(0, 0), 100);
      expect(nearby, contains(e1));
      expect(nearby, contains(e2));
      expect(nearby, isNot(contains(e3)));
    });

    test('returns entities in adjacent cells when range spans cell boundary', () {
      final e1 = makeTestEntity(255, 255); // near top-right of cell (0,0)
      final e2 = makeTestEntity(257, 0);  // just inside cell (1,0)

      grid.update([e1, e2]);

      // range = 300 > cellSize => adjacent cells are included
      final nearby = grid.getNearby(Vector2(0, 0), 300);
      expect(nearby, contains(e1));
      expect(nearby, contains(e2));
    });

    test('returns empty list when grid has no entities', () {
      grid.update([]);
      final nearby = grid.getNearby(Vector2(0, 0), 500);
      expect(nearby, isEmpty);
    });

    test('occupiedCells reflects number of occupied cells', () {
      grid.update([]);
      expect(grid.occupiedCells, 0);

      grid.update([
        makeTestEntity(0, 0),   // cell (0,0)
        makeTestEntity(256, 0), // cell (1,0)
      ]);
      expect(grid.occupiedCells, 2);
    });

    test('update clears previous entries', () {
      final e1 = makeTestEntity(0, 0);
      grid.update([e1]);
      expect(grid.getNearby(Vector2(0, 0), 10), contains(e1));

      // Update with different set – e1 should no longer appear
      final e2 = makeTestEntity(2000, 2000);
      grid.update([e2]);
      expect(grid.getNearby(Vector2(0, 0), 10), isNot(contains(e1)));
    });

    test('entities at negative coordinates are handled correctly', () {
      final e1 = makeTestEntity(-10, -10);
      final e2 = makeTestEntity(-300, -300);

      grid.update([e1, e2]);

      final nearby = grid.getNearby(Vector2(-10, -10), 50);
      expect(nearby, contains(e1));
      expect(nearby, isNot(contains(e2)));
    });
  });
}
