import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/models/city_cell.dart';
import '../spirit_world_game.dart';
import 'city_tile_renderer.dart';

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

  // Residuum ash mark (daemon natural dissolution imprint)
  static final Paint _residuumPaint = Paint()
    ..color = const Color(0x99616161) // grey[700] at 60 % alpha
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  // Shared paint for dynamic colors (spiritual world)
  static final Paint _dynamicPaint = Paint();

  static final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.white10;

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
    CityTileRenderer.renderCell(canvas, size.toRect(), cell.data);
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

    // Residuum mark: ash-grey 'X' left by a naturally dissolved daemon
    if (cell.hasResiduum) {
      canvas.drawLine(Offset(size.x * 0.2, size.y * 0.2),
          Offset(size.x * 0.8, size.y * 0.8), _residuumPaint);
      canvas.drawLine(Offset(size.x * 0.8, size.y * 0.2),
          Offset(size.x * 0.2, size.y * 0.8), _residuumPaint);
    }
  }

}
