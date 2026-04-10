import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/models/daemon_model.dart';
import '../../domain/models/city_cell.dart';
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
///
/// Lastenheft Issue #31
class DaemonComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final DaemonModel model;
  final math.Random _rng;

  static const double _daemonSize = 18.0;
  static const double _moveInterval = 2.5;    // seconds per move step
  static const double _energyToCellRatio = 0.01; // energy units → spiritualState change

  double _moveTimer = 0.0;
  double _wobble = 0.0;

  DaemonComponent(this.model)
      : _rng = math.Random(model.id.hashCode),
        super(
          position: model.position.clone(),
          size: Vector2.all(_daemonSize),
          anchor: Anchor.center,
          priority: 95,
        );

  @override
  void update(double dt) {
    super.update(dt);

    if (!game.isSpiritualWorld) return;
    if (model.dissolved) {
      removeFromParent();
      return;
    }

    _wobble += dt * 2.5;

    _moveTimer += dt;
    if (_moveTimer >= _moveInterval) {
      _moveTimer = 0.0;
      _step();
    }
  }

  void _step() {
    // Try to move to an adjacent cell, preferring negative cells
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();

    // Gather candidate cells
    final candidates = <List<int>>[
      [gx + 1, gy], [gx - 1, gy], [gx, gy + 1], [gx, gy - 1],
    ];
    candidates.shuffle(_rng);

    List<int>? best;
    double bestScore = double.infinity;
    for (final c in candidates) {
      final cell = game.grid.getCell(c[0], c[1]);
      if (cell == null) continue;
      // Prefer more negative cells (lower spiritualState score = more negative)
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

  void _applyEffect(CityCell cell) {
    // Determine cell type (negative / neutral / positive)
    double cellDrain;
    double energyDrain;

    if (cell.spiritualState < -0.5) {
      // Strongly negative: daemon thrives, costs little energy
      cellDrain  = 1.0 * _energyToCellRatio;
      energyDrain = 1.0;
    } else if (cell.spiritualState.abs() < 0.3) {
      // Neutral: moderate drain
      cellDrain  = 2.0 * _energyToCellRatio;
      energyDrain = 2.0;
    } else {
      // Positive territory: daemon is weakened rapidly
      cellDrain  = 3.0 * _energyToCellRatio;
      energyDrain = 6.0;
    }

    cell.spiritualState = (cell.spiritualState - cellDrain).clamp(-1.0, 1.0);

    model.energy += energyDrain; // energy drains toward 0 (starts negative, approaches 0)
    if (model.energy >= 0) {
      _dissolve(cell);
    }
  }

  void _dissolve(CityCell cell) {
    model.dissolved = true;
    // Leave a "residuum" marker – slight negative imprint
    cell.spiritualState = (cell.spiritualState - 0.05).clamp(-1.0, 1.0);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (!game.isSpiritualWorld) return;

    final wobbleOffset = math.sin(_wobble) * 3;
    final center = Offset(size.x / 2, size.y / 2 + wobbleOffset);
    final t = (math.sin(_wobble * 0.7) + 1) / 2;

    // Pulsing red-to-black aura
    final auraColor = Color.lerp(
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
      Paint()..color = Colors.red[800]!.withValues(alpha: 0.9),
    );

    // Energy indicator (how full the daemon still is)
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
