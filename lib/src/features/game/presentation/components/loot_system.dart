import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../domain/models/cell_object.dart';
import 'cell_component.dart';
import '../spirit_world_game.dart';

// ── Material pickup types ──────────────────────────────────────────────────

/// Type of material package that can be picked up on a road cell.
///
/// Probabilities (issue #47): 60 % small, 30 % normal, 10 % large.
enum LootType { small, normal, large }

extension LootTypeExt on LootType {
  /// Materials reward for this pickup type.
  double get reward => switch (this) {
        LootType.small  => 5.0,
        LootType.normal => 10.0,
        LootType.large  => 15.0,
      };

  /// Pick a random type: 60 % small, 30 % normal, 10 % large.
  static LootType random(Random rng) {
    final r = rng.nextDouble();
    if (r < 0.60) return LootType.small;
    if (r < 0.90) return LootType.normal;
    return LootType.large;
  }
}

// ── Single pickup data ─────────────────────────────────────────────────────

class _MaterialPickup {
  Vector2 worldPos; // centre of the cell in pixels – mutable for relocation
  final LootType type;

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
/// - Each pickup gives +[LootTypeExt.reward] materials to the player (real-world
///   resource only – no effect on the spiritual world).
/// - Pickups are always visible as a dim golden dot; they pulse brightly when
///   the pastor is within [_pickupRadius] world units (highlighting mechanic).
class LootSystem extends Component with HasGameReference<SpiritWorldGame> {
  static const int _maxPickups = 15;
  static const int _minPickups = 5;
  static const double _pickupRadius = 96.0; // 3 cells – easy to walk through
  static const double _staleDistance = 300.0; // relocate when player walks this far away
  static const double _respawnMin = 60.0;
  static const double _respawnMax = 120.0;

  final Random _rng;
  final List<_MaterialPickup> _pickups = [];
  final _log = Logger('LootSystem');

  // Pulsing animation timer (shared, cheap)
  double _pulseTimer = 0.0;

  // Throttle debug logs so they don't flood the console
  double _debugTimer = 0.0;
  static const double _debugInterval = 5.0; // log summary every 5 s

  // Paints – allocated once
  static final Paint _bgPaint = Paint();
  static final Paint _glowPaint = Paint()
    ..color = const Color(0x55FFD700)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static const Color _dimGoldColor = Color(0x66FFD700);

  LootSystem({int? seed}) : _rng = Random(seed);

  @override
  void update(double dt) {
    _pulseTimer = (_pulseTimer + dt) % (2 * pi);
    _debugTimer += dt;

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

    // Stale-relocation: move active pickups that are too far away to a new
    // road cell near the current player position so they stay reachable.
    for (final p in _pickups) {
      if (p.isPickedUp) continue;
      if (p.worldPos.distanceTo(playerPos) > _staleDistance) {
        _relocate(p);
      }
    }

    // Periodic summary log
    if (_debugTimer >= _debugInterval) {
      _debugTimer = 0.0;
      final total = _pickups.length;
      final activeNow = _pickups.where((p) => !p.isPickedUp).length;
      final respawning = total - activeNow;
      // Build a compact list of active pickup cell coords for easy inspection.
      final positions = _pickups
          .where((p) => !p.isPickedUp)
          .map((p) {
            final cx = (p.worldPos.x / CellComponent.cellSize).floor();
            final cy = (p.worldPos.y / CellComponent.cellSize).floor();
            return '(${p.type.name[0].toUpperCase()}:$cx,$cy)';
          })
          .join(' ');
      _log.info(
        '[LootSystem] pickups: $activeNow active, $respawning respawning, '
        '$total total | isSpiritualWorld=${game.isSpiritualWorld} | '
        'playerPos=${game.player.position}\n'
        '  active positions: $positions',
      );
    }
  }

  @override
  void render(Canvas canvas) {
    if (game.isSpiritualWorld) return; // not visible in spiritual world
    final pulse = (sin(_pulseTimer * 2) + 1) / 2; // 0..1
    final playerPos = game.player.position;
    int drawn = 0;
    for (final p in _pickups) {
      if (p.isPickedUp) continue;
      drawn++;
      final isNear = p.worldPos.distanceTo(playerPos) < _pickupRadius;
      _renderPickup(canvas, p, isNear ? pulse : 0.0, isNear);
    }
    // One-shot log on first render so we know the system is running.
    if (!_hasLoggedFirstRender) {
      _hasLoggedFirstRender = true;
      _log.info('[LootSystem] first render(): drew $drawn pickups');
    }
  }

  bool _hasLoggedFirstRender = false;

  void _renderPickup(Canvas canvas, _MaterialPickup p, double pulse, bool highlighted) {
    final cx = (p.worldPos.x / CellComponent.cellSize).floor();
    final cy = (p.worldPos.y / CellComponent.cellSize).floor();
    final offset = Offset(p.worldPos.x, p.worldPos.y);

    if (highlighted) {
      // Bright pulsing gold glow when pastor is near (< _pickupRadius units).
      final r = 14.0 + pulse * 6.0;
      final alpha = (0.7 + pulse * 0.3).clamp(0.0, 1.0);
      _bgPaint.color = Color.fromRGBO(255, 215, 0, alpha);
      canvas.drawCircle(offset, r, _bgPaint);
      canvas.drawCircle(offset, r + 4, _glowPaint);
    } else {
      // Clearly visible dim indicator even from afar.
      _bgPaint.color = _dimGoldColor;
      canvas.drawCircle(offset, 16.0, _bgPaint);
      canvas.drawCircle(offset, 18.0, _glowPaint);
    }

    // Inner package symbol: box
    final box = Rect.fromCenter(center: offset, width: 14, height: 14);
    final boxPaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawRect(box, boxPaint);

    // Cell-coordinate label above the dot so the player can spot & navigate to it.
    final label = '📦($cx,$cy)';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: highlighted ? const Color(0xFFFFD700) : const Color(0xAAFFD700),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy - 28));
  }

  // ── Spawning / relocation ─────────────────────────────────────────────────

  /// Returns a world-pixel centre for a random road cell within ±6 cells of
  /// the player, or `null` if no suitable cell was found in 30 attempts.
  Vector2? _findRoadCellNear() {
    final playerCell = game.player.position / CellComponent.cellSize;
    final px = playerCell.x.floor();
    final py = playerCell.y.floor();

    for (int attempt = 0; attempt < 30; attempt++) {
      final cx = px + _rng.nextInt(12) - 6;
      final cy = py + _rng.nextInt(12) - 6;
      final cell = game.grid.getCell(cx, cy);
      if (cell == null || cell.data is! RoadData) continue;

      final pos = Vector2(
        cx * CellComponent.cellSize + CellComponent.cellSize / 2,
        cy * CellComponent.cellSize + CellComponent.cellSize / 2,
      );
      // Don't stack on an occupied cell.
      if (_pickups.any((p) => !p.isPickedUp && p.worldPos.distanceTo(pos) < 8)) continue;

      return pos;
    }
    return null;
  }

  void _trySpawn() {
    if (_pickups.length >= _maxPickups) return;

    final pos = _findRoadCellNear();
    if (pos == null) {
      _log.warning('[LootSystem] _trySpawn: no road cell found near player');
      return;
    }

    final type = LootTypeExt.random(_rng);
    _pickups.add(_MaterialPickup(pos, type));
    final cx = (pos.x / CellComponent.cellSize).floor();
    final cy = (pos.y / CellComponent.cellSize).floor();
    _log.info('[LootSystem] spawned ${type.name} +${type.reward.toInt()} MP at ($cx,$cy)');
  }

  /// Move a stale pickup to a new road cell near the current player position.
  void _relocate(_MaterialPickup p) {
    final pos = _findRoadCellNear();
    if (pos == null) return;

    final oldCx = (p.worldPos.x / CellComponent.cellSize).floor();
    final oldCy = (p.worldPos.y / CellComponent.cellSize).floor();
    final cx = (pos.x / CellComponent.cellSize).floor();
    final cy = (pos.y / CellComponent.cellSize).floor();
    p.worldPos = pos;
    _log.info('[LootSystem] relocated ${p.type.name} ($oldCx,$oldCy) → ($cx,$cy)');
  }

  void _collect(_MaterialPickup p) {
    p.respawnTimer = _respawnMin + _rng.nextDouble() * (_respawnMax - _respawnMin);

    // Give materials to player (real-world resource only – no spiritual effect).
    game.gainMaterials(p.type.reward);

    _log.info(
      '[LootSystem] collected ${p.type.name} (+${p.type.reward.toInt()} MP) '
      'at world pixel (${p.worldPos.x},${p.worldPos.y}) | '
      'respawns in ${p.respawnTimer.toStringAsFixed(1)}s',
    );

    // Show pickup toast in HUD.
    final mp = p.type.reward.toInt();
    game.lootPickupMessage.value = '📦 +$mp MP';

    // Notify mission service
    game.missionService.onMaterialCollected();
  }
}
