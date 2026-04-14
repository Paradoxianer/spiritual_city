enum RoadType { small, big, highway }

/// All placeable building types in the city.
/// Grouped roughly by category for readability.
enum BuildingType {
  // --- Residential ---
  house,        // Single-family home (suburbs)
  apartment,    // Multi-storey apartment block (inner rings)
  pastorHouse,  // The pastor's personal home (always open; player base)

  // --- Commercial ---
  shop,         // Small shop / boutique
  supermarket,  // Neighbourhood grocery store
  mall,         // Large shopping centre (unique per large zone)
  office,       // Office building (commercial districts)
  skyscraper,   // High-rise office tower (downtown core)

  // --- Industrial ---
  factory,      // Manufacturing plant
  warehouse,    // Storage / logistics

  // --- Civic / Infrastructure ---
  trainStation, // Main / district rail station       (unique)
  policeStation,// Police station                     (per zone)
  fireStation,  // Fire station                       (per zone)
  postOffice,   // Post office                        (per zone)

  // --- Health & Education ---
  hospital,     // Hospital                           (per large zone)
  school,       // Primary / secondary school         (per zone)
  university,   // University campus                  (unique)

  // --- Culture / Religion ---
  church,       // Small neighbourhood church         (per zone)
  cathedral,    // Central cathedral / dom            (unique)
  library,      // Public library                     (per zone)
  museum,       // Museum                             (unique/rare)
  stadium,      // Sports arena                       (unique)

  // --- Government ---
  cityHall,     // Rathaus – city hall                (unique)

  // --- Other ---
  cemetery,     // Cemetery                           (rare)
  powerPlant,   // Power plant (industrial edge)      (unique)
}

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
