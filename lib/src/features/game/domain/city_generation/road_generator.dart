import 'dart:math';
import '../models/cell_object.dart';
import 'district_selector.dart';

class RoadGenerator {
  RoadData? getRoadData(int wx, int wy, DistrictType district, Random rand) {
    // Boulevards (Hauptverkehrsadern) - Alle 32 Felder
    if (wx % 32 == 0 || wy % 32 == 0) {
      return RoadData(
        type: RoadType.big, 
        isIntersection: wx % 32 == 0 && wy % 32 == 0
      );
    }

    // Nebenstraßen (Streets) - Gitterweite variiert je nach Distrikt
    if (district == DistrictType.park) return null;
    
    int interval = 8;
    if (district == DistrictType.slums) interval = 6;
    
    // Kleiner Jitter für organischere Straßen in Vororten/Slums
    int jitterX = (district == DistrictType.suburbs || district == DistrictType.slums) ? (wx % 32 > 16 ? 1 : 0) : 0;
    
    if ((wx + jitterX) % interval == 0 || wy % interval == 0) {
      return RoadData(type: RoadType.small);
    }

    return null;
  }
}
