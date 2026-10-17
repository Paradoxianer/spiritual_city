part of '../game_screen.dart';

/// Step-by-step tutorial overlay shown to new players.
///
/// Displays a speech bubble with the current tutorial step message, a "Weiter"
/// button for steps that require manual advance, and an "Überspringen" button
/// from step 4 onward. The final step shows a simple confetti celebration.
class _TutorialOverlay extends StatefulWidget {
  final SpiritWorldGame game;
  const _TutorialOverlay({required this.game});

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    widget.game.tutorialService.currentStepNotifier.addListener(_onStepChanged);
  }

  void _onStepChanged() {
    if (!mounted) return;
    final step = widget.game.tutorialService.currentStep;
    if (step == TutorialStep.completed) {
      _confettiCtrl.forward(from: 0.0);
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.game.tutorialService.currentStepNotifier.removeListener(_onStepChanged);
    _confettiCtrl.dispose();
    super.dispose();
  }

  // ── Step content ─────────────────────────────────────────────────────────

  static const _stepMeta =
      <TutorialStep, ({String emoji, bool needsNextButton, bool hasTrigger, bool isInteractive})>{
    TutorialStep.welcome: (
      emoji: '✝️',
      needsNextButton: true,
      hasTrigger: false,
      isInteractive: false
    ),
    TutorialStep.movement: (
      emoji: '🗺️',
      needsNextButton: false,
      hasTrigger: true,
      isInteractive: true
    ),
    TutorialStep.spiritWorld: (
      emoji: '🙏',
      needsNextButton: false,
      hasTrigger: true,
      isInteractive: true
    ),
    TutorialStep.prayer: (
      emoji: '⚡',
      needsNextButton: false,
      hasTrigger: true,
      isInteractive: true
    ),
    TutorialStep.returnToCity: (
      emoji: '🏙️',
      needsNextButton: false,
      hasTrigger: true,
      isInteractive: true
    ),
    TutorialStep.radialMenu: (
      emoji: '🖐️',
      needsNextButton: false,
      hasTrigger: true,
      isInteractive: true
    ),
    TutorialStep.npcTalk: (
      emoji: '💬',
      needsNextButton: true,
      hasTrigger: false,
      isInteractive: true
    ),
    TutorialStep.hudExplain: (
      emoji: '📊',
      needsNextButton: true,
      hasTrigger: false,
      isInteractive: false
    ),
    TutorialStep.homebase: (
      emoji: '🏠',
      needsNextButton: false,
      hasTrigger: true,
      isInteractive: true
    ),
    TutorialStep.firstMission: (
      emoji: '📋',
      needsNextButton: false,
      hasTrigger: true,
      isInteractive: true
    ),
    TutorialStep.completed: (
      emoji: '🎉',
      needsNextButton: true,
      hasTrigger: false,
      isInteractive: false
    ),
  };

  static ({String emoji, String title, String message, String? triggerHint, bool needsNextButton})?
      _contentFor(TutorialStep step) {
    final meta = _stepMeta[step];
    if (meta == null) return null;
    return (
      emoji: meta.emoji,
      title: AppStrings.get('tutorial.${step.name}.title'),
      message: AppStrings.get('tutorial.${step.name}.message'),
      triggerHint: meta.hasTrigger ? AppStrings.get('tutorial.${step.name}.trigger') : null,
      needsNextButton: meta.needsNextButton,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TutorialStep?>(
      valueListenable: widget.game.tutorialService.currentStepNotifier,
      builder: (context, step, _) {
        if (step == null) return const SizedBox.shrink();

        final content = _contentFor(step);
        if (content == null) return const SizedBox.shrink();

        final meta = _stepMeta[step]!;
        final isCompleted = step == TutorialStep.completed;
        final canSkip = widget.game.tutorialService.canSkip;

        final card = _buildCard(content, isCompleted, canSkip);

        if (meta.isInteractive) {
          // ── Interactive step: card pinned to top, background non-blocking ─
          // The joystick (bottom-left) and HUD buttons (bottom-right) remain
          // fully touchable because the background uses IgnorePointer.
          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.28),
                  ),
                ),
              ),
              // Card at top (below safe-area / HUD)
              Align(
                alignment: Alignment.topCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
                    child: Material(
                      type: MaterialType.transparency,
                      child: card,
                    ),
                  ),
                ),
              ),
              // Step dots just above the joystick row – non-blocking
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: _TutorialStepDots(currentStep: step),
                ),
              ),
            ],
          );
        }

        // ── Info / blocking step: full-screen overlay (current behaviour) ──
        return Stack(
          children: [
            // Semi-transparent dark background
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(
                  alpha: isCompleted ? 0.75 : 0.55,
                ),
              ),
            ),
            // Confetti (completion step only)
            if (isCompleted)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (context, _) => CustomPaint(
                    painter: _ConfettiPainter(_confettiCtrl.value),
                  ),
                ),
              ),
            // Centered card
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Material(
                  type: MaterialType.transparency,
                  child: card,
                ),
              ),
            ),
            // Step indicator dots
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: _TutorialStepDots(currentStep: step),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(
    ({
      String emoji,
      String title,
      String message,
      String? triggerHint,
      bool needsNextButton
    }) content,
    bool isCompleted,
    bool canSkip,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xEE0A1A0A) : const Color(0xEE080818),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? Colors.greenAccent.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? Colors.greenAccent : Colors.purpleAccent).withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji
          Text(
            content.emoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 6),
          // Title
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          // Message
          Text(
            content.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          // Trigger hint (auto-advance steps)
          if (content.triggerHint != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                content.triggerHint!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.amber.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Buttons
          if (content.needsNextButton || isCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCompleted
                    ? () {
                        widget.game.tutorialService.completeTutorial();
                        getIt<MenuService>().markTutorialCompleted();
                      }
                    : widget.game.tutorialService.nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.green.shade700 : Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(isCompleted
                    ? AppStrings.get('tutorial.start')
                    : AppStrings.get('tutorial.next')),
              ),
            ),
          if (canSkip && !isCompleted) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                widget.game.tutorialService.skipTutorial();
                getIt<MenuService>().markTutorialCompleted();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.45),
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: Text(AppStrings.get('tutorial.skip')),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Step indicator dots ───────────────────────────────────────────────────────

class _TutorialStepDots extends StatelessWidget {
  final TutorialStep currentStep;
  const _TutorialStepDots({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final total = TutorialStep.values.length;
    final current = currentStep.index;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        final done = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: active ? 20 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active
                ? Colors.white.withValues(alpha: 0.9)
                : done
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.18),
          ),
        );
      }),
    );
  }
}

// ── Confetti painter ──────────────────────────────────────────────────────────
