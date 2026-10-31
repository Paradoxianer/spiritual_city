import 'city_cell.dart';

class CityChunk {
  static const int chunkSize = 16;
  final int chunkX;
  final int chunkY;
  final Map<String, CityCell> cells = {};

  CityChunk({required this.chunkX, required this.chunkY});

  String get id => '$chunkX,$chunkY';

  /// Cells by local index (y × 16 + x) – a fast path for [CityGrid.getCell]
  /// and the world simulation (string keys were the hot spot, #194).
  /// Rebuilt lazily whenever [cells] grew.
  List<CityCell?>? _index;
  int _indexedCount = -1;

  /// The cell at local ([lx], [ly]), 0 … [chunkSize) − 1.
  CityCell? at(int lx, int ly) {
    if (_indexedCount != cells.length) _reindex();
    return _index![ly * chunkSize + lx];
  }

  /// Call after replacing a cell under an existing key.
  void invalidateIndex() => _indexedCount = -1;

  void _reindex() {
    final idx = List<CityCell?>.filled(chunkSize * chunkSize, null);
    final ox = chunkX * chunkSize, oy = chunkY * chunkSize;
    for (final cell in cells.values) {
      idx[(cell.y - oy) * chunkSize + (cell.x - ox)] = cell;
    }
    _index = idx;
    _indexedCount = cells.length;
  }

  // Get world coordinates for a cell within the chunk
  int getWorldX(int localX) => chunkX * chunkSize + localX;
  int getWorldY(int localY) => chunkY * chunkSize + localY;
}
