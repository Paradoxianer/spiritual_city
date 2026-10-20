part of '../game_screen.dart';

/// Full-screen pause menu – the single place to reach Help, Save and
/// Save & Quit.  Opened via the pause button (top-right), the Escape key or
/// the Android/desktop back gesture (see [GameScreen]'s `PopScope`).
class PauseMenuOverlay extends StatelessWidget {
  final SpiritWorldGame game;
  final bool isSaving;
  final Future<void> Function() onSave;
  final Future<void> Function() onSaveAndQuit;

  const PauseMenuOverlay({
    super.key,
    required this.game,
    required this.isSaving,
    required this.onSave,
    required this.onSaveAndQuit,
  });

  Future<void> _confirmSaveAndQuit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('game.pause.quitConfirm.title')),
        content: Text(AppStrings.get('game.pause.quitConfirm.body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.get('game.pause.quitConfirm.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.get('game.pause.quitConfirm.confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true) await onSaveAndQuit();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          color: Colors.black.withValues(alpha: 0.88),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⏸️', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.get('game.pause.title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _PauseMenuButton(
                        icon: Icons.play_arrow,
                        label: AppStrings.get('game.pause.resume'),
                        onPressed: game.closePauseMenu,
                        filled: true,
                      ),
                      const SizedBox(height: 12),
                      _PauseMenuButton(
                        icon: Icons.save_outlined,
                        label: AppStrings.get('game.pause.save'),
                        onPressed: isSaving ? null : onSave,
                      ),
                      const SizedBox(height: 12),
                      _PauseMenuButton(
                        icon: Icons.help_outline,
                        label: AppStrings.get('game.pause.help'),
                        onPressed: () {
                          game.closePauseMenu();
                          game.openHelp(fromPause: true);
                        },
                      ),
                      const SizedBox(height: 12),
                      // Sound on/off – emoji only, no label to translate.
                      StatefulBuilder(
                        builder: (context, setState) => IconButton(
                          iconSize: 30,
                          onPressed: () async {
                            await getIt<MenuService>().setSoundOn(!GameSound.enabled);
                            setState(() {});
                          },
                          icon: Text(
                            GameSound.enabled ? '🔊' : '🔇',
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      if (game.tutorialService.isActive) ...[
                        const SizedBox(height: 12),
                        _PauseMenuButton(
                          icon: Icons.skip_next,
                          label: AppStrings.get('tutorial.skip'),
                          onPressed: () {
                            game.tutorialService.skipTutorial();
                            game.closePauseMenu();
                          },
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        _PauseMenuButton(
                          icon: Icons.school,
                          label: AppStrings.get('tutorial.restart'),
                          onPressed: () {
                            game.tutorialService.restartTutorial();
                            game.closePauseMenu();
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      _PauseMenuButton(
                        icon: Icons.logout,
                        label: AppStrings.get('game.pause.quit'),
                        onPressed: isSaving ? null : () => _confirmSaveAndQuit(context),
                      ),
                    ],
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

/// A single full-width row in the [PauseMenuOverlay], sized generously for
/// touch (Issue #174: touch targets ≥ 48 dp).
class _PauseMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final FutureOr<void> Function()? onPressed;
  final bool filled;

  const _PauseMenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = (filled ? FilledButton.styleFrom : OutlinedButton.styleFrom)(
      minimumSize: const Size.fromHeight(52),
      foregroundColor: filled ? null : Colors.white,
      side: filled ? null : const BorderSide(color: Colors.white38),
    );
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
    return SizedBox(
      width: double.infinity,
      child: filled
          ? FilledButton(onPressed: onPressed, style: style, child: child)
          : OutlinedButton(onPressed: onPressed, style: style, child: child),
    );
  }
}

/// A single row in the keymap table showing a key label and its action.
class _KeyRow extends StatelessWidget {
  final KeymapEntry entry;
  const _KeyRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Key label badge
          Container(
            constraints: const BoxConstraints(minWidth: 130),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              entry.keys,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Action description
          Expanded(
            child: Text(
              entry.localizedAction,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pastorhouse HUD compass ────────────────────────────────────────────────────
