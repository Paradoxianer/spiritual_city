import 'dart:async';
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
          ),
          // Loading overlay – shown until the world is ready
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (isReady) return const SizedBox.shrink();
              return const _LoadingOverlay();
            },
          ),
        ],
      ),
    );
  }
}

/// Animated spiritual loading screen shown while the city generates.
class _LoadingOverlay extends StatefulWidget {
  const _LoadingOverlay();

  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _verses = [
    '"Der Herr ist mein Hirte" – Psalm 23,1',
    '"Bittet, so wird euch gegeben" – Mt 7,7',
    '"Die Wahrheit wird euch frei machen" – Joh 8,32',
    '"Ich kann alles durch Christus" – Phil 4,13',
    '"Gott ist Liebe" – 1 Joh 4,8',
  ];

  int _verseIndex = 0;
  Timer? _verseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Cycle through Bible verses every 2.5 s – use a cancellable Timer
    _verseTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        setState(() => _verseIndex = (_verseIndex + 1) % _verses.length);
      }
    });
  }

  @override
  void dispose() {
    _verseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = _controller.value;
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing cross / spiritual symbol
                Opacity(
                  opacity: 0.5 + pulse * 0.5,
                  child: Text(
                    '✝',
                    style: TextStyle(
                      fontSize: 64 + pulse * 12,
                      color: Colors.amber,
                      shadows: [
                        Shadow(
                          color: Colors.amber.withValues(alpha: 0.6),
                          blurRadius: 20 + pulse * 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'SPIRITWORLD CITY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Die Stadt erwacht...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),
                // Glowing progress dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final dotPhase = (pulse + i / 3) % 1.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.purpleAccent.withValues(
                            alpha: 0.3 + dotPhase * 0.7,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purpleAccent.withValues(alpha: dotPhase * 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                // Bible verse
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Text(
                    _verses[_verseIndex],
                    key: ValueKey(_verseIndex),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
  final ScrollController _scrollController = ScrollController();
  bool _isWaiting = false;
  bool _isSessionOver = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addMessage(String content, bool isPlayer) {
    setState(() {
      _messages.add(_ChatMessage(content: content, isPlayer: isPlayer));
    });
    _scrollToBottom();
  }

  void _handleInteraction(String type, String emoji) {
    if (_isWaiting || _isSessionOver) return;
    
    _addMessage(emoji, true);
    setState(() => _isWaiting = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final reaction = widget.game.handleInteraction(type);
      _addMessage(reaction, false);
      setState(() => _isWaiting = false);
      
      // Check for session end (👋) - 5 Sekunden Zeit zum Lesen
      if (reaction == '👋') {
        setState(() => _isSessionOver = true);
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) widget.game.closeDialog();
        });
      }

      // Wenn Bekehrung erfolgreich (✝️ statt ✨)
      if (reaction == '✝️🕊️') {
        setState(() => _isSessionOver = true);
        Future.delayed(const Duration(seconds: 5), () {
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
          color: const Color(0xFF075E54).withValues(alpha: 0.95), 
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
        ),
        child: Column(
          children: [
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
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: const Color(0xFFECE5DD).withValues(alpha: 0.1),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _ChatBubble(message: _messages[index]),
                ),
              ),
            ),

            if (!_isSessionOver)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _InteractionChip(emoji: '💬', label: 'Talk', onTap: () => _handleInteraction('talk', '💬')),
                      const SizedBox(width: 8),
                      _InteractionChip(emoji: '🙏', label: 'Pray', onTap: () => _handleInteraction('pray', '🙏')),
                      const SizedBox(width: 8),
                      _InteractionChip(emoji: '📦', label: 'Help', onTap: () => _handleInteraction('help', '📦')),
                      const SizedBox(width: 8),
                      _InteractionChip(
                        emoji: '✝️🕊️', 
                        label: 'Convert', 
                        isSpecial: true,
                        onTap: () => _handleInteraction('convert', '✝️?'),
                      ),
                    ],
                  ),
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
