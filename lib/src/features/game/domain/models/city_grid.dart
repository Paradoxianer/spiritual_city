import 'city_cell.dart';

class CityGrid {
  final int width;
  final int height;
  final Map<String, CityCell> _cells = {};

  CityGrid({required this.width, required this.height});

  void setCell(int x, int y, CityCell cell) {
    _cells['$x,$y'] = cell;
  }

  CityCell? getCell(int x, int y) {
    return _cells['$x,$y'];
  }

  List<CityCell> getAllCells() => _cells.values.toList();
  
  bool isWithinBounds(int x, int y) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }
}
