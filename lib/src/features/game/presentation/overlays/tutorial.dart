part of '../game_screen.dart';

/// "First steps" as a slim goal chip under the street label (playtest
/// 2026-10-18): it never covers the game. Tap it for a short explanation,
/// tap again to fold it. An arrow points to the target (also 📍 on the
/// map); info steps end with ✓. Skipping is in the pause menu.
class _TutorialChip extends StatefulWidget {
  final SpiritWorldGame game;
  const _TutorialChip({required this.game});

  @override
  State<_TutorialChip> createState() => _TutorialChipState();
}

class _TutorialChipState extends State<_TutorialChip> {
  bool _open = true;
  bool _confirmSkip = false;
  TutorialStep? _shown;

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return ValueListenableBuilder<TutorialStep?>(
      valueListenable: g.tutorialService.currentStepNotifier,
      builder: (context, step, _) {
        // Shown inside buildings too (playtest: after the bookshelf the
        // next step was hidden) – the hint then points to the door.
        if (step == null) return const SizedBox.shrink();
        // A new step opens its explanation once.
        if (step != _shown) {
          _shown = step;
          _open = true;
          _confirmSkip = false;
          if (step != TutorialStep.values.first) GameSound.play(Sfx.learned, volume: 0.35);
        }
        final key = 'tutorial.${step.name}';
        final width = MediaQuery.of(context).size.width;
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _open = !_open),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: (width - 140).clamp(200.0, 420.0)),
                    padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                    decoration: BoxDecoration(
                      color: const Color(0xE01A237E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF80DEEA), width: 1.5),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(step.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                AppStrings.get('$key.goal'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _Arrow(game: g),
                            if (step.isInfo)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: g.tutorialService.confirmInfo,
                                icon: const Text('✅', style: TextStyle(fontSize: 18)),
                              ),
                          ],
                        ),
                        if (_open)
                          Align(
                            alignment: Alignment.centerRight,
                            child: _confirmSkip
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(AppStrings.get('tutorial.skipAsk'),
                                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      TextButton(
                                        onPressed: g.tutorialService.skipTutorial,
                                        child: const Text('⏭️✅', style: TextStyle(fontSize: 16)),
                                      ),
                                      TextButton(
                                        onPressed: () => setState(() => _confirmSkip = false),
                                        child: const Text('❌', style: TextStyle(fontSize: 16)),
                                      ),
                                    ],
                                  )
                                : TextButton(
                                    onPressed: () => setState(() => _confirmSkip = true),
                                    child: const Text('⏭️', style: TextStyle(fontSize: 16)),
                                  ),
                          ),
                        if (_open) ...[
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.get('$key.detail'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Where to go next: 📍 with a direction while the target is far away,
/// otherwise what to tap right here (🖐️, the 📖 shelf, the 🚪 door), pulsing.
class _Arrow extends StatelessWidget {
  final SpiritWorldGame game;
  const _Arrow({required this.game});

  static const _style = TextStyle(color: Color(0xFF80DEEA), fontSize: 15, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Vector2>(
      valueListenable: game.playerWorldPosition,
      builder: (context, me, _) {
        final hint = game.tutorialHint;
        if (hint != null) return _PulsingHint(text: '👉$hint', style: _style);
        final t = game.tutorialTargetPosition;
        if (t == null || game.interior != null) return const SizedBox.shrink();
        final dx = t.x - me.x, dy = t.y - me.y;
        if (dx * dx + dy * dy < 48 * 48) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(_directionArrow(atan2(dy, dx) * 180 / pi), style: _style.copyWith(fontSize: 20)),
        );
      },
    );
  }
}

class _PulsingHint extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _PulsingHint({required this.text, required this.style});

  @override
  State<_PulsingHint> createState() => _PulsingHintState();
}

class _PulsingHintState extends State<_PulsingHint> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.2).animate(_c),
          child: Text(widget.text, style: widget.style),
        ),
      );
}
