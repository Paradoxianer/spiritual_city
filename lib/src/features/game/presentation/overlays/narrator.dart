part of '../game_screen.dart';

/// The narrator's speech bubble at the bottom: the text types out letter
/// by letter (a tap shows it whole) and fades out once there was time to
/// read it. ✕ closes it; swiped down by the handle the narrator is off
/// ([Narrator], [_NarratorHandle] brings it back).
class _NarratorBubble extends StatefulWidget {
  final NarratorLine line;
  const _NarratorBubble({super.key, required this.line});

  @override
  State<_NarratorBubble> createState() => _NarratorBubbleState();
}

/// Cuts [s] at [n] code units, never inside a surrogate pair (emoji).
int _safeCut(String s, int n) {
  if (n <= 0) return 0;
  if (n >= s.length) return s.length;
  final c = s.codeUnitAt(n - 1);
  return (c >= 0xD800 && c <= 0xDBFF) ? n - 1 : n;
}

class _NarratorBubbleState extends State<_NarratorBubble> {
  /// Letters per second of the typewriter.
  static const double _speed = 90;

  /// The text appears word by word, following the clock – a handful of
  /// redraws per second instead of one per letter, and a busy frame never
  /// slows it down (playtest 2026-10-31: walking felt sluggish).
  static const int _checksPerSecond = 15;

  final Stopwatch _clock = Stopwatch()..start();
  Timer? _timer;
  Timer? _hide;
  int _shown = 0;

  int get _length => widget.line.text.length;

  /// The end of the word that contains position [n].
  int _wordEnd(int n) {
    final t = widget.line.text;
    if (n >= t.length) return t.length;
    final next = t.indexOf(' ', n);
    return next < 0 ? t.length : next;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1000 ~/ _checksPerSecond), (t) {
      if (!mounted) return;
      final n = _wordEnd((_clock.elapsedMilliseconds * _speed / 1000).floor());
      if (n != _shown) setState(() => _shown = n);
      if (n >= _length) {
        t.cancel();
        _scheduleHide();
      }
    });
  }

  /// Time to read it, then it fades out.
  void _scheduleHide() {
    _hide?.cancel();
    final seconds = 4 + _length / 20;
    _hide = Timer(Duration(milliseconds: (seconds * 1000).round()), () => Narrator.hide(widget.line.key));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hide?.cancel();
    super.dispose();
  }

  void _showAll() {
    _timer?.cancel();
    setState(() => _shown = _length);
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final text = _shown >= _length ? line.text : line.text.substring(0, _safeCut(line.text, _shown));
    // Its own layer: redrawing the bubble never repaints the game.
    return RepaintBoundary(
      child: SafeArea(
      child: LayoutBuilder(
        builder: (context, box) => Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ConstrainedBox(
              // Between the joystick and the buttons on a phone.
              constraints: BoxConstraints(maxWidth: (box.maxWidth - 340).clamp(260.0, 560.0)),
              // Swiped down by the handle: the narrator is off.
              child: Dismissible(
                key: ValueKey('narrator-${line.key}'),
                direction: DismissDirection.down,
                onDismissed: (_) => Narrator.turnOff(),
                child: GestureDetector(
                onTap: _showAll,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 6, 6, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xF0FFF8E1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF8D6E63), width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ⌄ (tap or swipe down): the narrator is off.
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: Narrator.turnOff,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8, bottom: 2),
                          child: Icon(Icons.keyboard_arrow_down, size: 22, color: Color(0xFF8D6E63)),
                        ),
                      ),
                      Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (line.title.isNotEmpty)
                              Text(line.title,
                                  style: const TextStyle(
                                      color: Color(0xFF5D4037), fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              text,
                              style: const TextStyle(color: Color(0xFF3E2723), fontSize: 14, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                      // ✕: just this bubble (e.g. to chat on quickly).
                      GestureDetector(
                        onTap: Narrator.close,
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(8, 0, 6, 6),
                          child: Icon(Icons.close, size: 20, color: Color(0xFF6D4C41)),
                        ),
                      ),
                    ],
                  ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// With the narrator off, a small handle stays at the bottom: swipe it up
/// (or tap it) and the narrator is on again.
class _NarratorHandle extends StatelessWidget {
  const _NarratorHandle();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: Narrator.turnOn,
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) < -50) Narrator.turnOn();
          },
          child: Container(
            width: 72,
            height: 26,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: const Color(0xCCFFF8E1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: const Color(0xFF8D6E63)),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_up, size: 14, color: Color(0xFF6D4C41)),
                Text('💬', style: TextStyle(fontSize: 10, height: 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
