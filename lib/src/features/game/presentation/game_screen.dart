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
  final List<_ChatMessage> _messages = [];
  bool _isWaiting = false;

  void _addMessage(String content, bool isPlayer) {
    setState(() {
      _messages.add(_ChatMessage(content: content, isPlayer: isPlayer));
    });
  }

  void _handleInteraction(String type, String emoji) {
    if (_isWaiting) return;
    
    _addMessage(emoji, true);
    setState(() => _isWaiting = true);

    // Verzögerung für NPC-Antwort
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final reaction = widget.game.handleInteraction(type);
      _addMessage(reaction, false);
      setState(() => _isWaiting = false);
      
      // Wenn Bekehrung erfolgreich, nach kurzer Zeit schließen
      if (reaction == '✨🕊️') {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) widget.game.closeDialog();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dialog = widget.game.activeDialog;
    if (dialog == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.45,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF075E54).withValues(alpha: 0.95), // WhatsApp Dark Green
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
        ),
        child: Column(
          children: [
            // Header (WhatsApp Style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF128C7E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.white24, child: Text(dialog.npcEmoji)),
                  const SizedBox(width: 12),
                  Text(
                    dialog.npcName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => widget.game.closeDialog(),
                  ),
                ],
              ),
            ),
            
            // Chat Area
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: const Color(0xFFECE5DD).withValues(alpha: 0.1), // WhatsApp BG
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _ChatBubble(message: _messages[index]),
                ),
              ),
            ),

            // Interaction Bar (Chips)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _InteractionChip(emoji: '🙏', label: 'Pray', onTap: () => _handleInteraction('pray', '🙏')),
                  _InteractionChip(emoji: '📦', label: 'Help', onTap: () => _handleInteraction('help', '📦')),
                  _InteractionChip(
                    emoji: '✨🕊️', 
                    label: 'Convert', 
                    isSpecial: true,
                    onTap: () => _handleInteraction('convert', '🕊️?'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isPlayer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: message.isPlayer ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(message.isPlayer ? 12 : 0),
            bottomRight: Radius.circular(message.isPlayer ? 0 : 12),
          ),
        ),
        child: Text(
          message.content,
          style: const TextStyle(fontSize: 22, color: Colors.black87),
        ),
      ),
    );
  }
}

class _InteractionChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  final bool isSpecial;
  
  const _InteractionChip({
    required this.emoji, 
    required this.label, 
    required this.onTap,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Text(emoji, style: const TextStyle(fontSize: 18)),
      label: Text(label, style: TextStyle(color: isSpecial ? Colors.white : Colors.black87, fontWeight: isSpecial ? FontWeight.bold : FontWeight.normal)),
      backgroundColor: isSpecial ? Colors.amber[800] : Colors.white70,
      onPressed: onTap,
      shape: StadiumBorder(side: BorderSide(color: isSpecial ? Colors.amber : Colors.transparent)),
    );
  }
}

class _ChatMessage {
  final String content;
  final bool isPlayer;
  _ChatMessage({required this.content, required this.isPlayer});
}

class GameDialogData {
  final String npcName;
  final String npcEmoji;
  GameDialogData({required this.npcName, required this.npcEmoji});
}
