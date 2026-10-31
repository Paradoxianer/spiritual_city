import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../domain/models/daemon_kind.dart';
import '../../domain/models/prayer_combat.dart';
import '../../domain/models/quarter.dart';
import '../../domain/models/stronghold_kind.dart';
import '../../domain/help/near_texts.dart';
import '../../../../core/i18n/narrator.dart';
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

  /// 🏰 fort, 🏰🏰 bulwark or 🏯 great fortress (see [StrongholdKind]).
  final StrongholdKind kind;

  late double energy = kind.energy;
  bool fallen = false;

  double get radius => kind.radius;
  static const double activeReach = 520.0;
  static const double spawnInterval = 7.0;

  /// When each person last prayed at it ('pastor', 'disciple:<id>' …) –
  /// several together stop its healing and hit harder (Mt 18:19).
  final Map<String, double> _lastHitBy = {};

  /// People who prayed at it within [StrongholdKind.unityWindow].
  int get together =>
      _lastHitBy.values.where((t) => _t - t <= StrongholdKind.unityWindow).length;

  bool _narrated = false;

  double _spawnTimer = 0.0;

  /// 🪫 Disarmed: no healing while > 0 (seconds).
  double _disarmedFor = 0.0;

  /// ⏳ Bound: half healing, guards come half as often while > 0.
  double _boundFor = 0.0;

  /// Seconds a 🪫 / ⏳ wave (duration 1) works on a stronghold.
  static const double disarmSeconds = 4.0;
  static const double bindSeconds = 6.0;

  bool get disarmed => _disarmedFor > 0;
  bool get bound => _boundFor > 0;
  double _sinceHit = 99.0;
  double _t = 0.0;

  final Paint _auraPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
  final Paint _wallPaint = Paint()..color = const Color(0xFF1A0A0A);
  final Paint _shieldPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  final Paint _barBg = Paint()..color = const Color(0x66000000);
  final Paint _barFg = Paint()..color = const Color(0xFFFFE082);

  static final Map<StrongholdKind, TextPainter> _glyphs = {};
  static final TextPainter _lock = TextPainter(
    text: const TextSpan(text: '🔒', style: TextStyle(fontSize: 16)),
    textDirection: TextDirection.ltr,
  )..layout();

  StrongholdComponent(this.quarter, Vector2 position, {this.kind = StrongholdKind.fort})
      : super(
          position: position,
          size: Vector2.all(kind.radius * 2),
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
    _disarmedFor = math.max(0, _disarmedFor - dt);
    _boundFor = math.max(0, _boundFor - dt);
    // Healing: a fort heals when nobody prays; bulwarks and great
    // fortresses keep healing until enough pray together – or 🪫 disarms
    // them; ⏳ binding halves it.
    final united = together >= kind.unityNeeded;
    final heals = !disarmed && (kind.healsWhileHit ? !united : _sinceHit > 2.0);
    if (heals && energy < kind.energy) {
      final rate = kind.regenPerSecond * (bound ? 0.5 : 1.0);
      energy = math.min(kind.energy, energy + rate * dt);
    }
    if (!_near) return;
    if (!_narrated && isOpen && kind != StrongholdKind.fort) {
      _narrated = true;
      Narrator.say('stronghold.${kind.name}', kind.emoji, kind.emoji, NearTexts.strongholds[kind.name]?.text);
    }
    _spawnTimer += bound ? dt * 0.5 : dt;
    if (_spawnTimer < spawnInterval) return;
    _spawnTimer = 0;
    final guards = game.world.children
        .whereType<DaemonComponent>()
        .where((d) => !d.model.dissolved && d.position.distanceTo(position) < activeReach)
        .length;
    if (guards < kind.maxGuards) {
      final a = _t * 1.7;
      game.spiritualDynamics.spawnGuard(
        position + Vector2(math.cos(a), math.sin(a)) * (radius + 30),
        math.Random().nextBool() ? DaemonKind.brute : DaemonKind.lurker,
      );
    }
  }

  /// Hit by a prayer wave from [source]. Every prayer counts as praying
  /// together; 🪫 Drain stops the healing and ⏳ Slow halves it for a
  /// while ([duration] of the wave); only Liberation breaks walls, and only
  /// when open – harder the more pray together.
  void takeHit(double amount, PrayerMode mode, {String source = 'pastor', double duration = 1.0}) {
    if (fallen || !isOpen) return;
    _lastHitBy[source] = _t;
    switch (mode) {
      case PrayerMode.drain:
        _disarmedFor = math.max(_disarmedFor, disarmSeconds * duration);
        return;
      case PrayerMode.slow:
        _boundFor = math.max(_boundFor, bindSeconds * duration);
        return;
      case PrayerMode.rebuke:
        return;
      case PrayerMode.liberation:
        break;
    }
    _sinceHit = 0;
    energy -= amount * StrongholdKind.unityFactor(together);
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
    final glyph = _glyphs.putIfAbsent(kind, () => TextPainter(
          text: TextSpan(text: kind == StrongholdKind.greatFortress ? '🏯' : '🏰', style: TextStyle(fontSize: radius * 0.9)),
          textDirection: TextDirection.ltr,
        )..layout());
    glyph.paint(canvas, c - Offset(glyph.width / 2, glyph.height / 2));

    final open = isOpen;
    _shieldPaint.color = open ? const Color(0x55FFE082) : const Color(0xEE000000);
    canvas.drawCircle(c, radius, _shieldPaint);
    if (!open) {
      _lock.paint(canvas, Offset(c.dx - _lock.width / 2, -_lock.height));
    } else {
      // Remaining wall strength.
      final w = radius * 2;
      final frac = (energy / kind.energy).clamp(0.0, 1.0);
      canvas.drawRect(Rect.fromLTWH(0, -10, w, 5), _barBg);
      canvas.drawRect(Rect.fromLTWH(0, -10, w * frac, 5), _barFg);
      // How many pray together – and how many it takes (👥 1/3).
      if (kind.unityNeeded > 1) {
        final t = together;
        final label = TextPainter(
          text: TextSpan(
            text: '👥 $t/${kind.unityNeeded}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: t >= kind.unityNeeded ? const Color(0xFF9CFF9C) : const Color(0xFFFFE082),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(canvas, Offset(c.dx - label.width / 2, -12 - label.height));
      }
      // 🪫 disarmed / ⏳ bound: shown under the bar.
      final marks = [if (disarmed) PrayerMode.drain.icon, if (bound) PrayerMode.slow.icon];
      if (marks.isNotEmpty) {
        final m = TextPainter(
          text: TextSpan(text: marks.join(' '), style: const TextStyle(fontSize: 14)),
          textDirection: TextDirection.ltr,
        )..layout();
        m.paint(canvas, Offset(c.dx - m.width / 2, -3));
      }
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
