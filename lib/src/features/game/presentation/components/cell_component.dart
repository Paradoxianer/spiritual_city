import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/models/city_cell.dart';
import '../../domain/models/cell_object.dart';
import '../spirit_world_game.dart';

class CellComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final CityCell cell;
  static const double cellSize = 32.0;

  CellComponent(this.cell) {
    position = Vector2(cell.x * cellSize, cell.y * cellSize);
    size = Vector2.all(cellSize);
  }

  @override
  void render(Canvas canvas) {
    final isSpiritual = game.isSpiritualWorld;
    final paint = Paint()..style = PaintingStyle.fill;
    
    if (isSpiritual) {
      _renderSpiritual(canvas, paint);
    } else {
      _renderPhysical(canvas, paint);
    }

    // Debug: Draw border
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.white10;
    canvas.drawRect(size.toRect(), paint);
  }

  void _renderPhysical(Canvas canvas, Paint paint) {
    final data = cell.data;
    if (data == null) {
      paint.color = Colors.green[900]!;
      canvas.drawRect(size.toRect(), paint);
    } else if (data is RoadData) {
      _renderRoad(canvas, data);
    } else if (data is BuildingData) {
      _renderBuilding(canvas, data);
    } else if (data is NatureData) {
      _renderNature(canvas, data);
    }
  }

  void _renderSpiritual(Canvas canvas, Paint paint) {
    // Spiritual world: Blue/Gold (positive) to Grey/Red (negative)
    final state = cell.spiritualState; // -1.0 to 1.0
    
    if (state > 0) {
      // Positive: Gold/Blue
      paint.color = Color.lerp(Colors.blue[900], Colors.amber[400], state)!;
    } else {
      // Negative: Grey/Red
      paint.color = Color.lerp(Colors.grey[900], Colors.red[900], state.abs())!;
    }
    
    canvas.drawRect(size.toRect(), paint);
    
    // Add "glow" or "pulse" effect for strong spiritual areas
    if (state.abs() > 0.7) {
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      paint.color = paint.color.withValues(alpha: 0.5);
      canvas.drawRect(size.toRect().deflate(2), paint);
    }
  }

  void _renderRoad(Canvas canvas, RoadData road) {
    final paint = Paint()..color = road.type == RoadType.big ? Colors.grey[700]! : Colors.grey[800]!;
    canvas.drawRect(size.toRect(), paint);
    if (road.type == RoadType.big) {
      paint.color = Colors.yellow.withValues(alpha: 0.3);
      canvas.drawRect(Rect.fromLTWH(size.x * 0.45, 0, size.x * 0.1, size.y), paint);
    }
  }

  void _renderBuilding(Canvas canvas, BuildingData building) {
    switch (building.type) {
      case BuildingType.skyscraper:
        canvas.drawRect(size.toRect(), Paint()..color = Colors.blueGrey[900]!);
        _drawWindows(canvas, 3);
        break;
      case BuildingType.church:
        canvas.drawRect(size.toRect(), Paint()..color = Colors.amber[200]!);
        final p = Paint()..color = Colors.brown..strokeWidth = 2;
        canvas.drawLine(Offset(size.x * 0.5, size.y * 0.2), Offset(size.x * 0.5, size.y * 0.8), p);
        canvas.drawLine(Offset(size.x * 0.3, size.y * 0.4), Offset(size.x * 0.7, size.y * 0.4), p);
        break;
      case BuildingType.hospital:
        canvas.drawRect(size.toRect(), Paint()..color = Colors.white);
        final p = Paint()..color = Colors.red..strokeWidth = 3;
        canvas.drawLine(Offset(size.x * 0.5, size.y * 0.3), Offset(size.x * 0.5, size.y * 0.7), p);
        canvas.drawLine(Offset(size.x * 0.3, size.y * 0.5), Offset(size.x * 0.7, size.y * 0.5), p);
        break;
      case BuildingType.house:
        canvas.drawRect(size.toRect(), Paint()..color = Colors.brown[400]!);
        break;
      case BuildingType.shop:
        canvas.drawRect(size.toRect(), Paint()..color = Colors.blue[400]!);
        // Simple shop front
        canvas.drawRect(Rect.fromLTWH(size.x * 0.2, size.y * 0.6, size.x * 0.6, size.y * 0.4), Paint()..color = Colors.black45);
        break;
    }
  }

  void _renderNature(Canvas canvas, NatureData nature) {
    final paint = Paint();
    if (nature.type == NatureType.water) {
      paint.color = Colors.blue[800]!;
    } else {
      paint.color = Colors.green[700]!;
    }
    canvas.drawRect(size.toRect(), paint);
  }

  void _drawWindows(Canvas canvas, int count) {
    final p = Paint()..color = Colors.yellow.withValues(alpha: 0.5);
    for (int i = 0; i < count; i++) {
      canvas.drawRect(Rect.fromLTWH(size.x * 0.2, size.y * (0.2 + i * 0.25), size.x * 0.2, size.y * 0.15), p);
      canvas.drawRect(Rect.fromLTWH(size.x * 0.6, size.y * (0.2 + i * 0.25), size.x * 0.2, size.y * 0.15), p);
    }
  }
}
