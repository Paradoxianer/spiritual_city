import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/models/city_cell.dart';

class CellComponent extends PositionComponent {
  final CityCell cell;
  static const double cellSize = 32.0;

  CellComponent(this.cell) {
    position = Vector2(cell.x * cellSize, cell.y * cellSize);
    size = Vector2.all(cellSize);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Base color based on type
    switch (cell.type) {
      case CellType.road:
        paint.color = Colors.grey[800]!;
        break;
      case CellType.buildingLarge:
        paint.color = Colors.blueGrey[900]!;
        break;
      case CellType.buildingSmall:
        paint.color = Colors.brown[400]!;
        break;
      case CellType.church:
        paint.color = Colors.amber[200]!;
        break;
      case CellType.park:
        paint.color = Colors.green[700]!;
        break;
      case CellType.empty:
        paint.color = Colors.green[900]!;
        break;
    }

    canvas.drawRect(size.toRect(), paint);
    
    // Debug: Draw border
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.white10;
    canvas.drawRect(size.toRect(), paint);
  }
}
