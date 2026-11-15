part of '../game_screen.dart';

/// Lines along the screen's edge (playtest 2026-11-15) in the colour of
/// the bar that runs low, so neither can be overlooked:
/// - red like ❤️ while life is below 25 %, orange like 🍞 while the
///   provisions are below 30 % (both: red outside, orange inside) – thicker
///   and faster pulsing the emptier;
/// - a blood-red flare when a daemon strikes ([SpiritWorldGame.hitFlash]).
class _EdgeGlow extends StatefulWidget {
  final SpiritWorldGame game;
  const _EdgeGlow({required this.game});

  @override
  State<_EdgeGlow> createState() => _EdgeGlowState();
}

class _EdgeGlowState extends State<_EdgeGlow> with TickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _flash =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  /// 0 = fine … 1 = empty.
  double _health = 0;
  double _hunger = 0;

  SpiritWorldGame get _g => widget.game;

  @override
  void initState() {
    super.initState();
    _g.hungerNotifier.addListener(_onLevels);
    _g.healthNotifier.addListener(_onLevels);
    _g.hitFlash.addListener(_onHit);
    _onLevels();
  }

  static double _low(double value, double max, double warn) {
    final frac = (value / max).clamp(0.0, 1.0);
    return frac >= warn ? 0.0 : (1 - frac / warn).clamp(0.0, 1.0);
  }

  void _onLevels() {
    final health = _low(_g.healthNotifier.value, _g.progress.maxHealth, SpiritWorldGame.healthAlarmThreshold);
    final hunger = _low(_g.hungerNotifier.value, _g.progress.maxHunger, SpiritWorldGame.hungerWarnThreshold);
    if (health == _health && hunger == _hunger) return;
    _health = health;
    _hunger = hunger;
    final urgency = health > hunger ? health : hunger;
    if (urgency > 0) {
      // The emptier, the faster the pulse.
      _pulse.duration = Duration(milliseconds: (1200 - 700 * urgency).round());
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
    setState(() {});
  }

  void _onHit() => _flash.forward(from: 0);

  @override
  void dispose() {
    _g.hungerNotifier.removeListener(_onLevels);
    _g.healthNotifier.removeListener(_onLevels);
    _g.hitFlash.removeListener(_onHit);
    _pulse.dispose();
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _flash]),
          builder: (context, _) {
            // Clearly there from the first warning; the pulse only breathes
            // between nearly and fully opaque.
            final beat = 0.8 + 0.2 * _pulse.value;
            final hit = _flash.isAnimating ? 1 - _flash.value : 0.0;
            if (_health <= 0 && _hunger <= 0 && hit <= 0) return const SizedBox.expand();
            return CustomPaint(
              size: Size.infinite,
              painter: _EdgeGlowPainter(health: _health, hunger: _hunger, beat: beat, hit: hit),
            );
          },
        ),
      ),
    );
  }
}

class _EdgeGlowPainter extends CustomPainter {
  final double health;
  final double hunger;
  final double beat;
  final double hit;
  _EdgeGlowPainter({required this.health, required this.hunger, required this.beat, required this.hit});

  /// The colours of the ❤️ and 🍞 bars.
  static const Color _healthColor = Colors.redAccent;
  static const Color _hungerColor = Colors.orange;

  /// One line [inset] px from the edge; returns how wide it is.
  double _line(Canvas canvas, Rect rect, double inset, double urgency, Color color) {
    // Thin but solid (playtest 2026-11-15: 10–20 px was far too thick):
    // 3 px at the first warning, 6 px when empty …
    final w = 3 + 3 * urgency;
    // … and behind it a soft gradient fading into the game, 50 → 90 px.
    final depth = 50 + 40 * urgency;
    final inner = rect.deflate(inset);
    final from = color.withValues(alpha: 0.35 * beat);
    final to = color.withValues(alpha: 0);
    void side(Rect band, Alignment begin, Alignment end) => canvas.drawRect(
        band,
        Paint()..shader = LinearGradient(begin: begin, end: end, colors: [from, to]).createShader(band));
    side(Rect.fromLTWH(inner.left, inner.top, inner.width, depth), Alignment.topCenter, Alignment.bottomCenter);
    side(Rect.fromLTWH(inner.left, inner.bottom - depth, inner.width, depth), Alignment.bottomCenter,
        Alignment.topCenter);
    side(Rect.fromLTWH(inner.left, inner.top, depth, inner.height), Alignment.centerLeft, Alignment.centerRight);
    side(Rect.fromLTWH(inner.right - depth, inner.top, depth, inner.height), Alignment.centerRight,
        Alignment.centerLeft);
    canvas.drawRect(
      rect.deflate(inset + w / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = color.withValues(alpha: beat),
    );
    return w;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    var inset = 0.0;
    if (health > 0) inset += _line(canvas, rect, inset, health, _healthColor);
    if (hunger > 0) _line(canvas, rect, inset, hunger, _hungerColor);
    if (hit > 0) {
      // The strike: the whole edge flares up blood red, fading out.
      canvas.drawRect(
        rect.deflate(18),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 36
          ..color = const Color(0xFFB71C1C).withValues(alpha: 0.85 * hit)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }
  }

  @override
  bool shouldRepaint(_EdgeGlowPainter o) =>
      o.health != health || o.hunger != hunger || o.beat != beat || o.hit != hit;
}
