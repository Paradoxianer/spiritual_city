import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../domain/models/city_chunk.dart';
import '../../domain/models/city_cell.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';

class SpiritualRenderer extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final CityChunk chunk;
  static const double cellSize = CellComponent.cellSize;

  Picture? _cachedPicture;
  double _lastTime = 0;

  SpiritualRenderer(this.chunk) {
    size = Vector2.all(CityChunk.chunkSize * cellSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lastTime += dt;
    // Wir invalidieren den Cache regelmäßig für den "Lavalampen"-Effekt (Perlin Noise Animation)
    // In einer echten Implementierung würden wir hier Shader nutzen, 
    // aber für "Simple but Elegant" reicht ein Repaint-Interval.
    if (_lastTime > 0.1) {
      _cachedPicture = null;
      _lastTime = 0;
    }
  }

  void _createCache() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;
        
        final offset = Offset(x * cellSize, y * cellSize);
        _renderSpiritualCell(canvas, cell, offset);
      }
    }
    _cachedPicture = recorder.endRecording();
  }

  void _renderSpiritualCell(Canvas canvas, CityCell cell, Offset offset) {
    final state = cell.spiritualState; // -1.0 bis +1.0
    
    // Farbskala laut Lastenheft 5.1: Rot (Negativ) <-> Beige (Neutral) <-> Grün (Positiv)
    Color color;
    if (state < -0.3) {
      // Rot-Töne
      color = Color.lerp(Colors.black, Colors.red[900]!, (state + 1.0) / 0.7)!;
    } else if (state > 0.3) {
      // Grün-Töne
      color = Color.lerp(Colors.lightGreen[200]!, Colors.green[900]!, (state - 0.3) / 0.7)!;
    } else {
      // Neutraler Bereich (Beige/Weiß)
      color = Colors.wheat.withValues(alpha: 0.3);
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8); // Gaussian Blur Effekt laut #30

    canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, cellSize, cellSize), paint);
  }

  @override
  void render(Canvas canvas) {
    if (!game.isSpiritualWorld) return;
    
    if (_cachedPicture == null) {
      _createCache();
    }
    if (_cachedPicture != null) {
      canvas.drawPicture(_cachedPicture!);
    }
  }
}
