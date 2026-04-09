enum RoadType { small, big, highway }
enum BuildingType { house, skyscraper, church, hospital }
enum NatureType { park, water, tree }

abstract class CellData {
  String get categoryId;
}

class RoadData extends CellData {
  final RoadType type;
  final int connections; // Bitmask for auto-tiling

  RoadData({required this.type, this.connections = 0});
  
  @override
  String get categoryId => 'road_${type.name}';
}

class BuildingData extends CellData {
  final BuildingType type;
  final int size; // e.g., 1 for 1x1, 2 for 2x2

  BuildingData({required this.type, this.size = 1});

  @override
  String get categoryId => 'building_${type.name}';
}

class NatureData extends CellData {
  final NatureType type;

  NatureData({required this.type});

  @override
  String get categoryId => 'nature_${type.name}';
}
