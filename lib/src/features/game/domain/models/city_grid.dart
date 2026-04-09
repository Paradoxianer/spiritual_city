import 'city_chunk.dart';
import 'city_cell.dart';

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

    final localX = worldX % CityChunk.chunkSize;
    final localY = worldY % CityChunk.chunkSize;
    return chunk.cells['$localX,$localY'];
  }

  void setCell(int worldX, int worldY, CityCell cell) {
    final chunkX = (worldX / CityChunk.chunkSize).floor();
    final chunkY = (worldY / CityChunk.chunkSize).floor();
    
    final chunk = getOrCreateChunk(chunkX, chunkY);
    final localX = worldX % CityChunk.chunkSize;
    final localY = worldY % CityChunk.chunkSize;
    chunk.cells['$localX,$localY'] = cell;
  }

  List<CityChunk> getLoadedChunks() => _chunks.values.toList();
}
