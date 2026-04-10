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

class DialogOverlay extends StatefulWidget {
  final SpiritWorldGame game;
  const DialogOverlay({super.key, required this.game});

  @override
  State<DialogOverlay> createState() => _DialogOverlayState();
}

class _DialogOverlayState extends State<DialogOverlay> {
  String? _reactionEmoji;

  void _handleInteraction(String type) {
    setState(() {
      _reactionEmoji = widget.game.handleInteraction(type);
    });
    
    // Kurze Verzögerung bevor der Dialog schließt, damit man die Reaktion sieht
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) widget.game.closeDialog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dialog = widget.game.activeDialog;
    if (dialog == null) return const SizedBox.shrink();

    return Center(
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nur der Name als Header
            Text(
              dialog.npcName,
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            
            // NPC Emoji oder Reaktion
            Container(
              height: 60,
              alignment: Alignment.center,
              child: Text(
                _reactionEmoji ?? dialog.npcEmoji, 
                style: const TextStyle(fontSize: 40)
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Interaktions-Buttons (nur wenn keine Reaktion aktiv ist)
            if (_reactionEmoji == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _InteractionButton(emoji: '🙏', onTap: () => _handleInteraction('pray')),
                  _InteractionButton(emoji: '📦', onTap: () => _handleInteraction('help')),
                  _InteractionButton(emoji: '👋', onTap: () => widget.game.closeDialog()),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;
  const _InteractionButton({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

class GameDialogData {
  final String npcName;
  final String npcEmoji;
  GameDialogData({required this.npcName, required this.npcEmoji});
}
