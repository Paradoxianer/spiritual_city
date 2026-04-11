import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/material.dart' hide Image;
import '../../domain/models/city_chunk.dart';
import '../../domain/models/city_cell.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';

class SpiritualRenderer extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final CityChunk chunk;
  static const double cellSize = CellComponent.cellSize;

  Picture? _cachedPicture;
  double _animationTime = 0;
  final PerlinNoise _lavaNoise;

  SpiritualRenderer(this.chunk) : _lavaNoise = PerlinNoise(seed: chunk.chunkX * 31 + chunk.chunkY * 7) {
    size = Vector2.all(CityChunk.chunkSize * cellSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isSpiritualWorld) return;

    _animationTime += dt * 0.5; // Geschwindigkeit der "Lavalampen"-Bewegung
    
    // Wir invalidieren den Cache regelmäßig für die fließende Optik
    _cachedPicture = null;
  }

  void _createCache() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;
        
        // Organisches Rauschen für Hotspots hinzufügen
        final noise = _lavaNoise.getNoise3(
          chunk.getWorldX(x) * 0.1, 
          chunk.getWorldY(y) * 0.1, 
          _animationTime
        );

        final offset = Offset(x * cellSize, y * cellSize);
        _renderSpiritualCell(canvas, cell, offset, noise);
      }
    }
    _cachedPicture = recorder.endRecording();
  }

  void _renderSpiritualCell(Canvas canvas, CityCell cell, Offset offset, double noise) {
    // Basis-State kombiniert mit fließendem Noise (-1.0 bis 1.0)
    final state = (cell.spiritualState + (noise * 0.3)).clamp(-1.0, 1.0);
    
    Color color;
    if (state < -0.2) {
      // Dunkle Macht: Tiefrot bis Schwarz
      final factor = (state.abs() - 0.2) / 0.8;
      color = Color.lerp(Colors.red[900]!, Colors.black, factor)!;
    } else if (state > 0.2) {
      // Licht: Hellgrün bis Gold/Dunkelgrün
      final factor = (state - 0.2) / 0.8;
      color = Color.lerp(Colors.lightGreenAccent[100]!, Colors.green[900]!, factor)!;
    } else {
      // Neutraler Bereich
      color = const Color(0xFFF5DEB3).withValues(alpha: 0.2); 
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.5 + (noise.abs() * 0.2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12); // Weicherer Übergang

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
