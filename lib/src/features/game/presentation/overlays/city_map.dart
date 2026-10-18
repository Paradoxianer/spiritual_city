part of '../game_screen.dart';

/// The whole city (playtest 2026-10-18), opened by tapping the minimap.
/// Pinch to zoom, drag to move; ✕ (top right), back or Escape closes it. No text: districts as colours, the river,
/// boulevards, special buildings as emoji, 🏠 the pastor house, the pastor
/// as a bright dot. In the invisible world awakened neighbourhoods glow 🔥
/// and the current one is outlined.
class CityMapOverlay extends StatefulWidget {
  final SpiritWorldGame game;
  const CityMapOverlay({super.key, required this.game});

  @override
  State<CityMapOverlay> createState() => _CityMapOverlayState();
}

class _CityMapOverlayState extends State<CityMapOverlay> {
  static const double _scale = 2.0; // logical px per map pixel at zoom 1
  static const double _side = CityOverview.size * _scale;

  final TransformationController _ctrl = TransformationController();
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    widget.game.loadCityMap();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Start zoomed in on the pastor.
  void _centerOnPastor(Size view) {
    if (_placed) return;
    _placed = true;
    const zoom = 1.6;
    final p = _CityMapPainter.toMap(widget.game.player.position) * _scale;
    final dx = view.width / 2 - p.dx * zoom;
    final dy = view.height / 2 - p.dy * zoom;
    _ctrl.value = _ctrl.value.clone()
      ..setIdentity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(zoom, zoom, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return Material(
      color: const Color(0xF0101318),
      child: SafeArea(
        child: Stack(
          children: [
            ValueListenableBuilder<ui.Image?>(
              valueListenable: g.cityMapImage,
              builder: (context, img, _) {
                if (img == null) {
                  return const Center(child: Text('🗺️⏳', style: TextStyle(fontSize: 40)));
                }
                return LayoutBuilder(builder: (context, c) {
                  _centerOnPastor(c.biggest);
                  return InteractiveViewer(
                    transformationController: _ctrl,
                    constrained: false,
                    minScale: 0.3,
                    maxScale: 8,
                    boundaryMargin: const EdgeInsets.all(400),
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (context, _) => CustomPaint(
                        size: const Size(_side, _side),
                        painter: _CityMapPainter(
                          game: g,
                          image: img,
                          zoom: _ctrl.value.getMaxScaleOnAxis(),
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: g.closeCityMap,
                iconSize: 32,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xCC000000),
                  side: const BorderSide(color: Colors.white38),
                ),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: _LessonLegend(game: g),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: IconButton(
                onPressed: () => setState(() => _placed = false),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Text('🧍', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityMapPainter extends CustomPainter {
  final SpiritWorldGame game;
  final ui.Image image;
  final double zoom;

  _CityMapPainter({required this.game, required this.image, required this.zoom});

  static const double _s = _CityMapOverlayState._scale;

  /// World pixels → map pixels (before [_s]).
  static Offset toMap(Vector2 world) {
    const cs = CellComponent.cellSize;
    return Offset(
      (world.x / cs + CityOverview.radius) / CityOverview.step,
      (world.y / cs + CityOverview.radius) / CityOverview.step,
    );
  }

  static Offset _cell(num x, num y) => Offset(
        (x + CityOverview.radius) / CityOverview.step * _s,
        (y + CityOverview.radius) / CityOverview.step * _s,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Offset.zero & size;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );

    // Boulevards every 32 cells.
    final road = Paint()
      ..color = const Color(0x66D0D0D0)
      ..strokeWidth = 1 / zoom.clamp(0.5, 4);
    for (int c = -CityOverview.radius ~/ 32 * 32; c <= CityOverview.radius; c += 32) {
      final a = _cell(c, -CityOverview.radius), b = _cell(c, CityOverview.radius);
      canvas.drawLine(a, b, road);
      final l = _cell(-CityOverview.radius, c), r = _cell(CityOverview.radius, c);
      canvas.drawLine(l, r, road);
    }

    if (game.isSpiritualWorld) _paintQuarters(canvas);

    // Special buildings – tiny dots far out, emoji when zoomed in.
    final emojiSize = (13 / zoom).clamp(3.0, 13.0);
    final dot = Paint();
    final mentorTypes = {
      for (final t in BuildingType.values)
        if (Lessons.offeredAt(t, game.progress.skills,
                awakenings: game.progress.awakenedQuarters.length)
            .isNotEmpty)
          t,
    };
    for (final (x, y, t) in game.cityOverview?.landmarks ?? const <(int, int, BuildingType)>[]) {
      final o = _cell(x, y);
      // 🎓 A mentor waits here with something new to learn.
      if (mentorTypes.contains(t) && zoom >= 1.2) {
        _emojiAt(canvas, '🎓', o + Offset(emojiSize * 0.8, -emojiSize * 0.8), emojiSize * 0.9);
      }
      if (zoom < 1.2 && !_major(t)) {
        dot.color = const Color(0xCCFFFFFF);
        canvas.drawCircle(o, 1.2 / zoom.clamp(0.5, 2), dot);
      } else {
        _emojiAt(canvas, BuildingComponent.buildingEmoji(t), o, _major(t) ? emojiSize * 1.3 : emojiSize);
      }
    }

    final home = game.pastorhousePosition.value;
    _emojiAt(canvas, '🏠', home != null ? toMap(home) * _s : _cell(220, 222), emojiSize * 1.5);

    final target = game.trackedTargetPosition;
    if (target != null) _emojiAt(canvas, '📍', toMap(target) * _s - Offset(0, emojiSize), emojiSize * 1.8);

    // The pastor.
    final me = toMap(game.player.position) * _s;
    canvas.drawCircle(me, 11 / zoom, Paint()..color = const Color(0x55FFFFFF));
    canvas.drawCircle(me, 5 / zoom, Paint()..color = Colors.black);
    canvas.drawCircle(me, 3.8 / zoom, Paint()..color = const Color(0xFFFFE082));
  }

  bool _major(BuildingType t) => switch (t) {
        BuildingType.church || BuildingType.cathedral || BuildingType.hospital ||
        BuildingType.cityHall || BuildingType.trainStation || BuildingType.stadium ||
        BuildingType.university =>
          true,
        _ => false,
      };

  void _paintQuarters(Canvas canvas) {
    const q = Quarter.sizeCells;
    final glow = Paint()..color = const Color(0x66FF9800);
    for (final key in game.progress.awakenedQuarters) {
      final parts = key.split(',');
      if (parts.length != 2) continue;
      final qx = int.tryParse(parts[0]), qy = int.tryParse(parts[1]);
      if (qx == null || qy == null) continue;
      canvas.drawRect(Rect.fromPoints(_cell(qx * q, qy * q), _cell((qx + 1) * q, (qy + 1) * q)), glow);
    }
    final cur = game.currentQuarter;
    canvas.drawRect(
      Rect.fromPoints(_cell(cur.qx * q, cur.qy * q), _cell((cur.qx + 1) * q, (cur.qy + 1) * q)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 / zoom
        ..color = const Color(0xFFFFD54F),
    );
  }

  static final Map<String, TextPainter> _tp = {};

  void _emojiAt(Canvas canvas, String e, Offset c, double size) {
    final key = '$e|${size.toStringAsFixed(1)}';
    if (_tp.length > 300) _tp.clear();
    final tp = _tp.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(text: e, style: TextStyle(fontSize: size)),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CityMapPainter old) => true;
}

/// What can be learned now and where (emoji only): `🎓🫂 🏥`.
class _LessonLegend extends StatelessWidget {
  final SpiritWorldGame game;
  const _LessonLegend({required this.game});

  @override
  Widget build(BuildContext context) {
    final p = game.progress;
    final lessons = <Lesson>{
      for (final t in BuildingType.values)
        ...Lessons.offeredAt(t, p.skills, awakenings: p.awakenedQuarters.length),
    };
    if (lessons.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final l in lessons)
            Text(
              '🎓${l.skill.emoji}  ${l.mentorAt.map(BuildingComponent.buildingEmoji).join(' ')}',
              style: const TextStyle(fontSize: 16),
            ),
        ],
      ),
    );
  }
}
