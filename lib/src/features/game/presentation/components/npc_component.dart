import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../domain/models/npc_model.dart';
import '../../domain/models/interactions.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';

class NPCComponent extends PositionComponent with HasGameReference<SpiritWorldGame> implements Interactable {
  final NPCModel model;
  
  static const double npcSize = 20.0;
  double _currentSpeed = 40.0;
  final Random _random = Random();

  Vector2? _targetPosition;
  double _aiUpdateTimer = 0;
  static const double aiUpdateInterval = 2.0; 

  NPCComponent({required this.model}) : super(
    position: model.homePosition.clone(),
    size: Vector2.all(npcSize),
    anchor: Anchor.center,
    priority: 90,
  );

  @override
  String get interactionLabel => model.name;
  
  @override
  String get interactionEmoji => _getNPCEmoji();

  @override
  Vector2 get interactionPosition => position;

  String _getNPCEmoji() {
    if (model.isChristian) return '🕊️';
    if (model.faith < -30) return '😠';
    if (model.faith < 30) return '👤';
    return '🤔';
  }

  @override
  void onInteract() {
    game.showDialog(model.name, _getNPCEmoji());
  }

  @override
  String handleInteraction(String type) {
    // 1. Hole den Wert der unsichtbaren Welt (-1.0 bis +1.0)
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();
    final cell = game.grid.getCell(gx, gy);
    final spiritualState = cell?.spiritualState ?? 0.0; 

    // 2. Berechne den Interaktions-Score
    // Glaube des NPC + Einfluss der Umgebung
    // Ein Wert > 0 ist tendenziell positiv.
    final interactionScore = model.faith + (spiritualState * 50);

    if (type == 'pray') {
      model.prayerCount++;
      // Erfolgswahrscheinlichkeit steigt mit positivem Score
      if (interactionScore + _random.nextInt(40) > 20) {
        model.applyInfluence(15.0); // Gebet erhöht Faith
        return '❤️';
      } else {
        model.applyInfluence(-5.0); // Ablehnung senkt Faith leicht
        return interactionScore < -20 ? '💀' : '😠';
      }
    } 
    
    if (type == 'help') {
      model.conversationCount++;
      // Hilfe ist immer positiv, aber stärker in "hellen" Gebieten
      model.applyInfluence(10.0 + (spiritualState * 5));
      return '📦😊';
    } 
    
    if (type == 'convert') {
      // Bekehrung erfordert einen hohen Score (> 50)
      if (interactionScore > 50) {
        model.applyInfluence(100); // Voller Glaube
        return '✨🕊️';
      } else {
        // Reaktion zeigt, wie weit man noch entfernt ist
        if (interactionScore < 0) return '🚫';
        return '🤔';
      }
    }

    return '❓';
  }

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.paused) return;

    _aiUpdateTimer -= dt;
    if (_aiUpdateTimer <= 0) {
      _updateAI();
      _aiUpdateTimer = aiUpdateInterval + _random.nextDouble(); 
    }

    if (_targetPosition != null) {
      _moveTowardsTarget(dt);
    }
  }

  void _updateAI() {
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();
    final cell = game.grid.getCell(gx, gy);
    final state = cell?.spiritualState ?? 0;

    if (state < -0.5 && !model.isChristian) {
      _currentSpeed = 15.0;
    } else {
      _currentSpeed = 35.0 + (model.faith / 10.0);
    }

    if (_targetPosition == null || position.distanceTo(_targetPosition!) < 4) {
      _targetPosition = _findNextWanderTarget(gx, gy);
    }
  }

  Vector2? _findNextWanderTarget(int gx, int gy) {
    final directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)];
    directions.shuffle(_random);
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
    } else {
      if (model.faith < 0) {
        bodyColor = Color.lerp(Colors.red[900], Colors.grey, (model.faith + 100) / 100)!;
      } else {
        bodyColor = Color.lerp(Colors.grey, Colors.blue[100], model.faith / 50)!;
      }
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
    
    final auraPaint = Paint()..color = auraColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle((size / 2).toOffset(), size.x * 0.8, auraPaint);
  }
}
