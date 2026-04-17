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
/// Movement is a pure pixel-space orbit around the player – like a vulture
/// circling its prey.  The radius shrinks continuously so the player is
/// gradually encircled.  Prayer accelerates the inward spiral.
///
/// The daemon leaves a visible slime trail by draining the `spiritualState`
/// of the cell it occupies every frame (proportional to `dt`).  Energy
/// management is decoupled onto its own 2-second tick.
///
/// Lastenheft Issue #31
class DaemonComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final DaemonModel model;

  static const double _daemonSize = 18.0;

  double _cellDrainMultiplier = 1.0;

  // ── Pure orbital movement ─────────────────────────────────────────────────

  /// Angular velocity (rad/s) – controls how fast the daemon circles the player.
  double _angularSpeed = 1.2;

  static const double _angularSpeedEasy   = 0.8;  // ~7.9 s / full orbit
  static const double _angularSpeedNormal = 1.2;  // ~5.2 s / full orbit
  static const double _angularSpeedHard   = 1.8;  // ~3.5 s / full orbit

  double _orbitAngle  = 0.0;
  double _orbitRadius = 260.0;

  static const double _orbitRadiusMin = 50.0;

  /// How fast the orbit shrinks per second (continuous inward spiral).
  static const double _spiralSpeedNormal = 4.0;  // px/s
  static const double _spiralSpeedPrayer = 22.0; // px/s – faster during prayer

  // ── Slime trail ───────────────────────────────────────────────────────────

  /// Darkness drained from the current cell per second.  Applied every frame
  /// via `dt` so the trail is pixel-accurate and clearly visible.
  static const double _slimeDrainRate = 0.30;

  // ── Energy tick ───────────────────────────────────────────────────────────

  double _energyTimer = 0.0;
  static const double _energyInterval = 2.0;

  // ── Hit flicker ───────────────────────────────────────────────────────────

  double _hitFlickerTimer = 0.0;
  static const double _hitFlickerDuration = 0.3;

  DaemonComponent(this.model)
      : super(
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
    _cellDrainMultiplier =
        1.0 / FaithCalculatorService.difficultyFactorFor(game.difficulty);

    // Give each daemon a unique starting angle and radius so they spread out.
    final rng = math.Random(model.id.hashCode);
    _orbitAngle  = rng.nextDouble() * math.pi * 2;
    _orbitRadius = 180.0 + rng.nextDouble() * 180.0; // 180–360 px
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!game.isSpiritualWorld) return;
    if (model.dissolved) {
      removeFromParent();
      return;
    }

    if (_hitFlickerTimer > 0) _hitFlickerTimer -= dt;

    // ── Advance orbit angle every frame ───────────────────────────────────────
    _orbitAngle += _angularSpeed * dt;

    // ── Shrink orbit radius (faster during prayer) ────────────────────────────
    final spiralSpeed = game.spiritualDynamics.isPrayerAttractionActive
        ? _spiralSpeedPrayer
        : _spiralSpeedNormal;
    _orbitRadius = math.max(_orbitRadiusMin, _orbitRadius - spiralSpeed * dt);

    // ── Position = exact orbit point around the player ────────────────────────
    final p = game.player.position;
    position.setValues(
      p.x + math.cos(_orbitAngle) * _orbitRadius,
      p.y + math.sin(_orbitAngle) * _orbitRadius,
    );
    model.position.setFrom(position);

    // ── Slime trail: drain current cell every frame ───────────────────────────
    _drainCurrentCell(dt);

    // ── Energy tick ───────────────────────────────────────────────────────────
    _energyTimer += dt;
    if (_energyTimer >= _energyInterval) {
      _energyTimer = 0.0;
      _tickEnergy();
    }
  }

  // ── Slime trail ────────────────────────────────────────────────────────────

  /// Drains the cell the daemon currently occupies by `_slimeDrainRate × dt`.
  /// This is called every frame, producing a clearly visible dark trail.
  void _drainCurrentCell(double dt) {
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();
    final cell = game.grid.getCell(gx, gy);
    if (cell == null) return;
    cell.spiritualState =
        (cell.spiritualState - _slimeDrainRate * _cellDrainMultiplier * dt)
            .clamp(-1.0, 1.0);
  }

  // ── Energy tick ────────────────────────────────────────────────────────────

  /// Drains the daemon's energy every [_energyInterval] seconds based on the
  /// spiritual state of the cell it currently occupies.
  void _tickEnergy() {
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();
    final cell = game.grid.getCell(gx, gy);
    if (cell == null) return;

    final double energyDrain;
    if (cell.spiritualState < -0.5) {
      energyDrain = 1.0; // dark territory – daemon barely costs energy
    } else if (cell.spiritualState.abs() < 0.3) {
      energyDrain = 2.0; // neutral
    } else {
      energyDrain = 6.0; // positive territory – daemon weakened fast
    }

    model.energy += energyDrain;
    if (model.energy >= 0) _dissolve(cell);
  }

  // ── Combat ─────────────────────────────────────────────────────────────────

  /// Called by the prayer combat system when this daemon is within range.
  void takeDamage(double amount) {
    if (model.dissolved) return;
    _hitFlickerTimer = _hitFlickerDuration;
    model.energy += amount;
    if (model.energy >= 0) _explode();
  }

  /// Daemon killed by prayer: cleanses a 3-cell radius around the death point.
  void _explode() {
    model.dissolved = true;
    const int radius = 3;
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();

    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        final d = math.sqrt(dx * dx + dy * dy);
        if (d > radius) continue;
        final cell = game.grid.getCell(gx + dx, gy + dy);
        if (cell != null) {
          final falloff = 1.0 - (d / radius).clamp(0.0, 1.0);
          cell.spiritualState =
              (cell.spiritualState + 0.4 * falloff).clamp(-1.0, 1.0);
        }
      }
    }
    removeFromParent();
  }

  /// Natural dissolution: daemon's energy ran out; leaves a residuum marker.
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

    const center = Offset(_daemonSize / 2, _daemonSize / 2);

    // Simple color pulse driven by the orbit angle – no extra variable needed.
    final t = (math.sin(_orbitAngle * 2) + 1) / 2;
    final isFlickering = _hitFlickerTimer > 0;

    // Aura
    canvas.drawCircle(
      center,
      _daemonSize * 0.7,
      Paint()
        ..color = isFlickering
            ? Colors.white.withValues(alpha: 0.8)
            : Color.lerp(
                Colors.red[900]!.withValues(alpha: 0.6),
                Colors.black.withValues(alpha: 0.9),
                t,
              )!
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Core
    canvas.drawCircle(
      center,
      _daemonSize * 0.35,
      Paint()
        ..color = isFlickering
            ? Colors.white.withValues(alpha: 0.9)
            : Colors.red[800]!.withValues(alpha: 0.9),
    );

    // Energy arc (shows remaining life, always starts full)
    final energyFraction =
        (model.energy.abs() / model.initialEnergy.abs()).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: _daemonSize * 0.45),
      -math.pi / 2,
      math.pi * 2 * energyFraction,
      false,
      Paint()
        ..color = Colors.deepOrange.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }
}
