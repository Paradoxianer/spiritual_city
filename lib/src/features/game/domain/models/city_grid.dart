import 'city_chunk.dart';
import 'city_cell.dart';
import 'cell_object.dart';

class CityGrid {
  final Map<String, CityChunk> _chunks = {};

  /// The same chunks under an int key – [getCell] is called hundreds of
  /// thousands of times a day by the world simulation (#194).
  final Map<int, CityChunk> _byKey = {};

  static int _key(int cx, int cy) => ((cx + 0x100000) << 21) | (cy + 0x100000);

  CityChunk getOrCreateChunk(int chunkX, int chunkY) {
    final key = '$chunkX,$chunkY';
    return _chunks.putIfAbsent(key, () {
      final c = CityChunk(chunkX: chunkX, chunkY: chunkY);
      _byKey[_key(chunkX, chunkY)] = c;
      return c;
    });
  }

  CityCell? getCell(int worldX, int worldY) {
    // Arithmetic shift = floor division by 16 (CityChunk.chunkSize), also
    // for negative numbers; & 15 is the matching local coordinate.
    final chunk = _byKey[_key(worldX >> 4, worldY >> 4)];
    if (chunk == null) return null;
    return chunk.at(worldX & 15, worldY & 15);
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
    chunk.invalidateIndex();
  }

  List<CityChunk> getLoadedChunks() => _chunks.values.toList();

  /// Returns a loaded chunk at [chunkX],[chunkY], or null if not loaded yet.
  CityChunk? getLoadedChunk(int chunkX, int chunkY) => _byKey[_key(chunkX, chunkY)];
}
