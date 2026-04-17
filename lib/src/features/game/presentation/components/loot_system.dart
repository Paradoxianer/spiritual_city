import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/models/cell_object.dart';
import 'cell_component.dart';
import '../spirit_world_game.dart';

// ── Material pickup types ──────────────────────────────────────────────────

enum _LootType { small, normal, large }

extension _LootTypeExt on _LootType {
  double get reward => switch (this) {
        _LootType.small  => 5.0,
        _LootType.normal => 10.0,
        _LootType.large  => 15.0,
      };

  /// Pick a random type: 60 % small, 30 % normal, 10 % large.
  static _LootType random(Random rng) {
    final r = rng.nextDouble();
    if (r < 0.60) return _LootType.small;
    if (r < 0.90) return _LootType.normal;
    return _LootType.large;
  }
}

// ── Single pickup data ─────────────────────────────────────────────────────

class _MaterialPickup {
  final Vector2 worldPos; // centre of the cell in pixels
  final _LootType type;

  bool isPickedUp = false;

  /// Countdown (seconds) until this pickup re-spawns.  −1 = always active.
  double respawnTimer = -1;

  _MaterialPickup(this.worldPos, this.type);
}

// ── LootSystem Component ──────────────────────────────────────────────────

/// Manages spawning, rendering, and pickup of material packages on road cells.
///
/// Rules (from issue #47):
/// - 5–15 pickups active simultaneously.
/// - Only spawn on [RoadData] cells visible in the current render zone.
/// - Auto-pickup when player enters < [_pickupRadius] world units.
/// - Picked-up items respawn after a random 60–120 s delay.
/// - Each pickup gives +[_LootTypeExt.reward] materials to the player and
///   nudges the cell's spiritual state upward (+0.01).
class LootSystem extends Component with HasGameReference<SpiritWorldGame> {
  static const int _maxPickups = 15;
  static const int _minPickups = 5;
  static const double _pickupRadius = 40.0;
  static const double _respawnMin = 60.0;
  static const double _respawnMax = 120.0;

  final Random _rng;
  final List<_MaterialPickup> _pickups = [];

  // Pulsing animation timer (shared, cheap)
  double _pulseTimer = 0.0;

  // Paints – allocated once
  static final Paint _bgPaint = Paint();
  static final Paint _glowPaint = Paint()
    ..color = const Color(0x55FFD700)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  LootSystem({int? seed}) : _rng = Random(seed);

  @override
  void update(double dt) {
    _pulseTimer = (_pulseTimer + dt) % (2 * pi);

    // Respawn timer countdown
    for (final p in _pickups) {
      if (p.isPickedUp && p.respawnTimer > 0) {
        p.respawnTimer -= dt;
        if (p.respawnTimer <= 0) p.isPickedUp = false;
      }
    }

    // Maintain minimum count by trying to spawn on road cells
    final active = _pickups.where((p) => !p.isPickedUp).length;
    if (active < _minPickups) {
      _trySpawn();
    }

    // Auto-pickup check
    final playerPos = game.player.position;
    for (final p in _pickups) {
      if (p.isPickedUp) continue;
      if (p.worldPos.distanceTo(playerPos) < _pickupRadius) {
        _collect(p);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (game.isSpiritualWorld) return; // not visible in spiritual world
    final pulse = (sin(_pulseTimer * 2) + 1) / 2; // 0..1
    for (final p in _pickups) {
      if (p.isPickedUp) continue;
      _renderPickup(canvas, p, pulse);
    }
  }

  void _renderPickup(Canvas canvas, _MaterialPickup p, double pulse) {
    // Convert world position to local canvas coordinates (relative to world origin)
    final offset = Offset(p.worldPos.x, p.worldPos.y);
    const baseR = 6.0;
    final r = baseR + pulse * 3;

    final alpha = (0.6 + pulse * 0.4).clamp(0.0, 1.0);
    _bgPaint.color = Color.fromRGBO(255, 215, 0, alpha); // gold
    canvas.drawCircle(offset, r, _bgPaint);
    canvas.drawCircle(offset, r + 3, _glowPaint);

    // Inner package symbol: small box
    final box = Rect.fromCenter(center: offset, width: 8, height: 8);
    final boxPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(box, boxPaint);
  }

  // ── Spawning ──────────────────────────────────────────────────────────────

  void _trySpawn() {
    if (_pickups.length >= _maxPickups) return;

    // Sample random road cells near the player within a radius of 15 chunks
    final playerCell = game.player.position / CellComponent.cellSize;
    final px = playerCell.x.floor();
    final py = playerCell.y.floor();

    for (int attempt = 0; attempt < 30; attempt++) {
      final dx = _rng.nextInt(30) - 15;
      final dy = _rng.nextInt(30) - 15;
      final cx = px + dx;
      final cy = py + dy;
      final cell = game.grid.getCell(cx, cy);
      if (cell == null || cell.data is! RoadData) continue;

      // Don't stack pickups on the same cell
      final wx = cx * CellComponent.cellSize + CellComponent.cellSize / 2;
      final wy = cy * CellComponent.cellSize + CellComponent.cellSize / 2;
      final pos = Vector2(wx, wy);
      if (_pickups.any((p) => !p.isPickedUp && p.worldPos.distanceTo(pos) < 8)) {
        continue;
      }

      _pickups.add(_MaterialPickup(pos, _LootTypeExt.random(_rng)));
      return;
    }
  }

  void _collect(_MaterialPickup p) {
    p.isPickedUp = true;
    p.respawnTimer = _respawnMin + _rng.nextDouble() * (_respawnMax - _respawnMin);

    // Give materials to player
    game.gainMaterials(p.type.reward);

    // Nudge spiritual state of the cell underneath
    final cx = (p.worldPos.x / CellComponent.cellSize).floor();
    final cy = (p.worldPos.y / CellComponent.cellSize).floor();
    final cell = game.grid.getCell(cx, cy);
    if (cell != null) {
      cell.spiritualState = (cell.spiritualState + 0.01).clamp(-1.0, 1.0);
    }

    // Notify mission service
    game.missionService.onMaterialCollected();
  }
}
