import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../spirit_world_game.dart';
import 'daemon_component.dart';
import 'cell_component.dart';
import '../../domain/models/prayer_combat.dart';

/// A circular shockwave emitted during prayer combat.
/// Issue #9
class ShockwaveComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final double maxRadius;
  final double strength;
  final double duration; // How long the effect lasts on daemons
  final double speed;
  final Color color;
  
  final PrayerMode mode; // Add mode reference
  
  double _currentRadius = 0;
  
  // Track which entities have already been hit by this specific wave
  final Set<String> _hitIds = {};

  ShockwaveComponent({
    required Vector2 position,
    required this.maxRadius,
    required this.strength,
    required this.duration,
    required this.speed,
    required this.color,
    required this.mode,
  }) : super(position: position, anchor: Anchor.center, priority: 115);

  @override
  void update(double dt) {
    super.update(dt);
    _currentRadius += speed * dt;
    
    _checkImpact();

    if (_currentRadius >= maxRadius) {
      removeFromParent();
    }
  }

  void _checkImpact() {
    final center = position;
    
    // 1. Impact on Cells
    final gridX = (center.x / CellComponent.cellSize).floor();
    final gridY = (center.y / CellComponent.cellSize).floor();
    
    // We only check cells that are near the current expanding ring
    final cellRange = (_currentRadius / CellComponent.cellSize).ceil() + 1;

    for (int dy = -cellRange; dy <= cellRange; dy++) {
      for (int dx = -cellRange; dx <= cellRange; dx++) {
        final gx = gridX + dx;
        final gy = gridY + dy;
        final cellId = '$gx,$gy';
        
        if (_hitIds.contains(cellId)) continue;

        final cell = game.grid.getCell(gx, gy);
        if (cell != null) {
          final cellPos = Vector2(
            gx * CellComponent.cellSize + CellComponent.cellSize / 2,
            gy * CellComponent.cellSize + CellComponent.cellSize / 2,
          );
          
          final dist = center.distanceTo(cellPos);
          // Hit if the ring has just passed over the cell center
          if (dist <= _currentRadius && dist > _currentRadius - 20) {
            final falloff = 1.0 - (dist / maxRadius).clamp(0.0, 1.0);
            final impact = (strength / 100.0) * falloff;
            cell.spiritualState = (cell.spiritualState + impact).clamp(-1.0, 1.0);
            _hitIds.add(cellId);
          }
        }
      }
    }

    // 2. Impact on Daemons
    for (final daemon in game.world.children.whereType<DaemonComponent>()) {
      if (daemon.model.dissolved) continue;
      if (_hitIds.contains(daemon.model.id)) continue;

      final dist = center.distanceTo(daemon.position);
      if (dist <= _currentRadius && dist > _currentRadius - 25) {
        final falloff = 1.0 - (dist / maxRadius).clamp(0.0, 1.0);
        daemon.takeDamage(strength * 5.0 * falloff, mode: mode, duration: duration);
        _hitIds.add(daemon.model.id);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_currentRadius < 5.0) return; // Hide very small start to avoid blob

    final progress = (_currentRadius / maxRadius).clamp(0.01, 1.0);
    final alpha = (1.0 - progress) * 0.5;
    
    // Main shockwave body
    final paint = Paint()
      ..color = color.withValues(alpha: alpha * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0 + (progress * 55.0);
    
    // Blur grows with expansion to avoid "static aura" at start
    final blurAmount = (5.0 + progress * 25.0) * (1.0 - progress);
    if (blurAmount > 0.1) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurAmount);
    }
    
    canvas.drawCircle(Offset.zero, _currentRadius, paint);
    
    // Sharper leading edge
    final edgePaint = Paint()
      ..color = color.withValues(alpha: alpha * 1.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 + (progress * 2.0);
    canvas.drawCircle(Offset.zero, _currentRadius, edgePaint);
  }
}
