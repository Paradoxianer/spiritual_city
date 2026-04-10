import 'city_chunk.dart';
import 'city_cell.dart';
import 'cell_object.dart';

class CityGrid {
  final Map<String, CityChunk> _chunks = {};

  CityChunk getOrCreateChunk(int chunkX, int chunkY) {
    final key = '$chunkX,$chunkY';
    return _chunks.putIfAbsent(key, () => CityChunk(chunkX: chunkX, chunkY: chunkY));
  }

  CityCell? getCell(int worldX, int worldY) {
    final chunkX = (worldX / CityChunk.chunkSize).floor();
    final chunkY = (worldY / CityChunk.chunkSize).floor();
    
    final chunk = _chunks['$chunkX,$chunkY'];
    if (chunk == null) return null;

    // Correct modulo for negative numbers
    int localX = worldX % CityChunk.chunkSize;
    if (localX < 0) localX += CityChunk.chunkSize;
    
    int localY = worldY % CityChunk.chunkSize;
    if (localY < 0) localY += CityChunk.chunkSize;

    return chunk.cells['$localX,$localY'];
  }

  /// Checks if a world position is walkable.
  /// Buildings and deep water are blockers.
  bool isWalkable(int worldX, int worldY) {
    final cell = getCell(worldX, worldY);
    if (cell == null) return true; // Assume walkable if not yet loaded/generated

    final data = cell.data;
    if (data is BuildingData) return false;
    if (data is NatureData && data.type == NatureType.water) return false;

    return true;
  }

  void setCell(int worldX, int worldY, CityCell cell) {
    final chunkX = (worldX / CityChunk.chunkSize).floor();
    final chunkY = (worldY / CityChunk.chunkSize).floor();
    
    final chunk = getOrCreateChunk(chunkX, chunkY);
    
    int localX = worldX % CityChunk.chunkSize;
    if (localX < 0) localX += CityChunk.chunkSize;
    
    int localY = worldY % CityChunk.chunkSize;
    if (localY < 0) localY += CityChunk.chunkSize;

    chunk.cells['$localX,$localY'] = cell;
  }

  List<CityChunk> getLoadedChunks() => _chunks.values.toList();
}
