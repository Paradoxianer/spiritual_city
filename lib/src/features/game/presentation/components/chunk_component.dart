import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/models/city_chunk.dart';
import '../../domain/models/city_cell.dart';
import '../../domain/models/cell_object.dart';
import 'cell_component.dart';
import '../spirit_world_game.dart';

class ChunkComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final CityChunk chunk;
  static const double cellSize = CellComponent.cellSize;

  ChunkComponent(this.chunk) {
    position = Vector2(
      chunk.chunkX * CityChunk.chunkSize * cellSize,
      chunk.chunkY * CityChunk.chunkSize * cellSize,
    );
    size = Vector2.all(CityChunk.chunkSize * cellSize);
    priority = 0;
  }

  // ---- Rendering Logic (Copied and adapted from CellComponent) ----

  // Static paints to avoid allocations
  static final Paint _roadBig   = Paint()..color = const Color(0xFF616161);
  static final Paint _roadSmall = Paint()..color = const Color(0xFF424242);
  static final Paint _roadLine  = Paint()..color = const Color(0x4DFFEB3B);
  static final Paint _water = Paint()..color = const Color(0xFF1565C0);
  static final Paint _tree  = Paint()..color = const Color(0xFF388E3C);
  static final Paint _park  = Paint()..color = const Color(0xFF4CAF50);

  static final Paint _fillSkyscraper  = Paint()..color = const Color(0xFF263238);
  static final Paint _fillOffice      = Paint()..color = const Color(0xFF37474F);
  static final Paint _fillApartment   = Paint()..color = const Color(0xFF5D4037);
  static final Paint _fillHouse       = Paint()..color = const Color(0xFF795548);
  static final Paint _fillShop        = Paint()..color = const Color(0xFF1976D2);
  static final Paint _fillSupermarket = Paint()..color = const Color(0xFF0288D1);
  static final Paint _fillMall        = Paint()..color = const Color(0xFF1565C0);
  static final Paint _fillFactory     = Paint()..color = const Color(0xFF546E7A);
  static final Paint _fillWarehouse   = Paint()..color = const Color(0xFF607D8B);
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

  static final Paint _accentRedStroke3 = Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 3;
  static final Paint _accentWhiteStroke2 = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;
  static final Paint _accentWhiteStroke1 = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5;
  static final Paint _accentBrownStroke2 = Paint()..color = Colors.brown..style = PaintingStyle.stroke..strokeWidth = 2;
  static final Paint _accentBrownStroke3 = Paint()..color = Colors.brown..style = PaintingStyle.stroke..strokeWidth = 3;
  static final Paint _accentGoldStroke15 = Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 1.5;
  static final Paint _accentYellow = Paint()..color = Colors.yellow.withOpacity(0.5);
  static final Paint _accentBlack = Paint()..color = Colors.black45;
  static final Paint _borderPaint = Paint()..style = PaintingStyle.stroke..color = Colors.white10;

  static final Paint _dynamicPaint = Paint();

  @override
  void render(Canvas canvas) {
    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;

        canvas.save();
        canvas.translate(x * cellSize, y * cellSize);
        
        if (game.isSpiritualWorld) {
          _renderSpiritualCell(canvas, cell);
        } else {
          _renderPhysicalCell(canvas, cell);
        }
        
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _borderPaint);
        canvas.restore();
      }
    }
  }

  void _renderPhysicalCell(Canvas canvas, CityCell cell) {
    final data = cell.data;
    if (data == null) {
      canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _tree);
    } else if (data is RoadData) {
      _renderRoad(canvas, data);
    } else if (data is BuildingData) {
      _renderBuilding(canvas, data);
    } else if (data is NatureData) {
      _renderNature(canvas, data);
    }
  }

  void _renderSpiritualCell(Canvas canvas, CityCell cell) {
    final state = cell.spiritualState;
    final Color col = state > 0
        ? Color.lerp(Colors.blue[900]!, Colors.amber[400]!, state)!
        : Color.lerp(Colors.grey[900]!, Colors.red[900]!, state.abs())!;

    _dynamicPaint.color = col;
    _dynamicPaint.style = PaintingStyle.fill;
    canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _dynamicPaint);

    if (state.abs() > 0.7) {
      _dynamicPaint.style = PaintingStyle.stroke;
      _dynamicPaint.strokeWidth = 2;
      _dynamicPaint.color = col.withOpacity(0.5);
      canvas.drawRect(const Rect.fromLTWH(2, 2, cellSize - 4, cellSize - 4), _dynamicPaint);
    }
  }

  void _renderRoad(Canvas canvas, RoadData road) {
    canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), 
        road.type == RoadType.big ? _roadBig : _roadSmall);
    if (road.type == RoadType.big) {
      canvas.drawRect(const Rect.fromLTWH(cellSize * 0.45, 0, cellSize * 0.1, cellSize), _roadLine);
    }
  }

  void _renderBuilding(Canvas canvas, BuildingData building) {
    switch (building.type) {
      case BuildingType.house:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillHouse);
        break;
      case BuildingType.apartment:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillApartment);
        _drawWindows(canvas, 2);
        break;
      case BuildingType.skyscraper:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillSkyscraper);
        _drawWindows(canvas, 3);
        break;
      case BuildingType.office:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillOffice);
        _drawWindows(canvas, 2);
        break;
      case BuildingType.shop:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillShop);
        canvas.drawRect(const Rect.fromLTWH(cellSize * 0.2, cellSize * 0.6, cellSize * 0.6, cellSize * 0.4), _accentBlack);
        break;
      case BuildingType.supermarket:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillSupermarket);
        canvas.drawRect(const Rect.fromLTWH(cellSize * 0.1, cellSize * 0.55, cellSize * 0.8, cellSize * 0.45), _accentBlack);
        break;
      case BuildingType.mall:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillMall);
        _drawWindows(canvas, 2);
        canvas.drawArc(const Rect.fromLTWH(cellSize * 0.2, cellSize * 0.5, cellSize * 0.6, cellSize * 0.5), 3.14, 3.14, false, _accentWhiteStroke2);
        break;
      case BuildingType.factory:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillFactory);
        canvas.drawRect(const Rect.fromLTWH(cellSize * 0.6, cellSize * 0.1, cellSize * 0.15, cellSize * 0.5), _fillWarehouse);
        break;
      case BuildingType.warehouse:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillWarehouse);
        canvas.drawLine(Offset(0, cellSize * 0.35), Offset(cellSize, cellSize * 0.35), _accentWhiteStroke1);
        break;
      case BuildingType.cityHall:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillCityHall);
        canvas.drawArc(const Rect.fromLTWH(cellSize * 0.2, cellSize * 0.1, cellSize * 0.6, cellSize * 0.55), 3.14, 3.14, true, Paint()..color = Colors.blueGrey);
        for (double px in [0.25, 0.4, 0.55, 0.7]) {
          canvas.drawRect(Rect.fromLTWH(cellSize * px, cellSize * 0.55, cellSize * 0.04, cellSize * 0.4), Paint()..color = Colors.grey);
        }
        break;
      case BuildingType.policeStation:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillPolice);
        canvas.drawCircle(Offset(cellSize * 0.5, cellSize * 0.4), cellSize * 0.2, Paint()..color = const Color(0xFFFFD700));
        break;
      case BuildingType.fireStation:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillFire);
        canvas.drawRect(const Rect.fromLTWH(cellSize * 0.15, cellSize * 0.45, cellSize * 0.7, cellSize * 0.5), _accentWhiteStroke2);
        break;
      case BuildingType.postOffice:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillPostOffice);
        canvas.drawRect(const Rect.fromLTWH(cellSize * 0.2, cellSize * 0.3, cellSize * 0.6, cellSize * 0.4), _accentWhiteStroke2);
        canvas.drawLine(Offset(cellSize * 0.2, cellSize * 0.3), Offset(cellSize * 0.5, cellSize * 0.5), _accentWhiteStroke2);
        canvas.drawLine(Offset(cellSize * 0.8, cellSize * 0.3), Offset(cellSize * 0.5, cellSize * 0.5), _accentWhiteStroke2);
        break;
      case BuildingType.trainStation:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillTrainSt);
        canvas.drawArc(const Rect.fromLTWH(cellSize * 0.05, cellSize * 0.1, cellSize * 0.9, cellSize * 0.6), 3.14, 3.14, false, Paint()..color = Colors.grey..style = PaintingStyle.stroke..strokeWidth = 3);
        canvas.drawLine(Offset(cellSize * 0.3, cellSize * 0.7), Offset(cellSize * 0.3, cellSize), _accentGoldStroke15);
        canvas.drawLine(Offset(cellSize * 0.7, cellSize * 0.7), Offset(cellSize * 0.7, cellSize), _accentGoldStroke15);
        break;
      case BuildingType.hospital:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillHospital);
        canvas.drawLine(Offset(cellSize * 0.5, cellSize * 0.25), Offset(cellSize * 0.5, cellSize * 0.75), _accentRedStroke3);
        canvas.drawLine(Offset(cellSize * 0.25, cellSize * 0.5), Offset(cellSize * 0.75, cellSize * 0.5), _accentRedStroke3);
        break;
      case BuildingType.school:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillSchool);
        canvas.drawRect(const Rect.fromLTWH(cellSize * 0.35, cellSize * 0.05, cellSize * 0.3, cellSize * 0.3), Paint()..color = const Color(0xFFBF360C));
        _drawWindows(canvas, 2);
        break;
      case BuildingType.university:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillUniversity);
        _drawWindows(canvas, 3);
        canvas.drawArc(const Rect.fromLTWH(cellSize * 0.3, cellSize * 0.1, cellSize * 0.4, cellSize * 0.4), 3.14, 3.14, false, Paint()..color = Colors.pink..style = PaintingStyle.stroke..strokeWidth = 2);
        break;
      case BuildingType.church:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillChurch);
        canvas.drawLine(Offset(cellSize * 0.5, cellSize * 0.15), Offset(cellSize * 0.5, cellSize * 0.8), _accentBrownStroke2);
        canvas.drawLine(Offset(cellSize * 0.3, cellSize * 0.35), Offset(cellSize * 0.7, cellSize * 0.35), _accentBrownStroke2);
        break;
      case BuildingType.cathedral:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillCathedral);
        canvas.drawLine(Offset(cellSize * 0.5, cellSize * 0.05), Offset(cellSize * 0.5, cellSize * 0.85), _accentBrownStroke3);
        canvas.drawLine(Offset(cellSize * 0.25, cellSize * 0.3), Offset(cellSize * 0.75, cellSize * 0.3), _accentBrownStroke3);
        canvas.drawRect(const Rect.fromLTWH(cellSize * 0.05, cellSize * 0.25, cellSize * 0.18, cellSize * 0.7), Paint()..color = const Color(0xFFFFCC02));
        canvas.drawRect(const Rect.fromLTWH(cellSize * 0.77, cellSize * 0.25, cellSize * 0.18, cellSize * 0.7), Paint()..color = const Color(0xFFFFCC02));
        break;
      case BuildingType.library:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillLibrary);
        for (double ly in [0.3, 0.5, 0.7]) {
          canvas.drawLine(Offset(cellSize * 0.15, cellSize * ly), Offset(cellSize * 0.85, cellSize * ly), Paint()..color = Colors.purple[300]!..strokeWidth = 2);
        }
        break;
      case BuildingType.museum:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillMuseum);
        for (double px in [0.2, 0.4, 0.6, 0.8]) {
          canvas.drawRect(Rect.fromLTWH(cellSize * px - 0.02 * cellSize, cellSize * 0.4, cellSize * 0.04, cellSize * 0.55), Paint()..color = Colors.deepPurple[300]!);
        }
        final path = Path()
          ..moveTo(cellSize * 0.1, cellSize * 0.4)
          ..lineTo(cellSize * 0.5, cellSize * 0.1)
          ..lineTo(cellSize * 0.9, cellSize * 0.4)
          ..close();
        canvas.drawPath(path, Paint()..color = Colors.deepPurple[200]!);
        break;
      case BuildingType.stadium:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillStadium);
        canvas.drawOval(const Rect.fromLTWH(cellSize * 0.1, cellSize * 0.15, cellSize * 0.8, cellSize * 0.7), Paint()..color = const Color(0xFF2E7D32)..style = PaintingStyle.stroke..strokeWidth = 3);
        canvas.drawOval(const Rect.fromLTWH(cellSize * 0.2, cellSize * 0.25, cellSize * 0.6, cellSize * 0.5), Paint()..color = const Color(0xFF43A047));
        break;
      case BuildingType.cemetery:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillCemetery);
        for (int i = 0; i < 3; i++) {
          final cx = cellSize * (0.25 + i * 0.25);
          canvas.drawLine(Offset(cx, cellSize * 0.2), Offset(cx, cellSize * 0.7), Paint()..color = Colors.grey[500]!..strokeWidth = 1.5);
          canvas.drawLine(Offset(cx - cellSize * 0.08, cellSize * 0.35), Offset(cx + cellSize * 0.08, cellSize * 0.35), Paint()..color = Colors.grey[500]!..strokeWidth = 1.5);
        }
        break;
      case BuildingType.powerPlant:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _fillPowerPlant);
        canvas.drawRect(const Rect.fromLTWH(cellSize * 0.1, cellSize * 0.3, cellSize * 0.3, cellSize * 0.65), Paint()..color = const Color(0xFF37474F));
        canvas.drawRect(const Rect.fromLTWH(cellSize * 0.6, cellSize * 0.3, cellSize * 0.3, cellSize * 0.65), Paint()..color = const Color(0xFF37474F));
        break;
    }
  }

  void _renderNature(Canvas canvas, NatureData nature) {
    switch (nature.type) {
      case NatureType.water:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _water);
        break;
      case NatureType.tree:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _tree);
        break;
      case NatureType.park:
        canvas.drawRect(const Rect.fromLTWH(0, 0, cellSize, cellSize), _park);
        break;
    }
  }

  void _drawWindows(Canvas canvas, int rows) {
    for (int i = 0; i < rows; i++) {
      canvas.drawRect(Rect.fromLTWH(cellSize * 0.2, cellSize * (0.2 + i * 0.25), cellSize * 0.2, cellSize * 0.15), _accentYellow);
      canvas.drawRect(Rect.fromLTWH(cellSize * 0.6, cellSize * (0.2 + i * 0.25), cellSize * 0.2, cellSize * 0.15), _accentYellow);
    }
  }
}
