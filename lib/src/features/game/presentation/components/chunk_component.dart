import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../domain/models/city_chunk.dart';
import '../../domain/models/city_cell.dart';
import '../../domain/models/cell_object.dart';
import 'cell_component.dart';
import '../spirit_world_game.dart';

class ChunkComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final CityChunk chunk;
  static const double cellSize = CellComponent.cellSize;

  // Cache for the rendered chunk to boost performance
  Picture? _cachedPicture;
  bool _isSpiritualCache = false;

  ChunkComponent(this.chunk) {
    position = Vector2(
      chunk.chunkX * CityChunk.chunkSize * cellSize,
      chunk.chunkY * CityChunk.chunkSize * cellSize,
    );
    size = Vector2.all(CityChunk.chunkSize * cellSize);
    priority = 0;
  }

  void _createCache() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    
    _isSpiritualCache = game.isSpiritualWorld;

    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;

        final offset = Offset(x * cellSize, y * cellSize);
        
        if (_isSpiritualCache) {
          _renderSpiritualCell(canvas, cell, offset);
        } else {
          _renderPhysicalCell(canvas, cell, offset);
        }
        
        // Border
        canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, cellSize, cellSize), _borderPaint);
      }
    }
    _cachedPicture = recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    // Re-create cache if world type changed or cache is null
    if (_cachedPicture == null || _isSpiritualCache != game.isSpiritualWorld) {
      _createCache();
    }
    
    if (_cachedPicture != null) {
      canvas.drawPicture(_cachedPicture!);
    }
  }

  // --- RENDERING LOGIC (Optimized: No save/restore inside loops) ---

  static final Paint _roadBig   = Paint()..color = const Color(0xFF616161);
  static final Paint _roadSmall = Paint()..color = const Color(0xFF424242);
  static final Paint _roadLine  = Paint()..color = const Color(0x4DFFEB3B);
  static final Paint _water = Paint()..color = const Color(0xFF1565C0);
  static final Paint _tree  = Paint()..color = const Color(0xFF388E3C);
  static final Paint _fillHouse = Paint()..color = const Color(0xFF795548);
  static final Paint _fillApartment = Paint()..color = const Color(0xFF5D4037);
  static final Paint _fillSkyscraper = Paint()..color = const Color(0xFF263238);
  static final Paint _accentYellow = Paint()..color = Colors.yellow.withOpacity(0.5);
  static final Paint _borderPaint = Paint()..style = PaintingStyle.stroke..color = Colors.white10;

  void _renderPhysicalCell(Canvas canvas, CityCell cell, Offset offset) {
    final data = cell.data;
    final rect = Rect.fromLTWH(offset.dx, offset.dy, cellSize, cellSize);
    
    if (data == null) {
      canvas.drawRect(rect, _tree);
    } else if (data is RoadData) {
      canvas.drawRect(rect, data.type == RoadType.big ? _roadBig : _roadSmall);
      if (data.type == RoadType.big) {
        canvas.drawRect(Rect.fromLTWH(offset.dx + cellSize * 0.45, offset.dy, cellSize * 0.1, cellSize), _roadLine);
      }
    } else if (data is BuildingData) {
      final paint = data.type == BuildingType.house ? _fillHouse : 
                   data.type == BuildingType.apartment ? _fillApartment : _fillSkyscraper;
      canvas.drawRect(rect, paint);
      // Windows
      canvas.drawRect(Rect.fromLTWH(offset.dx + cellSize * 0.2, offset.dy + cellSize * 0.3, cellSize * 0.2, cellSize * 0.2), _accentYellow);
      canvas.drawRect(Rect.fromLTWH(offset.dx + cellSize * 0.6, offset.dy + cellSize * 0.3, cellSize * 0.2, cellSize * 0.2), _accentYellow);
    } else if (data is NatureData) {
      canvas.drawRect(rect, data.type == NatureType.water ? _water : _tree);
    }
  }

  void _renderSpiritualCell(Canvas canvas, CityCell cell, Offset offset) {
    final state = cell.spiritualState;
    final Color col = state > 0
        ? Color.lerp(Colors.blue[900]!, Colors.amber[400]!, state)!
        : Color.lerp(Colors.grey[900]!, Colors.red[900]!, state.abs())!;

    final paint = Paint()..color = col;
    canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, cellSize, cellSize), paint);
  }
}
