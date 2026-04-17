import 'dart:math';
import '../models/cell_object.dart';
import 'district_selector.dart';

class RoadGenerator {
  // ── Street-name pool ──────────────────────────────────────────────────────
  // A short but varied list of German city street types.  The generator picks
  // from this pool deterministically via a seed hash so the same city always
  // gets the same names.
  static const List<String> _streetNames = [
    'Hauptstraße', 'Kirchgasse', 'Bahnhofstr.', 'Lindenallee', 'Rosenweg',
    'Friedhofstr.', 'Bergstr.', 'Talweg', 'Mühlenweg', 'Gartenstr.',
    'Schulstr.', 'Waldweg', 'Marktplatz', 'Brunnenstr.', 'Ringstr.',
    'Ahornstr.', 'Birkenweg', 'Fichtenstr.', 'Kastanienallee', 'Ulmenstr.',
    'Dorfstr.', 'Neue Str.', 'Am Graben', 'Burgweg', 'Kapellenstr.',
    'Bachstr.', 'Amselweg', 'Buchenstr.', 'Eichenstr.', 'Wiesenweg',
  ];

  /// Large prime used to distribute axis keys across the street-name pool.
  /// Chosen to produce a good spread of indices for typical city coordinate
  /// ranges (−1000…1000 cells).
  static const int _nameHashMult = 1013904223;

  /// Returns a deterministic street name for a given road axis.
  ///
  /// Horizontal roads are keyed by their [wy] value; vertical by [wx].
  /// Major boulevards (multiple of 32) always get a name; secondary streets
  /// only get one on every alternate interval so minor lanes stay unnamed.
  String? _streetName(int wx, int wy, bool isHorizontal, bool isBig) {
    if (!isBig) return null; // only name major boulevards for now
    final axisKey = isHorizontal ? wy : wx;
    final hash = (axisKey * _nameHashMult) ^ (axisKey >> 16);
    return _streetNames[hash.abs() % _streetNames.length];
  }

  RoadData? getRoadData(int wx, int wy, DistrictType district, Random rand) {
    // ---- Boulevards (Hauptverkehrsadern) – every 32 cells -----------------
    if (wx % 32 == 0 || wy % 32 == 0) {
      final isHorizontal = wy % 32 == 0;
      final isBothAxes   = wx % 32 == 0 && wy % 32 == 0;
      return RoadData(
        type: RoadType.big,
        isIntersection: isBothAxes,
        streetName: _streetName(wx, wy, isHorizontal, true),
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
