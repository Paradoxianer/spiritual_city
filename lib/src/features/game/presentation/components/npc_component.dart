import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/game_time.dart';
import '../../domain/actions/npc_actions.dart';
import '../../domain/models/church.dart';
import '../../domain/services/learning_service.dart';
import 'daemon_component.dart';
import '../../domain/models/building_model.dart';
import '../../domain/models/npc_model.dart';
import '../../domain/models/cell_object.dart';
import '../../domain/models/interactions.dart';
import '../../domain/services/influence_service.dart';
import '../../domain/services/npc_interaction_service.dart';
import '../../../menu/domain/models/difficulty.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';

/// Level-of-detail setting for an NPC.
///
/// * [high]   – full AI, animation and spiritual-influence updates (≤200 u)
/// * [medium] – simplified movement only, no spiritual influence (200–500 u)
/// * [low]    – static/invisible, no logic (>500 u)
enum NPCDetailLevel { high, medium, low }

class NPCComponent extends PositionComponent
    with HasGameReference<SpiritWorldGame>
    implements Interactable {
  NPCModel _model;

  /// Current active data model.  Updated by [assignModel] when the component
  /// is recycled from the [NPCPool].
  NPCModel get model => _model;

  static const double npcSize = 20.0;

  final Random _random = Random();

  /// Dialog type for a life-talk step carried by a 🩹 wounded healer.
  static const String healerTalkType = 'healertalk';

  late final NpcInteractionService _interactions;


  /// LOD level assigned by the NPC manager based on distance to the player.
  NPCDetailLevel detailLevel = NPCDetailLevel.high;

  // ─── Movement ─────────────────────────────────────────────────────────────

  double _currentSpeed = 40.0;
  Vector2? _targetPosition;
  double _aiUpdateTimer = 0;
  static const double _aiUpdateInterval = 2.0;
  // If no wander target can be found for this long, we treat the NPC as
  // trapped and relocate it to a nearby valid tile.
  double _stuckTimer = 0.0;
  static const double _stuckRecoveryDelay = 4.0;
  // Search radius for trapped-NPC recovery. If no safe tile is found, the NPC
  // keeps its current position and retries on the next recovery cycle.
  static const int _recoverySearchRadius = 6;

  // Timer for daily NPC spiritual influence on cells (Lastenheft §6.3)
  double _spiritualInfluenceTimer = 0.0;

  /// One in-game day = [GameTime.gameDaySeconds] real seconds.
  static const double _spiritualInfluenceInterval = GameTime.gameDaySeconds;

  // ─── Pre-allocated paints (never create Paint() in render()) ─────────────

  /// Body fill – colour updated each render, object reused.
  final Paint _bodyPaint = Paint();

  /// Christian cross stroke – style/width set once.
  final Paint _crossPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  /// Spiritual aura in the invisible world – blur set once, colour per render.
  final Paint _auraPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

  /// Mission marker – pre-allocated paint for the background circle.
  final Paint _missionBadgePaint = Paint()..color = const Color(0xFFFFD700);
  final Paint _missionBadgeBorderPaint = Paint()
    ..color = const Color(0xFF8B6914)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  // ─────────────────────────────────────────────────────────────────────────

  NPCComponent({required NPCModel model})
      : _model = model,
        super(
          position: model.homePosition.clone(),
          size: Vector2.all(npcSize),
          anchor: Anchor.center,
          priority: 90,
        );

  // ─── Pool helpers ──────────────────────────────────────────────────────────

  /// Reassign this component to [newModel].  Called by [NPCPool.borrow] when
  /// recycling an existing component.
  void assignModel(NPCModel newModel) {
    _model = newModel;
    position.setFrom(newModel.homePosition);
    _spiritualInfluenceTimer = 0.0;
    _targetPosition = null;
    _aiUpdateTimer = 0;
    _stuckTimer = 0.0;
    detailLevel = NPCDetailLevel.high;
  }

  /// Prepare the component for return to the pool.  Removes it from the scene
  /// graph if it still has a parent and resets all per-session state so a
  /// future [assignModel] call gets a clean slate.
  void deactivateForPool() {
    _spiritualInfluenceTimer = 0.0;
    _stuckTimer = 0.0;
    detailLevel = NPCDetailLevel.high;
    removeFromParent();
  }

  @override
  String get interactionLabel => model.name;

  @override
  String get interactionEmoji => _getNPCEmoji();

  @override
  Vector2 get interactionPosition => position;

  String _getNPCEmoji() {
    if (model.isChristian) return '✝️'; // Geändert von 🕊️ zu ✝️
    if (model.faith < -30) return '😠';
    if (model.faith < 30) return '👤';
    return '🤔';
  }

  @override
  void onInteract() {
    model.resetSession();
    game.showDialog(model.name, _getNPCEmoji(), model);
  }

  /// Runs a dialog action through [NpcInteractionService] and applies
  /// everything outside the NPC: player resources, cells, counters, practice.
  @override
  String handleInteraction(String type) {
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();
    final cell = game.grid.getCell(gx, gy);
    // 🩹 A wounded healer from the church takes this life-talk step.
    ChurchMember? healer;
    if (type == healerTalkType) {
      final ch = model.backstory.currentChallenge;
      healer = ch == null ? null : game.progress.church
          .healerFor(ch.event.id, game.dayStats.day, exceptNpcId: model.id);
      if (healer == null) return '🚫🩹';
    }
    final discipline =
        healer != null ? null : NpcActions.byType(type)?.discipline;

    final r = _interactions.perform(
      healer != null ? NpcActions.lifeTalk.type : type,
      model,
      freeLifeTalk: healer != null,
      spiritualState: cell?.spiritualState ?? 0.0,
      playerFaith: game.faith,
      playerHealth: game.health,
      playerMaterials: game.materials,
      practiceMultiplier: game.progress.practice.multiplier(discipline) * _intercessionFactor,
    );

    if (r.playerFaithDelta != 0) game.gainFaith(r.playerFaithDelta);
    if (r.playerHealthDelta != 0) game.gainHealth(r.playerHealthDelta);
    if (r.playerMaterialsDelta < 0) game.spendMaterials(-r.playerMaterialsDelta);
    if (r.insightDelta > 0) game.progress.addInsight(r.insightDelta);
    if (r.cellDelta != 0 && cell != null) {
      cell.spiritualState = (cell.spiritualState + r.cellDelta).clamp(-1.0, 1.0);
    }
    if (healer != null && r.performed) healer.lastHelpDay = game.dayStats.day;
    if (r.conversationHeld) game.recordConversation();
    if (r.serviceCompleted) game.missionService.onServiceCompleted();
    if (r.converted) {
      game.progress.church.join(model);
      game.recordConversion();
      _lightUpAround(gx, gy);
    }
    if (r.performed && discipline != null) game.recordPractice(discipline);
    if (r.performed) {
      if (type == 'counsel') game.recordLessonTask(LessonTask.counsel);
      if (type == 'pray') game.recordLessonTask(LessonTask.pray);
      // A life-story challenge fully worked through (it pays insight).
      if ((type == 'lifetalk' || healer != null) && r.insightDelta > 0) {
        game.dayStats.storiesHealed++;
        game.progress.church.recordHealed(model);
      }
    }
    if (healer != null && r.performed) {
      return '🩹${healer.name.split(' ').first} ${r.reaction}';
    }
    return r.reaction;
  }

  /// 🙏🏠 The pastor interceded for this person's home today.
  double get _intercessionFactor {
    final home = model.homeBuildingId;
    if (home == null) return 1.0;
    final b = game.chunkManager.getBuildingModel(home);
    return b != null && b.intercededDay == game.dayStats.day
        ? SpiritWorldGame.intercessionGainFactor
        : 1.0;
  }

  /// Strong positive spiritual area effect on conversion (radius 5); cells
  /// closer to the NPC are affected more strongly.
  void _lightUpAround(int gx, int gy) {
    const radius = 5;
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        final distSq = dx * dx + dy * dy;
        if (distSq > radius * radius) continue;
        final c = game.grid.getCell(gx + dx, gy + dy);
        if (c == null) continue;
        final distanceFactor = 1.0 - distSq / (radius * radius);
        c.spiritualState = (c.spiritualState + 0.35 * distanceFactor).clamp(-1.0, 1.0);
      }
    }
  }

  @override
  Future<void> onLoad() async {
    _interactions =
        NpcInteractionService(difficulty: game.difficulty, rng: _random);
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.paused) return;

    // ── Spiritual world: cheap movement-only pass ─────────────────────────
    // NPCs keep gliding toward their last waypoint so they still visibly
    // wander, but all expensive operations (pathfinding, grid lookups,
    // spiritual-influence writes) are skipped to give the daemon rendering
    // a stable, stutter-free dt budget.
    if (game.isSpiritualWorld) {
      if (_targetPosition != null) _moveTowardsTarget(dt);
      if (model.possessed) _updatePossessor(dt);
      return;
    }
    // ── Normal world: full AI ─────────────────────────────────────────────

    switch (detailLevel) {
      case NPCDetailLevel.high:
        _updateAI(dt);
        _updateSpiritualInfluence(dt);
      case NPCDetailLevel.medium:
        // Simplified: only wander, skip expensive spiritual influence
        _updateAI(dt);
      case NPCDetailLevel.low:
        // Static placeholder – no logic executed
        break;
    }
  }

  // ── Possession (#180) ──────────────────────────────────────────────────────

  double _possessorTimer = 0.0;

  /// How often a possessed person sends out a new 👁️ possessor while the
  /// pastor is near and none of theirs is around.
  static const double possessorInterval = 10.0;

  /// Possessed people only act when the pastor is this close (px).
  static const double possessorReach = 420.0;

  void _updatePossessor(double dt) {
    _possessorTimer += dt;
    if (_possessorTimer < possessorInterval) return;
    _possessorTimer = 0.0;
    if (position.distanceTo(game.player.position) > possessorReach) return;
    final hasOne = game.world.children
        .whereType<DaemonComponent>()
        .any((d) => d.model.hostNpcId == model.id && !d.model.dissolved);
    if (!hasOne) game.spiritualDynamics.spawnPossessor(position, model.id);
  }

  /// Daily: NPC faith state influences the cell they are standing on (Lastenheft §6.3)
  ///
  /// Converted NPCs additionally call [InfluenceService.applyAoE] so their
  /// passive influence is tracked by the same system as building actions
  /// (Issue #59 – NPC-Influence-Integration).
  void _updateSpiritualInfluence(double dt) {
    _spiritualInfluenceTimer += dt;
    if (_spiritualInfluenceTimer < _spiritualInfluenceInterval) return;
    _spiritualInfluenceTimer = 0.0;

    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();
    final cell = game.grid.getCell(gx, gy);
    if (cell == null) return;

    if (model.isChristian) {
      // Converted Christians radiate positive influence on the cell they
      // occupy and on the four directly adjacent cells. The per-faith-point
      // multipliers are tuned per difficulty so that, at max faith (100),
      // the centre-cell delta is easy=0.7 / normal=0.5 / hard=0.3 and
      // the adjacent-cell delta is easy=0.3 / normal=0.25 / hard=0.2.
      final (centreK, adjacentK) = switch (game.difficulty) {
        Difficulty.easy => (0.0150, 0.0075),
        Difficulty.normal => (0.0100, 0.0050),
        Difficulty.hard => (0.0050, 0.0025),
      };
      cell.spiritualState =
          (cell.spiritualState + model.faith * centreK).clamp(-1.0, 1.0);
      // Adjacent cells receive a slightly weaker push.
      for (final offset in const [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1]
      ]) {
        final neighbour = game.grid.getCell(gx + offset[0], gy + offset[1]);
        if (neighbour != null) {
          neighbour.spiritualState =
              (neighbour.spiritualState + model.faith * adjacentK)
                  .clamp(-1.0, 1.0);
        }
      }
      // Small faith decay: without ongoing care their fervour slowly cools.
      // Floor at 50 so they remain Christian but their influence weakens.
      model.faith = (model.faith - 0.15).clamp(50.0, 100.0);

      // Passive AoE via InfluenceService (Issue #59 – NPC-Influence-Integration).
      // Converted NPCs emit a permanent per-tick influence pulse so their
      // spiritual footprint is visible and decays like other building actions.
      game.influenceService.applyAoE(
        grid: game.grid,
        originX: gx,
        originY: gy,
        delta: BuildingInfluenceConstants.deltaNpcPassive,
        radius: BuildingInfluenceConstants.radiusNpcPassive,
        durationType: InfluenceDurationType.permanent,
        buildingMultiplier: BuildingInfluenceConstants.multiplierSmall,
      );
    } else if (model.faith > 50) {
      // Sympathetic NPCs provide a weak positive nudge
      cell.spiritualState = (cell.spiritualState + 0.05).clamp(-1.0, 1.0);
    } else if (model.faith < -50) {
      // Very hostile NPCs reinforce darkness
      cell.spiritualState =
          (cell.spiritualState - model.faith.abs() * 0.002).clamp(-1.0, 1.0);
    }
  }

  void _updateAI(double dt) {
    _aiUpdateTimer -= dt;
    if (_aiUpdateTimer <= 0) {
      _aiUpdateTimer = _aiUpdateInterval + _random.nextDouble();

      final gx = (position.x / CellComponent.cellSize).floor();
      final gy = (position.y / CellComponent.cellSize).floor();
      final cell = game.grid.getCell(gx, gy);
      final state = cell?.spiritualState ?? 0;

      // Slow down in dark zones for non-Christians
      _currentSpeed = (state < -0.5 && !model.isChristian)
          ? 15.0
          : 35.0 + (model.faith / 10.0).clamp(-10.0, 20.0);

      if (_targetPosition == null ||
          position.distanceTo(_targetPosition!) < 4) {
        _targetPosition = _findNextWanderTarget(gx, gy);
      }
    }

    if (_targetPosition != null) {
      _stuckTimer = 0.0;
      _moveTowardsTarget(dt);
    } else {
      _stuckTimer += dt;
      if (_stuckTimer >= _stuckRecoveryDelay) {
        _stuckTimer = 0.0;
        final gx = (position.x / CellComponent.cellSize).floor();
        final gy = (position.y / CellComponent.cellSize).floor();
        _recoverFromTrap(gx, gy);
      }
    }
  }

  Vector2? _findNextWanderTarget(int gx, int gy) {
    final directions = [
      Vector2(0, 1),
      Vector2(0, -1),
      Vector2(1, 0),
      Vector2(-1, 0)
    ];
    directions.shuffle(_random);
    // Prefer road cells so NPCs walk along streets, not through buildings
    directions.sort((a, b) {
      final cellA = game.grid.getCell(gx + a.x.toInt(), gy + a.y.toInt());
      final cellB = game.grid.getCell(gx + b.x.toInt(), gy + b.y.toInt());
      final isRoadA = cellA?.data is RoadData ? 1 : 0;
      final isRoadB = cellB?.data is RoadData ? 1 : 0;
      return isRoadB.compareTo(isRoadA);
    });
    for (final dir in directions) {
      final tx = gx + dir.x.toInt();
      final ty = gy + dir.y.toInt();
      if (game.grid.isWalkable(tx, ty)) {
        return Vector2(
          tx * CellComponent.cellSize + CellComponent.cellSize / 2,
          ty * CellComponent.cellSize + CellComponent.cellSize / 2,
        );
      }
    }
    return null;
  }

  void _moveTowardsTarget(double dt) {
    final diff = _targetPosition! - position;
    if (diff.length < _currentSpeed * dt) {
      position.setFrom(_targetPosition!);
      _targetPosition = null;
    } else {
      diff.normalize();
      position.add(diff * _currentSpeed * dt);
    }
  }

  void _recoverFromTrap(int gx, int gy) {
    final recoveryPos = _findNearestRecoveryTarget(gx, gy);
    if (recoveryPos == null) return;
    position.setFrom(recoveryPos);
    _targetPosition = null;
    _aiUpdateTimer = 0.0;
  }

  Vector2? _findNearestRecoveryTarget(int originX, int originY) {
    if (_isSafeStandingCell(originX, originY)) {
      return Vector2(
        originX * CellComponent.cellSize + CellComponent.cellSize / 2,
        originY * CellComponent.cellSize + CellComponent.cellSize / 2,
      );
    }

    for (int r = 1; r <= _recoverySearchRadius; r++) {
      for (int dy = -r; dy <= r; dy++) {
        for (int dx = -r; dx <= r; dx++) {
          if (dx.abs() != r && dy.abs() != r) continue; // ring only
          final tx = originX + dx;
          final ty = originY + dy;
          if (!_isSafeStandingCell(tx, ty)) continue;
          return Vector2(
            tx * CellComponent.cellSize + CellComponent.cellSize / 2,
            ty * CellComponent.cellSize + CellComponent.cellSize / 2,
          );
        }
      }
    }

    for (int r = 1; r <= _recoverySearchRadius; r++) {
      for (int dy = -r; dy <= r; dy++) {
        for (int dx = -r; dx <= r; dx++) {
          if (dx.abs() != r && dy.abs() != r) continue; // ring only
          final tx = originX + dx;
          final ty = originY + dy;
          if (!_isWalkableLoadedCell(tx, ty)) continue;
          if (_countWalkableCardinalNeighbours(tx, ty) < 1) continue;
          return Vector2(
            tx * CellComponent.cellSize + CellComponent.cellSize / 2,
            ty * CellComponent.cellSize + CellComponent.cellSize / 2,
          );
        }
      }
    }

    return null;
  }

  bool _isSafeStandingCell(int gx, int gy) {
    if (!_isWalkableLoadedCell(gx, gy)) return false;
    if (_countWalkableCardinalNeighbours(gx, gy) < 2) return false;

    var openMooreNeighbours = 0;
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        if (_isWalkableLoadedCell(gx + dx, gy + dy)) openMooreNeighbours++;
      }
    }
    return openMooreNeighbours >= 4;
  }

  int _countWalkableCardinalNeighbours(int gx, int gy) {
    var walkable = 0;
    for (final d in const [
      [0, 1],
      [0, -1],
      [1, 0],
      [-1, 0],
    ]) {
      if (_isWalkableLoadedCell(gx + d[0], gy + d[1])) walkable++;
    }
    return walkable;
  }

  bool _isWalkableLoadedCell(int gx, int gy) {
    final cell = game.grid.getCell(gx, gy);
    if (cell == null) return false;
    final data = cell.data;
    if (data is BuildingData) return false;
    if (data is NatureData && data.type == NatureType.water) return false;
    return true;
  }

  @override
  void render(Canvas canvas) {
    Color bodyColor;
    if (model.isChristian) {
      bodyColor = Colors.white;
    } else if (model.faith < 0) {
      bodyColor =
          Color.lerp(Colors.red[900]!, Colors.grey, (model.faith + 100) / 100)!;
    } else {
      bodyColor = Color.lerp(Colors.grey, Colors.blue[100]!, model.faith / 50)!;
    }
    // Reuse pre-allocated paint – no new object allocation per frame.
    _bodyPaint.color = bodyColor;
    canvas.drawCircle((size / 2).toOffset(), size.x / 2, _bodyPaint);

    if (model.isChristian) {
      _crossPaint.color = Colors.amber;
      final center = (size / 2).toOffset();
      canvas.drawLine(center + const Offset(0, -4), center + const Offset(0, 4),
          _crossPaint);
      canvas.drawLine(center + const Offset(-3, -1),
          center + const Offset(3, -1), _crossPaint);
    }

    if (game.isSpiritualWorld) _renderSpiritualAura(canvas);

    // Mission marker: small golden circle above the NPC head
    if (model.activeMissionDescription != null) {
      const r = 5.0;
      final cx = size.x / 2;
      const cy = -r - 3;
      canvas.drawCircle(Offset(cx, cy), r, _missionBadgePaint);
      canvas.drawCircle(Offset(cx, cy), r, _missionBadgeBorderPaint);
      // Draw the '!' character inside the badge using a simple line+dot.
      final linePaint = Paint()
        ..color = const Color(0xFF5A3A00)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx, cy - 2.5), Offset(cx, cy + 0.5), linePaint);
      canvas.drawCircle(
          Offset(cx, cy + 2.5), 0.8, Paint()..color = const Color(0xFF5A3A00));
    }
  }

  void _renderSpiritualAura(Canvas canvas) {
    final faithFactor = (model.faith + 100) / 200.0;
    // Update only the color; the pre-allocated MaskFilter.blur stays intact.
    _auraPaint.color = Color.lerp(Colors.red, Colors.green, faithFactor)!
        .withValues(alpha: 0.3 + (faithFactor * 0.4));
    canvas.drawCircle((size / 2).toOffset(), size.x * 0.8, _auraPaint);

    // Possessed: a dark ring; with 👁️ discernment also the possessor's sign.
    if (model.possessed) {
      canvas.drawCircle((size / 2).toOffset(), size.x * 0.75, _possessedPaint);
      if (game.canDiscernSpirits) {
        _possessedGlyph.paint(canvas, Offset(size.x / 2 - _possessedGlyph.width / 2, -14));
      }
    }
  }

  final Paint _possessedPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = const Color(0xDD000000);

  static final TextPainter _possessedGlyph = TextPainter(
    text: const TextSpan(text: '👁️', style: TextStyle(fontSize: 10)),
    textDirection: TextDirection.ltr,
  )..layout();
}
