import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/material.dart' hide Image;

import '../../domain/models/city_chunk.dart';
import '../../domain/models/city_cell.dart';
import '../../domain/services/territory_color_mapper.dart';
import '../../domain/services/particle_service.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';

class SpiritualRenderer extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final CityChunk chunk;
  static const double cellSize = CellComponent.cellSize;

  Picture? _cachedPicture;
  double _animationTime = 0;
  final PerlinNoise _lavaNoise;

  final TerritoryColorMapper _colorMapper = TerritoryColorMapper();
  final ParticleService _particleService;
  final math.Random _rng = math.Random();

  SpiritualRenderer(this.chunk)
      : _lavaNoise = PerlinNoise(seed: chunk.chunkX * 31 + chunk.chunkY * 7),
        _particleService = ParticleService(seed: chunk.chunkX * 17 + chunk.chunkY * 13) {
    size = Vector2.all(CityChunk.chunkSize * cellSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isSpiritualWorld) return;

    _animationTime += dt * 0.5; // Speed of lava-lamp animation

    // Invalidate cache each frame for flowing animation
    _cachedPicture = null;

    _spawnParticles(dt);
    _particleService.update(dt);
  }

  void _spawnParticles(double dt) {
    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        // Skip non-positive cells early to avoid unnecessary RNG calls
        if (cell == null || cell.spiritualState <= TerritoryColorMapper.positiveThreshold) continue;

        if (_colorMapper.shouldSpawnSparkle(cell.spiritualState, _rng.nextDouble(), dt: dt)) {
          _particleService.spawnSparkle(
            x * cellSize + cellSize / 2,
            y * cellSize + cellSize / 2,
          );
        }
      }
    }
  }

  void _createCache() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;

        // Organic noise for lava-lamp effect
        final noise = _lavaNoise.getNoise3(
          chunk.getWorldX(x) * 0.1,
          chunk.getWorldY(y) * 0.1,
          _animationTime,
        );

        final offset = Offset(x * cellSize, y * cellSize);
        _renderSpiritualCell(canvas, cell, offset, noise);
      }
    }
    _cachedPicture = recorder.endRecording();
  }

  void _renderSpiritualCell(Canvas canvas, CityCell cell, Offset offset, double noise) {
    // Combine spiritual state with flowing noise for organic movement
    final state = (cell.spiritualState + (noise * 0.3)).clamp(-1.0, 1.0);

    final color = _colorMapper.stateToColor(state);
    final pulseAlpha = _colorMapper.redPulseAlpha(state, _animationTime);
    final alpha = ((0.45 + noise.abs() * 0.2) * pulseAlpha).clamp(0.0, 0.85);

    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12); // Gaussian-style soft edges

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

    // Sparkle particles rendered on top with additive blending
    _particleService.render(canvas);
  }
}
