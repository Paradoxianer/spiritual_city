import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../domain/models/daemon_kind.dart';
import '../../domain/models/prayer_combat.dart';
import '../../domain/models/quarter.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';
import 'daemon_component.dart';

/// A neighbourhood's 🏰 stronghold in the invisible world (#125, §3.3).
///
/// Sends out daemons while the pastor is near. Closed (shielded) until
/// enough people in the neighbourhood are Christians – then it falls to
/// sustained Liberation prayer ("Die Waffen unserer Ritterschaft … mächtig
/// vor Gott, zu zerstören Befestigungen", 2 Cor 10:4). It recovers when the
/// prayer stops.
class StrongholdComponent extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final Quarter quarter;

  double energy = Awakening.strongholdEnergy;
  bool fallen = false;

  static const double radius = 46.0;
  static const double activeReach = 520.0;
  static const double spawnInterval = 7.0;
  static const int maxGuards = 3;

  double _spawnTimer = 0.0;
  double _sinceHit = 99.0;
  double _t = 0.0;

  final Paint _auraPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
  final Paint _wallPaint = Paint()..color = const Color(0xFF1A0A0A);
  final Paint _shieldPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  final Paint _barBg = Paint()..color = const Color(0x66000000);
  final Paint _barFg = Paint()..color = const Color(0xFFFFE082);

  static final TextPainter _fort = TextPainter(
    text: const TextSpan(text: '🏰', style: TextStyle(fontSize: 40)),
    textDirection: TextDirection.ltr,
  )..layout();
  static final TextPainter _lock = TextPainter(
    text: const TextSpan(text: '🔒', style: TextStyle(fontSize: 16)),
    textDirection: TextDirection.ltr,
  )..layout();

  StrongholdComponent(this.quarter, Vector2 position)
      : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
          priority: 94,
        );

  bool get isOpen => game.quarterStatus.value?.quarter == quarter &&
      (game.quarterStatus.value?.strongholdOpen ?? false);

  bool get _near => position.distanceTo(game.player.position) < activeReach;

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isSpiritualWorld || fallen) return;
    _t += dt;
    _sinceHit += dt;
    if (_sinceHit > 2.0 && energy < Awakening.strongholdEnergy) {
      energy = math.min(Awakening.strongholdEnergy, energy + Awakening.strongholdRegenPerSecond * dt);
    }
    if (!_near) return;
    _spawnTimer += dt;
    if (_spawnTimer < spawnInterval) return;
    _spawnTimer = 0;
    final guards = game.world.children
        .whereType<DaemonComponent>()
        .where((d) => !d.model.dissolved && d.position.distanceTo(position) < activeReach)
        .length;
    if (guards < maxGuards) {
      final a = _t * 1.7;
      game.spiritualDynamics.spawnGuard(
        position + Vector2(math.cos(a), math.sin(a)) * (radius + 30),
        math.Random().nextBool() ? DaemonKind.brute : DaemonKind.lurker,
      );
    }
  }

  /// Hit by a prayer wave. Only Liberation breaks walls, and only when open.
  void takeHit(double amount, PrayerMode mode) {
    if (fallen || !isOpen || mode != PrayerMode.liberation) return;
    _sinceHit = 0;
    energy -= amount;
    if (energy <= 0) {
      fallen = true;
      game.onStrongholdFallen(this);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.isSpiritualWorld || fallen) return;
    final c = Offset(size.x / 2, size.y / 2);
    final pulse = (math.sin(_t * 2) + 1) / 2;
    _auraPaint.color = Color.lerp(const Color(0x99300000), const Color(0xCC000000), pulse)!;
    canvas.drawCircle(c, radius * 1.4, _auraPaint);
    canvas.drawCircle(c, radius * 0.8, _wallPaint);
    _fort.paint(canvas, c - Offset(_fort.width / 2, _fort.height / 2));

    final open = isOpen;
    _shieldPaint.color = open ? const Color(0x55FFE082) : const Color(0xEE000000);
    canvas.drawCircle(c, radius, _shieldPaint);
    if (!open) {
      _lock.paint(canvas, Offset(c.dx - _lock.width / 2, -_lock.height));
    } else {
      // Remaining wall strength.
      final w = radius * 2;
      final frac = (energy / Awakening.strongholdEnergy).clamp(0.0, 1.0);
      canvas.drawRect(Rect.fromLTWH(0, -10, w, 5), _barBg);
      canvas.drawRect(Rect.fromLTWH(0, -10, w * frac, 5), _barFg);
    }
  }

  /// Pixel centre of [quarter]'s stronghold.
  static Vector2 centerOf(Quarter quarter) {
    final (cx, cy) = quarter.centerCell;
    return Vector2(
      cx * CellComponent.cellSize + CellComponent.cellSize / 2,
      cy * CellComponent.cellSize + CellComponent.cellSize / 2,
    );
  }
}
