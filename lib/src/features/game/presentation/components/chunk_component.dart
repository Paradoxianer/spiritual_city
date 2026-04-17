import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../domain/models/city_chunk.dart';
import 'cell_component.dart';
import '../spirit_world_game.dart';
import 'city_tile_renderer.dart';
import 'spiritual_renderer.dart';

class ChunkComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final CityChunk chunk;
  static const double cellSize = CellComponent.cellSize;

  Picture? _cachedPicture;
  late final SpiritualRenderer _spiritualRenderer;

  ChunkComponent(this.chunk) {
    position = Vector2(
      chunk.chunkX * CityChunk.chunkSize * cellSize,
      chunk.chunkY * CityChunk.chunkSize * cellSize,
    );
    size = Vector2.all(CityChunk.chunkSize * cellSize);
    
    _spiritualRenderer = SpiritualRenderer(chunk);
    add(_spiritualRenderer);
  }

  void _createCache() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;
        final rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);
        CityTileRenderer.renderCell(canvas, rect, cell.data);
        canvas.drawRect(rect, _borderPaint);
      }
    }
    _cachedPicture = recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    // Wenn wir in der unsichtbaren Welt sind, rendert der SpiritualRenderer (als Child)
    // Wir rendern hier nur die physische Welt, falls sichtbar oder transparent
    if (!game.isSpiritualWorld) {
      if (_cachedPicture == null) {
        _createCache();
      }
      if (_cachedPicture != null) {
        canvas.drawPicture(_cachedPicture!);
      }
    }
  }

  static final Paint _borderPaint = Paint()..style = PaintingStyle.stroke..color = Colors.white10;
}
