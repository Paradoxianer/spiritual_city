import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:logging/logging.dart';

import '../../domain/models/city_chunk.dart';
import '../../domain/services/territory_color_mapper.dart';
import '../../domain/services/particle_service.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Rendering architecture (v3) – "Shadow-Orbs + Layer-Blur"
//
// The invisible (spiritual) world background is built from two cheap layers
// that together create the organic, "living darkness" required by the spec:
//
//   Layer A – Base colour grid (per-cell static colour from spiritualState).
//             Very cheap to rebuild; throttled to ≤ 1 Hz since cell values
//             change slowly.  Cached as a dart:ui Picture.
//
//   Layer B – Shadow orbs.  Each chunk owns a handful of dark, slowly-drifting
//             circles.  They are drawn directly in render() every frame so
//             their movement is sub-pixel-smooth even on slow hardware.
//             Count and opacity are proportional to the chunk's darkness.
//
//   Both layers are enclosed in a single canvas.saveLayer() call with an
//   ImageFilter.blur.  One GPU blur operation per rendered chunk per frame –
//   orders of magnitude cheaper than the previous per-cell MaskFilter.blur.
//
//   Layer C – Sparkle particles (positive zones only).  Drawn AFTER restore()
//             so they appear sharp above the blurred background.
// ─────────────────────────────────────────────────────────────────────────────

class SpiritualRenderer extends PositionComponent
    with HasGameReference<SpiritWorldGame> {
  static final _log = Logger('SpiritualRenderer');

  final CityChunk chunk;
  static const double cellSize = CellComponent.cellSize;

  /// Pixel size of one full chunk side (16 cells × 32 px = 512 px).
  static const double _chunkPx = CityChunk.chunkSize * cellSize;

  // ── Base colour layer ───────────────────────────────────────────────────

  Picture? _basePicture;
  double _baseRebuildTimer = 0.0;

  /// How often (seconds) the base colour layer is rebuilt.
  /// Cell states change slowly so 1 Hz is plenty.
  static const double _baseRebuildInterval = 1.0;

  // ── Shadow orbs ─────────────────────────────────────────────────────────

  late final List<_ShadowOrb> _orbs;
  double _time = 0.0; // accumulated for orb "breathing" effect

  // ── Blur layer ──────────────────────────────────────────────────────────

  /// One blur operation per chunk per rendered frame.
  /// sigma = 8 px gives a soft organic look without visible cell edges.
  /// TileMode.decal fades to transparent at the chunk boundary, keeping
  /// visual seams minimal where adjacent chunks share similar colours.
  static final Paint _blurLayerPaint = Paint()
    ..imageFilter =
        ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0, tileMode: TileMode.decal);

  // ── Pre-allocated draw paints (never create Paint() in render) ──────────

  final Paint _cellPaint = Paint();
  final Paint _orbPaint = Paint();

  // ── Particles ───────────────────────────────────────────────────────────

  final ParticleService _particleService;
  double _particleSpawnTimer = 0.0;
  static const double _particleSpawnInterval = 1.0 / 15.0; // 15 Hz

  static final TerritoryColorMapper _colorMapper = TerritoryColorMapper();

  // ── RNG ─────────────────────────────────────────────────────────────────

  final math.Random _rng;

  // ── Debug ────────────────────────────────────────────────────────────────

  double _debugTimer = 0.0;

  // ─────────────────────────────────────────────────────────────────────────

  SpiritualRenderer(this.chunk)
      : _rng = math.Random(chunk.chunkX * 97 + chunk.chunkY * 31),
        _particleService =
            ParticleService(seed: chunk.chunkX * 17 + chunk.chunkY * 13) {
    size = Vector2.all(_chunkPx);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initOrbs();
  }

  // ── Initialisation ───────────────────────────────────────────────────────

  void _initOrbs() {
    // Compute average darkness (0 = fully positive, 1 = fully negative).
    double totalDark = 0;
    int count = 0;
    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell != null) {
          totalDark += (-cell.spiritualState).clamp(0.0, 1.0);
          count++;
        }
      }
    }
    final avgDark = count > 0 ? totalDark / count : 0.3;

    // 4–14 orbs; darker chunks get more.
    final orbCount = 4 + (avgDark * 10).round().clamp(0, 10);
    _orbs = List.generate(orbCount, (i) {
      return _ShadowOrb(
        x: _rng.nextDouble() * _chunkPx,
        y: _rng.nextDouble() * _chunkPx,
        radius: 24.0 + _rng.nextDouble() * 34.0,
        baseAlpha: (0.18 + avgDark * 0.48).clamp(0.0, 0.85),
        breathPhase: i / orbCount * math.pi * 2,
        rng: math.Random(_rng.nextInt(0x7FFFFFFF)),
      );
    });
  }

  // ── Update ───────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isSpiritualWorld) return;

    _time += dt;

    // Orbs: full frame rate → smooth sub-pixel movement.
    for (final orb in _orbs) {
      orb.update(dt, _chunkPx, _chunkPx);
    }

    // Particles: update at full rate for smooth flight.
    _particleService.update(dt);

    // Particle spawn: throttled to 15 Hz (iterating all 256 cells is cheap
    // but pointless at 60 Hz).
    _particleSpawnTimer += dt;
    if (_particleSpawnTimer >= _particleSpawnInterval) {
      _particleSpawnTimer -= _particleSpawnInterval;
      _spawnParticles(_particleSpawnInterval);
    }

    // Base colour rebuild: 1 Hz (cell states change slowly).
    _baseRebuildTimer += dt;
    if (_baseRebuildTimer >= _baseRebuildInterval) {
      _baseRebuildTimer = 0.0;
      _basePicture = null; // mark dirty; rebuilt in render()
    }

    // Debug – log once per 10 s for the chunk nearest (0,0) only.
    if (chunk.chunkX == 0 && chunk.chunkY == 0) {
      _debugTimer += dt;
      if (_debugTimer >= 10.0) {
        _debugTimer = 0.0;
        _log.fine(
          '[SpiritualRenderer] chunk(0,0): ${_orbs.length} shadow-orbs, '
          '${_particleService.particleCount} particles',
        );
      }
    }
  }

  // ── Base colour cache ────────────────────────────────────────────────────

  void _buildBaseCache() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;
        _cellPaint.color = _stateToBaseColor(cell.spiritualState);
        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
          _cellPaint,
        );
      }
    }
    _basePicture = recorder.endRecording();
  }

  /// Maps spiritualState to a base colour.
  /// Colours are deliberately dark so the overlay layer reads clearly.
  static Color _stateToBaseColor(double state) {
    final s = state.clamp(-1.0, 1.0);
    if (s > 0.25) {
      // Positive territory: very dark green → slightly lighter green.
      return Color.lerp(
        const Color(0xFF091509),
        const Color(0xFF0A3D0A),
        (s - 0.25) / 0.75,
      )!;
    } else if (s < -0.25) {
      // Negative territory: deep near-black red → deep crimson.
      return Color.lerp(
        const Color(0xFF100408),
        const Color(0xFF4A0505),
        (-s - 0.25) / 0.75,
      )!;
    }
    // Neutral: dark grey.
    return const Color(0xFF252525);
  }

  // ── Particle spawning ────────────────────────────────────────────────────

  void _spawnParticles(double dt) {
    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null ||
            cell.spiritualState <= TerritoryColorMapper.positiveThreshold) {
          continue;
        }
        if (_colorMapper.shouldSpawnSparkle(
          cell.spiritualState,
          _rng.nextDouble(),
          dt: dt,
        )) {
          _particleService.spawnSparkle(
            x * cellSize + cellSize / 2,
            y * cellSize + cellSize / 2,
          );
        }
      }
    }
  }

  // ── Render ───────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (!game.isSpiritualWorld) return;

    // ── Blurred background layer ──────────────────────────────────────────
    // saveLayer + ImageFilter.blur = ONE GPU operation for the whole chunk.
    canvas.saveLayer(size.toRect(), _blurLayerPaint);

    // 1. Base cell colours (slowly updated, cached as a Picture).
    if (_basePicture == null) _buildBaseCache();
    canvas.drawPicture(_basePicture!);

    // 2. Shadow orbs (current-frame positions → always smooth).
    _drawOrbs(canvas);

    canvas.restore(); // blur executes here

    // ── Sparkles above blur ───────────────────────────────────────────────
    // Particles are drawn AFTER restore() so they appear sharp.
    _particleService.render(canvas);
  }

  void _drawOrbs(Canvas canvas) {
    for (final orb in _orbs) {
      // Shadow orbs only appear in demonic (red/negative) zones.
      // Convert chunk-local pixel position to cell index and check state.
      final cx = (orb.x / cellSize).floor().clamp(0, CityChunk.chunkSize - 1);
      final cy = (orb.y / cellSize).floor().clamp(0, CityChunk.chunkSize - 1);
      final cell = chunk.cells['$cx,$cy'];
      if (cell == null || cell.spiritualState >= TerritoryColorMapper.negativeThreshold) {
        continue;
      }

      // Gentle breathing: ±20 % alpha modulation.
      final breathe = 0.80 + 0.20 * math.sin(_time * 1.1 + orb.breathPhase);
      _orbPaint.color = const Color(0xFF030005).withValues(
        alpha: (orb.baseAlpha * breathe).clamp(0.0, 1.0),
      );
      canvas.drawCircle(Offset(orb.x, orb.y), orb.radius, _orbPaint);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shadow Orb
//
// A single slowly-wandering dark blob within a chunk.  Positions are tracked
// in chunk-local pixel coordinates.  Direction is updated via smooth steering
// every [_steerInterval] seconds so the movement feels organic, not robotic.
// ─────────────────────────────────────────────────────────────────────────────

class _ShadowOrb {
  double x, y;
  double vx = 0, vy = 0;
  final double radius;
  final double baseAlpha;
  final double breathPhase;

  double _steerTimer = 0.0;
  double _steerInterval;
  double _tvx = 0, _tvy = 0; // target velocity

  final math.Random _rng;

  static const double _minSpeed = 5.0;
  static const double _maxSpeed = 22.0;

  _ShadowOrb({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseAlpha,
    required this.breathPhase,
    required math.Random rng,
  })  : _rng = rng,
        _steerInterval = 3.0 + rng.nextDouble() * 5.0 {
    _pickNewTarget();
    // Start already moving in the chosen direction.
    vx = _tvx;
    vy = _tvy;
  }

  void _pickNewTarget() {
    final angle = _rng.nextDouble() * math.pi * 2;
    final speed = _minSpeed + _rng.nextDouble() * (_maxSpeed - _minSpeed);
    _tvx = math.cos(angle) * speed;
    _tvy = math.sin(angle) * speed;
    _steerInterval = 3.0 + _rng.nextDouble() * 5.0;
  }

  void update(double dt, double w, double h) {
    // Smooth steering: gradually blend current velocity toward target.
    const steerRate = 1.5; // higher → snappier turns
    vx += (_tvx - vx) * (steerRate * dt).clamp(0.0, 1.0);
    vy += (_tvy - vy) * (steerRate * dt).clamp(0.0, 1.0);

    x += vx * dt;
    y += vy * dt;

    // Wrap-around at chunk boundaries so orbs never disappear.
    if (x < -radius) {
      x += w + radius * 2;
    }
    if (x > w + radius) {
      x -= w + radius * 2;
    }
    if (y < -radius) {
      y += h + radius * 2;
    }
    if (y > h + radius) {
      y -= h + radius * 2;
    }

    // Pick a new direction after the current interval expires.
    _steerTimer += dt;
    if (_steerTimer >= _steerInterval) {
      _steerTimer = 0;
      _pickNewTarget();
    }
  }
}
