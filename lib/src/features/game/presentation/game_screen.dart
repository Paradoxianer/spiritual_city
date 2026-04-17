import 'dart:async';
import 'dart:math' show atan2, pi;
import 'package:flame/components.dart' show Vector2;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../features/menu/domain/menu_service.dart';
import '../../../features/menu/domain/models/difficulty.dart';
import '../../../features/menu/domain/models/game_save.dart';
import '../domain/models/building_model.dart';
import '../domain/models/cell_object.dart';
import '../domain/models/npc_model.dart';
import '../domain/models/npc_reaction.dart';
import '../domain/services/faith_calculator_service.dart';
import '../presentation/components/building_component.dart';
import 'spirit_world_game.dart';

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;

  /// The save slot associated with this session.  Non-null for both new and
  /// loaded games (a fresh save is created before the screen is pushed).
  final GameSave? gameSave;

  const GameScreen({
    super.key,
    this.difficulty = Difficulty.normal,
    this.gameSave,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final SpiritWorldGame _game;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _game = SpiritWorldGame(
      difficulty: widget.difficulty,
      gameSave: widget.gameSave,
    );
  }

  /// Captures the current game state, persists it to Hive and returns to the
  /// main menu.
  Future<void> _saveAndQuit() async {
    final save = _game.gameSave;
    if (save == null) {
      if (mounted) context.go('/menu');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final state = _game.captureGameState();
      await getIt<MenuService>().updateSaveState(save.id, state);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        context.go('/menu');
      }
    }
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
              'BuildingInteriorOverlay': (context, game) =>
                  BuildingInteriorOverlay(game: _game),
              'LookOverlay': (context, game) => LookOverlay(game: _game),
              'MissionBoardOverlay': (context, game) =>
                  MissionBoardOverlay(game: _game),
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
          // Close (save & quit) button – only shown when the world is ready.
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return Positioned(
                top: 12,
                right: 12,
                child: SafeArea(
                  child: IconButton(
                    onPressed: _isSaving ? null : _saveAndQuit,
                    tooltip: AppStrings.get('game.saveQuit'),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ),
              );
            },
          ),
          // Pastorhouse HUD compass (shown when world is ready and house is far)
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return _PastorhouseHud(game: _game);
            },
          ),
          // Street-name label – persistent top-center
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return _StreetLabel(game: _game);
            },
          ),
          // Saving overlay – centered indicator shown while persisting to Hive.
          if (_isSaving)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save, size: 48, color: Colors.white70),
                    SizedBox(height: 16),
                    CircularProgressIndicator(
                      color: Colors.white70,
                      strokeWidth: 2,
                    ),
                  ],
                ),
              ),
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

  // Delta snapshot captured after each interaction for header display.
  double _lastNpcDelta = 0.0;
  double _lastPlayerDelta = 0.0;
  double _lastMaterialsDelta = 0.0;
  double _lastPlayerHealthDelta = 0.0;
  bool _showDelta = false;

  // ── Bible reading timer ───────────────────────────────────────────────────
  /// Remaining seconds of the bible-reading block (0 = not reading).
  int _bibleSecondsLeft = 0;
  Timer? _bibleTimer;

  /// Reading duration derived from the same difficulty factor used for costs:
  /// base 5 s × (1 / factor) → easy ≈ 3 s, normal = 5 s, hard = 10 s.
  int get _bibleDuration {
    final factor = FaithCalculatorService.difficultyFactorFor(widget.game.difficulty);
    return (5.0 / factor).round();
  }

  /// Whether the player is currently blocked by the bible-reading timer.
  bool get _isReadingBible => _bibleSecondsLeft > 0;

  @override
  void dispose() {
    _bibleTimer?.cancel();
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
    if (_isWaiting || _isSessionOver || _isReadingBible) return;

    // ── Bible reading: start blocking countdown, then process ─────────────
    if (type == 'bible') {
      _addMessage(emoji, true);
      setState(() {
        _bibleSecondsLeft = _bibleDuration;
        _showDelta = false;
      });
      _bibleTimer?.cancel();
      _bibleTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _bibleSecondsLeft--);
        if (_bibleSecondsLeft <= 0) {
          t.cancel();
          _processBibleResult();
        }
      });
      return;
    }

    _addMessage(emoji, true);
    setState(() {
      _isWaiting = true;
      _showDelta = false;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final model = widget.game.activeDialog?.npcModel;
      final reaction = widget.game.handleInteraction(type);
      _addMessage(reaction, false);

      // Capture deltas for header display.
      if (model != null) {
        setState(() {
          _isWaiting = false;
          _lastNpcDelta = model.lastNpcFaithDelta;
          _lastPlayerDelta = model.lastPlayerFaithDelta;
          _lastMaterialsDelta = model.lastMaterialsDelta;
          _lastPlayerHealthDelta = model.lastPlayerHealthDelta;
          _showDelta = true;
        });
      } else {
        setState(() => _isWaiting = false);
      }

      // Conversion success → session ends
      if (reaction == '✝️🕊️') {
        setState(() => _isSessionOver = true);
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) widget.game.closeDialog();
        });
        return;
      }

      // After 3 interactions: NPC sends farewell, then auto-close
      if (model != null && model.isReadyToLeave) {
        setState(() => _isSessionOver = true);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          final sessionReaction = NPCReaction.fromFaithLevel(
            model.faith,
            gotGift: model.hadGiftThisSession,
          );
          _addMessage('${sessionReaction.emoji}👋', false);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) widget.game.closeDialog();
          });
        });
      }
    });
  }

  /// Called after the bible-reading countdown expires.
  void _processBibleResult() {
    final model = widget.game.activeDialog?.npcModel;
    final reaction = widget.game.handleInteraction('bible');
    _addMessage(reaction, false);

    if (model != null) {
      setState(() {
        _lastNpcDelta = model.lastNpcFaithDelta;
        _lastPlayerDelta = model.lastPlayerFaithDelta;
        _lastMaterialsDelta = model.lastMaterialsDelta;
        _lastPlayerHealthDelta = model.lastPlayerHealthDelta;
        _showDelta = true;
      });
    }

    if (model != null && model.isReadyToLeave) {
      setState(() => _isSessionOver = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        final sessionReaction = NPCReaction.fromFaithLevel(
          model.faith,
          gotGift: model.hadGiftThisSession,
        );
        _addMessage('${sessionReaction.emoji}👋', false);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) widget.game.closeDialog();
        });
      });
    }
  }

  /// Formats a delta value as a signed string, e.g. "+3" or "-8".
  String _fmtDelta(double v) => v >= 0 ? '+${v.toStringAsFixed(0)}' : v.toStringAsFixed(0);

  /// Builds the delta text shown in the header after an interaction.
  Widget _buildDeltaRow() {
    final parts = <String>[];
    if (_lastNpcDelta != 0) parts.add('${_fmtDelta(_lastNpcDelta)}✝️');
    if (_lastPlayerDelta != 0) parts.add('${_fmtDelta(_lastPlayerDelta)}🙏');
    if (_lastPlayerHealthDelta != 0) parts.add('${_fmtDelta(_lastPlayerHealthDelta)}❤️');
    if (_lastMaterialsDelta != 0) parts.add('${_fmtDelta(_lastMaterialsDelta)}📦');
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join('  '),
      style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.w600),
    );
  }

  /// Progressive faith bar shown to the right of the chat.
  Widget _buildFaithBar(NPCModel model) {
    if (!model.isFaithVague) {
      // Not enough conversations yet – show a question mark placeholder.
      return SizedBox(
        width: 28,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✝️', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text('?', style: TextStyle(color: Colors.white38, fontSize: 9)),
              ),
            ),
          ],
        ),
      );
    }

    final faithNorm = ((model.faith + 100) / 200.0).clamp(0.0, 1.0);
    final barColor = Color.lerp(Colors.red[700]!, Colors.green[600]!, faithNorm)!;

    // Vague: round to nearest 25%; revealed: exact value.
    final displayNorm = model.isFaithRevealed
        ? faithNorm
        : ((faithNorm * 4).round() / 4.0).clamp(0.0, 1.0);

    const barHeight = 80.0;

    return SizedBox(
      width: 28,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✝️', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 8,
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 8,
                height: barHeight * displayNorm,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (model.isFaithRevealed)
            Text(
              model.faith.toStringAsFixed(0),
              style: const TextStyle(color: Colors.white60, fontSize: 9),
            )
          else
            const Text('~', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialog = widget.game.activeDialog;
    if (dialog == null) return const SizedBox.shrink();
    final model = dialog.npcModel;

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
            // ── Header ────────────────────────────────────────────────────────
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dialog.npcName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (_showDelta) _buildDeltaRow(),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isReadingBible ? null : () => widget.game.closeDialog(),
                  ),
                ],
              ),
            ),

            // ── Chat body + faith bar ─────────────────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  // Progressive faith reveal bar
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: _buildFaithBar(model),
                  ),
                ],
              ),
            ),

            // ── Action chips ──────────────────────────────────────────────────
            if (!_isSessionOver)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: _isReadingBible
                    // ── Bible reading in progress: show countdown ──────────────
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📖', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            '${_bibleSecondsLeft}s',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('📖', style: TextStyle(fontSize: 20)),
                        ],
                      )
                    // ── Normal action chips ────────────────────────────────────
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _EmojiChip(
                            emoji: '💬',
                            hint: '→✝️',
                            onTap: () => _handleInteraction('talk', '💬'),
                          ),
                          _EmojiChip(
                            emoji: '👂',
                            hint: '−❤️→✝️',
                            onTap: () => _handleInteraction('counsel', '👂'),
                          ),
                          _EmojiChip(
                            emoji: '🙏',
                            hint: '−🙏→✝️🌍',
                            onTap: () => _handleInteraction('pray', '🙏'),
                          ),
                          _EmojiChip(
                            emoji: '📖',
                            hint: '→🙏🙏+✝️',
                            onTap: () => _handleInteraction('bible', '📖'),
                          ),
                          if (model.wantsGift)
                            _EmojiChip(
                              emoji: '📦',
                              hint: '−8📦→✝️',
                              onTap: () => _handleInteraction('help', '📦'),
                            ),
                          _EmojiChip(
                            emoji: '✝️🕊️',
                            hint: '→?',
                            isSpecial: true,
                            onTap: () => _handleInteraction('convert', '✝️?'),
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

class _EmojiChip extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;
  final bool isSpecial;
  /// Short cost/benefit hint shown below the emoji, e.g. "→✝️" or "−8📦→✝️".
  final String? hint;

  const _EmojiChip({
    required this.emoji,
    required this.onTap,
    this.isSpecial = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionChip(
          label: Text(emoji, style: const TextStyle(fontSize: 22)),
          backgroundColor: isSpecial ? Colors.amber[800] : Colors.white70,
          onPressed: onTap,
          shape: StadiumBorder(side: BorderSide(color: isSpecial ? Colors.amber : Colors.transparent)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint!,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ],
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
  final NPCModel npcModel;
  GameDialogData({required this.npcName, required this.npcEmoji, required this.npcModel});
}

/// Data passed to the [LookOverlay].
class LookCellInfo {
  final String label;           // e.g. "Hauptstraße" or "Rathaus Nr. 12"
  final double spiritualState;  // -1..1
  final String? npcName;        // first NPC name seen in that cell, or null
  final String? streetName;     // nearest named road, or null

  const LookCellInfo({
    required this.label,
    required this.spiritualState,
    this.npcName,
    this.streetName,
  });
}

class GameLookData {
  final List<LookCellInfo> cells;
  final double playerSpiritualState;
  GameLookData({required this.cells, required this.playerSpiritualState});
}

// ── Street name HUD label ─────────────────────────────────────────────────────

/// Persistent top-center label showing the current street / address.
/// Only visible when there is a street name to display.
class _StreetLabel extends StatelessWidget {
  final SpiritWorldGame game;
  const _StreetLabel({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: game.currentStreetLabel,
      builder: (context, label, _) {
        if (label.isEmpty) return const SizedBox.shrink();
        return Positioned(
          top: 14,
          left: 60,
          right: 60,
          child: SafeArea(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Look Overlay ──────────────────────────────────────────────────────────────

/// Rich look overlay – shows spiritual state, building/NPC info, and street
/// info for all 8 neighbouring cells.  Activated by the 👀 radial-menu action.
class LookOverlay extends StatelessWidget {
  final SpiritWorldGame game;
  const LookOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final data = game.activeLookData;
    if (data == null) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.20,
      left: 24,
      right: 24,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Text('👀', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Umgebung',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  // Spiritual state indicator for the current cell
                  _SpiritualDot(state: data.playerSpiritualState),
                ],
              ),
              const SizedBox(height: 8),
              if (data.cells.isEmpty)
                Text(
                  'Nichts Besonderes in der Nähe.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12),
                )
              else
                ...data.cells.map((c) => _LookCellRow(cell: c)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpiritualDot extends StatelessWidget {
  final double state; // -1..1
  const _SpiritualDot({required this.state});

  @override
  Widget build(BuildContext context) {
    final Color col = state > 0
        ? Color.lerp(Colors.grey, Colors.amber, state)!
        : Color.lerp(Colors.grey, Colors.red, state.abs())!;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: col,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30),
      ),
    );
  }
}

class _LookCellRow extends StatelessWidget {
  final LookCellInfo cell;
  const _LookCellRow({required this.cell});

  @override
  Widget build(BuildContext context) {
    final spiritualPct = (cell.spiritualState * 100).round();
    final spiritualLabel = cell.spiritualState >= 0
        ? '+$spiritualPct%'
        : '$spiritualPct%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _SpiritualDot(state: cell.spiritualState),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cell.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                spiritualLabel,
                style: TextStyle(
                  color: cell.spiritualState >= 0
                      ? Colors.amber.withValues(alpha: 0.85)
                      : Colors.red.withValues(alpha: 0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (cell.npcName != null) ...[
                const SizedBox(width: 6),
                Text(
                  cell.npcName!,
                  style: TextStyle(
                    color: Colors.cyan.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          if (cell.streetName != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 1),
              child: Text(
                '🛣️ ${cell.streetName}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}


// ── Mission board data classes ─────────────────────────────────────────────────

/// A single mission entry shown in [MissionBoardOverlay].
class MissionEntry {
  final String targetEmoji;
  final String targetName;
  final String description;
  final int faithReward;
  final int materialsReward;
  /// Formatted address, e.g. "Lindenallee 14" or "Nr. 22". May be null.
  final String? address;

  const MissionEntry({
    required this.targetEmoji,
    required this.targetName,
    required this.description,
    required this.faithReward,
    required this.materialsReward,
    this.address,
  });
}

/// Data passed to [MissionBoardOverlay].
class MissionBoardData {
  final List<MissionEntry> entries;
  const MissionBoardData({required this.entries});
}

// ── Mission Board Overlay ─────────────────────────────────────────────────────

/// Shows all active missions as an emoji-styled list.
/// Opened from inside the pastor house via the '📋 Missionen' action.
class MissionBoardOverlay extends StatelessWidget {
  final SpiritWorldGame game;
  const MissionBoardOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final data = game.activeMissionBoardData;
    if (data == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.center,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.82,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2A1B).withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF2E4A2E),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Text('📋', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Aktive Missionen',
                      style: TextStyle(
                        color: Color(0xFFFFD54F),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => game.closeMissionBoard(),
                  ),
                ],
              ),
            ),
            // Mission list
            Flexible(
              child: data.entries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Derzeit keine aktiven Missionen.\nKomme wieder, um neue Aufgaben zu erhalten.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                            fontStyle: FontStyle.italic),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shrinkWrap: true,
                      itemCount: data.entries.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white12),
                      itemBuilder: (context, i) {
                        final m = data.entries[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.targetEmoji,
                                  style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      m.description,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    if (m.address != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        '📍 ${m.address}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                              alpha: 0.60),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '+${m.faithReward}🙏',
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '+${m.materialsReward}📦',
                                    style: const TextStyle(
                                      color: Colors.lightBlue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pastorhouse HUD compass ────────────────────────────────────────────────────

/// Shows a golden 🏠 icon + direction arrow when the pastor house is off-screen.
/// Renders as a [Positioned] overlay in the top-left corner with a subtle glow.
class _PastorhouseHud extends StatelessWidget {
  final SpiritWorldGame game;
  const _PastorhouseHud({required this.game});

  @override
  Widget build(BuildContext context) {
    // Rebuild whenever the player moves (playerWorldPosition updates every frame
    // via game.update()) so the compass direction is always current.
    return ValueListenableBuilder<Vector2>(
      valueListenable: game.playerWorldPosition,
      builder: (context, playerPx, _) {
        final housePx = game.pastorhousePosition.value;
        if (housePx == null) return const SizedBox.shrink();

        final dx = housePx.x - playerPx.x;
        final dy = housePx.y - playerPx.y;
        final distSq = dx * dx + dy * dy;
        // Hide only when the player is almost on top of the pastor house
        // (within 64 px ≈ 2 cells).
        if (distSq < 64 * 64) return const SizedBox.shrink();

        final angleDeg = atan2(dy, dx) * 180 / pi;
        final arrow = _directionArrow(angleDeg);

        return Positioned(
          // Position below the resource-bar panel (which ends at ≈ y 110).
          top: 114,
          left: 12,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏠', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    arrow,
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Maps an angle in degrees (−180…180) to an arrow Unicode character.
  /// Uses screen-space atan2 where Y grows downward:
  ///   0°=→  90°=↓  ±180°=←  −90°=↑
  String _directionArrow(double deg) {
    if (deg < -157.5 || deg >= 157.5) return '←';
    if (deg < -112.5) return '↖';
    if (deg < -67.5)  return '↑';
    if (deg < -22.5)  return '↗';
    if (deg <  22.5)  return '→';
    if (deg <  67.5)  return '↘';
    if (deg < 112.5)  return '↓';
    return '↙';
  }
}



// ── Interior art abstraction ──────────────────────────────────────────────────

/// Sealed type for a building's interior visual.
///
/// [EmojiGridArt] displays a fixed 12 × 12 top-down emoji grid (default).
/// Switching a building to [ImageArt] only requires changing its entry in
/// [_BuildingInteriorOverlayState._interiorArt] – no widget code changes.
sealed class InteriorArt {}

/// Emoji-grid art: a list of rows, each row a list of individual emoji/char
/// strings.  Every cell is rendered in a fixed-size box so the grid stays
/// perfectly aligned regardless of emoji width.
class EmojiGridArt extends InteriorArt {
  final List<List<String>> cells;
  EmojiGridArt(this.cells);
}

/// Pixel / raster art: rendered via [Image.asset].
class ImageArt extends InteriorArt {
  final String assetPath;
  ImageArt(this.assetPath);
}



// ── Building interior data & overlay ──────────────────────────────────────────

/// Data passed to the [BuildingInteriorOverlay] when a building is entered.
class GameBuildingData {
  final BuildingModel building;
  GameBuildingData({required this.building});
}

/// Overlay shown when the player enters a building.
///
/// Flow for residential buildings:
///   1. Access attempt (faith-based knock) → success / failure feedback.
///   2. On success: interior view + radial action chips.
///
/// For commercial / church buildings: skip directly to the interior view.
class BuildingInteriorOverlay extends StatefulWidget {
  final SpiritWorldGame game;
  const BuildingInteriorOverlay({super.key, required this.game});

  @override
  State<BuildingInteriorOverlay> createState() =>
      _BuildingInteriorOverlayState();
}

class _BuildingInteriorOverlayState extends State<BuildingInteriorOverlay> {
  /// Maximum height of the interior art widget.
  /// A 12 × 12 grid at _cellSize = 20 is 240 px; adding container padding
  /// yields ≈ 252 px — comfortably within this cap.
  static const double _maxInteriorArtHeight = 260.0;

  /// `null`  = access check not yet done (residential) or always-open
  /// `true`  = access granted
  /// `false` = access denied
  bool? _accessGranted;

  /// Latest action reaction emoji to display as feedback.
  String? _lastReaction;

  @override
  void initState() {
    super.initState();
    final data = widget.game.activeBuildingData;
    if (data == null) return;

    if (data.building.isAlwaysOpen) {
      _accessGranted = true;
    }
    // For residential buildings we show a knock screen first.
  }

  void _attemptKnock() {
    final data = widget.game.activeBuildingData;
    if (data == null) return;
    final granted = widget.game.attemptBuildingAccess(data.building);
    setState(() {
      _accessGranted = granted;
      _lastReaction = null;
    });
  }

  void _performAction(String actionType) {
    final result = widget.game.handleBuildingAction(actionType);
    setState(() => _lastReaction = result.reactionEmoji);
    // Auto-leave on success – but NOT for the pastor's own home (homebase),
    // where the player should stay as long as they like.
    final data = widget.game.activeBuildingData;
    if (result.success && (data == null || !data.building.isHomebase)) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) widget.game.closeBuildingInterior();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.game.activeBuildingData;
    if (data == null) return const SizedBox.shrink();

    final isHome = data.building.isHomebase;
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.82,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.70,
        ),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHome
              ? const Color(0xFF3E2723).withValues(alpha: 0.97)
              : const Color(0xFF1A237E).withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(20),
          border: isHome
              ? Border.all(color: const Color(0xFFFFD54F), width: 2.5)
              : null,
          boxShadow: isHome
              ? [
                  const BoxShadow(color: Colors.black54, blurRadius: 12),
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ]
              : const [BoxShadow(color: Colors.black54, blurRadius: 12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(data.building),
            if (_accessGranted == null)
              _buildKnockScreen(data.building)
            else if (_accessGranted == false)
              _buildDeniedScreen()
            else
              _buildInteriorScreen(data.building),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildingModel building) {
    final isHome = building.isHomebase;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHome ? const Color(0xFF4E342E) : const Color(0xFF283593),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Text(
            _buildingTypeEmoji(building.type),
            style: TextStyle(fontSize: isHome ? 32 : 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _buildingTypeName(building.type),
                      style: TextStyle(
                        color: isHome ? const Color(0xFFFFD54F) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isHome ? 19 : 17,
                      ),
                    ),
                    if (isHome) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFFFD54F).withValues(alpha: 0.6)),
                        ),
                        child: const Text(
                          'Mein Zuhause',
                          style: TextStyle(
                            color: Color(0xFFFFD54F),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (building.residents.isNotEmpty)
                  Text(
                    _residentSummaryLine(building),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => widget.game.closeBuildingInterior(),
          ),
        ],
      ),
    );
  }

  /// One-liner "Maria Müller (Bewohnerin) · Johannes Schmidt" for the header.
  String _residentSummaryLine(BuildingModel building) {
    final names = building.residents.map((r) => r.name.split(' ').first);
    return names.join(' · ');
  }

  // ── Knock screen (residential only) ──────────────────────────────────────

  Widget _buildKnockScreen(BuildingModel building) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚪', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            'Anklopfen?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _accessHint(building, widget.game.faith),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          // Show who might live here
          if (building.residents.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildResidentChips(building, compact: true),
          ],
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: const StadiumBorder(),
              ),
              icon: const Text('👊', style: TextStyle(fontSize: 22)),
              label: const Text('Anklopfen', style: TextStyle(fontSize: 16)),
              onPressed: _attemptKnock,
            ),
          ),
        ],
      ),
    );
  }

  String _accessHint(BuildingModel building, double faith) {
    final accessPercentage =
        (building.accessChance(faith) * 100).round();
    final bonus = building.totalConversations >= 3 ? ' (+30 % Bonus)' : '';
    return 'Erfolgschance: $accessPercentage %$bonus';
  }

  // ── Denied screen ─────────────────────────────────────────────────────────

  Widget _buildDeniedScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😤', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          const Text(
            'Niemand öffnet die Tür.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => widget.game.closeBuildingInterior(),
            child: const Text('Weggehen', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  // ── Interior screen ───────────────────────────────────────────────────────

  Widget _buildInteriorScreen(BuildingModel building) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reaction feedback
        if (_lastReaction != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _lastReaction!,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left: action menu ─────────────────────────────────────────
              SizedBox(
                width: 162,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 16),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildActionMenuRows(building),
                    ),
                  ),
                ),
              ),
              // Divider
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 10),
                color: Colors.white12,
              ),
              // ── Right: art + residents ────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 12, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: _maxInteriorArtHeight),
                        child: _InteriorArtWidget(art: _interiorArt(building.type)),
                      ),
                      if (building.residents.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildResidentChips(building, compact: true),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Action menu rows (left panel) ─────────────────────────────────────────

  /// Returns a vertical list of [_ActionMenuRow] widgets for [building].
  ///
  /// Each row shows: action emoji  →/←  effect emoji(s)
  /// A Tooltip (long-press mobile / hover desktop) reveals a German description.
  List<Widget> _buildActionMenuRows(BuildingModel building) {
    switch (building.type) {
      // ── Pastor's house ────────────────────────────────────────────────────
      case BuildingType.pastorHouse:
        return [
          _ActionMenuRow(leadingEmoji: '📖', arrowText: '→', trailingEmoji: '🙏MAX', tooltip: 'Bibel lesen (Glauben komplett auffüllen)', onTap: () => _performAction('readBible')),
          _ActionMenuRow(leadingEmoji: '🍽️', arrowText: '→', trailingEmoji: '🍞MAX', tooltip: 'Essen (Hunger komplett stillen)', onTap: () => _performAction('eat')),
          _ActionMenuRow(leadingEmoji: '😴', arrowText: '→', trailingEmoji: '❤️MAX', tooltip: 'Schlafen (Leben komplett auffüllen)', onTap: () => _performAction('sleep')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '→', trailingEmoji: '✨🌍', tooltip: 'Beten (massiver Einfluss auf die unsichtbare Welt)', onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '📋', arrowText: '→', trailingEmoji: '📜', tooltip: 'Missionsübersicht öffnen', onTap: () => _performAction('missions')),
        ];

      // ── Residential ───────────────────────────────────────────────────────
      case BuildingType.house:
      case BuildingType.apartment:
        return [
          _ActionMenuRow(leadingEmoji: '💬', arrowText: '→', trailingEmoji: '👥✝️', tooltip: 'Gespräch führen (+5 Glauben)', onTap: () => _performAction('talk')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '←', trailingEmoji: '❤️×5', tooltip: 'Für Familie beten (−5 HP, +15 Glauben)', onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '📦', arrowText: '←', trailingEmoji: '💰×10', tooltip: 'Hilfe anbieten (−10 Material, +10 Glauben)', onTap: () => _performAction('help')),
          _ActionMenuRow(leadingEmoji: '📖', arrowText: '←', trailingEmoji: '❤️×3💰×3', tooltip: 'Gemeinsam Bibel lesen (−3 HP, −3 Material, +10 Glauben)', onTap: () => _performAction('bible')),
        ];

      // ── Church ────────────────────────────────────────────────────────────
      case BuildingType.church:
      case BuildingType.cathedral:
        return [
          _ActionMenuRow(leadingEmoji: '📖', arrowText: '←', trailingEmoji: '💰×3', tooltip: 'Bibel lesen (−3 Material, +10 Glauben)', onTap: () => _performAction('readBible')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '←', trailingEmoji: '💰×3', tooltip: 'Gemeinsam beten (−3 Material, +15 Glauben)', onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '🎵', arrowText: '←', trailingEmoji: '💰×8', tooltip: 'Gottesdienst halten (−8 Material, +20 Glauben)', onTap: () => _performAction('worship')),
        ];

      // ── Hospital ──────────────────────────────────────────────────────────
      case BuildingType.hospital:
        return [
          _ActionMenuRow(leadingEmoji: '🤝', arrowText: '←', trailingEmoji: '💰×5', tooltip: 'Kranke besuchen (−5 Material, +12 Glauben)', onTap: () => _performAction('visitSick')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '←', trailingEmoji: '💰×3', tooltip: 'Für Heilung beten (−3 Material, +10 Glauben)', onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '💊', arrowText: '←', trailingEmoji: '💰×10', tooltip: 'Heilen lassen (−10 Material, +20 Glauben)', onTap: () => _performAction('heal')),
        ];

      // ── School / University ───────────────────────────────────────────────
      case BuildingType.school:
      case BuildingType.university:
        return [
          _ActionMenuRow(leadingEmoji: '📚', arrowText: '←', trailingEmoji: '💰×5', tooltip: 'Glauben lehren (−5 Material, +8 Glauben)', onTap: () => _performAction('teach')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '←', trailingEmoji: '💰×3', tooltip: 'Für Schüler beten (−3 Material, +10 Glauben)', onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '📦', arrowText: '←', trailingEmoji: '💰×8', tooltip: 'Material spenden (−8 Material, +10 Glauben)', onTap: () => _performAction('distribute')),
        ];

      // ── Cemetery ──────────────────────────────────────────────────────────
      case BuildingType.cemetery:
        return [
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '←', trailingEmoji: '💰×5', tooltip: 'Stille Andacht (−5 Material, +18 Glauben)', onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '🤝', arrowText: '←', trailingEmoji: '💰×3', tooltip: 'Trauernde trösten (−3 Material, +10 Glauben)', onTap: () => _performAction('comfort')),
        ];

      // ── Commercial ────────────────────────────────────────────────────────
      case BuildingType.shop:
      case BuildingType.supermarket:
      case BuildingType.mall:
      case BuildingType.office:
      case BuildingType.skyscraper:
        return [
          _ActionMenuRow(leadingEmoji: '💸', arrowText: '←', trailingEmoji: '💰↑↑', tooltip: 'Um Spende bitten (+20–40 Material)', onTap: () => _performAction('donate')),
          _ActionMenuRow(leadingEmoji: '💬', arrowText: '→', trailingEmoji: '👷✝️', tooltip: 'Mit Arbeiter sprechen (+5 Glauben)', onTap: () => _performAction('worker')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '←', trailingEmoji: '💰×3', tooltip: 'Für den Betrieb beten (−3 Material, +10 Glauben)', onTap: () => _performAction('prayBusiness')),
          _ActionMenuRow(leadingEmoji: '📦', arrowText: '←', trailingEmoji: '💰×5', tooltip: 'Material verteilen (−5 Material, +15 Glauben)', onTap: () => _performAction('distribute')),
        ];

      // ── Everything else ───────────────────────────────────────────────────
      default:
        return [
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '→', trailingEmoji: '🌿✝️', tooltip: 'Beten (+8 Glauben)', onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '💬', arrowText: '←', trailingEmoji: '💰×3', tooltip: 'Zeugnis geben (−3 Material, +10 Glauben)', onTap: () => _performAction('witness')),
          _ActionMenuRow(leadingEmoji: '📦', arrowText: '←', trailingEmoji: '💰×8', tooltip: 'Material verteilen (−8 Material, +12 Glauben)', onTap: () => _performAction('distribute')),
        ];
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Delegates to the static helpers in [BuildingComponent] to stay DRY.
  String _buildingTypeEmoji(BuildingType type) =>
      BuildingComponent.buildingEmoji(type);

  String _buildingTypeName(BuildingType type) =>
      BuildingComponent.buildingName(type);

  /// Builds a row of resident info chips showing name, role and faith level.
  Widget _buildResidentChips(BuildingModel building, {required bool compact}) {
    if (building.residents.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: building.residents.map((npc) {
        final faithEmoji = npc.faith > 50
            ? '✝️'
            : npc.faith > 0
                ? '😐'
                : '😔';
        final roleLabel = _npcRoleLabel(npc.type);
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(faithEmoji, style: TextStyle(fontSize: compact ? 12 : 14)),
              const SizedBox(width: 4),
              Text(
                compact ? npc.name.split(' ').first : npc.name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 4),
                Text(
                  '· $roleLabel',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  String _npcRoleLabel(NPCType type) {
    switch (type) {
      case NPCType.priest:    return 'Pastor';
      case NPCType.merchant:  return 'Händler';
      case NPCType.officer:   return 'Beamter';
      default:                return 'Bürger';
    }
  }

  /// Creates a 12 × 12 emoji grid for a top-down room view.
  ///
  /// Border cells (row / col 0 or 11) are drawn as walls ('▓'); all other
  /// cells default to floor ('·').  [items] overrides specific interior cells
  /// with themed emojis — keys are (row, col), values are emoji strings.
  static List<List<String>> _makeRoom(Map<(int, int), String> items) {
    const int n = 12;
    final g = List.generate(
      n,
      (r) => List.generate(
        n,
        (c) => (r == 0 || r == n - 1 || c == 0 || c == n - 1) ? '▓' : '·',
      ),
    );
    for (final e in items.entries) {
      g[e.key.$1.clamp(1, n - 2)][e.key.$2.clamp(1, n - 2)] = e.value;
    }
    return g;
  }

  /// Returns the [InteriorArt] for [type] — a fixed 12 × 12 top-down emoji
  /// grid.  Swapping to [ImageArt] only requires changing the return value.
  InteriorArt _interiorArt(BuildingType type) {
    switch (type) {
      // ── Residential ─────────────────────────────────────────────────────────
      case BuildingType.pastorHouse:
        return EmojiGridArt(_makeRoom({
          (1, 5): '✝️',
          (2, 2): '📚', (2, 9): '🛏️',
          (4, 4): '📖', (4, 8): '🕯️',
          (6, 5): '🙏',
          (8, 2): '🪴', (8, 8): '☕',
        }));
      case BuildingType.house:
        return EmojiGridArt(_makeRoom({
          (2, 2): '🛋️', (2, 8): '🛏️',
          (4, 5): '📺',
          (6, 2): '🍳', (6, 9): '🪑',
          (8, 4): '🪴', (8, 8): '🧸',
          (10, 5): '🐾',
        }));
      case BuildingType.apartment:
        return EmojiGridArt(_makeRoom({
          (2, 3): '🛏️', (2, 8): '🚿',
          (4, 6): '💻',
          (6, 2): '🛋️', (6, 8): '📺',
          (8, 4): '🍳', (8, 9): '☕',
          (10, 5): '🪴',
        }));
      // ── Religion ─────────────────────────────────────────────────────────────
      case BuildingType.church:
        return EmojiGridArt(_makeRoom({
          (1, 5): '✝️',
          (3, 2): '🕯️', (3, 9): '🕯️',
          (5, 5): '📖',
          (7, 2): '🪑', (7, 5): '🙏', (7, 9): '🪑',
          (9, 3): '🪑', (9, 8): '🪑',
        }));
      case BuildingType.cathedral:
        return EmojiGridArt(_makeRoom({
          (1, 5): '✝️',
          (2, 2): '🕯️', (2, 9): '🕯️',
          (3, 5): '🔔',
          (5, 3): '📖', (5, 8): '📖',
          (6, 5): '🙏',
          (8, 2): '🪑', (8, 9): '🪑',
          (10, 4): '🎵', (10, 7): '🎵',
        }));
      case BuildingType.cemetery:
        return EmojiGridArt(_makeRoom({
          (2, 3): '✝️', (2, 8): '✝️',
          (4, 1): '🌿', (4, 6): '✝️', (4, 10): '🌿',
          (6, 3): '🕯️', (6, 8): '🕯️',
          (8, 5): '⛪',
          (10, 2): '🌹', (10, 9): '🌹',
        }));
      // ── Health & Education ───────────────────────────────────────────────────
      case BuildingType.hospital:
        return EmojiGridArt(_makeRoom({
          (2, 2): '🛏️', (2, 7): '🛏️',
          (4, 4): '🩺',
          (6, 2): '💊', (6, 8): '🔬',
          (8, 5): '📋',
          (10, 2): '🏥', (10, 8): '🧴',
        }));
      case BuildingType.school:
        return EmojiGridArt(_makeRoom({
          (1, 5): '🖊️',
          (3, 2): '🪑', (3, 5): '🪑', (3, 9): '🪑',
          (6, 3): '📝', (6, 7): '📚',
          (8, 2): '🪑', (8, 5): '🪑', (8, 9): '🪑',
          (10, 5): '📐',
        }));
      case BuildingType.university:
        return EmojiGridArt(_makeRoom({
          (2, 3): '📚', (2, 8): '🔬',
          (4, 5): '🎓',
          (6, 2): '💻', (6, 9): '🗂️',
          (8, 4): '📖', (8, 8): '🧪',
          (10, 5): '🏛️',
        }));
      // ── Commercial ───────────────────────────────────────────────────────────
      case BuildingType.shop:
        return EmojiGridArt(_makeRoom({
          (2, 2): '📦', (2, 8): '📦',
          (4, 5): '🛒',
          (6, 2): '🏷️', (6, 5): '🛍️', (6, 9): '💰',
          (8, 3): '📦', (8, 8): '📦',
          (10, 5): '🪙',
        }));
      case BuildingType.supermarket:
        return EmojiGridArt(_makeRoom({
          (2, 2): '🥦', (2, 5): '🥩', (2, 9): '🥛',
          (4, 4): '🥫', (4, 8): '🍞',
          (6, 5): '🛒',
          (8, 2): '🧃', (8, 8): '🧴',
          (10, 4): '💳', (10, 7): '🧾',
        }));
      case BuildingType.mall:
        return EmojiGridArt(_makeRoom({
          (2, 2): '👗', (2, 9): '👟',
          (4, 5): '☕',
          (6, 2): '💎', (6, 5): '🛍️', (6, 9): '🍕',
          (8, 3): '👜', (8, 8): '🎁',
          (10, 5): '💳',
        }));
      case BuildingType.office:
        return EmojiGridArt(_makeRoom({
          (2, 2): '🖥️', (2, 8): '📁',
          (4, 5): '☕',
          (6, 2): '🪑', (6, 5): '📋', (6, 9): '🖊️',
          (8, 3): '📞', (8, 8): '💼',
          (10, 5): '📊',
        }));
      case BuildingType.skyscraper:
        return EmojiGridArt(_makeRoom({
          (2, 3): '📊', (2, 8): '💹',
          (4, 5): '💻',
          (6, 2): '📱', (6, 5): '🤝', (6, 9): '💼',
          (8, 3): '🖥️', (8, 8): '📋',
          (10, 5): '🏙️',
        }));
      // ── Industrial ───────────────────────────────────────────────────────────
      case BuildingType.factory:
        return EmojiGridArt(_makeRoom({
          (2, 2): '⚙️', (2, 8): '🔧',
          (4, 5): '⚡',
          (6, 2): '🔩', (6, 5): '📦', (6, 9): '🔨',
          (8, 3): '⚙️', (8, 8): '🪛',
          (10, 5): '🏭',
        }));
      case BuildingType.warehouse:
        return EmojiGridArt(_makeRoom({
          (2, 2): '📦', (2, 5): '📦', (2, 9): '📦',
          (4, 2): '📦', (4, 9): '📦',
          (5, 5): '📋',
          (7, 2): '📦', (7, 9): '📦',
          (9, 3): '🔦', (9, 7): '📦',
        }));
      case BuildingType.powerPlant:
        return EmojiGridArt(_makeRoom({
          (2, 2): '⚡', (2, 9): '⚡',
          (4, 4): '🔌', (4, 8): '🔌',
          (6, 5): '⚡',
          (8, 2): '🔧', (8, 5): '🔌', (8, 9): '🔧',
          (10, 5): '🏭',
        }));
      // ── Culture ──────────────────────────────────────────────────────────────
      case BuildingType.library:
        return EmojiGridArt(_makeRoom({
          (2, 1): '📚', (2, 4): '📚', (2, 8): '📚',
          (4, 1): '📚', (4, 10): '📚',
          (6, 4): '📖', (6, 7): '📖',
          (8, 2): '🪑', (8, 5): '📖', (8, 9): '🪑',
          (10, 5): '🔎',
        }));
      case BuildingType.museum:
        return EmojiGridArt(_makeRoom({
          (2, 2): '🖼️', (2, 9): '🖼️',
          (4, 5): '🏺',
          (6, 2): '🗿', (6, 9): '📜',
          (7, 5): '🔎',
          (8, 3): '🎭', (8, 8): '🪆',
          (10, 5): '🏛️',
        }));
      case BuildingType.stadium:
        return EmojiGridArt(_makeRoom({
          (2, 2): '📣', (2, 5): '⚽', (2, 9): '📣',
          (4, 5): '🏟️',
          (6, 2): '🏆', (6, 5): '🎫', (6, 9): '🎽',
          (8, 3): '🎵', (8, 8): '📸',
          (10, 5): '🏅',
        }));
      // ── Civic / Government ───────────────────────────────────────────────────
      case BuildingType.cityHall:
        return EmojiGridArt(_makeRoom({
          (2, 2): '⚖️', (2, 9): '📜',
          (4, 5): '🗳️',
          (6, 2): '📋', (6, 5): '🤝', (6, 9): '🏛️',
          (8, 3): '🖊️', (8, 8): '📁',
          (10, 5): '🔏',
        }));
      case BuildingType.postOffice:
        return EmojiGridArt(_makeRoom({
          (2, 2): '📮', (2, 9): '📫',
          (4, 5): '✉️',
          (6, 2): '📦', (6, 5): '💳', (6, 9): '📝',
          (8, 3): '📬', (8, 8): '🔖',
          (10, 5): '🏣',
        }));
      case BuildingType.policeStation:
        return EmojiGridArt(_makeRoom({
          (2, 2): '👮', (2, 9): '🔑',
          (4, 5): '🔵',
          (6, 2): '📋', (6, 5): '🔒', (6, 9): '📡',
          (8, 3): '🚓', (8, 8): '🔍',
          (10, 5): '🛡️',
        }));
      case BuildingType.fireStation:
        return EmojiGridArt(_makeRoom({
          (2, 2): '🧯', (2, 9): '🪓',
          (4, 5): '🔴',
          (6, 2): '🪣', (6, 5): '🚒', (6, 9): '📡',
          (8, 3): '🧰', (8, 8): '⛑️',
          (10, 5): '🔥',
        }));
      case BuildingType.trainStation:
        return EmojiGridArt(_makeRoom({
          (2, 2): '🚂', (2, 9): '🕐',
          (4, 5): '🎫',
          (6, 2): '🧳', (6, 5): '📋', (6, 9): '🚂',
          (8, 3): '🪑', (8, 8): '🗺️',
          (10, 5): '🚉',
        }));
    }
  }
}



/// A tappable action menu row shown in the left panel of the interior overlay.
///
/// Layout: `[leadingEmoji]  [arrowText]  [trailingEmoji]`
///
/// Arrow convention:
/// * `→`  the player performs an action whose benefit flows outward (faith,
///         influence, NPC boosts).
/// * `←`  the player receives something, but it costs a resource.
class _ActionMenuRow extends StatelessWidget {
  final String leadingEmoji;
  final String arrowText;
  final String trailingEmoji;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionMenuRow({
    required this.leadingEmoji,
    required this.arrowText,
    required this.trailingEmoji,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Row(
            children: [
              Text(leadingEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(
                arrowText,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trailingEmoji,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders an [InteriorArt] object.
///
/// [EmojiGridArt] is drawn as a grid of fixed-size cells so that every emoji
/// aligns perfectly regardless of its intrinsic glyph width.
/// [ImageArt] delegates to [Image.asset].
class _InteriorArtWidget extends StatelessWidget {
  final InteriorArt art;
  const _InteriorArtWidget({required this.art});

  static const double _cellSize = 20.0;

  @override
  Widget build(BuildContext context) {
    return switch (art) {
      // ── Emoji grid ─────────────────────────────────────────────────────────
      EmojiGridArt(:final cells) => Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(4),
          child: _buildGrid(cells),
        ),
      // ── Raster image ───────────────────────────────────────────────────────
      ImageArt(:final assetPath) => Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
    };
  }

  Widget _buildGrid(List<List<String>> cells) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: cells
          .map(
            (row) => Row(
              mainAxisSize: MainAxisSize.min,
              children: row
                  .map(
                    (cell) => SizedBox(
                      width: _cellSize,
                      height: _cellSize,
                      child: Center(
                        child: Text(
                          cell,
                          style: TextStyle(
                            fontSize: 14,
                            color: (cell == '▓' || cell == '·')
                                ? Colors.white.withValues(alpha: 0.38)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}
