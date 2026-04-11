import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../domain/models/city_chunk.dart';
import '../../domain/models/city_cell.dart';
import '../../domain/models/cell_object.dart';
import 'cell_component.dart';
import '../spirit_world_game.dart';
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
        final offset = Offset(x * cellSize, y * cellSize);
        _renderPhysicalCell(canvas, cell, offset);
        canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, cellSize, cellSize), _borderPaint);
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

  static final Paint _roadBig = Paint()..color = const Color(0xFF616161);
  static final Paint _roadSmall = Paint()..color = const Color(0xFF424242);
  static final Paint _roadLine = Paint()..color = const Color(0x4DFFEB3B);
  static final Paint _water = Paint()..color = const Color(0xFF1565C0);
  static final Paint _tree = Paint()..color = const Color(0xFF388E3C);
  static final Paint _fillHouse = Paint()..color = const Color(0xFF795548);
  static final Paint _fillApartment = Paint()..color = const Color(0xFF5D4037);
  static final Paint _fillSkyscraper = Paint()..color = const Color(0xFF263238);
  static final Paint _accentYellow = Paint()..color = Colors.yellow.withValues(alpha: 0.5);
  static final Paint _borderPaint = Paint()..style = PaintingStyle.stroke..color = Colors.white10;

  void _renderPhysicalCell(Canvas canvas, CityCell cell, Offset offset) {
    final data = cell.data;
    final rect = Rect.fromLTWH(offset.dx, offset.dy, cellSize, cellSize);
    if (data == null) { canvas.drawRect(rect, _tree); }
    else if (data is RoadData) {
      canvas.drawRect(rect, data.type == RoadType.big ? _roadBig : _roadSmall);
      if (data.type == RoadType.big) canvas.drawRect(Rect.fromLTWH(offset.dx + cellSize * 0.45, offset.dy, cellSize * 0.1, cellSize), _roadLine);
    } else if (data is BuildingData) {
      final p = data.type == BuildingType.house ? _fillHouse : data.type == BuildingType.apartment ? _fillApartment : _fillSkyscraper;
      canvas.drawRect(rect, p);
      canvas.drawRect(Rect.fromLTWH(offset.dx + cellSize * 0.2, offset.dy + cellSize * 0.3, cellSize * 0.2, cellSize * 0.2), _accentYellow);
      canvas.drawRect(Rect.fromLTWH(offset.dx + cellSize * 0.6, offset.dy + cellSize * 0.3, cellSize * 0.2, cellSize * 0.2), _accentYellow);
    } else if (data is NatureData) { canvas.drawRect(rect, data.type == NatureType.water ? _water : _tree); }
  }
}
