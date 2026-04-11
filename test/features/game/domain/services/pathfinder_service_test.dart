import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_cell.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_chunk.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_grid.dart';
import 'package:spiritual_city/src/features/game/domain/services/pathfinder_service.dart';

/// Builds a minimal [CityGrid] containing an open corridor of walkable cells.
CityGrid _openGrid() {
  final grid = CityGrid();
  // Fill a 10x10 area with plain (walkable) cells
  for (int wx = 0; wx < 10; wx++) {
    for (int wy = 0; wy < 10; wy++) {
      final chunkX = (wx / CityChunk.chunkSize).floor();
      final chunkY = (wy / CityChunk.chunkSize).floor();
      final chunk = grid.getOrCreateChunk(chunkX, chunkY);
      final localX = wx % CityChunk.chunkSize;
      final localY = wy % CityChunk.chunkSize;
      chunk.cells['$localX,$localY'] = CityCell(x: wx, y: wy);
    }
  }
  return grid;
}

void main() {
  const cellSize = 32.0;
  late PathfinderService pathfinder;

  setUp(() {
    pathfinder = PathfinderService(cellSize: cellSize);
  });

  group('PathfinderService', () {
    test('returns null when start and end are the same cell', () {
      final grid = _openGrid();
      final pos = Vector2(cellSize / 2, cellSize / 2); // cell (0,0)
      final result = pathfinder.findPath(pos, pos, grid);
      expect(result, isNull);
    });

    test('finds a path between adjacent cells', () {
      final grid = _openGrid();
      final from = Vector2(cellSize / 2, cellSize / 2);         // cell (0,0)
      final to   = Vector2(cellSize + cellSize / 2, cellSize / 2); // cell (1,0)

      final path = pathfinder.findPath(from, to, grid);
      expect(path, isNotNull);
      expect(path, isNotEmpty);
    });

    test('path ends near the target position', () {
      final grid = _openGrid();
      final from = Vector2(cellSize / 2, cellSize / 2); // (0,0)
      final to   = Vector2(5 * cellSize + cellSize / 2, 5 * cellSize + cellSize / 2); // (5,5)

      final path = pathfinder.findPath(from, to, grid);
      expect(path, isNotNull);
      expect(path, isNotEmpty);
      // Last waypoint should be at or near the destination cell
      final last = path!.last;
      expect((last - to).length, lessThan(cellSize * 2));
    });

    test('returns cached result on second identical call', () {
      final grid = _openGrid();
      final from = Vector2(cellSize / 2, cellSize / 2);
      final to   = Vector2(3 * cellSize + cellSize / 2, 3 * cellSize + cellSize / 2);

      final path1 = pathfinder.findPath(from, to, grid);
      final path2 = pathfinder.findPath(from, to, grid);

      // Same list object means result came from cache
      expect(identical(path1, path2), isTrue);
    });

    test('invalidateCache clears the cache', () {
      final grid = _openGrid();
      final from = Vector2(cellSize / 2, cellSize / 2);
      final to   = Vector2(2 * cellSize + cellSize / 2, cellSize / 2);

      final path1 = pathfinder.findPath(from, to, grid);
      pathfinder.invalidateCache();
      final path2 = pathfinder.findPath(from, to, grid);

      // After clearing cache a new list is computed
      expect(identical(path1, path2), isFalse);
    });

    test('handles target in unwalkable cell with straight-line fallback', () {
      // Create a grid where the target is surrounded by unwalkable cells
      final grid = CityGrid();
      // Only cell (0,0) is walkable
      final chunk = grid.getOrCreateChunk(0, 0);
      chunk.cells['0,0'] = CityCell(x: 0, y: 0);

      final from = Vector2(cellSize / 2, cellSize / 2);
      final to   = Vector2(5 * cellSize + cellSize / 2, 5 * cellSize + cellSize / 2);

      // Should fall back to [to] since no path exists
      final path = pathfinder.findPath(from, to, grid);
      expect(path, isNotNull);
      expect(path, isNotEmpty);
    });
  });
}
