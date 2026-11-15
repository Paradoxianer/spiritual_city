part of '../game_screen.dart';

/// A thick red line along the screen's edge (playtest 2026-11-15):
/// - it pulses while the provisions 🍞 run low – faster and thicker the
///   emptier they are – so hunger can no longer be overlooked;
/// - it flashes when a daemon strikes the pastor ([SpiritWorldGame.hitFlash]).
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

  /// 0 = fine … 1 = empty: how urgent the hunger is.
  double _hunger = 0;

  SpiritWorldGame get _g => widget.game;

  @override
  void initState() {
    super.initState();
    _g.hungerNotifier.addListener(_onHunger);
    _g.hitFlash.addListener(_onHit);
    _onHunger();
  }

  void _onHunger() {
    final frac = (_g.hungerNotifier.value / _g.progress.maxHunger).clamp(0.0, 1.0);
    const warn = SpiritWorldGame.hungerWarnThreshold;
    final urgency = frac >= warn ? 0.0 : (1 - frac / warn).clamp(0.0, 1.0);
    if (urgency == _hunger) return;
    _hunger = urgency;
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
    _g.hungerNotifier.removeListener(_onHunger);
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
            final hunger = _hunger * (0.35 + 0.65 * _pulse.value);
            final hit = _flash.isAnimating ? 1 - _flash.value : 0.0;
            if (hunger <= 0 && hit <= 0) return const SizedBox.expand();
            return CustomPaint(
              size: Size.infinite,
              painter: _EdgeGlowPainter(hunger: hunger, urgency: _hunger, hit: hit),
            );
          },
        ),
      ),
    );
  }
}

class _EdgeGlowPainter extends CustomPainter {
  final double hunger;
  final double urgency;
  final double hit;
  _EdgeGlowPainter({required this.hunger, required this.urgency, required this.hit});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (hunger > 0) {
      // Thick: 10 px at the first warning, 26 px when nearly empty.
      final w = 10 + 16 * urgency;
      canvas.drawRect(
        rect.deflate(w / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = const Color(0xFFE53935).withValues(alpha: (0.25 + 0.7 * hunger).clamp(0.0, 0.95))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.45),
      );
    }
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
  bool shouldRepaint(_EdgeGlowPainter o) => o.hunger != hunger || o.urgency != urgency || o.hit != hit;
}
