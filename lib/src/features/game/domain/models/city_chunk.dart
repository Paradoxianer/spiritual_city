import 'city_cell.dart';

class CityChunk {
  static const int chunkSize = 16;
  final int chunkX;
  final int chunkY;
  final Map<String, CityCell> cells = {};

  CityChunk({required this.chunkX, required this.chunkY});

  String get id => '$chunkX,$chunkY';

  // Get world coordinates for a cell within the chunk
  int getWorldX(int localX) => chunkX * chunkSize + localX;
  int getWorldY(int localY) => chunkY * chunkSize + localY;
}
