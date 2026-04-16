import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/models/daemon_model.dart';
import '../../domain/models/city_cell.dart';
import '../../../menu/domain/models/difficulty.dart';
import '../../domain/services/faith_calculator_service.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';

/// Visual and logic component for a Daemon NPC in the invisible world.
///
/// Movement is fully continuous (pixel-space orbital flight):
/// - The daemon orbits a center point at a constant angular velocity,
///   producing smooth, vulture-like circling.  A secondary phase oscillator
///   warps the radius organically so the path is never perfectly circular.
/// - Without prayer: the orbit center drifts toward the nearest strongly-
///   negative cell, so the daemon patrols dark territory.
/// - When prayer attraction is active: the orbit center snaps to the player
///   and the radius slowly tightens, drawing the daemon ever closer.
///
/// Cell drain and energy management run on their own 2-second timer,
/// completely decoupled from the render loop.
///
/// Lastenheft Issue #31
class DaemonComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final DaemonModel model;
  final math.Random _rng;

  static const double _daemonSize = 18.0;
  static const double _energyToCellRatio = 0.01;

  double _cellDrainMultiplier = 1.0;

  // ── Continuous orbital movement ────────────────────────────────────────────

  /// Angular velocity (rad/s) – how fast the daemon circles its orbit center.
  double _angularSpeed = 1.1;

  static const double _angularSpeedEasy   = 0.7;  // ~9 s per full orbit
  static const double _angularSpeedNormal = 1.1;  // ~5.7 s per full orbit
  static const double _angularSpeedHard   = 1.7;  // ~3.7 s per full orbit

  /// How fast (px/s) the daemon's rendered position chases its computed
  /// orbit point.  Lower = floaty lag; higher = snappy.
  double _followSpeed = 90.0;

  static const double _followSpeedEasy   = 55.0;
  static const double _followSpeedNormal = 85.0;
  static const double _followSpeedHard   = 125.0;

  double _orbitAngle = 0.0;
  double _orbitRadius = 200.0;

  static const double _orbitRadiusMin = 60.0;
  static const double _orbitRadiusMax = 300.0;

  /// Rate at which the orbit radius shrinks while spiralling toward the player (px/s).
  static const double _spiralInSpeed = 18.0;

  /// Secondary phase oscillator: creates organic radius variation.
  double _radiusPhase = 0.0;
  static const double _radiusPhaseSpeed = 0.53; // prime-ratio to _wobble

  /// Orbit center in world coordinates – updated every frame.
  final Vector2 _orbitCenter = Vector2.zero();

  // ── Drift (wandering without prayer) ──────────────────────────────────────

  final Vector2 _driftTarget = Vector2.zero();
  double _driftUpdateTimer = 0.0;
  static const double _driftUpdateInterval = 4.0;
  bool _driftInitialized = false;

  // ── Cell-effect timer ──────────────────────────────────────────────────────

  double _cellEffectTimer = 0.0;
  static const double _cellEffectInterval = 2.0;

  // ── Visuals ────────────────────────────────────────────────────────────────

  double _wobble = 0.0;

  // ── Hit flicker ────────────────────────────────────────────────────────────

  double _hitFlickerTimer = 0.0;
  static const double _hitFlickerDuration = 0.3;

  DaemonComponent(this.model)
      : _rng = math.Random(model.id.hashCode),
        super(
          position: model.position.clone(),
          size: Vector2.all(_daemonSize),
          anchor: Anchor.center,
          priority: 95,
        );

  @override
  Future<void> onLoad() async {
    _angularSpeed = switch (game.difficulty) {
      Difficulty.easy   => _angularSpeedEasy,
      Difficulty.normal => _angularSpeedNormal,
      Difficulty.hard   => _angularSpeedHard,
    };
    _followSpeed = switch (game.difficulty) {
      Difficulty.easy   => _followSpeedEasy,
      Difficulty.normal => _followSpeedNormal,
      Difficulty.hard   => _followSpeedHard,
    };
    _cellDrainMultiplier =
        1.0 / FaithCalculatorService.difficultyFactorFor(game.difficulty);

    // Spread daemons' starting angles and radii for visual variety.
    _orbitAngle  = _rng.nextDouble() * math.pi * 2;
    _orbitRadius = 150.0 + _rng.nextDouble() * (_orbitRadiusMax - 150.0);
    _radiusPhase = _rng.nextDouble() * math.pi * 2;

    _driftTarget.setFrom(position);
    _orbitCenter.setFrom(position);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!game.isSpiritualWorld) return;
    if (model.dissolved) {
      removeFromParent();
      return;
    }

    _wobble      += dt * 2.5;
    _radiusPhase += dt * _radiusPhaseSpeed;
    if (_hitFlickerTimer > 0) _hitFlickerTimer -= dt;

    // ── Update orbit center ───────────────────────────────────────────────────

    if (game.spiritualDynamics.isPrayerAttractionActive) {
      // Lock onto player and tighten the spiral.
      _orbitCenter.setFrom(game.player.position);
      _orbitRadius = math.max(
          _orbitRadiusMin, _orbitRadius - _spiralInSpeed * dt);
    } else {
      // Slowly expand back outward when prayer is not active.
      if (_orbitRadius < _orbitRadiusMax) {
        _orbitRadius = math.min(
            _orbitRadiusMax, _orbitRadius + _spiralInSpeed * 0.25 * dt);
      }

      // Drift orbit center toward a nearby dark cell.
      _driftUpdateTimer += dt;
      if (!_driftInitialized || _driftUpdateTimer >= _driftUpdateInterval) {
        _driftUpdateTimer = 0.0;
        _driftInitialized = true;
        _pickNewDriftTarget();
      }
      // Smoothly slide orbit center toward drift target.
      _orbitCenter.lerp(_driftTarget, (dt * 0.4).clamp(0.0, 1.0));
    }

    // ── Advance orbit angle ───────────────────────────────────────────────────
    _orbitAngle += _angularSpeed * dt;

    // ── Compute target position with organic radius wobble ───────────────────
    final effectiveRadius = _orbitRadius + math.sin(_radiusPhase) * 28.0;
    final target = Vector2(
      _orbitCenter.x + math.cos(_orbitAngle) * effectiveRadius,
      _orbitCenter.y + math.sin(_orbitAngle) * effectiveRadius,
    );

    // ── Chase target position smoothly ───────────────────────────────────────
    final diff = target - position;
    final dist = diff.length;
    if (dist > 0.5) {
      final step = math.min(dist, _followSpeed * dt);
      position.addScaled(diff / dist, step);
    }
    model.position.setFrom(position);

    // ── Cell effect (independent of movement speed) ───────────────────────────
    _cellEffectTimer += dt;
    if (_cellEffectTimer >= _cellEffectInterval) {
      _cellEffectTimer = 0.0;
      _applyEffectAtCurrentPos();
    }
  }

  // ── Drift target ───────────────────────────────────────────────────────────

  /// Pick a new drift target: the most-negative cell within a search window,
  /// or a random offset if no cells are found.
  void _pickNewDriftTarget() {
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();

    CityCell? best;
    double bestScore = double.infinity;
    const int searchRadius = 10;

    for (int dy = -searchRadius; dy <= searchRadius; dy += 2) {
      for (int dx = -searchRadius; dx <= searchRadius; dx += 2) {
        final cell = game.grid.getCell(gx + dx, gy + dy);
        if (cell == null) continue;
        if (cell.spiritualState < bestScore) {
          bestScore = cell.spiritualState;
          best = cell;
        }
      }
    }

    if (best != null) {
      _driftTarget.setValues(
        best.x * CellComponent.cellSize + CellComponent.cellSize / 2,
        best.y * CellComponent.cellSize + CellComponent.cellSize / 2,
      );
    } else {
      final angle = _rng.nextDouble() * math.pi * 2;
      final d = 100.0 + _rng.nextDouble() * 150.0;
      _driftTarget.setValues(
        position.x + math.cos(angle) * d,
        position.y + math.sin(angle) * d,
      );
    }
  }

  // ── Cell effect ────────────────────────────────────────────────────────────

  void _applyEffectAtCurrentPos() {
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();
    final cell = game.grid.getCell(gx, gy);
    if (cell != null) _applyEffect(cell);
  }

  void _applyEffect(CityCell cell) {
    double cellDrain;
    double energyDrain;

    if (cell.spiritualState < -0.5) {
      // Strongly negative: daemon thrives, costs little energy
      cellDrain   = 1.0 * _energyToCellRatio * _cellDrainMultiplier;
      energyDrain = 1.0;
    } else if (cell.spiritualState.abs() < 0.3) {
      // Neutral: moderate drain
      cellDrain   = 2.0 * _energyToCellRatio * _cellDrainMultiplier;
      energyDrain = 2.0;
    } else {
      // Positive territory: daemon is weakened rapidly
      cellDrain   = 3.0 * _energyToCellRatio * _cellDrainMultiplier;
      energyDrain = 6.0;
    }

    cell.spiritualState = (cell.spiritualState - cellDrain).clamp(-1.0, 1.0);

    model.energy += energyDrain; // energy drains toward 0 (starts negative)
    if (model.energy >= 0) {
      _dissolve(cell);
    }
  }

  // ── Combat ─────────────────────────────────────────────────────────────────

  /// Called by the prayer combat system when this daemon is within the impact zone.
  void takeDamage(double amount) {
    if (model.dissolved) return;
    _hitFlickerTimer = _hitFlickerDuration;
    model.energy += amount;
    if (model.energy >= 0) {
      _explode();
    }
  }

  /// Daemon destroyed by prayer: strongly cleanses the surrounding area.
  void _explode() {
    model.dissolved = true;
    const int explosionRadius = 3;
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();

    for (int dy = -explosionRadius; dy <= explosionRadius; dy++) {
      for (int dx = -explosionRadius; dx <= explosionRadius; dx++) {
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist > explosionRadius) continue;
        final cell = game.grid.getCell(gx + dx, gy + dy);
        if (cell != null) {
          final falloff = 1.0 - (dist / explosionRadius).clamp(0.0, 1.0);
          cell.spiritualState =
              (cell.spiritualState + 0.4 * falloff).clamp(-1.0, 1.0);
        }
      }
    }
    removeFromParent();
  }

  /// Natural dissolution: daemon's energy ran out; leaves an ash residuum marker.
  void _dissolve(CityCell cell) {
    model.dissolved = true;
    cell.spiritualState = (cell.spiritualState - 0.05).clamp(-1.0, 1.0);
    cell.hasResiduum = true;
    removeFromParent();
  }

  // ── Rendering ──────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (!game.isSpiritualWorld) return;

    final wobbleOffset = math.sin(_wobble) * 3;
    final center = Offset(size.x / 2, size.y / 2 + wobbleOffset);
    final t = (math.sin(_wobble * 0.7) + 1) / 2;

    final isFlickering = _hitFlickerTimer > 0;

    // Pulsing red-to-black aura
    final auraColor = isFlickering
        ? Colors.white.withValues(alpha: 0.8)
        : Color.lerp(
            Colors.red[900]!.withValues(alpha: 0.6),
            Colors.black.withValues(alpha: 0.9),
            t,
          )!;
    canvas.drawCircle(
      center,
      size.x * 0.7,
      Paint()
        ..color = auraColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Inner core
    canvas.drawCircle(
      center,
      size.x * 0.35,
      Paint()
        ..color = isFlickering
            ? Colors.white.withValues(alpha: 0.9)
            : Colors.red[800]!.withValues(alpha: 0.9),
    );

    // Energy arc: normalised against spawn energy so it always starts full.
    final energyFraction =
        (model.energy.abs() / model.initialEnergy.abs()).clamp(0.0, 1.0);
    final arcPaint = Paint()
      ..color = Colors.deepOrange.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.x * 0.45),
      -math.pi / 2,
      math.pi * 2 * energyFraction,
      false,
      arcPaint,
    );
  }
}
