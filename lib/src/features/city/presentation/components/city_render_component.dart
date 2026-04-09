import 'dart:ui';
import 'package:flame/components.dart';
import '../../domain/entities/cell_type.dart';
import '../../domain/entities/city_grid.dart';
import '../../../../core/constants/game_constants.dart';

class CityRenderComponent extends PositionComponent {
  final CityGrid _cityGrid;

  CityRenderComponent(this._cityGrid);

  static const _roadColor = Color(0xFF555555);
  static const _buildingColor = Color(0xFF8B4513);
  static const _parkColor = Color(0xFF228B22);
  static const _waterColor = Color(0xFF1E90FF);

  @override
  void render(Canvas canvas) {
    final paint = Paint();
    for (int y = 0; y < _cityGrid.height; y++) {
      for (int x = 0; x < _cityGrid.width; x++) {
        final cell = _cityGrid.cellAt(x, y);
        paint.color = switch (cell.type) {
          CellType.road => _roadColor,
          CellType.building => _buildingColor,
          CellType.park => _parkColor,
          CellType.water => _waterColor,
        };
        canvas.drawRect(
          Rect.fromLTWH(
            x * GameConstants.cellSize,
            y * GameConstants.cellSize,
            GameConstants.cellSize,
            GameConstants.cellSize,
          ),
          paint,
        );
      }
    }
  }
}
