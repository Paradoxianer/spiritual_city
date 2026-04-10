import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'spirit_world_game.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final SpiritWorldGame _game;

  @override
  void initState() {
    super.initState();
    _game = SpiritWorldGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(
            game: _game,
            overlayBuilderMap: {
              'DialogOverlay': (context, game) => DialogOverlay(game: _game),
            },
            loadingBuilder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}

class DialogOverlay extends StatelessWidget {
  final SpiritWorldGame game;
  const DialogOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final dialog = game.activeDialog;
    if (dialog == null) return const SizedBox.shrink();

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 50),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(dialog.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    dialog.title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 20),
            // Chat-ähnliche Emojis als Antwortmöglichkeiten
            Wrap(
              spacing: 15,
              children: [
                _InteractionOption(emoji: '🙏', label: 'Bete', onTap: () => game.closeDialog()),
                _InteractionOption(emoji: '📦', label: 'Hilf', onTap: () => game.closeDialog()),
                _InteractionOption(emoji: '👋', label: 'Ciao', onTap: () => game.closeDialog()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractionOption extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _InteractionOption({required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

class GameDialogData {
  final String title;
  final String emoji;
  GameDialogData({required this.title, required this.emoji});
}
