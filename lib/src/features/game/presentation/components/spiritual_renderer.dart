import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/material.dart' hide Image;
import '../../domain/models/city_chunk.dart';
import '../../domain/models/city_cell.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';

/// Renders the "invisible world" spiritual overlay for a single [CityChunk].
///
/// Features:
/// - Perlin-noise lava-lamp animation for the spiritual state colour field
/// - Gaussian blur for soft territory boundaries
/// - Sparkle particles in strongly-positive (light) zones
/// - Pulsing dark halos in strongly-negative (dark) zones
class SpiritualRenderer extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final CityChunk chunk;
  static const double cellSize = CellComponent.cellSize;

  Picture? _cachedPicture;
  double _animationTime = 0;
  final PerlinNoise _lavaNoise;
  final Random _rng;

  // ── Sparkle particles ──────────────────────────────────────────────────────
  /// Each sparkle: [x, y, life] in chunk-local pixel coordinates.
  final List<_Sparkle> _sparkles = [];
  static const int _maxSparkles = 30;
  static const double _sparkleSpawnRate = 0.08; // seconds between spawns
  double _sparkleTimer = 0;

  // ── Pulsing halo ───────────────────────────────────────────────────────────
  double _pulsePhase = 0;

  SpiritualRenderer(this.chunk)
      : _lavaNoise = PerlinNoise(seed: chunk.chunkX * 31 + chunk.chunkY * 7),
        _rng = Random(chunk.chunkX * 1000 + chunk.chunkY) {
    size = Vector2.all(CityChunk.chunkSize * cellSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isSpiritualWorld) return;

    _animationTime += dt * 0.5; // Lava-lamp animation speed
    _pulsePhase += dt * 2.0;    // Pulsing speed for dark zones
    _cachedPicture = null;      // Invalidate cache every frame while animated

    _updateSparkles(dt);
  }

  void _updateSparkles(double dt) {
    // Age existing sparkles
    _sparkles.removeWhere((s) => s.life <= 0);
    for (final s in _sparkles) {
      s.life -= dt;
      s.y -= dt * 20; // float upward
      s.alpha = (s.life / s.maxLife).clamp(0, 1);
    }

    // Spawn new sparkles in light zones
    _sparkleTimer += dt;
    if (_sparkleTimer >= _sparkleSpawnRate && _sparkles.length < _maxSparkles) {
      _sparkleTimer = 0;
      _trySpawnSparkle();
    }
  }

  void _trySpawnSparkle() {
    // Pick a random cell and check if it is a light zone
    final cx = _rng.nextInt(CityChunk.chunkSize);
    final cy = _rng.nextInt(CityChunk.chunkSize);
    final cell = chunk.cells['$cx,$cy'];
    if (cell != null && cell.spiritualState > 0.4) {
      _sparkles.add(_Sparkle(
        x: cx * cellSize + _rng.nextDouble() * cellSize,
        y: cy * cellSize + _rng.nextDouble() * cellSize,
        size: 1.5 + _rng.nextDouble() * 2.5,
        maxLife: 0.6 + _rng.nextDouble() * 0.6,
      ));
    }
  }

  // ── Picture cache ──────────────────────────────────────────────────────────

  void _createCache() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    final pulseAlpha = 0.12 + 0.08 * sin(_pulsePhase); // 0.04 – 0.20

    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;

        final noise = _lavaNoise.getNoise3(
          chunk.getWorldX(x) * 0.1,
          chunk.getWorldY(y) * 0.1,
          _animationTime,
        );

        final offset = Offset(x * cellSize, y * cellSize);
        _renderSpiritualCell(canvas, cell, offset, noise, pulseAlpha);
      }
    }

    // Sparkles rendered on top
    _renderSparkles(canvas);

    _cachedPicture = recorder.endRecording();
  }

  void _renderSpiritualCell(Canvas canvas, CityCell cell, Offset offset,
      double noise, double pulseAlpha) {
    final state = (cell.spiritualState + (noise * 0.3)).clamp(-1.0, 1.0);

    Color color;
    if (state < -0.2) {
      // Dark territory: deep red → black
      final factor = (state.abs() - 0.2) / 0.8;
      color = Color.lerp(Colors.red[900]!, Colors.black, factor)!;
    } else if (state > 0.2) {
      // Light territory: pale green → deep green/gold
      final factor = (state - 0.2) / 0.8;
      color = Color.lerp(Colors.lightGreenAccent[100]!, Colors.green[900]!, factor)!;
    } else {
      // Neutral
      color = const Color(0xFFF5DEB3).withValues(alpha: 0.2);
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.5 + (noise.abs() * 0.2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawRect(
        Rect.fromLTWH(offset.dx, offset.dy, cellSize, cellSize), paint);

    // Pulsing dark halo for strongly-negative cells
    if (state < -0.6) {
      final haloPaint = Paint()
        ..color = Colors.red[900]!.withValues(alpha: pulseAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(
        offset + Offset(cellSize / 2, cellSize / 2),
        cellSize * 0.8,
        haloPaint,
      );
    }
  }

  void _renderSparkles(Canvas canvas) {
    for (final s in _sparkles) {
      final sparkPaint = Paint()
        ..color = Colors.white.withValues(alpha: s.alpha * 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(s.x, s.y), s.size, sparkPaint);

      // Golden glow
      final glowPaint = Paint()
        ..color = Colors.amber.withValues(alpha: s.alpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset(s.x, s.y), s.size * 1.8, glowPaint);
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
  }
}

// ── Internal data classes ────────────────────────────────────────────────────

class _Sparkle {
  double x;
  double y;
  final double size;
  final double maxLife;
  double life;
  double alpha;

  _Sparkle({
    required this.x,
    required this.y,
    required this.size,
    required this.maxLife,
  })  : life = maxLife,
        alpha = 1.0;
}
