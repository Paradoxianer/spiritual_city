part of '../game_screen.dart';

/// The narrator's speech bubble at the bottom: the text types out letter
/// by letter (a tap shows it whole) and fades out once there was time to
/// read it; swiped down by the handle it never comes again ([Narrator]).
class _NarratorBubble extends StatefulWidget {
  final NarratorLine line;
  const _NarratorBubble({super.key, required this.line});

  @override
  State<_NarratorBubble> createState() => _NarratorBubbleState();
}

class _NarratorBubbleState extends State<_NarratorBubble> {
  /// Letters per second of the typewriter.
  static const double _speed = 90;

  Timer? _timer;
  Timer? _hide;
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(milliseconds: (1000 / _speed).round()), (t) {
      if (!mounted) return;
      setState(() => _shown++);
      if (_shown >= widget.line.text.length) {
        t.cancel();
        _scheduleHide();
      }
    });
  }

  /// Time to read it, then it fades out (and comes again next time).
  void _scheduleHide() {
    _hide?.cancel();
    final seconds = 4 + widget.line.text.length / 20;
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
    setState(() => _shown = widget.line.text.length);
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final text = line.text.characters.take(_shown).toString();
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, box) => Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ConstrainedBox(
              // Between the joystick and the buttons on a phone.
              constraints: BoxConstraints(maxWidth: (box.maxWidth - 340).clamp(260.0, 560.0)),
              // Swiped down by the handle: never again.
              child: Dismissible(
                key: ValueKey('narrator-${line.key}'),
                direction: DismissDirection.down,
                onDismissed: (_) => Narrator.dismiss(),
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
                      // The handle: swipe down to never see this again.
                      Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 6, right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA1887F),
                          borderRadius: BorderRadius.circular(3),
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
                      const SizedBox(width: 8),
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
    );
  }
}
