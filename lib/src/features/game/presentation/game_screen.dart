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
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dialog.emoji,
              style: const TextStyle(fontSize: 50),
            ),
            const SizedBox(height: 10),
            Text(
              dialog.title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (dialog.rewardEmoji != null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dialog.rewardEmoji!, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 10),
                  const Text('+5', style: TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => game.closeDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameDialogData {
  final String title;
  final String emoji;
  final String? rewardEmoji;
  GameDialogData({required this.title, required this.emoji, this.rewardEmoji});
}
