import 'dart:math';
import '../models/cell_object.dart';
import 'district_selector.dart';

class RoadGenerator {
  RoadData? getRoadData(int wx, int wy, DistrictType district, Random rand) {
    // ---- Boulevards (Hauptverkehrsadern) – every 32 cells -----------------
    if (wx % 32 == 0 || wy % 32 == 0) {
      return RoadData(
        type: RoadType.big,
        isIntersection: wx % 32 == 0 && wy % 32 == 0,
      );
    }

    // ---- No secondary roads in parks / outskirts --------------------------
    if (district == DistrictType.park) return null;
    if (district == DistrictType.outskirts) return null;

    // ---- Secondary street grid (pitch varies by district) -----------------
    int interval;
    switch (district) {
      case DistrictType.downtown:
      case DistrictType.commercial:
        interval = 6; // dense city-block grid
        break;
      case DistrictType.slums:
        interval = 6;
        break;
      case DistrictType.industrial:
        interval = 10; // wider industrial blocks
        break;
      default:
        interval = 8; // suburbs / waterfront
    }

    // Small organic jitter for suburbs and slums
    final int jitterX =
        (district == DistrictType.suburbs || district == DistrictType.slums)
            ? (wx % 32 > 16 ? 1 : 0)
            : 0;

    if ((wx + jitterX) % interval == 0 || wy % interval == 0) {
      return RoadData(type: RoadType.small);
    }

    return null;
  }
}
