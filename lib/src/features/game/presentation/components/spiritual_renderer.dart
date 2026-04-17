import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:logging/logging.dart';

import '../../domain/models/city_chunk.dart';
import '../../domain/models/city_cell.dart';
import '../../domain/services/territory_color_mapper.dart';
import '../../domain/services/particle_service.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';

class SpiritualRenderer extends PositionComponent with HasGameReference<SpiritWorldGame> {
  static final _log = Logger('SpiritualRenderer');

  final CityChunk chunk;
  static const double cellSize = CellComponent.cellSize;

  Picture? _cachedPicture;

  /// Fast, small-scale noise – drives the flowing lava-lamp movement.
  final PerlinNoise _lavaNoise;
  double _animationTime = 0;

  /// Slow, large-scale noise – shapes the dark blobs inside negative zones.
  final PerlinNoise _blobNoise;
  double _blobTime = 0;

  // ── Animation throttle ───────────────────────────────────────────────────
  //
  // Rebuilding the Picture (which calls Perlin-noise for 256 cells) every
  // single frame was the primary cause of the ~1fps stutter when entering the
  // invisible world.  We now regenerate at most [_refreshFps] times per second.
  // The flowing animation is still clearly visible at 20 fps.

  double _refreshTimer = 0.0;
  static const double _refreshFps = 20.0;
  static const double _refreshInterval = 1.0 / _refreshFps;

  // ── Pre-allocated Paint objects (never create Paint() per cell) ──────────

  final Paint _cellPaint = Paint();
  final Paint _blobPaint = Paint();

  // ── Debug counters ───────────────────────────────────────────────────────

  int _rebuildCount = 0;
  double _debugLogTimer = 0.0;
  static const double _debugLogInterval = 5.0; // log every 5 s

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

    // Particles always update at full frame rate so motion is smooth.
    _particleService.update(dt);

    // Picture rebuild throttled to _refreshFps.  Previously this was set to
    // null every frame, forcing a full Perlin-noise + Picture rebuild at 60 fps
    // per chunk – the main performance killer.
    _refreshTimer += dt;
    if (_refreshTimer >= _refreshInterval) {
      _refreshTimer -= _refreshInterval;
      _cachedPicture = null; // mark dirty → rebuilt in render()
      _spawnParticles(dt);   // sparkle spawning also throttled

      _rebuildCount++;
    }

    // Periodic debug summary (only for chunk 0,0 to avoid log spam)
    if (chunk.chunkX == 0 && chunk.chunkY == 0) {
      _debugLogTimer += dt;
      if (_debugLogTimer >= _debugLogInterval) {
        _debugLogTimer = 0.0;
        final rebuildsPerSec = _rebuildCount / _debugLogInterval;
        _log.info(
          '[SpiritualRenderer] chunk(0,0): '
          '${rebuildsPerSec.toStringAsFixed(1)} rebuilds/s '
          '(target $_refreshFps fps), '
          '${_particleService.particleCount} particles',
        );
        _rebuildCount = 0;
      }
    }
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

      // NOTE: MaskFilter.blur was removed here.  Per-cell blur (10–16 px over a
      // 32 px tile) forced 6 400+ separate GPU compositing passes per frame
      // (25 chunks × 256 cells) and was the primary cause of <2 fps in the
      // invisible world.  The flowing colour + alpha already conveys the visual
      // effect; adding a single saveLayer blur per chunk (if desired) is far
      // cheaper.
      _cellPaint.color = baseColor.withValues(alpha: baseAlpha);
      canvas.drawRect(rect, _cellPaint);

      // Layer 2: near-black blob (slow blobNoise shapes the dark masses)
      // blobNoise > 0 → darker region; depth scales with how strongly negative the cell is
      if (blobNoise > 0.05) {
        final blobStrength = ((blobNoise - 0.05) / 0.95).clamp(0.0, 1.0);
        final cellDarkness =
            ((-cell.spiritualState - TerritoryColorMapper.negativeThreshold.abs()) /
                    (1.0 - TerritoryColorMapper.negativeThreshold.abs()))
                .clamp(0.0, 1.0);
        final blobAlpha = blobStrength * cellDarkness * 0.65;

        _blobPaint.color = const Color(0xFF020001).withValues(alpha: blobAlpha);
        canvas.drawRect(rect, _blobPaint);
      }
    } else {
      // ── POSITIVE / NEUTRAL ZONE ──────────────────────────────────────────
      final state = (cell.spiritualState + lavaNoise * 0.3).clamp(-1.0, 1.0);
      final color = _colorMapper.stateToColor(state);
      final pulseAlpha = _colorMapper.redPulseAlpha(state, _animationTime);
      final alpha = ((0.45 + lavaNoise.abs() * 0.2) * pulseAlpha).clamp(0.0, 0.85);

      _cellPaint.color = color.withValues(alpha: alpha);
      canvas.drawRect(rect, _cellPaint);
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
