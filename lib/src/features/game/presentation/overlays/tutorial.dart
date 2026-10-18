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
  TutorialStep? _shown;

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    return ValueListenableBuilder<TutorialStep?>(
      valueListenable: g.tutorialService.currentStepNotifier,
      builder: (context, step, _) {
        if (step == null || g.interior != null && step != TutorialStep.readBible &&
            step != TutorialStep.mission) {
          return const SizedBox.shrink();
        }
        // A new step opens its explanation once.
        if (step != _shown) {
          _shown = step;
          _open = true;
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

/// Direction to the current tutorial target (pastor house, a person).
class _Arrow extends StatelessWidget {
  final SpiritWorldGame game;
  const _Arrow({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Vector2>(
      valueListenable: game.playerWorldPosition,
      builder: (context, me, _) {
        final t = game.tutorialTargetPosition;
        if (t == null || game.interior != null) return const SizedBox.shrink();
        final dx = t.x - me.x, dy = t.y - me.y;
        if (dx * dx + dy * dy < 64 * 64) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            '📍${_directionArrow(atan2(dy, dx) * 180 / pi)}',
            style: const TextStyle(color: Color(0xFF80DEEA), fontSize: 15, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
