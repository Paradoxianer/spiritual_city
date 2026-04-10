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
    if (model.isChristian) return '✝️'; // Geändert von 🕊️ zu ✝️
    if (model.faith < -30) return '😠';
    if (model.faith < 30) return '👤';
    return '🤔';
  }

  @override
  void onInteract() {
    model.resetSession(); 
    game.showDialog(model.name, _getNPCEmoji());
  }

  @override
  String handleInteraction(String type) {
    model.currentSessionInteractions++;
    if (model.currentSessionInteractions > 3) {
      return '👋'; 
    }

    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();
    final cell = game.grid.getCell(gx, gy);
    final spiritualState = cell?.spiritualState ?? 0.0; 

    final interactionScore = model.faith + (spiritualState * 50);

    final double resonanceExchange = (model.faith / 20.0).clamp(-5.0, 5.0);
    game.gainFaith(resonanceExchange);

    if (type == 'talk') {
      model.applyInfluence(1.0);
      return '💬😊';
    }

    if (type == 'pray') {
      model.prayerCount++;
      if (interactionScore + _random.nextInt(40) > 20) {
        model.applyInfluence(12.0 + (spiritualState * 5)); 
        game.gainFaith(3.0);
        return '❤️';
      } else {
        model.applyInfluence(-8.0);
        return interactionScore < -20 ? '💀' : '😠';
      }
    } 
    
    if (type == 'help') {
      model.conversationCount++;
      model.applyInfluence(8.0 + (spiritualState * 4));
      game.gainFaith(5.0);      // +5 Faith for helping
      game.gainMaterials(-8.0); // costs 8 MP to help
      return '📦😊';
    } 
    
    if (type == 'convert') {
      if (model.isChristian) return '✝️🙏'; // Kreuz statt Stern
      
      if (interactionScore > 60) {
        model.applyInfluence(100);
        game.gainFaith(25.0);
        return '✝️🕊️';
      } else {
        model.applyInfluence(3.0); 
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
    _updateAI(dt);
  }

  void _updateAI(double dt) {
    if (_random.nextDouble() < 0.01) {
      final gx = (position.x / CellComponent.cellSize).floor();
      final gy = (position.y / CellComponent.cellSize).floor();
      final target = _findNextWanderTarget(gx, gy);
      if (target != null) {
        position.setFrom(target);
      }
    }
  }

  Vector2? _findNextWanderTarget(int gx, int gy) {
    final dir = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)][_random.nextInt(4)];
    final tx = gx + dir.x.toInt();
    final ty = gy + dir.y.toInt();
    if (game.grid.isWalkable(tx, ty)) {
      return Vector2(tx * CellComponent.cellSize + 10, ty * CellComponent.cellSize + 10);
    }
    return null;
  }

  @override
  void render(Canvas canvas) {
    Color bodyColor = model.isChristian ? Colors.white : (model.faith < 0 ? Colors.red[800]! : Colors.grey);
    canvas.drawCircle((size / 2).toOffset(), size.x / 2, Paint()..color = bodyColor);
    
    // Kreuz-Symbol Rendering auf dem NPC
    if (model.isChristian) {
      final paint = Paint()..color = Colors.amber..style = PaintingStyle.stroke..strokeWidth = 1.5;
      final center = (size / 2).toOffset();
      // Vertikaler Balken
      canvas.drawLine(center + const Offset(0, -5), center + const Offset(0, 5), paint);
      // Horizontaler Balken
      canvas.drawLine(center + const Offset(-3.5, -1.5), center + const Offset(3.5, -1.5), paint);
    }

    if (game.isSpiritualWorld) _renderSpiritualAura(canvas);
  }

  void _renderSpiritualAura(Canvas canvas) {
    final faithFactor = (model.faith + 100) / 200.0;
    final auraColor = Color.lerp(Colors.red, Colors.green, faithFactor)!.withValues(alpha: 0.5);
    canvas.drawCircle((size / 2).toOffset(), size.x * 0.8, Paint()..color = auraColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  }
}
