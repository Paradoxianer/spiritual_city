import 'dart:ui';
import 'package:flame/components.dart';
import '../../domain/entities/spiritual_cell_state.dart';
import '../../../../core/constants/game_constants.dart';

class SpiritualOverlayComponent extends PositionComponent {
  final int _gridWidth;
  final int _gridHeight;

  late List<List<SpiritualCellState>> spiritualGrid;
  bool isVisible = false;

  static const _lightColor = Color.fromARGB(120, 100, 180, 255);
  static const _darkColor = Color.fromARGB(80, 150, 0, 0);

  SpiritualOverlayComponent({required int width, required int height})
      : _gridWidth = width,
        _gridHeight = height {
    spiritualGrid = List.generate(
      height,
      (_) => List.generate(
        width,
        (_) => const SpiritualCellState(),
      ),
    );
  }

  void updateGrid(List<List<SpiritualCellState>> newGrid) {
    spiritualGrid = newGrid;
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;
    final paint = Paint();
    for (int y = 0; y < _gridHeight; y++) {
      for (int x = 0; x < _gridWidth; x++) {
        final cell = spiritualGrid[y][x];
        paint.color = cell.isActive ? _lightColor : _darkColor;
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
