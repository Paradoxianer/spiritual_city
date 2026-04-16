import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/models/daemon_model.dart';
import '../../domain/models/city_cell.dart';
import '../../../menu/domain/models/difficulty.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';

/// Visual and logic component for a Daemon NPC in the invisible world.
///
/// Behaviour per move tick:
/// - On a strongly negative cell (spiritualState < -0.5): drains cell by 1, own energy by 1
/// - On a neutral cell (|spiritualState| < 0.3):          drains cell by 2, own energy by 2
/// - On a positive cell (spiritualState > 0.5):           drains cell by 3, own energy by 6
///
/// When energy reaches 0 the daemon dissolves and leaves a "residuum" marker on the cell.
/// When killed by prayer combat, the daemon explodes and strongly cleanses the surrounding area.
///
/// Lastenheft Issue #31
class DaemonComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final DaemonModel model;
  final math.Random _rng;

  static const double _daemonSize = 18.0;
  static const double _energyToCellRatio = 0.01; // energy units → spiritualState change

  /// Seconds per move step – set in onLoad() based on difficulty.
  double _moveInterval = 2.5;

  double _moveTimer = 0.0;
  double _wobble = 0.0;

  // ── Prayer-attraction spiral state ────────────────────────────────────────
  double _spiralRadius = 0.0;
  double _spiralAngle = 0.0;
  bool _spiralInitialized = false;

  // Flicker effect when hit
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
    // Difficulty-scaled movement speed (hard = faster = 2.0 s, easy = slower = 3.0 s)
    _moveInterval = switch (game.difficulty) {
      Difficulty.easy => 3.0,
      Difficulty.normal => 2.5,
      Difficulty.hard => 2.0,
    };
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!game.isSpiritualWorld) return;
    if (model.dissolved) {
      removeFromParent();
      return;
    }

    _wobble += dt * 2.5;

    if (_hitFlickerTimer > 0) _hitFlickerTimer -= dt;

    _moveTimer += dt;
    if (_moveTimer >= _moveInterval) {
      _moveTimer = 0.0;
      _step();
    }
  }

  // ── Movement ──────────────────────────────────────────────────────────────

  void _step() {
    if (game.spiritualDynamics.isPrayerAttractionActive) {
      _stepSpiral();
    } else {
      _spiralInitialized = false; // reset so spiral restarts fresh next time
      _stepRandom();
    }
  }

  /// Normal wandering movement: prefer more-negative cells.
  void _stepRandom() {
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();

    final candidates = <List<int>>[
      [gx + 1, gy], [gx - 1, gy], [gx, gy + 1], [gx, gy - 1],
    ];
    candidates.shuffle(_rng);

    List<int>? best;
    double bestScore = double.infinity;
    for (final c in candidates) {
      final cell = game.grid.getCell(c[0], c[1]);
      if (cell == null) continue;
      if (cell.spiritualState < bestScore) {
        bestScore = cell.spiritualState;
        best = c;
      }
    }

    final targetGridPos = best ?? candidates.first;
    final targetCell = game.grid.getCell(targetGridPos[0], targetGridPos[1]);

    if (targetCell != null) {
      _applyEffect(targetCell);
      if (!model.dissolved) {
        position = Vector2(
          targetGridPos[0] * CellComponent.cellSize + CellComponent.cellSize / 2,
          targetGridPos[1] * CellComponent.cellSize + CellComponent.cellSize / 2,
        );
        model.position.setFrom(position);
      }
    }
  }

  /// Prayer-attraction spiral movement: circle the player in ever-tightening arcs.
  ///
  /// Attraction is ~2.5× stronger than normal drift: the spiral radius shrinks
  /// by 25 % per step (vs. random drift which has no direct player pull).
  void _stepSpiral() {
    final playerPos = game.player.position;

    // Initialise spiral from the daemon's current position relative to the player.
    if (!_spiralInitialized) {
      _spiralRadius = position.distanceTo(playerPos).clamp(50.0, 600.0);
      _spiralAngle = math.atan2(
          position.y - playerPos.y, position.x - playerPos.x);
      _spiralInitialized = true;
    }

    // Tighten the spiral by 25 % each step and advance 60° around the player.
    _spiralRadius = (_spiralRadius * 0.75).clamp(0.0, 600.0);
    _spiralAngle += math.pi / 3;

    final targetX = playerPos.x + math.cos(_spiralAngle) * _spiralRadius;
    final targetY = playerPos.y + math.sin(_spiralAngle) * _spiralRadius;

    // Among the four adjacent cells pick the one nearest to the spiral target.
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();

    final candidates = <List<int>>[
      [gx + 1, gy], [gx - 1, gy], [gx, gy + 1], [gx, gy - 1],
    ];

    List<int>? best;
    double bestDist = double.infinity;
    for (final c in candidates) {
      if (game.grid.getCell(c[0], c[1]) == null) continue;
      final cx = c[0] * CellComponent.cellSize + CellComponent.cellSize / 2;
      final cy = c[1] * CellComponent.cellSize + CellComponent.cellSize / 2;
      final dist = math.sqrt(
          math.pow(cx - targetX, 2) + math.pow(cy - targetY, 2));
      if (dist < bestDist) {
        bestDist = dist;
        best = c;
      }
    }

    if (best != null) {
      final targetCell = game.grid.getCell(best[0], best[1]);
      if (targetCell != null) {
        _applyEffect(targetCell);
        if (!model.dissolved) {
          position = Vector2(
            best[0] * CellComponent.cellSize + CellComponent.cellSize / 2,
            best[1] * CellComponent.cellSize + CellComponent.cellSize / 2,
          );
          model.position.setFrom(position);
        }
      }
    }
  }

  // ── Cell effect ───────────────────────────────────────────────────────────

  void _applyEffect(CityCell cell) {
    double cellDrain;
    double energyDrain;

    if (cell.spiritualState < -0.5) {
      // Strongly negative: daemon thrives, costs little energy
      cellDrain   = 1.0 * _energyToCellRatio;
      energyDrain = 1.0;
    } else if (cell.spiritualState.abs() < 0.3) {
      // Neutral: moderate drain
      cellDrain   = 2.0 * _energyToCellRatio;
      energyDrain = 2.0;
    } else {
      // Positive territory: daemon is weakened rapidly
      cellDrain   = 3.0 * _energyToCellRatio;
      energyDrain = 6.0;
    }

    cell.spiritualState = (cell.spiritualState - cellDrain).clamp(-1.0, 1.0);

    model.energy += energyDrain; // energy drains toward 0 (starts negative, approaches 0)
    if (model.energy >= 0) {
      _dissolve(cell);
    }
  }

  // ── Combat ────────────────────────────────────────────────────────────────

  /// Called by the prayer combat system when this daemon is within the impact zone.
  ///
  /// [amount] is scaled by difficulty and prayer power by the caller.
  void takeDamage(double amount) {
    if (model.dissolved) return;
    _hitFlickerTimer = _hitFlickerDuration;
    model.energy += amount; // advances energy toward 0
    if (model.energy >= 0) {
      _explode();
    }
  }

  /// Daemon destroyed by prayer: strongly cleanses the surrounding area.
  ///
  /// Explosion radius is 3 cells; inner cells receive a larger positive boost.
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

  // ── Rendering ─────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (!game.isSpiritualWorld) return;

    final wobbleOffset = math.sin(_wobble) * 3;
    final center = Offset(size.x / 2, size.y / 2 + wobbleOffset);
    final t = (math.sin(_wobble * 0.7) + 1) / 2;

    // Hit flicker: briefly tint white when damaged
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

    // Energy indicator (how much energy the daemon still has)
    final energyFraction = (model.energy.abs() / 100.0).clamp(0.0, 1.0);
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
