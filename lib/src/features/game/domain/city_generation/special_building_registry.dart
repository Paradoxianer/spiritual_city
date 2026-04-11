import '../models/cell_object.dart';
import 'district_selector.dart';

/// Handles placement of special / unique buildings so that globally-unique
/// landmarks appear exactly once and per-zone civic buildings are spread
/// realistically across the city.
///
/// Two tiers of uniqueness:
///   1. **Global** – exactly one per city, placed at a deterministic position
///      derived from the world seed.
///   2. **Zoned** – at most one per zone of a given size.  The zone is
///      identified by dividing world coordinates by the zone size; the exact
///      cell within the zone is derived deterministically from the seed.
///
/// Design notes (inspired by probabletrain city-generator and
/// evolving-city-generation research):
///   • Special buildings anchor the character of neighbourhoods (churches,
///     hospitals, police stations) and give players navigation landmarks.
///   • Globally-unique buildings (city hall, cathedral, main train station,
///     stadium, university) cluster near the city centre, giving the downtown
///     its distinct dense/civic feel.
///   • Per-zone buildings scale naturally: as the player explores outwards,
///     new hospitals, schools, and fire stations appear at appropriate
///     intervals.
class SpecialBuildingRegistry {
  final int seed;

  // ---- Global landmark positions (offset from world origin in cells) ------
  // These are snapped to the nearest lot-root when the map is built.

  static const int _cityHallX      =   0;
  static const int _cityHallY      =   0;
  static const int _cathedralOffX  =  18;
  static const int _cathedralOffY  =  -8;
  static const int _trainStOffX    = -30;
  static const int _trainStOffY    =  15;
  static const int _stadiumOffX    =  55;
  static const int _stadiumOffY    =  40;
  static const int _universityOffX = -50;
  static const int _universityOffY = -35;
  static const int _centralLibOffX =  10;
  static const int _centralLibOffY =  12;
  static const int _museumOffX     = -12;
  static const int _museumOffY     =   8;
  static const int _powerPlantOffX = 200;
  static const int _powerPlantOffY = 180;

  // ---- Zone sizes for per-zone buildings (in cells, ~1 cell = 10 m) -------
  // Roughly calibrated for a 500 000-inhabitant city (~650-cell radius):
  static const int _hospitalZone      = 220; // 1 hospital   per ~2.2 km²
  static const int _policeZone        = 110; // 1 per ~1.1 km²
  static const int _fireZone          = 130; // 1 per ~1.3 km²
  static const int _schoolZone        =  90; // 1 per ~0.9 km²
  static const int _churchZone        = 100; // 1 per ~1 km²
  static const int _libraryZone       = 170; // branch library
  static const int _mallZone          = 280; // 1 shopping centre per ~2.8 km²
  static const int _supermarketZone   =  95; // neighbourhood grocery
  static const int _postOfficeZone    = 130;
  static const int _cemeteryZone      = 450; // rare

  // ---- Constructor --------------------------------------------------------

  SpecialBuildingRegistry({required this.seed});

  // ---- Public API ---------------------------------------------------------

  /// Returns the special [BuildingType] that should occupy world cell
  /// ([wx], [wy]) given its [district], or `null` if no special building
  /// belongs here.
  ///
  /// Callers should skip this cell for ordinary lot generation when the
  /// return value is non-null.
  BuildingType? getSpecialBuilding(int wx, int wy, DistrictType district) {
    // ---- 1. Global landmarks (check exact cell) --------------------------
    final BuildingType? global = _checkGlobal(wx, wy, district);
    if (global != null) return global;

    // ---- 2. Zone-based civic buildings -----------------------------------
    return _checkZoned(wx, wy, district);
  }

  // ---- Global landmark helpers --------------------------------------------

  BuildingType? _checkGlobal(int wx, int wy, DistrictType district) {
    // City Hall – must be in downtown
    if (district == DistrictType.downtown &&
        wx == _cityHallX && wy == _cityHallY) {
      return BuildingType.cityHall;
    }
    if (district == DistrictType.downtown &&
        wx == _cathedralOffX && wy == _cathedralOffY) {
      return BuildingType.cathedral;
    }
    if ((district == DistrictType.downtown ||
             district == DistrictType.commercial) &&
        wx == _trainStOffX && wy == _trainStOffY) {
      return BuildingType.trainStation;
    }
    if (wx == _stadiumOffX && wy == _stadiumOffY) {
      return BuildingType.stadium;
    }
    if ((district == DistrictType.downtown ||
             district == DistrictType.commercial) &&
        wx == _universityOffX && wy == _universityOffY) {
      return BuildingType.university;
    }
    if (district == DistrictType.downtown &&
        wx == _centralLibOffX && wy == _centralLibOffY) {
      return BuildingType.library;
    }
    if ((district == DistrictType.downtown ||
             district == DistrictType.commercial) &&
        wx == _museumOffX && wy == _museumOffY) {
      return BuildingType.museum;
    }
    if (district == DistrictType.industrial &&
        wx == _powerPlantOffX && wy == _powerPlantOffY) {
      return BuildingType.powerPlant;
    }
    return null;
  }

  // ---- Zone-based civic building helpers ----------------------------------

  BuildingType? _checkZoned(int wx, int wy, DistrictType district) {
    // Each check: if (wx, wy) is the designated spot inside its zone,
    // and the district is appropriate, place the building.

    if (_isZoneCenter(wx, wy, _hospitalZone, 0) &&
        district != DistrictType.downtown &&
        district != DistrictType.industrial &&
        district != DistrictType.park) {
      return BuildingType.hospital;
    }
    if (_isZoneCenter(wx, wy, _policeZone, 1) &&
        district != DistrictType.park &&
        district != DistrictType.industrial) {
      return BuildingType.policeStation;
    }
    if (_isZoneCenter(wx, wy, _fireZone, 2) &&
        district != DistrictType.park) {
      return BuildingType.fireStation;
    }
    if (_isZoneCenter(wx, wy, _schoolZone, 3) &&
        (district == DistrictType.suburbs ||
            district == DistrictType.outskirts ||
            district == DistrictType.commercial ||
            district == DistrictType.slums)) {
      return BuildingType.school;
    }
    if (_isZoneCenter(wx, wy, _churchZone, 4) &&
        district != DistrictType.industrial &&
        district != DistrictType.park) {
      return BuildingType.church;
    }
    if (_isZoneCenter(wx, wy, _libraryZone, 5) &&
        (district == DistrictType.suburbs ||
            district == DistrictType.commercial ||
            district == DistrictType.outskirts)) {
      return BuildingType.library;
    }
    if (_isZoneCenter(wx, wy, _mallZone, 6) &&
        (district == DistrictType.commercial ||
            district == DistrictType.suburbs)) {
      return BuildingType.mall;
    }
    if (_isZoneCenter(wx, wy, _supermarketZone, 7) &&
        (district == DistrictType.suburbs ||
            district == DistrictType.outskirts ||
            district == DistrictType.slums)) {
      return BuildingType.supermarket;
    }
    if (_isZoneCenter(wx, wy, _postOfficeZone, 8) &&
        district != DistrictType.park &&
        district != DistrictType.industrial) {
      return BuildingType.postOffice;
    }
    if (_isZoneCenter(wx, wy, _cemeteryZone, 9) &&
        (district == DistrictType.suburbs ||
            district == DistrictType.outskirts)) {
      return BuildingType.cemetery;
    }
    return null;
  }

  /// Returns true when ([wx], [wy]) is the deterministic "centre cell" of the
  /// zone that ([wx], [wy]) belongs to, given [zoneSize] and a [salt] that
  /// differentiates zone types from each other.
  bool _isZoneCenter(int wx, int wy, int zoneSize, int salt) {
    final int zx = _floorDiv(wx, zoneSize);
    final int zy = _floorDiv(wy, zoneSize);
    final int hash = _zoneHash(zx, zy, salt);
    final int targetX = (zx * zoneSize) + (hash.abs() % zoneSize);
    final int targetY = (zy * zoneSize) + ((_zoneHash(zx, zy, salt + 100)).abs() % zoneSize);
    return wx == targetX && wy == targetY;
  }

  int _zoneHash(int zx, int zy, int salt) {
    // Large primes chosen for good hash distribution across zone coordinates.
    // The bit-mixing step (xor-shift + multiply) reduces clustering.
    int h = seed ^ (zx * 374761393) ^ (zy * 668265263) ^ (salt * 1013904223);
    h = ((h >> 16) ^ h) * 0x45D9F3B;
    h = ((h >> 16) ^ h);
    return h;
  }

  // Dart's `~/` operator truncates towards zero; we need floor division.
  static int _floorDiv(int a, int b) => (a / b).floor();
}
