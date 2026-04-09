import '../entities/spiritual_cell_state.dart';

class GameOfLifeService {
  List<List<SpiritualCellState>> evolve(
    List<List<SpiritualCellState>> grid, {
    Set<String> prayerZoneKeys = const {},
  }) {
    final height = grid.length;
    if (height == 0) return grid;
    final width = grid[0].length;

    return List.generate(height, (y) {
      return List.generate(width, (x) {
        final lightNeighbors = _countLightNeighbors(grid, x, y, width, height);
        final current = grid[y][x];
        final bool nextActive;
        if (current.isActive) {
          nextActive = lightNeighbors == 2 || lightNeighbors == 3;
        } else {
          nextActive = lightNeighbors == 3;
        }
        final bonus = prayerZoneKeys.contains('$x,$y') ? 0.2 : 0.0;
        final nextIntensity =
            ((nextActive ? 1.0 : 0.0) + bonus).clamp(0.0, 1.0);
        return SpiritualCellState(
          lightIntensity: nextIntensity,
          isActive: nextActive,
        );
      });
    });
  }

  int _countLightNeighbors(
    List<List<SpiritualCellState>> grid,
    int x,
    int y,
    int width,
    int height,
  ) {
    int count = 0;
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
          if (grid[ny][nx].isActive) count++;
        }
      }
    }
    return count;
  }
}
