import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/game_time.dart';
import '../../domain/models/npc_model.dart';
import '../../domain/models/cell_object.dart';
import '../../domain/models/interactions.dart';
import '../../domain/services/faith_calculator_service.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';

/// Level-of-detail setting for an NPC.
///
/// * [high]   – full AI, animation and spiritual-influence updates (≤200 u)
/// * [medium] – simplified movement only, no spiritual influence (200–500 u)
/// * [low]    – static/invisible, no logic (>500 u)
enum NPCDetailLevel { high, medium, low }

class NPCComponent extends PositionComponent with HasGameReference<SpiritWorldGame> implements Interactable {
  NPCModel _model;

  /// Current active data model.  Updated by [assignModel] when the component
  /// is recycled from the [NPCPool].
  NPCModel get model => _model;

  static const double npcSize = 20.0;
  final Random _random = Random();

  late final FaithCalculatorService _faithCalc;

  /// LOD level assigned by the NPC manager based on distance to the player.
  NPCDetailLevel detailLevel = NPCDetailLevel.high;

  // ─── Movement ─────────────────────────────────────────────────────────────

  double _currentSpeed = 40.0;
  Vector2? _targetPosition;
  double _aiUpdateTimer = 0;
  static const double _aiUpdateInterval = 2.0;

  // Timer for daily NPC spiritual influence on cells (Lastenheft §6.3)
  double _spiritualInfluenceTimer = 0.0;
  /// One in-game day = [GameTime.gameDaySeconds] real seconds.
  static const double _spiritualInfluenceInterval = GameTime.gameDaySeconds;

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
    detailLevel = NPCDetailLevel.high;
  }

  /// Prepare the component for return to the pool.  Removes it from the scene
  /// graph if it still has a parent and resets all per-session state so a
  /// future [assignModel] call gets a clean slate.
  void deactivateForPool() {
    _spiritualInfluenceTimer = 0.0;
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

  @override
  String handleInteraction(String type) {
    model.currentSessionInteractions++;

    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();
    final cell = game.grid.getCell(gx, gy);
    final spiritualState = cell?.spiritualState ?? 0.0;

    final interactionScore = model.faith + (spiritualState * 50);

    final double resonanceExchange = (model.faith / 20.0).clamp(-5.0, 5.0);
    game.gainFaith(resonanceExchange);

    // Reset per-action deltas before computing new ones.
    model.lastNpcFaithDelta = 0.0;
    model.lastPlayerFaithDelta = resonanceExchange;
    model.lastMaterialsDelta = 0.0;
    model.lastPlayerHealthDelta = 0.0;

    if (type == 'talk') {
      final gain = _faithCalc.calculateConversationGain();
      model.applyInfluence(gain.toDouble());
      model.conversationCount++;
      model.lastNpcFaithDelta = gain.toDouble();
      game.recordConversation();
      return _talkEmoji();
    }

    if (type == 'counsel') {
      final hpCost = _faithCalc.calculateCounselingHpCost();
      if (game.health <= hpCost) {
        model.currentSessionInteractions--;
        return '🚫❤️';
      }
      game.gainHealth(-hpCost.toDouble());
      model.lastPlayerHealthDelta = -hpCost.toDouble();
      final gain = _faithCalc.calculateCounselingGain();
      model.applyInfluence(gain.toDouble());
      model.conversationCount++;
      model.counselingCount++;
      model.lastNpcFaithDelta = gain.toDouble();
      return ['👂💬', '👂🙏', '👂😊', '👂💛'][_random.nextInt(4)];
    }

    if (type == 'pray') {
      model.prayerCount++;
      final faithCost = _faithCalc.calculatePrayerFaithCost();
      if (game.faith < faithCost) {
        model.currentSessionInteractions--;
        return '🚫🙏';
      }
      game.gainFaith(-faithCost.toDouble());
      model.lastPlayerFaithDelta -= faithCost.toDouble();
      final prayerGain = _faithCalc.calculatePrayerGain();
      // Base 20% acceptance probability that scales positively with faith.
      // Even the most hostile NPC has a realistic chance to accept prayer.
      final acceptanceChance = ((interactionScore + 100) / 200.0 * 0.6 + 0.2).clamp(0.0, 1.0);
      if (_random.nextDouble() < acceptanceChance) {
        model.applyInfluence(prayerGain.toDouble());
        model.lastNpcFaithDelta = prayerGain.toDouble();
        model.lastPlayerFaithDelta += 3.0;
        game.gainFaith(3.0);
        // Nudge the spiritual state of the cell toward the light.
        final cellDelta = _faithCalc.calculatePrayerCellDelta();
        if (cell != null) {
          cell.spiritualState = (cell.spiritualState + cellDelta).clamp(-1.0, 1.0);
        }
        return ['❤️🕊️', '🙏💛', '❤️🙌', '🙏❤️'][_random.nextInt(4)];
      } else {
        model.applyInfluence(-8.0);
        model.lastNpcFaithDelta = -8.0;
        return interactionScore < -20 ? '💀😬' : '😠💭';
      }
    }

    if (type == 'bible') {
      final gain = _faithCalc.calculateBibleGain();
      model.applyInfluence(gain.toDouble());
      model.conversationCount++;
      model.lastNpcFaithDelta = gain.toDouble();
      model.lastPlayerFaithDelta += 2.0;
      game.gainFaith(2.0);
      return ['📖✝️', '📖😊', '📖🙏', '📖💛'][_random.nextInt(4)];
    }

    if (type == 'help') {
      final giftGain = _faithCalc.calculateGiftGain();
      model.conversationCount++;
      model.hadGiftThisSession = true;
      model.wantsGift = false;
      model.applyInfluence(giftGain.toDouble());
      model.lastNpcFaithDelta = giftGain.toDouble();
      model.lastPlayerFaithDelta += 5.0;
      model.lastMaterialsDelta = -8.0;
      game.gainFaith(5.0);
      game.spendMaterials(8.0);
      return ['📦🙏', '😊📦', '🙏😊'][_random.nextInt(3)];
    }

    if (type == 'convert') {
      if (model.isChristian) return '✝️🙏';

      if (interactionScore > 60) {
        model.applyInfluence(100);
        model.lastNpcFaithDelta = 100.0;
        model.lastPlayerFaithDelta += 25.0;
        game.gainFaith(25.0);
        game.recordConversion();
        return '✝️🕊️';
      } else {
        model.applyInfluence(3.0);
        model.lastNpcFaithDelta = 3.0;
        if (interactionScore < 0) return '🚫😤';
        return '🤔💭';
      }
    }

    return '❓💭';
  }

  /// Returns a dynamic two-emoji response for a talk interaction based on
  /// the NPC's current faith level.
  String _talkEmoji() {
    if (model.faith > 50) return ['😊✝️', '🙌💬', '😄🕊️'][_random.nextInt(3)];
    if (model.faith > 20) return ['😊💬', '🙌😊', '💬😄'][_random.nextInt(3)];
    if (model.faith > 0)  return ['🤔💬', '💭😊', '👀💬'][_random.nextInt(3)];
    if (model.faith > -30) return ['😐💬', '💭🤔', '😒💬'][_random.nextInt(3)];
    return ['😠💬', '😤🙅', '😡💭'][_random.nextInt(3)];
  }

  @override
  Future<void> onLoad() async {
    _faithCalc = FaithCalculatorService(difficulty: game.difficulty, rng: _random);
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.paused) return;

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

  /// Daily: NPC faith state influences the cell they are standing on (Lastenheft §6.3)
  void _updateSpiritualInfluence(double dt) {
    _spiritualInfluenceTimer += dt;
    if (_spiritualInfluenceTimer < _spiritualInfluenceInterval) return;
    _spiritualInfluenceTimer = 0.0;

    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();
    final cell = game.grid.getCell(gx, gy);
    if (cell == null) return;

    if (model.isChristian) {
      // Converted Christians radiate positive influence
      cell.spiritualState = (cell.spiritualState + model.faith * 0.003).clamp(-1.0, 1.0);
    } else if (model.faith > 50) {
      // Sympathetic NPCs provide a weak positive nudge
      cell.spiritualState = (cell.spiritualState + 0.05).clamp(-1.0, 1.0);
    } else if (model.faith < -50) {
      // Very hostile NPCs reinforce darkness
      cell.spiritualState = (cell.spiritualState - model.faith.abs() * 0.002).clamp(-1.0, 1.0);
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

      if (_targetPosition == null || position.distanceTo(_targetPosition!) < 4) {
        _targetPosition = _findNextWanderTarget(gx, gy);
      }
    }

    if (_targetPosition != null) {
      _moveTowardsTarget(dt);
    }
  }

  Vector2? _findNextWanderTarget(int gx, int gy) {
    final directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)];
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

  @override
  void render(Canvas canvas) {
    Color bodyColor;
    if (model.isChristian) {
      bodyColor = Colors.white;
    } else if (model.faith < 0) {
      bodyColor = Color.lerp(Colors.red[900]!, Colors.grey, (model.faith + 100) / 100)!;
    } else {
      bodyColor = Color.lerp(Colors.grey, Colors.blue[100]!, model.faith / 50)!;
    }
    canvas.drawCircle((size / 2).toOffset(), size.x / 2, Paint()..color = bodyColor);

    if (model.isChristian) {
      final paint = Paint()..color = Colors.amber..style = PaintingStyle.stroke..strokeWidth = 1.2;
      final center = (size / 2).toOffset();
      canvas.drawLine(center + const Offset(0, -4), center + const Offset(0, 4), paint);
      canvas.drawLine(center + const Offset(-3, -1), center + const Offset(3, -1), paint);
    }

    if (game.isSpiritualWorld) _renderSpiritualAura(canvas);
  }

  void _renderSpiritualAura(Canvas canvas) {
    final faithFactor = (model.faith + 100) / 200.0;
    final auraColor = Color.lerp(Colors.red, Colors.green, faithFactor)!
        .withValues(alpha: 0.3 + (faithFactor * 0.4));
    canvas.drawCircle((size / 2).toOffset(), size.x * 0.8,
        Paint()..color = auraColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  }
}
