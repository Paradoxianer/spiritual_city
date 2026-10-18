import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, TextPainter, TextSpan, TextStyle, FontWeight;

import '../../../../../core/utils/stable_hash.dart';
import '../../../domain/interior/interior_layout.dart';
import '../../../domain/models/building_model.dart';
import '../../../domain/models/npc_model.dart';
import '../../../domain/services/learning_service.dart';
import '../../spirit_world_game.dart';
import '../character_sprites.dart';
import 'interior_renderer.dart';

/// What the pastor can act on right now inside a building.
sealed class InteriorTarget {
  const InteriorTarget();
}

class StationTarget extends InteriorTarget {
  final Furniture furniture;
  const StationTarget(this.furniture);
  String get action => furniture.action!;
}

class ResidentTarget extends InteriorTarget {
  final NPCModel npc;
  const ResidentTarget(this.npc);
}

class MentorTarget extends InteriorTarget {
  final Lesson lesson;
  const MentorTarget(this.lesson);
}

class DoorTarget extends InteriorTarget {
  const DoorTarget();
}

/// The inside of a building as its own world – the third layer (playtest
/// 2026-10-18). The camera switches here on entering; the city keeps
/// running in the background.
class InteriorWorld extends World with HasGameReference<SpiritWorldGame> {
  final BuildingModel building;
  final InteriorLayout layout;

  /// Emoji per station action (from the building's actions).
  final Map<String, String> stationEmoji;

  /// A mentor stands in the room when this building offers a lesson.
  final Lesson? lesson;

  InteriorWorld({
    required this.building,
    required this.layout,
    required this.stationEmoji,
    this.lesson,
  });

  static const double cell = InteriorRenderer.cell;

  late final InteriorPastor pastor;
  final Map<NPCModel, Vector2> residents = {};
  Vector2? mentorPos;

  /// Nearest thing to act on (drives the action button).
  InteriorTarget? target;

  // ── Timed action ──────────────────────────────────────────────────────────
  String? busyAction;
  String busyEmoji = '';
  double busyLeft = 0;
  double busyTotal = 0;
  bool get isBusy => busyAction != null;

  /// Set once the visit is over (session limit), the pastor walks out.
  bool leaving = false;

  Vector2 get size => Vector2(layout.width * cell, layout.height * cell);

  static Vector2 centerOf((int, int) c) => Vector2((c.$1 + 0.5) * cell, (c.$2 + 0.5) * cell);

  @override
  Future<void> onLoad() async {
    add(_RoomLayer(InteriorRenderer.record(layout)));
    for (final f in layout.stations) {
      add(_StationMarker(this, f, stationEmoji[f.action] ?? '❔'));
    }
    final rs = building.residents;
    for (var i = 0; i < rs.length && i < layout.residentSpots.length; i++) {
      final pos = centerOf(layout.residentSpots[i]);
      residents[rs[i]] = pos;
      add(_Person(this, pos, CharacterSprites.figureFor(stableStringHash(rs[i].id)),
          () => _faceOf(rs[i]), () => target is ResidentTarget && (target as ResidentTarget).npc == rs[i]));
    }
    if (lesson != null) {
      final spots = layout.residentSpots;
      final cellPos = spots.length > rs.length ? spots[rs.length] : layout.find;
      mentorPos = centerOf(cellPos);
      add(_Person(this, mentorPos!, 5, () => '🎓${lesson!.skill.emoji}', () => target is MentorTarget));
    }
    add(_FindSparkle(this));
    pastor = InteriorPastor(this)..position = centerOf(layout.entry);
    add(pastor);
    add(_BusyBadge(this));
  }

  static String _faceOf(NPCModel n) => n.isChristian ? '😇' : (n.faith > 0 ? '🙂' : '😐');

  @override
  void update(double dt) {
    super.update(dt);
    _updateTarget();
    if (isBusy) {
      busyLeft -= dt;
      if (busyLeft <= 0) game.finishInteriorAction();
    }
    if (!building.findCollected) {
      final (fx, fy) = layout.find;
      final p = pastor.cellPos;
      if (p.$1 == fx && p.$2 == fy) game.collectInteriorFind();
    }
  }

  void _updateTarget() {
    final px = pastor.position.x / cell;
    final py = pastor.position.y / cell;
    InteriorTarget? best;
    var bestD = double.infinity;
    for (final f in layout.stations) {
      final d = f.distanceTo(px, py);
      // Floor pieces (prayer rug) count when standing on them.
      final reach = f.kind.blocks ? 0.95 : 0.2;
      if (d <= reach && d < bestD) {
        bestD = d;
        best = StationTarget(f);
      }
    }
    for (final e in residents.entries) {
      final d = e.value.distanceTo(pastor.position) / cell - 0.4;
      if (d <= 1.0 && d < bestD) {
        bestD = d;
        best = ResidentTarget(e.key);
      }
    }
    if (mentorPos != null) {
      final d = mentorPos!.distanceTo(pastor.position) / cell - 0.4;
      if (d <= 1.0 && d < bestD) {
        bestD = d;
        best = MentorTarget(lesson!);
      }
    }
    final (dx, dy) = layout.door;
    if (best == null && (px - (dx + 0.5)).abs() < 1.0 && dy - py < 1.6) best = const DoorTarget();
    target = best;
  }

  /// Short emoji that rises over the pastor and fades (reactions, rewards).
  void float(String text) => add(_FloatingText(text, pastor.position - Vector2(0, 26)));
}

/// The cached room picture.
class _RoomLayer extends Component {
  final Picture picture;
  _RoomLayer(this.picture) : super(priority: 0);

  @override
  void render(Canvas canvas) => canvas.drawPicture(picture);
}

/// The pastor inside: same joystick / keys as outside, collides with walls
/// and furniture, leaves through the door.
class InteriorPastor extends PositionComponent with HasGameReference<SpiritWorldGame> {
  final InteriorWorld room;
  InteriorPastor(this.room) : super(size: Vector2.all(26), anchor: Anchor.center, priority: 50);

  static const double speed = 95.0;
  final CharacterAnimator _anim = CharacterAnimator();

  (int, int) get cellPos =>
      ((position.x / InteriorWorld.cell).floor(), (position.y / InteriorWorld.cell).floor());

  bool _free(double x, double y) {
    const r = 9.0; // body half-width
    for (final (ox, oy) in const [(-r, -2.0), (r, -2.0), (-r, r), (r, r)]) {
      final cx = ((x + ox) / InteriorWorld.cell).floor();
      final cy = ((y + oy) / InteriorWorld.cell).floor();
      if (!room.layout.isWalkable(cx, cy)) return false;
    }
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _anim.update(dt, position);
    if (room.isBusy || room.leaving) return;
    final dir = game.player.moveInput;
    if (dir.isZero()) return;
    final step = dir * speed * dt;
    final nx = position.x + step.x, ny = position.y + step.y;
    if (_free(nx, ny)) {
      position.setValues(nx, ny);
    } else if (_free(nx, position.y)) {
      position.x = nx;
    } else if (_free(position.x, ny)) {
      position.y = ny;
    }
    final (dx, dy) = room.layout.door;
    if (cellPos == (dx, dy) && position.y > (dy + 0.35) * InteriorWorld.cell) {
      game.leaveInterior();
    }
  }

  @override
  void render(Canvas canvas) {
    if (CharacterSprites.render(canvas, CharacterSprites.pastor, _anim, size)) return;
    canvas.drawCircle((size / 2).toOffset(), size.x / 2, Paint()..color = Colors.blueAccent);
  }
}

/// A resident or mentor standing in the room, with a small emoji above.
class _Person extends PositionComponent {
  final InteriorWorld room;
  final int figure;
  final String Function() label;
  final bool Function() isTarget;
  final CharacterAnimator _anim = CharacterAnimator();

  _Person(this.room, Vector2 pos, this.figure, this.label, this.isTarget)
      : super(position: pos, size: Vector2.all(26), anchor: Anchor.center, priority: 40);

  @override
  void render(Canvas canvas) {
    if (!CharacterSprites.render(canvas, figure, _anim, size)) {
      canvas.drawCircle((size / 2).toOffset(), size.x / 2, Paint()..color = Colors.orangeAccent);
    }
    final active = isTarget();
    _emoji(canvas, active ? '💬' : label(), Offset(size.x / 2, -8), active ? 16 : 12,
        bob: active);
  }
}

/// Emoji bubble over a station: small and quiet, big and bobbing when the
/// pastor stands next to it; gold ring when the building's mission wants it.
class _StationMarker extends PositionComponent {
  final InteriorWorld room;
  final Furniture f;
  final String emoji;
  _StationMarker(this.room, this.f, this.emoji) : super(priority: 60);

  @override
  void render(Canvas canvas) {
    final t = room.target;
    final active = t is StationTarget && identical(t.furniture, f);
    final cx = (f.x + f.kind.w / 2) * InteriorWorld.cell;
    final top = f.kind.blocks ? f.y * InteriorWorld.cell : (f.y + f.kind.h / 2) * InteriorWorld.cell;
    final mission = room.building.activeMission?.actionEmoji;
    final wanted = mission != null && emoji.startsWith(mission);
    final c = Offset(cx, top - (active ? 10 : 4));
    final bg = Paint()
      ..color = (wanted ? const Color(0xFFFFD54F) : Colors.black)
          .withValues(alpha: active ? 0.75 : (wanted ? 0.55 : 0.35));
    canvas.drawCircle(c, active ? 15 : 10, bg);
    _emoji(canvas, emoji, c, active ? 18 : 11, bob: active, alpha: active ? 1 : 0.85);
  }
}

/// ✨ on the floor, visible once the pastor comes within three cells.
class _FindSparkle extends Component {
  final InteriorWorld room;
  _FindSparkle(this.room) : super(priority: 30);

  @override
  void render(Canvas canvas) {
    if (room.building.findCollected) return;
    final (fx, fy) = room.layout.find;
    final (px, py) = room.pastor.cellPos;
    if ((px - fx).abs() + (py - fy).abs() > 3) return;
    _emoji(canvas, '✨', InteriorWorld.centerOf(room.layout.find).toOffset(), 16, bob: true);
  }
}

/// Countdown of a timed action: emoji and a shrinking ring over the pastor.
class _BusyBadge extends Component {
  final InteriorWorld room;
  _BusyBadge(this.room) : super(priority: 70);

  static final Paint _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..color = const Color(0xFFFFD54F);
  static final Paint _bg = Paint()..color = const Color(0xAA000000);

  @override
  void render(Canvas canvas) {
    if (!room.isBusy) return;
    final c = (room.pastor.position - Vector2(0, 34)).toOffset();
    canvas.drawCircle(c, 16, _bg);
    final frac = room.busyTotal <= 0 ? 0.0 : (room.busyLeft / room.busyTotal).clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: c, radius: 16), -pi / 2, 2 * pi * frac, false, _ring);
    _emoji(canvas, room.busyEmoji, c, 15);
  }
}

class _FloatingText extends PositionComponent {
  final String text;
  double _t = 0;
  static const double _life = 1.8;
  _FloatingText(this.text, Vector2 pos) : super(position: pos, priority: 80);

  @override
  void update(double dt) {
    _t += dt;
    position.y -= 18 * dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = (1 - (_t / _life)).clamp(0.0, 1.0);
    _emoji(canvas, text, Offset.zero, 18, alpha: a, shadow: true);
  }
}

final Map<String, TextPainter> _painters = {};

void _emoji(Canvas canvas, String text, Offset center, double size,
    {bool bob = false, double alpha = 1, bool shadow = false}) {
  final key = '$text|$size|$shadow';
  if (_painters.length > 200) _painters.clear();
  final tp = _painters.putIfAbsent(key, () {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: shadow ? const [Shadow(blurRadius: 3, color: Color(0xFF000000))] : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  });
  final dy = bob ? sin(DateTime.now().millisecondsSinceEpoch / 180.0) * 2.5 : 0.0;
  final o = Offset(center.dx - tp.width / 2, center.dy - tp.height / 2 + dy);
  if (alpha >= 0.999) {
    tp.paint(canvas, o);
  } else {
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    tp.paint(canvas, o);
    canvas.restore();
  }
}
