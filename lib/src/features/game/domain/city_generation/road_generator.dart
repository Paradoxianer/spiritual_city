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
  /// Every road gets a name.  Horizontal roads are keyed by their [wy] value;
  /// vertical roads by [wx].  The hash spreads the axis key across the name
  /// pool so adjacent streets almost always get different names.
  String _streetName(int wx, int wy, bool isHorizontal) {
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
        streetName: _streetName(wx, wy, isHorizontal),
      );
    }

    // ---- No secondary roads in parks / outskirts --------------------------
    if (district == DistrictType.park) return null;
    if (district == DistrictType.outskirts) return null;

    // ---- Secondary street grid -------------------------------------------
    // Always on the lot grid (LotGenerator.lotBlock), which also divides the
    // boulevard spacing: streets run along lots, never through them
    // (playtest 2026-11-01). Industrial blocks are twice as wide.
    final interval = district == DistrictType.industrial ? 16 : 8;

    if (wx % interval == 0 || wy % interval == 0) {
      final isHorizontal = wy % interval == 0;
      return RoadData(
        type: RoadType.small,
        streetName: _streetName(wx, wy, isHorizontal),
      );
    }

    return null;
  }
}
