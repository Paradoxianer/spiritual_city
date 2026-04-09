import 'cell_state.dart';

class CityGrid {
  final int width;
  final int height;
  final List<List<CellState>> cells;

  const CityGrid({
    required this.width,
    required this.height,
    required this.cells,
  });

  CellState cellAt(int x, int y) => cells[y][x];
}
