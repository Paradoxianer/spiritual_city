import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/models/city_cell.dart';
import '../../domain/models/cell_object.dart';
import '../spirit_world_game.dart';

/// Renders a single world cell.
///
/// Paint objects are declared as static constants so they are allocated once
/// for all CellComponent instances, not recreated on every render() call.
class CellComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final CityCell cell;
  static const double cellSize = 32.0;

  CellComponent(this.cell) {
    position = Vector2(cell.x * cellSize, cell.y * cellSize);
    size = Vector2.all(cellSize);
    priority = 0;
  }

  // ---- Cached paints (static = allocated once) ----------------------------

  // Road
  static final Paint _roadBig   = Paint()..color = const Color(0xFF616161); // grey[700]
  static final Paint _roadSmall = Paint()..color = const Color(0xFF424242); // grey[800]
  static final Paint _roadLine  = Paint()..color = const Color(0x4DFFEB3B); // yellow 30 %

  // Nature
  static final Paint _water = Paint()..color = const Color(0xFF1565C0); // blue[800]
  static final Paint _tree  = Paint()..color = const Color(0xFF388E3C); // green[700]
  static final Paint _park  = Paint()..color = const Color(0xFF4CAF50); // green[500]

  // Buildings – fill colours
  static final Paint _fillSkyscraper  = Paint()..color = const Color(0xFF263238); // blueGrey[900]
  static final Paint _fillOffice      = Paint()..color = const Color(0xFF37474F); // blueGrey[800]
  static final Paint _fillApartment   = Paint()..color = const Color(0xFF5D4037); // brown[700]
  static final Paint _fillHouse       = Paint()..color = const Color(0xFF795548); // brown[400]
  static final Paint _fillShop        = Paint()..color = const Color(0xFF1976D2); // blue[700]
  static final Paint _fillSupermarket = Paint()..color = const Color(0xFF0288D1); // lightBlue[700]
  static final Paint _fillMall        = Paint()..color = const Color(0xFF1565C0); // blue[800]
  static final Paint _fillFactory     = Paint()..color = const Color(0xFF546E7A); // blueGrey[600]
  static final Paint _fillWarehouse   = Paint()..color = const Color(0xFF607D8B); // blueGrey[500]
  static final Paint _fillHospital    = Paint()..color = const Color(0xFFFFFFFF);
  static final Paint _fillChurch      = Paint()..color = const Color(0xFFFFF9C4); // amber[100]
  static final Paint _fillCathedral   = Paint()..color = const Color(0xFFFFE082); // amber[200]
  static final Paint _fillCityHall    = Paint()..color = const Color(0xFFECEFF1); // blueGrey[50]
  static final Paint _fillPolice      = Paint()..color = const Color(0xFF1A237E); // indigo[900]
  static final Paint _fillFire        = Paint()..color = const Color(0xFFB71C1C); // red[900]
  static final Paint _fillSchool      = Paint()..color = const Color(0xFFE65100); // deepOrange[900]
  static final Paint _fillUniversity  = Paint()..color = const Color(0xFF880E4F); // pink[900]
  static final Paint _fillLibrary     = Paint()..color = const Color(0xFF4A148C); // purple[900]
  static final Paint _fillMuseum      = Paint()..color = const Color(0xFF311B92); // deepPurple[900]
  static final Paint _fillTrainSt     = Paint()..color = const Color(0xFF212121); // grey[900]
  static final Paint _fillStadium     = Paint()..color = const Color(0xFF1B5E20); // green[900]
  static final Paint _fillPostOffice  = Paint()..color = const Color(0xFFF57F17); // amber[900]
  static final Paint _fillCemetery    = Paint()..color = const Color(0xFF424242); // grey[800]
  static final Paint _fillPowerPlant  = Paint()..color = const Color(0xFF212121);

  // Detail paints
  static final Paint _domePaint = Paint()..color = Colors.blueGrey..style = PaintingStyle.fill;
  static final Paint _pillarPaint = Paint()..color = Colors.grey;
  static final Paint _badgePaint = Paint()..color = const Color(0xFFFFD700);
  static final Paint _bellTowerPaint = Paint()..color = const Color(0xFFBF360C);
  static final Paint _gothicArchPaint = Paint()..color = Colors.pink..style = PaintingStyle.stroke..strokeWidth = 2;
  static final Paint _cathedralTowerPaint = Paint()..color = const Color(0xFFFFCC02);
  static final Paint _libraryShelfPaint = Paint()..color = Colors.purple[300]!..strokeWidth = 2;
  static final Paint _museumColumnPaint = Paint()..color = Colors.deepPurple[300]!;
  static final Paint _museumPedimentPaint = Paint()..color = Colors.deepPurple[200]!;
  static final Paint _stadiumPitchStroke = Paint()..color = const Color(0xFF2E7D32)..style = PaintingStyle.stroke..strokeWidth = 3;
  static final Paint _stadiumPitchFill = Paint()..color = const Color(0xFF43A047);
  static final Paint _cemeteryCrossPaint = Paint()..color = Colors.grey[500]!..strokeWidth = 1.5;
  static final Paint _coolingTowerPaint = Paint()..color = const Color(0xFF37474F);
  static final Paint _trainStationArch = Paint()..color = Colors.grey..style = PaintingStyle.stroke..strokeWidth = 3;

  // Accent / detail colours – stroke variants defined per use-case so that
  // no static Paint object is ever mutated at render time.
  static final Paint _accentRedStroke3  = Paint()
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

  static final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.white10;

  // Shared paint for dynamic colors (spiritual world)
  static final Paint _dynamicPaint = Paint();

  // ---- Render -------------------------------------------------------------

  @override
  void render(Canvas canvas) {
    if (game.isSpiritualWorld) {
      _renderSpiritual(canvas);
    } else {
      _renderPhysical(canvas);
    }

    // Debug border
    canvas.drawRect(size.toRect(), _borderPaint);
  }

  void _renderPhysical(Canvas canvas) {
    final data = cell.data;
    if (data == null) {
      canvas.drawRect(size.toRect(), _tree);
    } else if (data is RoadData) {
      _renderRoad(canvas, data);
    } else if (data is BuildingData) {
      _renderBuilding(canvas, data);
    } else if (data is NatureData) {
      _renderNature(canvas, data);
    }
  }

  void _renderSpiritual(Canvas canvas) {
    final state = cell.spiritualState; // -1.0 to 1.0
    final Color col = state > 0
        ? Color.lerp(Colors.blue[900]!, Colors.amber[400]!, state)!
        : Color.lerp(Colors.grey[900]!, Colors.red[900]!, state.abs())!;

    _dynamicPaint.color = col;
    canvas.drawRect(size.toRect(), _dynamicPaint);

    if (state.abs() > 0.7) {
      _dynamicPaint.style = PaintingStyle.stroke;
      _dynamicPaint.strokeWidth = 2;
      _dynamicPaint.color = col.withValues(alpha: 0.5);
      canvas.drawRect(size.toRect().deflate(2), _dynamicPaint);
      
      // Reset for next use
      _dynamicPaint.style = PaintingStyle.fill;
    }
  }

  void _renderRoad(Canvas canvas, RoadData road) {
    canvas.drawRect(
        size.toRect(), road.type == RoadType.big ? _roadBig : _roadSmall);
    if (road.type == RoadType.big) {
      canvas.drawRect(
          Rect.fromLTWH(size.x * 0.45, 0, size.x * 0.1, size.y), _roadLine);
    }
  }

  void _renderBuilding(Canvas canvas, BuildingData building) {
    switch (building.type) {
      // ---- Residential ---------------------------------------------------
      case BuildingType.house:
        canvas.drawRect(size.toRect(), _fillHouse);
        break;
      case BuildingType.apartment:
        canvas.drawRect(size.toRect(), _fillApartment);
        _drawWindows(canvas, 2);
        break;

      // ---- Commercial ----------------------------------------------------
      case BuildingType.skyscraper:
        canvas.drawRect(size.toRect(), _fillSkyscraper);
        _drawWindows(canvas, 3);
        break;
      case BuildingType.office:
        canvas.drawRect(size.toRect(), _fillOffice);
        _drawWindows(canvas, 2);
        break;
      case BuildingType.shop:
        canvas.drawRect(size.toRect(), _fillShop);
        canvas.drawRect(
            Rect.fromLTWH(size.x * 0.2, size.y * 0.6, size.x * 0.6, size.y * 0.4),
            _accentBlack);
        break;
      case BuildingType.supermarket:
        canvas.drawRect(size.toRect(), _fillSupermarket);
        canvas.drawRect(
            Rect.fromLTWH(size.x * 0.1, size.y * 0.55, size.x * 0.8, size.y * 0.45),
            _accentBlack);
        break;
      case BuildingType.mall:
        canvas.drawRect(size.toRect(), _fillMall);
        _drawWindows(canvas, 2);
        // Large entrance arch
        canvas.drawArc(
            Rect.fromLTWH(size.x * 0.2, size.y * 0.5, size.x * 0.6, size.y * 0.5),
            3.14, 3.14, false, _accentWhiteStroke2);
        break;

      // ---- Industrial ----------------------------------------------------
      case BuildingType.factory:
        canvas.drawRect(size.toRect(), _fillFactory);
        // Chimney stack
        canvas.drawRect(
            Rect.fromLTWH(size.x * 0.6, size.y * 0.1, size.x * 0.15, size.y * 0.5),
            _fillWarehouse);
        break;
      case BuildingType.warehouse:
        canvas.drawRect(size.toRect(), _fillWarehouse);
        // Roof line
        canvas.drawLine(Offset(0, size.y * 0.35),
            Offset(size.x, size.y * 0.35), _accentWhiteStroke1);
        break;

      // ---- Civic ---------------------------------------------------------
      case BuildingType.cityHall:
        canvas.drawRect(size.toRect(), _fillCityHall);
        // Dome symbol
        canvas.drawArc(
            Rect.fromLTWH(size.x * 0.2, size.y * 0.1, size.x * 0.6, size.y * 0.55),
            3.14, 3.14, true, _domePaint);
        // Pillars
        for (double px in [0.25, 0.4, 0.55, 0.7]) {
          canvas.drawRect(
              Rect.fromLTWH(size.x * px, size.y * 0.55, size.x * 0.04, size.y * 0.4),
              _pillarPaint);
        }
        break;
      case BuildingType.policeStation:
        canvas.drawRect(size.toRect(), _fillPolice);
        // Star badge
        canvas.drawCircle(
            Offset(size.x * 0.5, size.y * 0.4), size.x * 0.2, _badgePaint);
        break;
      case BuildingType.fireStation:
        canvas.drawRect(size.toRect(), _fillFire);
        // Garage door
        canvas.drawRect(
            Rect.fromLTWH(size.x * 0.15, size.y * 0.45, size.x * 0.7, size.y * 0.5),
            _accentWhiteStroke2);
        break;
      case BuildingType.postOffice:
        canvas.drawRect(size.toRect(), _fillPostOffice);
        // Envelope symbol
        canvas.drawRect(
            Rect.fromLTWH(size.x * 0.2, size.y * 0.3, size.x * 0.6, size.y * 0.4),
            _accentWhiteStroke2);
        canvas.drawLine(Offset(size.x * 0.2, size.y * 0.3),
            Offset(size.x * 0.5, size.y * 0.5), _accentWhiteStroke2);
        canvas.drawLine(Offset(size.x * 0.8, size.y * 0.3),
            Offset(size.x * 0.5, size.y * 0.5), _accentWhiteStroke2);
        break;
      case BuildingType.trainStation:
        canvas.drawRect(size.toRect(), _fillTrainSt);
        // Arch roof
        canvas.drawArc(
            Rect.fromLTWH(size.x * 0.05, size.y * 0.1, size.x * 0.9, size.y * 0.6),
            3.14, 3.14, false, _trainStationArch);
        // Track lines
        canvas.drawLine(
            Offset(size.x * 0.3, size.y * 0.7), Offset(size.x * 0.3, size.y),
            _accentGoldStroke15);
        canvas.drawLine(
            Offset(size.x * 0.7, size.y * 0.7), Offset(size.x * 0.7, size.y),
            _accentGoldStroke15);
        break;

      // ---- Health & Education -------------------------------------------
      case BuildingType.hospital:
        canvas.drawRect(size.toRect(), _fillHospital);
        canvas.drawLine(Offset(size.x * 0.5, size.y * 0.25),
            Offset(size.x * 0.5, size.y * 0.75), _accentRedStroke3);
        canvas.drawLine(Offset(size.x * 0.25, size.y * 0.5),
            Offset(size.x * 0.75, size.y * 0.5), _accentRedStroke3);
        break;
      case BuildingType.school:
        canvas.drawRect(size.toRect(), _fillSchool);
        // Bell tower hint
        canvas.drawRect(
            Rect.fromLTWH(size.x * 0.35, size.y * 0.05, size.x * 0.3, size.y * 0.3),
            _bellTowerPaint);
        _drawWindows(canvas, 2);
        break;
      case BuildingType.university:
        canvas.drawRect(size.toRect(), _fillUniversity);
        _drawWindows(canvas, 3);
        // Gothic arch
        canvas.drawArc(
            Rect.fromLTWH(size.x * 0.3, size.y * 0.1, size.x * 0.4, size.y * 0.4),
            3.14, 3.14, false, _gothicArchPaint);
        break;

      // ---- Culture / Religion -------------------------------------------
      case BuildingType.church:
        canvas.drawRect(size.toRect(), _fillChurch);
        // Cross
        canvas.drawLine(Offset(size.x * 0.5, size.y * 0.15),
            Offset(size.x * 0.5, size.y * 0.8), _accentBrownStroke2);
        canvas.drawLine(Offset(size.x * 0.3, size.y * 0.35),
            Offset(size.x * 0.7, size.y * 0.35), _accentBrownStroke2);
        break;
      case BuildingType.cathedral:
        canvas.drawRect(size.toRect(), _fillCathedral);
        // Prominent cross + spire
        canvas.drawLine(Offset(size.x * 0.5, size.y * 0.05),
            Offset(size.x * 0.5, size.y * 0.85), _accentBrownStroke3);
        canvas.drawLine(Offset(size.x * 0.25, size.y * 0.3),
            Offset(size.x * 0.75, size.y * 0.3), _accentBrownStroke3);
        // Side towers
        canvas.drawRect(
            Rect.fromLTWH(size.x * 0.05, size.y * 0.25, size.x * 0.18, size.y * 0.7),
            _cathedralTowerPaint);
        canvas.drawRect(
            Rect.fromLTWH(size.x * 0.77, size.y * 0.25, size.x * 0.18, size.y * 0.7),
            _cathedralTowerPaint);
        break;
      case BuildingType.library:
        canvas.drawRect(size.toRect(), _fillLibrary);
        // Book shelves hint
        for (double ly in [0.3, 0.5, 0.7]) {
          canvas.drawLine(Offset(size.x * 0.15, size.y * ly),
              Offset(size.x * 0.85, size.y * ly), _libraryShelfPaint);
        }
        break;
      case BuildingType.museum:
        canvas.drawRect(size.toRect(), _fillMuseum);
        // Column row
        for (double px in [0.2, 0.4, 0.6, 0.8]) {
          canvas.drawRect(
              Rect.fromLTWH(size.x * px - 0.02 * size.x, size.y * 0.4,
                  size.x * 0.04, size.y * 0.55),
              _museumColumnPaint);
        }
        // Pediment triangle
        final path = Path()
          ..moveTo(size.x * 0.1, size.y * 0.4)
          ..lineTo(size.x * 0.5, size.y * 0.1)
          ..lineTo(size.x * 0.9, size.y * 0.4)
          ..close();
        canvas.drawPath(path, _museumPedimentPaint);
        break;
      case BuildingType.stadium:
        canvas.drawRect(size.toRect(), _fillStadium);
        // Oval pitch
        canvas.drawOval(
            Rect.fromLTWH(size.x * 0.1, size.y * 0.15, size.x * 0.8, size.y * 0.7),
            _stadiumPitchStroke);
        canvas.drawOval(
            Rect.fromLTWH(size.x * 0.2, size.y * 0.25, size.x * 0.6, size.y * 0.5),
            _stadiumPitchFill);
        break;
      case BuildingType.cemetery:
        canvas.drawRect(size.toRect(), _fillCemetery);
        // Cross markers
        for (int i = 0; i < 3; i++) {
          final cx = size.x * (0.25 + i * 0.25);
          canvas.drawLine(Offset(cx, size.y * 0.2), Offset(cx, size.y * 0.7), _cemeteryCrossPaint);
          canvas.drawLine(Offset(cx - size.x * 0.08, size.y * 0.35),
              Offset(cx + size.x * 0.08, size.y * 0.35), _cemeteryCrossPaint);
        }
        break;
      case BuildingType.powerPlant:
        canvas.drawRect(size.toRect(), _fillPowerPlant);
        // Cooling towers
        canvas.drawRect(
            Rect.fromLTWH(size.x * 0.1, size.y * 0.3, size.x * 0.3, size.y * 0.65),
            _coolingTowerPaint);
        canvas.drawRect(
            Rect.fromLTWH(size.x * 0.6, size.y * 0.3, size.x * 0.3, size.y * 0.65),
            _coolingTowerPaint);
        break;
    }
  }

  void _renderNature(Canvas canvas, NatureData nature) {
    switch (nature.type) {
      case NatureType.water:
        canvas.drawRect(size.toRect(), _water);
        break;
      case NatureType.tree:
        canvas.drawRect(size.toRect(), _tree);
        break;
      case NatureType.park:
        canvas.drawRect(size.toRect(), _park);
        break;
    }
  }

  void _drawWindows(Canvas canvas, int rows) {
    for (int i = 0; i < rows; i++) {
      canvas.drawRect(
          Rect.fromLTWH(
              size.x * 0.2, size.y * (0.2 + i * 0.25), size.x * 0.2, size.y * 0.15),
          _accentYellow);
      canvas.drawRect(
          Rect.fromLTWH(
              size.x * 0.6, size.y * (0.2 + i * 0.25), size.x * 0.2, size.y * 0.15),
          _accentYellow);
    }
  }
}
