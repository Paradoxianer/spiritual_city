part of '../game_screen.dart';

/// A neighbourhood is prayed free (≥ 95 % green in the invisible world):
/// confetti, the neighbourhood's numbers and the narrator congratulates.
/// Driven by [SpiritWorldGame.quarterCelebration].
class _QuarterCelebrationOverlay extends StatefulWidget {
  final SpiritWorldGame game;
  const _QuarterCelebrationOverlay({super.key, required this.game});

  @override
  State<_QuarterCelebrationOverlay> createState() => _QuarterCelebrationOverlayState();
}

class _QuarterCelebrationOverlayState extends State<_QuarterCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _close() {
    Narrator.hide('celebrate');
    widget.game.quarterCelebration.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.game.quarterCelebration.value;
    if (c == null) return const SizedBox.shrink();
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _close,
            child: Container(color: const Color(0xE60A1628)),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _confetti,
              builder: (context, _) => CustomPaint(painter: _WinConfettiPainter(_confetti.value)),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 140), // room for the narrator
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏘️🟩', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 4),
                    const Text('🙌 🎉 🕊️', style: TextStyle(fontSize: 28)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        children: [
                          _WinStatRow(emoji: '🌐🟩', label: '', value: '${c.percent} %'),
                          const SizedBox(height: 10),
                          _WinStatRow(emoji: '🏘️✝️', label: '', value: '${c.christians} / ${c.people}'),
                          const SizedBox(height: 10),
                          _WinStatRow(emoji: '⛪👥', label: '', value: '${c.church}'),
                          const SizedBox(height: 10),
                          _WinStatRow(emoji: '📅', label: '', value: '${c.day}'),
                          if (c.awakened) ...[
                            const SizedBox(height: 10),
                            const _WinStatRow(emoji: '🏰💥', label: '', value: '🔥✝️'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => ShareProgress.share(widget.game,
                                    shot: context.findAncestorStateOfType<_GameScreenState>()?._shotKey)
                                .catchError((_) {}),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Icon(Icons.adaptive.share, color: Colors.amber),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _close,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('✅', style: TextStyle(fontSize: 18)),
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
      ],
    );
  }
}
