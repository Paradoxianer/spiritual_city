part of '../game_screen.dart';

/// Small map in the top-right corner (playtest 2026-10-18), no text.
///
/// - City: streets, houses, water and green; ⛪ churches, the 🏠 pastor
///   house and other special buildings as bright dots, 📋 mission targets
///   as amber dots.
/// - Invisible world: the spiritual state of every cell (red = dark,
///   green = light), daemons as red dots, the 🏰 stronghold.
///
/// Tap: bigger / smaller. Double tap: the whole city ([CityMapOverlay]).
/// Hidden inside buildings.
class _Minimap extends StatefulWidget {
  final SpiritWorldGame game;
  const _Minimap({required this.game});

  @override
  State<_Minimap> createState() => _MinimapState();
}

class _MinimapState extends State<_Minimap> {
  Timer? _timer;
  bool _big = false;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    // The map only needs a few updates per second.
    _timer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    if (g.interior != null) return const SizedBox.shrink();
    final size = _big ? 200.0 : 112.0;
    final spirit = g.isSpiritualWorld;
    return GestureDetector(
      onTap: () => setState(() => _big = !_big),
      onDoubleTap: g.openCityMap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: spirit ? const Color(0x88FFD54F) : Colors.white24,
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: CustomPaint(
            painter: _MinimapPainter(
              game: g,
              spirit: spirit,
              radiusCells: _big ? 60 : 36,
              tick: _tick,
            ),
          ),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final SpiritWorldGame game;
  final bool spirit;
  final int radiusCells;
  final int tick;

  _MinimapPainter({
    required this.game,
    required this.spirit,
    required this.radiusCells,
    required this.tick,
  });

  static final Paint _p = Paint();

  static const Color _unknown = Color(0xFF15171C);
  static const Color _road = Color(0xFF55585E);
  static const Color _bigRoad = Color(0xFF6E7178);
  static const Color _walk = Color(0xFF3A3D42);
  static const Color _water = Color(0xFF2F6FB0);
  static const Color _green = Color(0xFF3F7A3A);
  static const Color _house = Color(0xFFA0634B);

  @override
  void paint(Canvas canvas, Size size) {
    const cs = CellComponent.cellSize;
    final pcx = (game.player.position.x / cs).floor();
    final pcy = (game.player.position.y / cs).floor();
    final n = radiusCells * 2 + 1;
    final px = size.width / n;

    final markers = <(Offset, Color, double)>[];
    for (int j = 0; j < n; j++) {
      for (int i = 0; i < n; i++) {
        final wx = pcx - radiusCells + i;
        final wy = pcy - radiusCells + j;
        final cell = game.grid.getCell(wx, wy);
        final Color c;
        if (cell == null) {
          c = _unknown;
        } else if (spirit) {
          c = _spiritColor(cell.spiritualState, cell.data);
        } else {
          c = _cityColor(cell.data);
          final d = cell.data;
          if (d is BuildingData && d.isEntrance) {
            final m = _specialColor(d.type);
            if (m != null) markers.add((Offset((i + 0.5) * px, (j + 0.5) * px), m, 2.6));
          }
        }
        _p.color = c;
        canvas.drawRect(Rect.fromLTWH(i * px, j * px, px + 0.4, px + 0.4), _p);
      }
    }

    Offset? toMap(Vector2 world) {
      final dx = world.x / cs - pcx + radiusCells;
      final dy = world.y / cs - pcy + radiusCells;
      if (dx < 0 || dy < 0 || dx > n || dy > n) return null;
      return Offset(dx * px, dy * px);
    }

    if (spirit) {
      for (final d in game.world.children.whereType<DaemonComponent>()) {
        final o = toMap(d.position);
        if (o != null) markers.add((o, const Color(0xFFFF3B3B), 2.4));
      }
      for (final s in game.world.children.whereType<StrongholdComponent>()) {
        final o = toMap(s.position);
        if (o != null) markers.add((o, const Color(0xFFB000FF), 4.5));
      }
    } else {
      // 📋 Mission targets.
      for (final npc in game.chunkManager.allActiveNPCs) {
        if (npc.model.activeMission == null) continue;
        final o = toMap(npc.position);
        if (o != null) markers.add((o, const Color(0xFFFFC107), 2.4));
      }
      final home = game.pastorhousePosition.value;
      if (home != null) {
        final o = toMap(home);
        if (o != null) markers.add((o, const Color(0xFFFFD54F), 4.0));
      }
    }

    for (final (o, c, r) in markers) {
      _p.color = Colors.black;
      canvas.drawCircle(o, r + 1, _p);
      _p.color = c;
      canvas.drawCircle(o, r, _p);
    }

    // 📍 Accepted mission (amber) and the tutorial's target (cyan): ring
    // on the map, or an arrow at the edge.
    void guide(Vector2? target, Color color) {
      if (target == null) return;
      final o = toMap(target);
      final pulse = 0.5 + 0.5 * sin(tick * 1.4);
      if (o != null) {
        canvas.drawCircle(
            o,
            4 + 3 * pulse,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = color);
        _p.color = color;
        canvas.drawCircle(o, 2.5, _p);
        return;
      }
      final c = Offset(size.width / 2, size.height / 2);
      final d = Offset(target.x / cs - pcx, target.y / cs - pcy);
      final len = d.distance;
      if (len == 0) return;
      final u = d / len;
      final tip = c + u * (size.width / 2 - 5);
      final side = Offset(-u.dy, u.dx);
      final a = tip - u * 9 + side * 5, b = tip - u * 9 - side * 5;
      _p.color = color;
      canvas.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(a.dx, a.dy)
            ..lineTo(b.dx, b.dy)
            ..close(),
          _p);
    }

    guide(game.trackedTargetPosition, const Color(0xFFFFC107));
    guide(game.tutorialTargetPosition, const Color(0xFF80DEEA));

    // The pastor in the middle.
    final me = Offset((radiusCells + 0.5) * px, (radiusCells + 0.5) * px);
    _p.color = Colors.black;
    canvas.drawCircle(me, 4.2, _p);
    _p.color = spirit ? const Color(0xFFFFE082) : Colors.white;
    canvas.drawCircle(me, 3.2, _p);
  }

  Color _cityColor(CellData? d) {
    if (d == null) return _walk;
    if (d is RoadData) return d.type == RoadType.small ? _road : _bigRoad;
    if (d is NatureData) return d.type == NatureType.water ? _water : _green;
    if (d is BuildingData) {
      return switch (d.type) {
        BuildingType.pastorHouse => const Color(0xFFFFD54F),
        BuildingType.church || BuildingType.cathedral => const Color(0xFFE8E0C8),
        BuildingType.cemetery || BuildingType.stadium => _green,
        BuildingType.house || BuildingType.apartment => _house,
        _ => const Color(0xFF8D8F96),
      };
    }
    return _walk;
  }

  /// Bright dot for buildings worth finding.
  Color? _specialColor(BuildingType t) => switch (t) {
        BuildingType.church || BuildingType.cathedral => const Color(0xFFFFFFFF),
        BuildingType.hospital => const Color(0xFFFF5252),
        BuildingType.school || BuildingType.university => const Color(0xFF40C4FF),
        BuildingType.cityHall || BuildingType.policeStation => const Color(0xFF448AFF),
        _ => null,
      };

  Color _spiritColor(double s, CellData? d) {
    final base = d is RoadData ? 0.18 : 0.26;
    final v = s.clamp(-1.0, 1.0);
    if (v >= 0) {
      return Color.lerp(const Color.fromRGBO(30, 30, 40, 1), const Color(0xFF3CE07A), base + v * 0.7)!;
    }
    return Color.lerp(const Color.fromRGBO(30, 30, 40, 1), const Color(0xFFE53935), base + -v * 0.7)!;
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter old) =>
      old.tick != tick || old.spirit != spirit || old.radiusCells != radiusCells;
}
