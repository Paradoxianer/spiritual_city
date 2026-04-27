import 'package:flutter/material.dart' hide Image;

import '../../domain/models/cell_object.dart';

/// Static utility that renders a single physical city tile onto a [Canvas].
///
/// Extracted from [CellComponent] so that both the per-component renderer and
/// the cached [ChunkComponent] batch-renderer share exactly the same drawing
/// code, eliminating the previous duplication where [ChunkComponent] only
/// handled three building types (house / apartment / skyscraper) and rendered
/// everything else as a plain dark-grey square.
///
/// All [Paint] objects are pre-allocated as static fields so they are created
/// only once for the entire application lifetime.
class CityTileRenderer {
  CityTileRenderer._(); // non-instantiable utility class

  // ── Road ─────────────────────────────────────────────────────────────────

  static final Paint _roadBig   = Paint()..color = const Color(0xFF616161);
  static final Paint _roadSmall = Paint()..color = const Color(0xFF424242);
  static final Paint _roadLine  = Paint()..color = const Color(0x4DFFEB3B);

  // ── Nature ────────────────────────────────────────────────────────────────

  static final Paint _water = Paint()..color = const Color(0xFF1565C0);
  static final Paint _tree  = Paint()..color = const Color(0xFF388E3C);
  static final Paint _park  = Paint()..color = const Color(0xFF4CAF50);

  // ── Buildings – fill colours ──────────────────────────────────────────────

  static final Paint _fillSkyscraper  = Paint()..color = const Color(0xFF263238);
  static final Paint _fillOffice      = Paint()..color = const Color(0xFF37474F);
  static final Paint _fillApartment   = Paint()..color = const Color(0xFF5D4037);
  static final Paint _fillHouse       = Paint()..color = const Color(0xFF795548);
  static final Paint _fillShop        = Paint()..color = const Color(0xFF1976D2);
  static final Paint _fillSupermarket = Paint()..color = const Color(0xFF0288D1);
  static final Paint _fillMall        = Paint()..color = const Color(0xFF1565C0);
  static final Paint _fillFactory     = Paint()..color = const Color(0xFF546E7A);
  static final Paint _fillWarehouse   = Paint()..color = const Color(0xFF607D8B);
  static final Paint _fillPastorHouse = Paint()..color = const Color(0xFFFFF8E1);
  static final Paint _fillHospital    = Paint()..color = const Color(0xFFFFFFFF);
  static final Paint _fillChurch      = Paint()..color = const Color(0xFFFFF9C4);
  static final Paint _fillCathedral   = Paint()..color = const Color(0xFFFFE082);
  static final Paint _fillCityHall    = Paint()..color = const Color(0xFFECEFF1);
  static final Paint _fillPolice      = Paint()..color = const Color(0xFF1A237E);
  static final Paint _fillFire        = Paint()..color = const Color(0xFFB71C1C);
  static final Paint _fillSchool      = Paint()..color = const Color(0xFFE65100);
  static final Paint _fillUniversity  = Paint()..color = const Color(0xFF880E4F);
  static final Paint _fillLibrary     = Paint()..color = const Color(0xFF4A148C);
  static final Paint _fillMuseum      = Paint()..color = const Color(0xFF311B92);
  static final Paint _fillTrainSt     = Paint()..color = const Color(0xFF212121);
  static final Paint _fillStadium     = Paint()..color = const Color(0xFF1B5E20);
  static final Paint _fillPostOffice  = Paint()..color = const Color(0xFFF57F17);
  static final Paint _fillCemetery    = Paint()..color = const Color(0xFF424242);
  static final Paint _fillPowerPlant  = Paint()..color = const Color(0xFF212121);

  // ── Detail / accent paints ────────────────────────────────────────────────

  static final Paint _domePaint           = Paint()..color = Colors.blueGrey..style = PaintingStyle.fill;
  static final Paint _pillarPaint         = Paint()..color = Colors.grey;
  static final Paint _badgePaint          = Paint()..color = const Color(0xFFFFD700);
  static final Paint _bellTowerPaint      = Paint()..color = const Color(0xFFBF360C);
  static final Paint _gothicArchPaint     = Paint()..color = Colors.pink..style = PaintingStyle.stroke..strokeWidth = 2;
  static final Paint _cathedralTowerPaint = Paint()..color = const Color(0xFFFFCC02);
  static final Paint _libraryShelfPaint   = Paint()..color = Colors.purple[300]!..style = PaintingStyle.stroke..strokeWidth = 2;
  static final Paint _museumColumnPaint   = Paint()..color = Colors.deepPurple[300]!;
  static final Paint _museumPedimentPaint = Paint()..color = Colors.deepPurple[200]!;
  static final Paint _stadiumPitchStroke  = Paint()..color = const Color(0xFF2E7D32)..style = PaintingStyle.stroke..strokeWidth = 3;
  static final Paint _stadiumPitchFill    = Paint()..color = const Color(0xFF43A047);
  static final Paint _cemeteryCrossPaint  = Paint()..color = Colors.grey[500]!..style = PaintingStyle.stroke..strokeWidth = 1.5;
  static final Paint _coolingTowerPaint   = Paint()..color = const Color(0xFF37474F);
  static final Paint _trainStationArch    = Paint()..color = Colors.grey..style = PaintingStyle.stroke..strokeWidth = 3;

  static final Paint _accentRedStroke3 = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _accentBrownStroke2 = Paint()
    ..color = Colors.brown
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _accentBrownStroke3 = Paint()
    ..color = Colors.brown
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _accentWhiteStroke1 = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _accentWhiteStroke2 = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final Paint _accentGoldStroke15 = Paint()
    ..color = const Color(0xFFFFD700)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _accentYellow = Paint()
    ..color = Colors.yellow.withValues(alpha: 0.5);
  static final Paint _accentBlack  = Paint()..color = Colors.black45;

  // Shared mutable paint used for transient colours (reset after each use).
  static final Paint _tmp = Paint();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Renders [data] into [rect] on [canvas].
  ///
  /// Covers roads, all building types and nature cells.  A `null` [data] value
  /// is treated as an empty / wilderness cell (drawn as a tree/grass tile).
  static void renderCell(Canvas canvas, Rect rect, CellData? data) {
    if (data == null) {
      canvas.drawRect(rect, _tree);
    } else if (data is RoadData) {
      _renderRoad(canvas, rect, data);
    } else if (data is BuildingData) {
      _renderBuilding(canvas, rect, data);
    } else if (data is NatureData) {
      _renderNature(canvas, rect, data);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static void _renderRoad(Canvas canvas, Rect r, RoadData road) {
    canvas.drawRect(r, road.type == RoadType.big ? _roadBig : _roadSmall);
    if (road.type == RoadType.big) {
      canvas.drawRect(
          Rect.fromLTWH(r.left + r.width * 0.45, r.top, r.width * 0.1, r.height),
          _roadLine);
    }
  }

  static void _renderNature(Canvas canvas, Rect r, NatureData nature) {
    switch (nature.type) {
      case NatureType.water:
        canvas.drawRect(r, _water);
        break;
      case NatureType.tree:
        canvas.drawRect(r, _tree);
        break;
      case NatureType.park:
        canvas.drawRect(r, _park);
        break;
    }
  }

  static void _renderBuilding(Canvas canvas, Rect r, BuildingData building) {
    final double w = r.width;
    final double h = r.height;
    switch (building.type) {
      // ---- Residential -----------------------------------------------------
      case BuildingType.house:
        canvas.drawRect(r, _fillHouse);
        break;
      case BuildingType.apartment:
        canvas.drawRect(r, _fillApartment);
        _drawWindows(canvas, r, 2);
        break;
      case BuildingType.pastorHouse:
        // Distinctive amber/gold background – immediately stands out from
        // regular brown houses and other buildings.
        canvas.drawRect(r, _fillPastorHouse);
        // Bold golden cross – significantly bigger and brighter than churches
        // so the building is unmistakable even at a glance.
        final crossPaint = Paint()
          ..color = const Color(0xFFFFB300) // amber[700]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(r.left + w * 0.5, r.top + h * 0.04),
            Offset(r.left + w * 0.5, r.top + h * 0.80), crossPaint);
        canvas.drawLine(Offset(r.left + w * 0.22, r.top + h * 0.26),
            Offset(r.left + w * 0.78, r.top + h * 0.26), crossPaint);
        // Bold golden glow border (1.25 px inset so it stays within the cell)
        _tmp
          ..color = const Color(0xCCFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawRect(r.deflate(1.25), _tmp);
        _tmp.style = PaintingStyle.fill;
        break;

      // ---- Commercial -------------------------------------------------------
      case BuildingType.skyscraper:
        canvas.drawRect(r, _fillSkyscraper);
        _drawWindows(canvas, r, 3);
        break;
      case BuildingType.office:
        canvas.drawRect(r, _fillOffice);
        _drawWindows(canvas, r, 2);
        break;
      case BuildingType.shop:
        canvas.drawRect(r, _fillShop);
        canvas.drawRect(
            Rect.fromLTWH(r.left + w * 0.2, r.top + h * 0.6, w * 0.6, h * 0.4),
            _accentBlack);
        break;
      case BuildingType.supermarket:
        canvas.drawRect(r, _fillSupermarket);
        canvas.drawRect(
            Rect.fromLTWH(r.left + w * 0.1, r.top + h * 0.55, w * 0.8, h * 0.45),
            _accentBlack);
        break;
      case BuildingType.mall:
        canvas.drawRect(r, _fillMall);
        _drawWindows(canvas, r, 2);
        canvas.drawArc(
            Rect.fromLTWH(r.left + w * 0.2, r.top + h * 0.5, w * 0.6, h * 0.5),
            3.14, 3.14, false, _accentWhiteStroke2);
        break;

      // ---- Industrial -------------------------------------------------------
      case BuildingType.factory:
        canvas.drawRect(r, _fillFactory);
        canvas.drawRect(
            Rect.fromLTWH(r.left + w * 0.6, r.top + h * 0.1, w * 0.15, h * 0.5),
            _fillWarehouse);
        break;
      case BuildingType.warehouse:
        canvas.drawRect(r, _fillWarehouse);
        canvas.drawLine(Offset(r.left, r.top + h * 0.35),
            Offset(r.right, r.top + h * 0.35), _accentWhiteStroke1);
        break;

      // ---- Civic ------------------------------------------------------------
      case BuildingType.cityHall:
        canvas.drawRect(r, _fillCityHall);
        canvas.drawArc(
            Rect.fromLTWH(r.left + w * 0.2, r.top + h * 0.1, w * 0.6, h * 0.55),
            3.14, 3.14, true, _domePaint);
        for (final double px in [0.25, 0.4, 0.55, 0.7]) {
          canvas.drawRect(
              Rect.fromLTWH(r.left + w * px, r.top + h * 0.55, w * 0.04, h * 0.4),
              _pillarPaint);
        }
        break;
      case BuildingType.policeStation:
        canvas.drawRect(r, _fillPolice);
        canvas.drawCircle(
            Offset(r.left + w * 0.5, r.top + h * 0.4), w * 0.2, _badgePaint);
        break;
      case BuildingType.fireStation:
        canvas.drawRect(r, _fillFire);
        canvas.drawRect(
            Rect.fromLTWH(r.left + w * 0.15, r.top + h * 0.45, w * 0.7, h * 0.5),
            _accentWhiteStroke2);
        break;
      case BuildingType.postOffice:
        canvas.drawRect(r, _fillPostOffice);
        canvas.drawRect(
            Rect.fromLTWH(r.left + w * 0.2, r.top + h * 0.3, w * 0.6, h * 0.4),
            _accentWhiteStroke2);
        canvas.drawLine(Offset(r.left + w * 0.2, r.top + h * 0.3),
            Offset(r.left + w * 0.5, r.top + h * 0.5), _accentWhiteStroke2);
        canvas.drawLine(Offset(r.left + w * 0.8, r.top + h * 0.3),
            Offset(r.left + w * 0.5, r.top + h * 0.5), _accentWhiteStroke2);
        break;
      case BuildingType.trainStation:
        canvas.drawRect(r, _fillTrainSt);
        canvas.drawArc(
            Rect.fromLTWH(r.left + w * 0.05, r.top + h * 0.1, w * 0.9, h * 0.6),
            3.14, 3.14, false, _trainStationArch);
        canvas.drawLine(
            Offset(r.left + w * 0.3, r.top + h * 0.7), Offset(r.left + w * 0.3, r.bottom),
            _accentGoldStroke15);
        canvas.drawLine(
            Offset(r.left + w * 0.7, r.top + h * 0.7), Offset(r.left + w * 0.7, r.bottom),
            _accentGoldStroke15);
        break;

      // ---- Health & Education -----------------------------------------------
      case BuildingType.hospital:
        canvas.drawRect(r, _fillHospital);
        canvas.drawLine(Offset(r.left + w * 0.5, r.top + h * 0.25),
            Offset(r.left + w * 0.5, r.top + h * 0.75), _accentRedStroke3);
        canvas.drawLine(Offset(r.left + w * 0.25, r.top + h * 0.5),
            Offset(r.left + w * 0.75, r.top + h * 0.5), _accentRedStroke3);
        break;
      case BuildingType.school:
        canvas.drawRect(r, _fillSchool);
        canvas.drawRect(
            Rect.fromLTWH(r.left + w * 0.35, r.top + h * 0.05, w * 0.3, h * 0.3),
            _bellTowerPaint);
        _drawWindows(canvas, r, 2);
        break;
      case BuildingType.university:
        canvas.drawRect(r, _fillUniversity);
        _drawWindows(canvas, r, 3);
        canvas.drawArc(
            Rect.fromLTWH(r.left + w * 0.3, r.top + h * 0.1, w * 0.4, h * 0.4),
            3.14, 3.14, false, _gothicArchPaint);
        break;

      // ---- Culture / Religion -----------------------------------------------
      case BuildingType.church:
        canvas.drawRect(r, _fillChurch);
        canvas.drawLine(Offset(r.left + w * 0.5, r.top + h * 0.15),
            Offset(r.left + w * 0.5, r.top + h * 0.8), _accentBrownStroke2);
        canvas.drawLine(Offset(r.left + w * 0.3, r.top + h * 0.35),
            Offset(r.left + w * 0.7, r.top + h * 0.35), _accentBrownStroke2);
        break;
      case BuildingType.cathedral:
        canvas.drawRect(r, _fillCathedral);
        canvas.drawLine(Offset(r.left + w * 0.5, r.top + h * 0.05),
            Offset(r.left + w * 0.5, r.top + h * 0.85), _accentBrownStroke3);
        canvas.drawLine(Offset(r.left + w * 0.25, r.top + h * 0.3),
            Offset(r.left + w * 0.75, r.top + h * 0.3), _accentBrownStroke3);
        canvas.drawRect(
            Rect.fromLTWH(r.left + w * 0.05, r.top + h * 0.25, w * 0.18, h * 0.7),
            _cathedralTowerPaint);
        canvas.drawRect(
            Rect.fromLTWH(r.left + w * 0.77, r.top + h * 0.25, w * 0.18, h * 0.7),
            _cathedralTowerPaint);
        break;
      case BuildingType.library:
        canvas.drawRect(r, _fillLibrary);
        for (final double ly in [0.3, 0.5, 0.7]) {
          canvas.drawLine(Offset(r.left + w * 0.15, r.top + h * ly),
              Offset(r.left + w * 0.85, r.top + h * ly), _libraryShelfPaint);
        }
        break;
      case BuildingType.museum:
        canvas.drawRect(r, _fillMuseum);
        for (final double px in [0.2, 0.4, 0.6, 0.8]) {
          canvas.drawRect(
              Rect.fromLTWH(r.left + w * px - 0.02 * w, r.top + h * 0.4,
                  w * 0.04, h * 0.55),
              _museumColumnPaint);
        }
        final path = Path()
          ..moveTo(r.left + w * 0.1, r.top + h * 0.4)
          ..lineTo(r.left + w * 0.5, r.top + h * 0.1)
          ..lineTo(r.left + w * 0.9, r.top + h * 0.4)
          ..close();
        canvas.drawPath(path, _museumPedimentPaint);
        break;
      case BuildingType.stadium:
        canvas.drawRect(r, _fillStadium);
        canvas.drawOval(
            Rect.fromLTWH(r.left + w * 0.1, r.top + h * 0.15, w * 0.8, h * 0.7),
            _stadiumPitchStroke);
        canvas.drawOval(
            Rect.fromLTWH(r.left + w * 0.2, r.top + h * 0.25, w * 0.6, h * 0.5),
            _stadiumPitchFill);
        break;

      // ---- Other ------------------------------------------------------------
      case BuildingType.cemetery:
        canvas.drawRect(r, _fillCemetery);
        for (int i = 0; i < 3; i++) {
          final double cx = r.left + w * (0.25 + i * 0.25);
          canvas.drawLine(Offset(cx, r.top + h * 0.2), Offset(cx, r.top + h * 0.7),
              _cemeteryCrossPaint);
          canvas.drawLine(Offset(cx - w * 0.08, r.top + h * 0.35),
              Offset(cx + w * 0.08, r.top + h * 0.35), _cemeteryCrossPaint);
        }
        break;
      case BuildingType.powerPlant:
        canvas.drawRect(r, _fillPowerPlant);
        canvas.drawRect(
            Rect.fromLTWH(r.left + w * 0.1, r.top + h * 0.3, w * 0.3, h * 0.65),
            _coolingTowerPaint);
        canvas.drawRect(
            Rect.fromLTWH(r.left + w * 0.6, r.top + h * 0.3, w * 0.3, h * 0.65),
            _coolingTowerPaint);
        break;
    }
  }

  static void _drawWindows(Canvas canvas, Rect r, int rows) {
    final double w = r.width;
    final double h = r.height;
    for (int i = 0; i < rows; i++) {
      canvas.drawRect(
          Rect.fromLTWH(r.left + w * 0.2, r.top + h * (0.2 + i * 0.25), w * 0.2, h * 0.15),
          _accentYellow);
      canvas.drawRect(
          Rect.fromLTWH(r.left + w * 0.6, r.top + h * (0.2 + i * 0.25), w * 0.2, h * 0.15),
          _accentYellow);
    }
  }
}
