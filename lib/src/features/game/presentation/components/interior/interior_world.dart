import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' show VoidCallback, Colors, TextPainter, TextSpan, TextStyle, FontWeight;

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

  /// Tutorial guide: a station action to pulse, or [guideDoor].
  String? guide;
  static const guideDoor = '🚪';

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
      final npc = rs[i];
      add(_Person(this, pos, CharacterSprites.figureFor(stableStringHash(npc.id)),
          () => _faceOf(npc), () => target is ResidentTarget && (target as ResidentTarget).npc == npc,
          () => ResidentTarget(npc)));
    }
    if (lesson != null) {
      final spots = layout.residentSpots;
      final cellPos = spots.length > rs.length ? spots[rs.length] : layout.find;
      mentorPos = centerOf(cellPos);
      add(_Person(this, mentorPos!, 5, () => '🎓${lesson!.skill.emoji}', () => target is MentorTarget,
          () => MentorTarget(lesson!)));
    }
    add(_FindSparkle(this));
    if (!building.isHomebase) add(_WallStatus(this));
    pastor = InteriorPastor(this)..position = centerOf(layout.entry);
    add(pastor);
    add(_BusyBadge(this));
    add(_TutorialGuide(this));
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
    if (_forced != null || pastor.isWalking) return;
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

  /// Target chosen by a tap; kept while the pastor walks there.
  InteriorTarget? _forced;

  /// Tap on a station or a person: the pastor walks there by himself
  /// (playtest: walking every time got tedious) and then acts.
  void goAndAct(InteriorTarget t) {
    if (isBusy || leaving) return;
    final bool Function(int x, int y) goal = switch (t) {
      StationTarget(:final furniture) => (x, y) =>
          furniture.distanceTo(x + 0.5, y + 0.5) < (furniture.kind.blocks ? 0.95 : 0.2),
      ResidentTarget(:final npc) => (x, y) => _nextTo(residents[npc], x, y),
      MentorTarget() => (x, y) => _nextTo(mentorPos, x, y),
      DoorTarget() => (x, y) => (x, y) == layout.entry,
    };
    final path = _route(goal);
    if (path == null) return;
    pastor.walk(path, () {
      _forced = t;
      target = t;
      game.interiorInteract();
      _forced = null;
    });
  }

  bool _nextTo(Vector2? p, int x, int y) {
    if (p == null) return false;
    final px = (p.x / cell).floor(), py = (p.y / cell).floor();
    return (px - x).abs() + (py - y).abs() == 1;
  }

  /// Shortest walk over free cells to the nearest cell that satisfies [goal].
  List<Vector2>? _route(bool Function(int x, int y) goal) {
    final start = pastor.cellPos;
    if (goal(start.$1, start.$2)) return const [];
    final prev = <(int, int), (int, int)>{};
    final queue = <(int, int)>[start];
    final seen = {start};
    for (var i = 0; i < queue.length; i++) {
      final cur = queue[i];
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final n = (cur.$1 + dx, cur.$2 + dy);
        if (seen.contains(n) || !layout.isWalkable(n.$1, n.$2) || n == layout.door) continue;
        if (residents.values.any((p) => (p.x / cell).floor() == n.$1 && (p.y / cell).floor() == n.$2)) {
          continue;
        }
        seen.add(n);
        prev[n] = cur;
        if (goal(n.$1, n.$2)) {
          final path = <Vector2>[];
          var p = n;
          while (p != start) {
            path.insert(0, centerOf(p));
            p = prev[p]!;
          }
          return path;
        }
        queue.add(n);
      }
    }
    return null;
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
  static const double autoSpeed = 190.0;
  final CharacterAnimator _anim = CharacterAnimator();

  List<Vector2> _path = const [];
  VoidCallback? _onArrive;
  bool get isWalking => _onArrive != null;

  void walk(List<Vector2> path, VoidCallback onArrive) {
    _path = List.of(path);
    _onArrive = onArrive;
  }

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
    if (!dir.isZero()) {
      _onArrive = null; // the player takes over
      _path = const [];
    } else if (_onArrive != null) {
      if (_path.isEmpty) {
        final done = _onArrive!;
        _onArrive = null;
        done();
        return;
      }
      final to = _path.first;
      final d = to - position;
      final stepLen = autoSpeed * dt;
      if (d.length <= stepLen) {
        position.setFrom(to);
        _path.removeAt(0);
      } else {
        position.add(d.normalized() * stepLen);
      }
      return;
    }
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
class _Person extends PositionComponent with TapCallbacks {
  final InteriorWorld room;
  final int figure;
  final String Function() label;
  final bool Function() isTarget;
  final InteriorTarget Function() asTarget;
  final CharacterAnimator _anim = CharacterAnimator();

  _Person(this.room, Vector2 pos, this.figure, this.label, this.isTarget, this.asTarget)
      : super(position: pos, size: Vector2.all(30), anchor: Anchor.center, priority: 40);

  @override
  void onTapUp(TapUpEvent event) => room.goAndAct(asTarget());

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
class _StationMarker extends PositionComponent with TapCallbacks {
  final InteriorWorld room;
  final Furniture f;
  final String emoji;

  /// Room for the bubble above the piece.
  static const double _head = 30;

  _StationMarker(this.room, this.f, this.emoji)
      : super(
          priority: 60,
          position: Vector2(f.x * InteriorWorld.cell, f.y * InteriorWorld.cell - _head),
          size: Vector2(f.kind.w * InteriorWorld.cell, f.kind.h * InteriorWorld.cell + _head),
        );

  @override
  void onTapUp(TapUpEvent event) => room.goAndAct(StationTarget(f));

  @override
  void render(Canvas canvas) {
    final t = room.target;
    final active = t is StationTarget && identical(t.furniture, f);
    final cx = f.kind.w / 2 * InteriorWorld.cell;
    final top = f.kind.blocks ? _head : _head + f.kind.h / 2 * InteriorWorld.cell;
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

/// Pulsing cyan ring around what the tutorial wants next (the 📖 shelf,
/// the 📋 board or the door out) – the same colour as on the minimap.
class _TutorialGuide extends Component {
  final InteriorWorld room;
  _TutorialGuide(this.room) : super(priority: 59);

  double _t = 0;
  static final Paint _p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final g = room.guide;
    if (g == null) return;
    const c = InteriorWorld.cell;
    Offset center;
    double r;
    if (g == InteriorWorld.guideDoor) {
      final (dx, dy) = room.layout.door;
      center = Offset((dx + 0.5) * c, (dy + 0.3) * c);
      r = c * 0.8;
    } else {
      final f = room.layout.stations.where((f) => f.action == g).firstOrNull;
      if (f == null) return;
      center = Offset((f.x + f.kind.w / 2) * c, (f.y + f.kind.h / 2) * c);
      r = max(f.kind.w, f.kind.h) * c * 0.65 + 6;
    }
    final pulse = (sin(_t * 5) + 1) / 2;
    _p.color = const Color(0xFF80DEEA).withValues(alpha: 0.5 + 0.5 * pulse);
    canvas.drawCircle(center, r + pulse * 6, _p);
  }
}

/// Visit points on the top wall (like the dialog header) and the house's
/// ✝️ holiness as a bar in the right wall (playtest 2026-10-18).
class _WallStatus extends Component {
  final InteriorWorld room;
  _WallStatus(this.room) : super(priority: 20);

  static final Paint _p = Paint();

  @override
  void render(Canvas canvas) {
    const c = InteriorWorld.cell;
    final b = room.building;
    final l = room.layout;

    // ●●○ – used points bright; all used → the visit ends.
    final max = b.maxSessionInteractions.clamp(1, 12);
    final done = b.currentSessionInteractions.clamp(0, max);
    const r = 6.0, gap = 18.0;
    final x0 = l.width * c / 2 - (max - 1) * gap / 2;
    for (var i = 0; i < max; i++) {
      final o = Offset(x0 + i * gap, c * 0.5);
      _p.color = const Color(0xAA000000);
      canvas.drawCircle(o, r + 1.5, _p);
      _p.color = i < done ? const Color(0xFFFFD54F) : const Color(0x55FFFFFF);
      canvas.drawCircle(o, r, _p);
    }

    // ✝️ holiness: ? until known, rounded while vague, exact once revealed.
    final x = (l.width - 0.5) * c;
    final top = 2.2 * c, bottom = (l.height - 1.6) * c;
    final bar = Rect.fromLTRB(x - 5, top, x + 5, bottom);
    _p.color = const Color(0xAA000000);
    canvas.drawRRect(RRect.fromRectAndRadius(bar.inflate(2), const Radius.circular(6)), _p);
    _p.color = const Color(0x33FFFFFF);
    canvas.drawRRect(RRect.fromRectAndRadius(bar, const Radius.circular(5)), _p);
    _emoji(canvas, '✝️', Offset(x, top - 14), 14);
    if (!b.isFaithVague) {
      _emoji(canvas, '?', bar.center, 11);
      return;
    }
    final norm = ((b.holiness + 100) / 200).clamp(0.0, 1.0);
    final shown = b.isFaithRevealed ? norm : ((norm * 4).round() / 4).clamp(0.0, 1.0);
    _p.color = Color.lerp(const Color(0xFFD32F2F), const Color(0xFF43A047), norm)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(bar.left, bar.bottom - bar.height * shown, bar.right, bar.bottom),
        const Radius.circular(5),
      ),
      _p,
    );
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
