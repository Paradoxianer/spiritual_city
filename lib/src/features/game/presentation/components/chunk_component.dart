import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../../domain/models/city_chunk.dart';
import '../../domain/services/influence_service.dart' show kCellGlowDuration;
import 'cell_component.dart';
import '../spirit_world_game.dart';
import 'city_tile_renderer.dart';
import 'spiritual_renderer.dart';

class ChunkComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final CityChunk chunk;
  static const double cellSize = CellComponent.cellSize;

  Picture? _cachedPicture;
  late final SpiritualRenderer _spiritualRenderer;

  // Pre-allocated paint for the glow overlay (never allocate in render/update).
  final Paint _glowPaint = Paint();

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

  // ── Glow timer decay ──────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    // Decrement glow timers for all cells in this chunk (physical world only).
    if (game.isSpiritualWorld) return;
    for (final cell in chunk.cells.values) {
      if (cell.glowTimer > 0) {
        cell.glowTimer = (cell.glowTimer - dt).clamp(0.0, double.infinity);
        if (cell.glowTimer <= 0) {
          cell.glowStrength = 0.0;
        }
      }
    }
  }

  // ── Render ────────────────────────────────────────────────────────────────

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
      _renderGlowOverlay(canvas);
    }
  }

  // ── Cell-Glow overlay (Issue #118) ────────────────────────────────────────

  /// Draws a short colour flash over cells that were recently touched by
  /// [InfluenceService.applyAoE].
  ///
  /// Positive delta → green; negative → red.  Alpha is proportional to the
  /// remaining glow time so the effect fades out smoothly.
  void _renderGlowOverlay(Canvas canvas) {
    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null || cell.glowTimer <= 0) continue;

        // Fade: 1.0 at peak, 0.0 at expiry (linear fade-out).
        // Alpha uses a normalised minimum so that even small deltas (e.g.
        // practicalHelp with delta=0.05) produce a clearly perceptible flash
        // while keeping the underlying tile (road, etc.) visible through it.
        // Range: 0.20 (minimum, any non-zero influence) … 0.35 (maximum).
        final fade = (cell.glowTimer / kCellGlowDuration).clamp(0.0, 1.0);
        // Normalise intensity to [0..1] so we only scale the *amplitude* of
        // the base alpha range, not the visibility floor.
        final normIntensity = cell.glowStrength.abs().clamp(0.0, 1.0);
        final alpha = fade * (0.20 + normIntensity * 0.15);

        final color = cell.glowStrength > 0
            ? Color.fromARGB((alpha * 255).round(), 0, 230, 80)   // green
            : Color.fromARGB((alpha * 255).round(), 220, 30, 30); // red

        _glowPaint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
          _glowPaint,
        );
      }
    }
  }

  static final Paint _borderPaint = Paint()..style = PaintingStyle.stroke..color = Colors.white10;
}
