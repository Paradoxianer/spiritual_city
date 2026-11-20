import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../spirit_world_game.dart';
import 'daemon_component.dart';
import 'stronghold_component.dart';
import '../../domain/services/combat_abilities.dart';
import '../../domain/services/daemon_combat_rules.dart';
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

  /// Who prayed this wave ('pastor', 'disciple:<id>') – people praying
  /// together at a stronghold count (StrongholdKind).
  final String source;

  /// [source] of a 🌊 breakthrough – it greens the land, but never counts
  /// against a stronghold.
  static const String breakthrough = 'breakthrough';
  
  double _currentRadius = 0;
  
  // Track which entities have already been hit by this specific wave
  final Set<String> _hitIds = {};

  /// Daemons this wave has hit – the prayer spreads over them
  /// ([DaemonCombatRules.spread]).
  int _daemonsHit = 0;

  /// Share of a wave's strength that liberates the cells it passes over.
  ///
  /// Liberation is *the* tool for cleansing the city; Rebuke, Slow and
  /// Drain are control/damage tools against daemons and liberate almost
  /// nothing, so that the modes have distinct jobs and are worth switching
  /// between and combining (docs/game_design/daemons_and_combat.md §6).
  /// Was 0.15 for the control modes – enough that pure Rebuke spam still
  /// cleansed noticeably, which made Liberation optional.
  static const double controlModeCellFactor = 0.02;

  static double cellImpactFactor(PrayerMode mode) =>
      mode == PrayerMode.liberation ? 1.0 : controlModeCellFactor;

  ShockwaveComponent({
    required Vector2 position,
    required this.maxRadius,
    required this.strength,
    required this.duration,
    required this.speed,
    required this.color,
    required this.mode,
    this.source = 'pastor',
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
            
            // Mode-specific cell impact (Issue #9) – see cellImpactFactor.
            final modeMultiplier = cellImpactFactor(mode) *
                (mode == PrayerMode.liberation &&
                        (game.combatAbilityTiers[PrayerMode.liberation] ?? 0) >= 2
                    ? CombatAbilities.liberationCellFactor
                    : 1.0);

            final impact = (strength / 100.0) * falloff * modeMultiplier;
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
        daemon.takeDamage(strength * 5.0 * falloff * DaemonCombatRules.spread(_daemonsHit++),
            mode: mode, duration: duration);
        _hitIds.add(daemon.model.id);
      }
    }

    // 3. Impact on strongholds (#125)
    _checkStrongholds();
  }

  void _checkStrongholds() {
    if (source == breakthrough) return;
    for (final s in game.world.children.whereType<StrongholdComponent>()) {
      final id = 'fort_${s.quarter.key}';
      if (_hitIds.contains(id)) continue;
      final dist = position.distanceTo(s.position);
      if (dist <= _currentRadius + s.radius &&
          dist > _currentRadius - s.radius) {
        final falloff = 1.0 - (dist / maxRadius).clamp(0.0, 1.0);
        s.takeHit(strength * 5.0 * falloff, mode, source: source, duration: duration);
        _hitIds.add(id);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_currentRadius < 5.0) return; // Hide very small start to avoid blob

    final progress = (_currentRadius / maxRadius).clamp(0.01, 1.0);
    if (source == breakthrough) return _renderBreakthrough(canvas, progress);
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

  /// A 🌊 breakthrough: one wide band, strongest along its middle and
  /// fading out to both sides – like a wave crest, no blurred aura
  /// (playtest 2026-11-17). Far wider than any prayer wave.
  void _renderBreakthrough(Canvas canvas, double progress) {
    final r = _currentRadius;
    final half = math.min(r, 40.0 + progress * 60.0);
    final outer = r + half;
    final c = color.withValues(alpha: 0.9 * (1.0 - progress * 0.7));
    final clear = color.withValues(alpha: 0);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = half * 2
      ..shader = RadialGradient(
        colors: [clear, c, clear],
        stops: [(r - half) / outer, r / outer, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: outer));
    canvas.drawCircle(Offset.zero, r, paint);
  }
}
