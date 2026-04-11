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

  /// Fast, small-scale noise – drives the flowing lava-lamp movement.
  final PerlinNoise _lavaNoise;
  double _animationTime = 0;

  /// Slow, large-scale noise – shapes the dark blobs inside negative zones.
  final PerlinNoise _blobNoise;
  double _blobTime = 0;

  final TerritoryColorMapper _colorMapper = TerritoryColorMapper();
  final ParticleService _particleService;
  final math.Random _rng = math.Random();

  SpiritualRenderer(this.chunk)
      : _lavaNoise = PerlinNoise(seed: chunk.chunkX * 31 + chunk.chunkY * 7),
        _blobNoise = PerlinNoise(seed: chunk.chunkX * 53 + chunk.chunkY * 29),
        _particleService = ParticleService(seed: chunk.chunkX * 17 + chunk.chunkY * 13) {
    size = Vector2.all(CityChunk.chunkSize * cellSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isSpiritualWorld) return;

    _animationTime += dt * 0.5;  // fast flowing movement
    _blobTime += dt * 0.12;      // slow blob drifting

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

    final worldOffsetX = chunk.chunkX * CityChunk.chunkSize;
    final worldOffsetY = chunk.chunkY * CityChunk.chunkSize;

    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;

        final wx = (worldOffsetX + x).toDouble();
        final wy = (worldOffsetY + y).toDouble();

        final lavaNoise = _lavaNoise.getNoise3(wx * 0.1, wy * 0.1, _animationTime);
        // Larger scale (0.035) = bigger blobs; separate time axis for independent movement
        final blobNoise = _blobNoise.getNoise3(wx * 0.035, wy * 0.035, _blobTime);

        final offset = Offset(x * cellSize, y * cellSize);
        _renderSpiritualCell(canvas, cell, offset, lavaNoise, blobNoise);
      }
    }
    _cachedPicture = recorder.endRecording();
  }

  void _renderSpiritualCell(
    Canvas canvas,
    CityCell cell,
    Offset offset,
    double lavaNoise,
    double blobNoise,
  ) {
    final rect = Rect.fromLTWH(offset.dx, offset.dy, cellSize, cellSize);

    if (cell.spiritualState < TerritoryColorMapper.negativeThreshold) {
      // ── DARK ZONE – two-layer rendering ──────────────────────────────────
      //
      // Layer 1: flowing crimson base (fast lavaNoise animates the movement)
      final baseState = (cell.spiritualState + lavaNoise * 0.2).clamp(-1.0, 1.0);
      final baseColor = _colorMapper.stateToColor(baseState);
      final pulseAlpha = _colorMapper.redPulseAlpha(baseState, _animationTime);
      final baseAlpha = (0.55 * pulseAlpha).clamp(0.0, 0.85);

      canvas.drawRect(
        rect,
        Paint()
          ..color = baseColor.withValues(alpha: baseAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Layer 2: near-black blob (slow blobNoise shapes the dark masses)
      // blobNoise > 0 → darker region; depth scales with how strongly negative the cell is
      if (blobNoise > 0.05) {
        final blobStrength = ((blobNoise - 0.05) / 0.95).clamp(0.0, 1.0);
        final cellDarkness =
            ((-cell.spiritualState - TerritoryColorMapper.negativeThreshold.abs()) /
                    (1.0 - TerritoryColorMapper.negativeThreshold.abs()))
                .clamp(0.0, 1.0);
        final blobAlpha = blobStrength * cellDarkness * 0.65;

        canvas.drawRect(
          rect,
          Paint()
            ..color = const Color(0xFF020001).withValues(alpha: blobAlpha) // near-black
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
        );
      }
    } else {
      // ── POSITIVE / NEUTRAL ZONE ──────────────────────────────────────────
      final state = (cell.spiritualState + lavaNoise * 0.3).clamp(-1.0, 1.0);
      final color = _colorMapper.stateToColor(state);
      final pulseAlpha = _colorMapper.redPulseAlpha(state, _animationTime);
      final alpha = ((0.45 + lavaNoise.abs() * 0.2) * pulseAlpha).clamp(0.0, 0.85);

      canvas.drawRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
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
