import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../../domain/models/npc_model.dart';
import '../../domain/models/cell_object.dart';
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
  Vector2 get interactionPosition => position;

  @override
  void onInteract() {
    // Mission Logik: Belohnung beim ersten Mal
    String message = model.currentMessage ?? 'Hallo! Ich bin ${model.name}. Schön dich zu sehen.';
    
    if (!model.hasTalkedTo) {
      model.hasTalkedTo = true;
      message += '\n\n(Du hast +5 Faith erhalten!)';
      // Hier würde man später den globalen Game-State/Player-State aktualisieren
    }

    game.showDialog(model.name, message);
  }

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Wenn pausiert (z.B. durch Dialog), keine Bewegung
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

    if (cell != null) {
      final state = cell.spiritualState;
      if (state < -0.4) {
        _currentSpeed = 25.0; 
      } else if (state > 0.4) {
        _currentSpeed = 55.0; 
      } else {
        _currentSpeed = 40.0;
      }
    }

    if (_targetPosition == null || position.distanceTo(_targetPosition!) < 4) {
      _targetPosition = _findNextWanderTarget(gx, gy);
    }
  }

  Vector2? _findNextWanderTarget(int gx, int gy) {
    final directions = [
      Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)
    ];
    
    directions.shuffle(_random);
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
    final paint = Paint()..color = _getColorForType(model.type);
    
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();
    final state = game.grid.getCell(gx, gy)?.spiritualState ?? 0;
    
    if (state < -0.5) {
      paint.color = Color.lerp(paint.color, Colors.black, 0.3)!;
    }

    canvas.drawCircle((size / 2).toOffset(), size.x / 2, paint);
    if (game.isSpiritualWorld) _renderSpiritualAura(canvas);
    _renderTypeSymbol(canvas);
  }

  Color _getColorForType(NPCType type) {
    switch (type) {
      case NPCType.citizen: return Colors.grey;
      case NPCType.merchant: return Colors.orange;
      case NPCType.priest: return Colors.purple;
      case NPCType.officer: return Colors.blueGrey;
    }
  }

  void _renderSpiritualAura(Canvas canvas) {
    final faith = model.faith;
    final auraColor = faith >= 0 
        ? Colors.green.withOpacity(0.3 + (faith * 0.4))
        : Colors.red.withOpacity(0.3 + (faith.abs() * 0.4));
    
    final auraPaint = Paint()..color = auraColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle((size / 2).toOffset(), size.x * 0.8, auraPaint);
  }

  void _renderTypeSymbol(Canvas canvas) {
    final symbolPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final center = (size / 2).toOffset();
    if (model.type == NPCType.priest) {
      canvas.drawLine(center + const Offset(0, -4), center + const Offset(0, 4), symbolPaint);
      canvas.drawLine(center + const Offset(-3, -1), center + const Offset(3, -1), symbolPaint);
    }
  }
}
