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
/// Probabilities: 60 % small, 30 % normal, 10 % large.
enum LootType { small, normal, large }

extension LootTypeExt on LootType {
  /// Materials reward for this pickup type.
  double get reward => switch (this) {
        LootType.small  => 5.0,
        LootType.normal => 10.0,
        LootType.large  => 15.0,
      };

  // TODO(spirit-combat): XP reward for use in the spiritual-world combat circle.
  // double get xpReward => switch (this) {
  //       LootType.small  => 2.0,
  //       LootType.normal => 5.0,
  //       LootType.large  => 10.0,
  //     };

  // TODO(spirit-combat): Combat modifier granted when carrying this pickup into
  // the spiritual world (e.g. temporary damage or defence boost).
  // double get combatModifier => switch (this) {
  //       LootType.small  => 0.05,
  //       LootType.normal => 0.10,
  //       LootType.large  => 0.20,
  //     };

  /// Emoji displayed on the road cell for this loot type.
  String get emoji => switch (this) {
        LootType.small  => '📦',
        LootType.normal => '🎁',
        LootType.large  => '💎',
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
  Vector2 worldPos; // centre of the cell in pixels
  final LootType type;

  bool isPickedUp = false;

  /// Countdown (seconds) until this pickup re-spawns.
  double respawnTimer = -1;

  // TODO(spirit-combat): track if this pickup was "charged" in the spiritual
  // world so it can grant xpReward / combatModifier on collection.
  // bool isCharged = false;

  _MaterialPickup(this.worldPos, this.type);
}

// ── LootSystem Component ──────────────────────────────────────────────────

/// Manages spawning, rendering, and pickup of material packages on road cells.
///
/// - At most [_maxPickups] pickups active simultaneously (normally 0–[_minPickups]).
/// - Only spawns on [RoadData] cells near the player.
/// - Pickup triggers only when the player steps directly on the item
///   (distance < [_pickupRadius], i.e. roughly half a cell).
/// - Picked-up items respawn after [_respawnMin]–[_respawnMax] seconds.
/// - Each pickup renders as a plain emoji so it looks like it is lying on the road.
/// - Priority 10 ensures rendering above road chunks (priority 0) but below NPCs.
class LootSystem extends Component with HasGameReference<SpiritWorldGame> {
  // Render above road-chunk tiles (priority 0) and buildings (priority 5),
  // but below NPCs / player (priority 90+).
  static const int _renderPriority = 10;

  static const int _maxPickups = 3;
  static const int _minPickups = 1;
  /// Pickup radius ≈ half a cell – player must step directly on the item.
  static const double _pickupRadius = 16.0;
  static const double _respawnMin = 180.0;
  static const double _respawnMax = 360.0;

  /// Grace period (seconds) before the first spawn on a fresh game (no saved
  /// state).  Prevents a pickup from appearing right beside the spawn point.
  static const double _initialSpawnDelay = 30.0;

  final Random _rng;
  final List<_MaterialPickup> _pickups = [];
  final _log = Logger('LootSystem');

  // Throttle debug logs so they don't flood the console
  double _debugTimer = 0.0;
  static const double _debugInterval = 5.0;

  /// Countdown before the very first spawn.  Set to [_initialSpawnDelay] for
  /// fresh games; set to 0 when state is restored from a save.
  double _spawnDelay;

  LootSystem({int? seed})
      : _rng = Random(seed),
        _spawnDelay = _initialSpawnDelay,
        super(priority: _renderPriority);

  // ── Save / restore ────────────────────────────────────────────────────────

  /// Serialises all current pickups (active and respawning) for persistence.
  List<Map<String, dynamic>> captureState() {
    return _pickups.map((p) => {
      'x':            p.worldPos.x,
      'y':            p.worldPos.y,
      'type':         p.type.index,
      'isPickedUp':   p.isPickedUp,
      'respawnTimer': p.respawnTimer,
    }).toList();
  }

  /// Restores pickups from a previously serialised state.
  ///
  /// After a restore the spawn delay is cleared so the loot system does not
  /// add extra pickups on top of the restored ones immediately.
  void restoreState(List<Map<String, dynamic>> data) {
    _pickups.clear();
    for (final d in data) {
      final pos  = Vector2((d['x'] as num).toDouble(), (d['y'] as num).toDouble());
      final type = LootType.values[(d['type'] as num).toInt()];
      final p    = _MaterialPickup(pos, type);
      p.isPickedUp   = d['isPickedUp']   as bool?   ?? false;
      p.respawnTimer = (d['respawnTimer'] as num?)?.toDouble() ?? -1.0;
      _pickups.add(p);
    }
    // State restored – no extra startup delay needed.
    _spawnDelay = 0.0;
    _log.info('[LootSystem] restored ${_pickups.length} pickups from save');
  }

  @override
  void update(double dt) {
    _debugTimer += dt;

    // Startup grace-period countdown (only active on fresh games).
    if (_spawnDelay > 0) {
      _spawnDelay -= dt;
      if (_spawnDelay < 0) _spawnDelay = 0;
    }

    // Respawn timer countdown
    for (final p in _pickups) {
      if (p.isPickedUp && p.respawnTimer > 0) {
        p.respawnTimer -= dt;
        if (p.respawnTimer <= 0) p.isPickedUp = false;
      }
    }

    // Only spawn genuinely new pickups when the total pool hasn't reached the
    // minimum yet.  Collected items already have a respawn timer running – they
    // will reappear on their own, so we must NOT create an extra entry here.
    // Also honour the startup delay so no loot spawns right next to the player
    // when first loading into the world.
    if (_spawnDelay <= 0 && _pickups.length < _minPickups) {
      _trySpawn();
    }

    // Auto-pickup: only when the player steps directly on the item.
    final playerPos = game.player.position;
    for (final p in _pickups) {
      if (p.isPickedUp) continue;
      if (p.worldPos.distanceTo(playerPos) < _pickupRadius) {
        _collect(p);
      }
    }

    // Periodic summary log
    if (_debugTimer >= _debugInterval) {
      _debugTimer = 0.0;
      final total = _pickups.length;
      final activeNow = _pickups.where((p) => !p.isPickedUp).length;
      final respawning = total - activeNow;
      final positions = _pickups
          .where((p) => !p.isPickedUp)
          .map((p) {
            final cx = (p.worldPos.x / CellComponent.cellSize).floor();
            final cy = (p.worldPos.y / CellComponent.cellSize).floor();
            return '(${p.type.emoji}$cx,$cy)';
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
    for (final p in _pickups) {
      if (p.isPickedUp) continue;
      _renderPickup(canvas, p);
    }
    if (!_hasLoggedFirstRender) {
      _hasLoggedFirstRender = true;
      final drawn = _pickups.where((p) => !p.isPickedUp).length;
      _log.info('[LootSystem] first render(): drew $drawn pickups (priority=$priority)');
    }
  }

  bool _hasLoggedFirstRender = false;

  void _renderPickup(Canvas canvas, _MaterialPickup p) {
    final offset = Offset(p.worldPos.x, p.worldPos.y);
    // Draw the emoji centered on the cell so it looks like it's lying on the road.
    final tp = TextPainter(
      text: TextSpan(
        text: p.type.emoji,
        style: const TextStyle(fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2));
  }

  // ── Spawning ──────────────────────────────────────────────────────────────

  /// Returns a world-pixel centre for a random road cell within ±8 cells of
  /// the player, or `null` if no suitable cell was found in 30 attempts.
  Vector2? _findRoadCellNear() {
    final playerCell = game.player.position / CellComponent.cellSize;
    final px = playerCell.x.floor();
    final py = playerCell.y.floor();

    for (int attempt = 0; attempt < 30; attempt++) {
      final cx = px + _rng.nextInt(16) - 8;
      final cy = py + _rng.nextInt(16) - 8;
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
    _log.info('[LootSystem] spawned ${type.emoji} +${type.reward.toInt()} MP at ($cx,$cy)');
  }

  void _collect(_MaterialPickup p) {
    p.isPickedUp = true;
    p.respawnTimer = _respawnMin + _rng.nextDouble() * (_respawnMax - _respawnMin);

    // Give materials to player (real-world resource only – no spiritual effect).
    game.gainMaterials(p.type.reward);

    // TODO(spirit-combat): also grant p.type.xpReward when XP system is active.
    // TODO(spirit-combat): apply p.type.combatModifier as a timed buff.

    _log.info(
      '[LootSystem] collected ${p.type.emoji} (+${p.type.reward.toInt()} MP) '
      'at world pixel (${p.worldPos.x},${p.worldPos.y}) | '
      'respawns in ${p.respawnTimer.toStringAsFixed(1)}s',
    );

    // Show pickup toast in HUD.
    final mp = p.type.reward.toInt();
    game.lootPickupMessage.value = '${p.type.emoji} +$mp MP';

    // Notify mission service
    game.missionService.onMaterialCollected();
  }
}
