enum RoadType { small, big, highway }
enum BuildingType { house, skyscraper, church, hospital, shop }
enum NatureType { park, water, tree }

abstract class CellData {
  String get categoryId;
}

class RoadData extends CellData {
  final RoadType type;
  final bool isIntersection;
  final int connections; // Bitmask for auto-tiling (N:1, E:2, S:4, W:8)

  RoadData({required this.type, this.isIntersection = false, this.connections = 0});
  
  @override
  String get categoryId => 'road_${type.name}';
}

class BuildingData extends CellData {
  final BuildingType type;
  final String buildingId; // Unique ID to link to an interior/state
  final bool hasInterior;
  final int floorCount;
  final bool isEntrance;

  BuildingData({
    required this.type, 
    required this.buildingId,
    this.hasInterior = true,
    this.floorCount = 1,
    this.isEntrance = false,
  });

  @override
  String get categoryId => 'building_${type.name}';
}

class NatureData extends CellData {
  final NatureType type;

  NatureData({required this.type});

  @override
  String get categoryId => 'nature_${type.name}';
}
