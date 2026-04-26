import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' show atan2, pi;
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../features/menu/domain/menu_service.dart';
import '../domain/models/base_interactable_entity.dart';
import '../domain/models/building_model.dart';
import '../domain/models/cell_object.dart';
import '../domain/models/game_keymap.dart';
import '../domain/models/npc_model.dart';
import '../domain/models/npc_reaction.dart';
import '../domain/services/building_interaction_service.dart';
import '../domain/services/faith_calculator_service.dart';
import '../presentation/components/building_component.dart';
import 'spirit_world_game.dart';

/// Whether keyboard shortcut hint badges should be shown on action buttons.
/// True on desktop (Windows / Linux / macOS) and web; false on mobile.
bool _shouldShowKeyHints() {
  if (kIsWeb) return true;
  try {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  } catch (_) {
    return false;
  }
}

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
              'KeymapOverlay': (context, game) =>
                  KeymapOverlay(game: _game),
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
          // Keymap help button – small "?" icon, bottom-right, only when world is ready.
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return Positioned(
                bottom: 12,
                right: 12,
                child: SafeArea(
                  child: IconButton(
                    onPressed: _game.toggleKeymapOverlay,
                    tooltip: 'Tastenbelegung (F1 / ?)',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.help_outline),
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
          // Resource HUD – Flutter widget so bars update even while the Flame
          // game loop is paused (building / dialog overlays open).
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return _ResourceHud(game: _game);
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
          // Loot pickup toast – briefly shown when a material package is collected
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return _LootToast(game: _game);
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
  /// Material cost for the "help" (gift) action.  Single source of truth used
  /// by both the chip [isDisabled] check and [_isChipActionDisabled].
  static const double _helpMaterialCost = 8.0;

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
  void initState() {
    super.initState();
    widget.game.dialogActionIndex.addListener(_onDialogKey);
  }

  @override
  void dispose() {
    widget.game.dialogActionIndex.removeListener(_onDialogKey);
    _bibleTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Called when the player presses digit 1–6 while the dialog is open.
  ///
  /// Uses fixed slot positions so the key numbers never shift when optional
  /// chips (help / convert) are hidden. Disabled chips are silently skipped.
  void _onDialogKey() {
    final idx = widget.game.dialogActionIndex.value;
    if (idx < 0) return;
    final model = widget.game.activeDialog?.npcModel;
    if (model == null) return;
    final entry = _slotAction(idx, model);
    if (entry == null) return; // slot unavailable for this NPC state
    final (type, emoji) = entry;
    if (_isChipActionDisabled(type)) return; // grayed-out: ignore shortkey
    _handleInteraction(type, emoji);
  }

  /// Maps a fixed slot index (0–5 from keys 1–6) to an action (type, emoji),
  /// or null if the slot is unavailable for [model]'s current state.
  ///
  /// Slots are always:  0=talk  1=counsel  2=pray  3=bible  4=help  5=convert
  /// This keeps key numbers stable even when conditional chips are hidden.
  static (String, String)? _slotAction(int slotIndex, NPCModel model) {
    switch (slotIndex) {
      case 0: return ('talk',    '💬');
      case 1: return ('counsel', '👂');
      case 2: return ('pray',    '🙏');
      case 3: return ('bible',   '📖');
      case 4: return model.wantsGift    ? ('help',    '📦')  : null;
      case 5: return model.isChristian  ? null        : ('convert', '✝️?');
      default: return null;
    }
  }

  /// Returns true when [type] is currently disabled due to insufficient
  /// resources, mirroring the [isDisabled] logic of the rendered chips.
  bool _isChipActionDisabled(String type) {
    final factor = FaithCalculatorService.difficultyFactorFor(
        widget.game.difficulty);
    switch (type) {
      case 'counsel':
        final hpCost = (2.0 / factor).round().clamp(1, 99);
        return widget.game.health <= hpCost;
      case 'pray':
        final faithCost = (2.0 / factor).round().clamp(1, 99);
        return widget.game.faith < faithCost;
      case 'help':
        return widget.game.materials < _helpMaterialCost;
      default:
        return false;
    }
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
            _InteractionHeader(
              bgColor: const Color(0xFF128C7E),
              verticalPadding: 10,
              leading: CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(dialog.npcEmoji),
              ),
              title: dialog.npcName,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              subtitle: _showDelta ? _buildDeltaRow() : null,
              sessionDone: model.currentSessionInteractions,
              sessionMax: model.maxSessionInteractions,
              onClose: _isReadingBible ? null : () => widget.game.closeDialog(),
              closeIconColor: Colors.white,
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
                    child: _FaithBarWidget(entity: model),
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
                    : Builder(builder: (context) {
                        // Compute resource costs once for disabled-state checks.
                        final factor = FaithCalculatorService.difficultyFactorFor(
                            widget.game.difficulty);
                        final counselHpCost =
                            (2.0 / factor).round().clamp(1, 99);
                        final prayFaithCost =
                            (2.0 / factor).round().clamp(1, 99);
                        const helpMaterialCost = _helpMaterialCost;

                        // Fixed key indices: talk=1, counsel=2, pray=3,
                        // bible=4, help=5, convert=6. The numbers are stable
                        // even when optional chips (help/convert) are hidden.
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _EmojiChip(
                              emoji: '💬',
                              hint: '→✝️',
                              keyIndex: 1,
                              onTap: () => _handleInteraction('talk', '💬'),
                            ),
                            _EmojiChip(
                              emoji: '👂',
                              hint: '−❤️→✝️',
                              keyIndex: 2,
                              isDisabled:
                                  widget.game.health <= counselHpCost,
                              onTap: () =>
                                  _handleInteraction('counsel', '👂'),
                            ),
                            _EmojiChip(
                              emoji: '🙏',
                              hint: '−🙏→✝️🌍',
                              keyIndex: 3,
                              isDisabled:
                                  widget.game.faith < prayFaithCost,
                              onTap: () => _handleInteraction('pray', '🙏'),
                            ),
                            _EmojiChip(
                              emoji: '📖',
                              hint: '→🙏🙏+✝️',
                              keyIndex: 4,
                              onTap: () =>
                                  _handleInteraction('bible', '📖'),
                            ),
                            if (model.wantsGift)
                              _EmojiChip(
                                emoji: '📦',
                                hint: '−8📦→✝️',
                                keyIndex: 5,
                                isDisabled: widget.game.materials <
                                    helpMaterialCost,
                                onTap: () =>
                                    _handleInteraction('help', '📦'),
                              ),
                            if (!model.isChristian)
                              _EmojiChip(
                                emoji: '✝️🕊️',
                                hint: '→?',
                                keyIndex: 6,
                                isSpecial: true,
                                onTap: () =>
                                    _handleInteraction('convert', '✝️?'),
                              ),
                          ],
                        );
                      }),
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
  final bool isDisabled;
  /// Short cost/benefit hint shown below the emoji, e.g. "→✝️" or "−8📦→✝️".
  final String? hint;
  /// 1-based keyboard shortcut shown as an amber badge (null = no badge).
  final int? keyIndex;

  const _EmojiChip({
    required this.emoji,
    required this.onTap,
    this.isSpecial = false,
    this.isDisabled = false,
    this.hint,
    this.keyIndex,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = keyIndex != null && _shouldShowKeyHints();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ActionChip(
              label: Text(emoji, style: const TextStyle(fontSize: 22)),
              backgroundColor: isDisabled
                  ? Colors.red[900]?.withValues(alpha: 0.35)
                  : (isSpecial ? Colors.amber[800] : Colors.white70),
              onPressed: isDisabled ? null : onTap,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isDisabled
                      ? Colors.red
                      : (isSpecial ? Colors.amber : Colors.transparent),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            if (showBadge)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFA000), // amber 700
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$keyIndex',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(
            hint!,
            style: TextStyle(
              color: isDisabled ? Colors.red[300] : Colors.white70,
              fontSize: 10,
            ),
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

// ── Loot Pickup Toast ─────────────────────────────────────────────────────────

/// Brief bottom-center toast shown when the player auto-collects a material
/// package on the street.  It fades in, stays for 2 s, then fades out.
/// Tapping it (or any key that fires a tap) dismisses it immediately.
class _LootToast extends StatefulWidget {
  final SpiritWorldGame game;
  const _LootToast({required this.game});

  @override
  State<_LootToast> createState() => _LootToastState();
}

class _LootToastState extends State<_LootToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  Timer? _dismissTimer;
  String? _message;

  static const Duration _fadeDuration = Duration(milliseconds: 250);
  static const Duration _visibleDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _fadeDuration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    widget.game.lootPickupMessage.addListener(_onMessage);
  }

  void _onMessage() {
    final msg = widget.game.lootPickupMessage.value;
    if (msg == null || !mounted) return;
    _dismissTimer?.cancel();
    setState(() => _message = msg);
    _ctrl.forward(from: 0.0);
    _dismissTimer = Timer(_visibleDuration, _dismiss);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _ctrl.reverse().then((_) {
      if (mounted) {
        widget.game.lootPickupMessage.value = null;
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    widget.game.lootPickupMessage.removeListener(_onMessage);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_message == null) return const SizedBox.shrink();
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xCC1B2A1B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 8),
                ],
              ),
              child: Text(
                _message!,
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
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

// ── Keymap Overlay ─────────────────────────────────────────────────────────────

/// Full-screen overlay that displays all keyboard shortcuts grouped by
/// category.  Toggle with F1 or ? at any time during gameplay.
class KeymapOverlay extends StatelessWidget {
  final SpiritWorldGame game;
  const KeymapOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // Group entries by category
    final categories = <String, List<KeymapEntry>>{};
    for (final entry in GameKeymap.entries) {
      categories.putIfAbsent(entry.category, () => []).add(entry);
    }

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          color: Colors.black.withValues(alpha: 0.88),
          child: SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const Text('⌨️', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      const Text(
                        'Tastenbelegung',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        tooltip: 'Schließen (F1 / ?)',
                        onPressed: game.closeKeymapOverlay,
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),

                // ── Key-binding table ──────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categories.entries.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.key.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...cat.value.map((e) => _KeyRow(entry: e)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // ── Footer hint ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'F1 / ?  –  Tastenbelegung schließen',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
              entry.action,
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

/// Shows a golden 🏠 icon + direction arrow at a fixed position below the
/// resource-bar panel.  Always visible as long as the player is more than
/// 64 px (≈ 2 cells) away from the pastor house.
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
          // Fixed position below the resource-bar panel (which ends at ≈ y 110).
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



// ── Resource HUD (Flutter overlay) ──────────────────────────────────────────

/// Flutter-based resource-bar panel positioned at the top-left of the screen.
///
/// Using Flutter widgets (rather than a Flame component) ensures the bars
/// update immediately after every action – even while the Flame game loop is
/// paused (e.g. when a building or dialog overlay is open).
class _ResourceHud extends StatelessWidget {
  final SpiritWorldGame game;
  const _ResourceHud({required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 6,
      left: 6,
      child: SafeArea(
        child: Container(
          // Keep padding tight so the panel stays ~96 px tall (matching the
          // original Flame-rendered panel) and does not overlap the compass
          // that is anchored at top: 114.
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedResourceBar(
                notifier: game.healthNotifier,
                max: SpiritWorldGame.maxHealth,
                icon: '❤️',
                label: 'HP',
                color: Colors.redAccent,
              ),
              const SizedBox(height: 2),
              _AnimatedResourceBar(
                notifier: game.hungerNotifier,
                max: SpiritWorldGame.maxHunger,
                icon: '🍞',
                label: 'Hunger',
                color: Colors.orange,
              ),
              const SizedBox(height: 2),
              _AnimatedResourceBar(
                notifier: game.faithNotifier,
                max: SpiritWorldGame.maxFaith,
                icon: '🙏',
                label: 'Faith',
                color: Colors.purpleAccent,
              ),
              const SizedBox(height: 2),
              _AnimatedResourceBar(
                notifier: game.materialsNotifier,
                max: SpiritWorldGame.maxMaterials,
                icon: '📦',
                label: 'Supplies',
                color: Colors.blueGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single resource bar with a brief "+N" / "−N" delta text that fades out
/// after each change.
///
/// Listens directly to a [ValueNotifier] so it rebuilds immediately on any
/// resource change, regardless of the Flame game pause state.
class _AnimatedResourceBar extends StatefulWidget {
  final ValueNotifier<double> notifier;
  final double max;
  final String icon;
  final String label;
  final Color color;

  const _AnimatedResourceBar({
    required this.notifier,
    required this.max,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  State<_AnimatedResourceBar> createState() => _AnimatedResourceBarState();
}

class _AnimatedResourceBarState extends State<_AnimatedResourceBar>
    with SingleTickerProviderStateMixin {
  static const double _barWidth  = 130.0;
  static const double _barHeight = 8.0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  double _prevValue = 0.0;
  double _lastDelta = 0.0;

  @override
  void initState() {
    super.initState();
    _prevValue = widget.notifier.value;
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Opacity goes 1.0 → 0.0 so the delta text fades out completely.
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn),
    );
    widget.notifier.addListener(_onValueChanged);
  }

  void _onValueChanged() {
    if (!mounted) return;
    final newValue = widget.notifier.value;
    if (newValue == _prevValue) return;
    setState(() {
      _lastDelta = newValue - _prevValue;
      _prevValue = newValue;
    });
    // (Re-)start the fade so the delta text disappears after 1.2 s.
    _fadeCtrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onValueChanged);
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.notifier.value;
    final progress = (value / widget.max).clamp(0.0, 1.0);
    final deltaSign = _lastDelta >= 0 ? '+' : '';
    final deltaText = '$deltaSign${_lastDelta.toInt()}';
    final deltaColor = _lastDelta >= 0 ? Colors.amber : Colors.redAccent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Emoji icon
        Text(widget.icon, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        SizedBox(
          width: _barWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label + current value + fading delta
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.label} ${value.toInt()}/${widget.max.toInt()}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Delta chip – only shown while the fade is in progress.
                  if (_fadeCtrl.isAnimating || _fadeCtrl.value < 1.0)
                    AnimatedBuilder(
                      animation: _fadeAnim,
                      builder: (context, _) => Opacity(
                        opacity: _fadeAnim.value.clamp(0.0, 1.0),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            deltaText,
                            style: TextStyle(
                              color: deltaColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Progress bar (plain, no glow)
              Container(
                width: _barWidth,
                height: _barHeight,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

  /// Ordered list of action types for the current building – populated when
  /// [_accessGranted] becomes true and used for keyboard dispatch.
  List<String> _actionTypes = [];

  // ── Action countdown timer ────────────────────────────────────────────────

  /// Remaining seconds for the current timed action (0 = no action in progress).
  int _actionSecondsLeft = 0;

  /// The action type currently being processed by the timer.
  String? _pendingActionType;

  Timer? _actionTimer;

  /// Whether an action countdown is currently running.
  bool get _isActionBusy => _actionSecondsLeft > 0;

  /// Returns the duration [baseSeconds] scaled by the current difficulty level.
  ///
  /// Easy difficulty (factor 1.5) shortens durations; hard difficulty (factor 0.5)
  /// lengthens them. Result is clamped to [1, 60] seconds.
  /// Uses the same formula as the dialog's bible-reading timer.
  int _scaledDuration(int baseSeconds) {
    final factor = FaithCalculatorService.difficultyFactorFor(
      widget.game.difficulty,
    );
    return (baseSeconds / factor).round().clamp(1, 60);
  }

  /// Returns the countdown duration for [actionType], or 0 for instant actions.
  int _durationFor(String actionType) {
    switch (actionType) {
      case 'readBible':
        return _scaledDuration(BuildingInteractionService.pastorHouseReadBibleSeconds);
      case 'eat':
        return _scaledDuration(BuildingInteractionService.pastorHouseEatSeconds);
      case 'sleep':
        return _scaledDuration(BuildingInteractionService.pastorHouseSleepSeconds);
      case 'pray':
        return _scaledDuration(BuildingInteractionService.pastorHousePraySeconds);
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    widget.game.buildingActionIndex.addListener(_onBuildingKey);
    final data = widget.game.activeBuildingData;
    if (data == null) return;

    if (data.building.isAlwaysOpen) {
      _accessGranted = true;
      _actionTypes = _actionsFor(data.building.type);
    }
    // For residential buildings we show a knock screen first.
  }

  @override
  void dispose() {
    widget.game.buildingActionIndex.removeListener(_onBuildingKey);
    _actionTimer?.cancel();
    super.dispose();
  }

  /// Called when the player presses digit 1–6 while the building is open.
  void _onBuildingKey() {
    final idx = widget.game.buildingActionIndex.value;
    if (idx < 0) return;

    // Knock screen: key 1 triggers the knock attempt.
    if (_accessGranted == null) {
      if (idx == 0) _attemptKnock();
      return;
    }

    if (_accessGranted != true || _isActionBusy) return;
    if (idx < _actionTypes.length) {
      _performAction(_actionTypes[idx]);
    }
  }

  /// Returns the ordered list of action-type strings for a building type,
  /// matching the chip order in [_buildBuildingChips].
  static List<String> _actionsFor(BuildingType type) {
    switch (type) {
      case BuildingType.pastorHouse:
        return ['readBible', 'eat', 'sleep', 'pray', 'missions'];
      case BuildingType.house:
      case BuildingType.apartment:
        return ['talk', 'pray', 'help', 'bible'];
      case BuildingType.church:
      case BuildingType.cathedral:
        return ['readBible', 'pray', 'worship'];
      case BuildingType.hospital:
        return ['visitSick', 'pray', 'heal'];
      case BuildingType.school:
      case BuildingType.university:
        return ['teach', 'pray', 'distribute'];
      case BuildingType.cemetery:
        return ['pray', 'comfort'];
      case BuildingType.shop:
      case BuildingType.supermarket:
      case BuildingType.mall:
      case BuildingType.office:
      case BuildingType.skyscraper:
        return ['donate', 'worker', 'prayBusiness', 'distribute'];
      default:
        return ['pray', 'witness', 'distribute'];
    }
  }

  void _attemptKnock() {
    final data = widget.game.activeBuildingData;
    if (data == null) return;
    final granted = widget.game.attemptBuildingAccess(data.building);
    setState(() {
      _accessGranted = granted;
      _lastReaction = null;
      if (granted) _actionTypes = _actionsFor(data.building.type);
    });
  }

  void _performAction(String actionType) {
    if (_isActionBusy) return;
    final duration = _durationFor(actionType);
    if (duration > 0) {
      // Start countdown; the actual game action fires when the timer expires.
      setState(() {
        _actionSecondsLeft = duration;
        _pendingActionType = actionType;
        _lastReaction = null;
      });
      _actionTimer?.cancel();
      _actionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _actionSecondsLeft--);
        if (_actionSecondsLeft <= 0) {
          t.cancel();
          _applyPendingAction();
        }
      });
    } else {
      _executeAction(actionType);
    }
  }

  /// Fires when the countdown timer expires: executes the pending action.
  void _applyPendingAction() {
    final pending = _pendingActionType;
    setState(() {
      _pendingActionType = null;
      _actionSecondsLeft = 0;
    });
    if (pending != null) _executeAction(pending);
  }

  /// Calls the game layer to execute [actionType] and updates the UI.
  void _executeAction(String actionType) {
    final result = widget.game.handleBuildingAction(actionType);
    setState(() => _lastReaction = result.reactionEmoji);
    // Auto-leave when the session limit is reached (tracked by
    // building.currentSessionInteractions vs building.maxSessionInteractions).
    // The homebase is exempt: it has baseSessionInteractions=999 and never
    // forces the player to leave.
    final data = widget.game.activeBuildingData;
    if (result.success && data != null && data.building.isReadyToLeave) {
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
          // CrossAxisAlignment.stretch ensures the interior Row receives TIGHT
          // width constraints, so that its Expanded child can allocate space.
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
    return _InteractionHeader(
      bgColor: isHome ? const Color(0xFF4E342E) : const Color(0xFF283593),
      verticalPadding: 12,
      leading: Text(
        _buildingTypeEmoji(building.type),
        style: TextStyle(fontSize: isHome ? 32 : 28),
      ),
      title: _buildingTypeName(building.type),
      titleStyle: TextStyle(
        color: isHome ? const Color(0xFFFFD54F) : Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: isHome ? 19 : 17,
      ),
      titleBadge: isHome
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
            )
          : null,
      subtitle: building.residents.isNotEmpty
          ? Text(
              _residentSummaryLine(building),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            )
          : null,
      showDots: !isHome,
      sessionDone: building.currentSessionInteractions,
      sessionMax: building.maxSessionInteractions,
      onClose: () => widget.game.closeBuildingInterior(),
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
            'Klingeln?',
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Text('🔔', style: TextStyle(fontSize: 22)),
                  label: const Text('Klingeln', style: TextStyle(fontSize: 16)),
                  onPressed: _attemptKnock,
                ),
                if (_shouldShowKeyHints())
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFA000),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '1',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _accessHint(BuildingModel building, double faith) {
    final accessPercentage =
        (building.accessChance(faith) * 100).round();
    final bonus = building.interactionCount >= 3 ? ' (+30 % Bonus)' : '';
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left: action menu (or countdown) ──────────────────────────
          SizedBox(
            width: 170,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 4, 14),
              child: _isActionBusy
                  ? _buildActionCountdown()
                  : _buildBuildingChipsColumn(building),
            ),
          ),
          // Full-height divider
          const VerticalDivider(width: 1, thickness: 1, color: Colors.white12),
          // ── Middle: art + residents + reaction ─────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: _maxInteriorArtHeight),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: _InteriorArtWidget(art: _interiorArt(building.type)),
                    ),
                  ),
                  if (building.residents.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildResidentChips(building, compact: true),
                  ],
                  if (_lastReaction != null) ...[
                    const SizedBox(height: 6),
                    Text(_lastReaction!, style: const TextStyle(fontSize: 28)),
                  ],
                ],
              ),
            ),
          ),
          // Full-height divider
          const VerticalDivider(width: 1, thickness: 1, color: Colors.white12),
          // ── Right: faith bar (centered, colored background like NPC dialog) ──
          Container(
            color: Colors.black26,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Center(
              child: _FaithBarWidget(entity: building),
            ),
          ),
        ],
      ),
    );
  }

  /// Vertical countdown shown in the right action panel while an action is in progress.
  Widget _buildActionCountdown() {
    final emoji = _actionEmojiFor(_pendingActionType ?? '');
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(
          '${_actionSecondsLeft}s',
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _actionLabelFor(_pendingActionType ?? ''),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  static String _actionEmojiFor(String actionType) {
    switch (actionType) {
      case 'readBible': return '📖';
      case 'eat':       return '🍽️';
      case 'sleep':     return '😴';
      case 'pray':      return '🙏';
      default:          return '⏳';
    }
  }

  static String _actionLabelFor(String actionType) {
    switch (actionType) {
      case 'readBible': return 'Bibel lesen …';
      case 'eat':       return 'Essen …';
      case 'sleep':     return 'Schlafen …';
      case 'pray':      return 'Beten …';
      default:          return 'Warten …';
    }
  }

  // ── Building action menu (left side-panel) ───────────────────────────────

  /// Returns a vertical column of [_ActionMenuRow] widgets for [building],
  /// matching the order in [_actionsFor] so that keyboard badges 1-N stay in sync.
  ///
  /// Rows are disabled when the player lacks the required resources.
  /// This column lives in the LEFT side-panel and uses the classic menu-row
  /// layout (emoji + cost arrow + effect) to distinguish it visually from the
  /// NPC dialog which uses a horizontal chip row at the bottom.
  Widget _buildBuildingChipsColumn(BuildingModel building) {
    final g = widget.game;
    int idx = 0;
    int nk() => ++idx;

    final List<Widget> rows;
    switch (building.type) {
      // ── Pastor's house ─────────────────────────────────────────────────
      case BuildingType.pastorHouse:
        rows = [
          _ActionMenuRow(leadingEmoji: '📖', arrowText: '↔', trailingEmoji: '🙏+20', tooltip: 'Bibel lesen', keyIndex: nk(), isDisabled: g.health <= 5, onTap: () => _performAction('readBible')),
          _ActionMenuRow(leadingEmoji: '🍽️', arrowText: '→', trailingEmoji: '🍞+50', tooltip: 'Essen', keyIndex: nk(), onTap: () => _performAction('eat')),
          _ActionMenuRow(leadingEmoji: '😴', arrowText: '→', trailingEmoji: '❤️+50', tooltip: 'Schlafen', keyIndex: nk(), onTap: () => _performAction('sleep')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '↔', trailingEmoji: '🕊️+15', tooltip: 'Beten', keyIndex: nk(), isDisabled: g.health <= 5, onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '📋', arrowText: '→', trailingEmoji: '📜', tooltip: 'Missionen', keyIndex: nk(), onTap: () => _performAction('missions')),
        ];

      // ── Residential ───────────────────────────────────────────────────
      case BuildingType.house:
      case BuildingType.apartment:
        rows = [
          _ActionMenuRow(leadingEmoji: '💬', arrowText: '→', trailingEmoji: '✝️', tooltip: 'Gespräch', keyIndex: nk(), onTap: () => _performAction('talk')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '−❤️→', trailingEmoji: '✝️', tooltip: 'Beten', keyIndex: nk(), isDisabled: g.health <= 5, onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '📦', arrowText: '−10💰→', trailingEmoji: '✝️', tooltip: 'Helfen', keyIndex: nk(), isDisabled: g.materials < 10, onTap: () => _performAction('help')),
          _ActionMenuRow(leadingEmoji: '📖', arrowText: '−💰❤️→', trailingEmoji: '✝️', tooltip: 'Bibelstunde', keyIndex: nk(), isDisabled: g.materials < 3 || g.health <= 3, onTap: () => _performAction('bible')),
        ];

      // ── Church ────────────────────────────────────────────────────────
      case BuildingType.church:
      case BuildingType.cathedral:
        rows = [
          _ActionMenuRow(leadingEmoji: '📖', arrowText: '−3💰→', trailingEmoji: '✝️', tooltip: 'Bibel lesen', keyIndex: nk(), isDisabled: g.materials < 3, onTap: () => _performAction('readBible')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '−3💰→', trailingEmoji: '✝️', tooltip: 'Beten', keyIndex: nk(), isDisabled: g.materials < 3, onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '🎵', arrowText: '−8💰→', trailingEmoji: '✝️', tooltip: 'Lobpreis', keyIndex: nk(), isDisabled: g.materials < 8, onTap: () => _performAction('worship')),
        ];

      // ── Hospital ──────────────────────────────────────────────────────
      case BuildingType.hospital:
        rows = [
          _ActionMenuRow(leadingEmoji: '🤝', arrowText: '−5💰→', trailingEmoji: '✝️', tooltip: 'Kranke besuchen', keyIndex: nk(), isDisabled: g.materials < 5, onTap: () => _performAction('visitSick')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '−3💰→', trailingEmoji: '✝️', tooltip: 'Beten', keyIndex: nk(), isDisabled: g.materials < 3, onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '💊', arrowText: '−10💰→', trailingEmoji: '✝️', tooltip: 'Heilen', keyIndex: nk(), isDisabled: g.materials < 10, onTap: () => _performAction('heal')),
        ];

      // ── School / University ───────────────────────────────────────────
      case BuildingType.school:
      case BuildingType.university:
        rows = [
          _ActionMenuRow(leadingEmoji: '📚', arrowText: '−5💰→', trailingEmoji: '✝️', tooltip: 'Unterrichten', keyIndex: nk(), isDisabled: g.materials < 5, onTap: () => _performAction('teach')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '−3💰→', trailingEmoji: '✝️', tooltip: 'Beten', keyIndex: nk(), isDisabled: g.materials < 3, onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '📦', arrowText: '−8💰→', trailingEmoji: '✝️', tooltip: 'Verteilen', keyIndex: nk(), isDisabled: g.materials < 8, onTap: () => _performAction('distribute')),
        ];

      // ── Cemetery ──────────────────────────────────────────────────────
      case BuildingType.cemetery:
        rows = [
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '−5💰→', trailingEmoji: '✝️', tooltip: 'Beten', keyIndex: nk(), isDisabled: g.materials < 5, onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '🤝', arrowText: '−3💰→', trailingEmoji: '✝️', tooltip: 'Trösten', keyIndex: nk(), isDisabled: g.materials < 3, onTap: () => _performAction('comfort')),
        ];

      // ── Commercial ────────────────────────────────────────────────────
      case BuildingType.shop:
      case BuildingType.supermarket:
      case BuildingType.mall:
      case BuildingType.office:
      case BuildingType.skyscraper:
        rows = [
          _ActionMenuRow(leadingEmoji: '💸', arrowText: '→', trailingEmoji: '💰', tooltip: 'Spenden', keyIndex: nk(), onTap: () => _performAction('donate')),
          _ActionMenuRow(leadingEmoji: '💬', arrowText: '→', trailingEmoji: '✝️', tooltip: 'Zeugnis', keyIndex: nk(), onTap: () => _performAction('worker')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '−3💰→', trailingEmoji: '✝️', tooltip: 'Für Betrieb beten', keyIndex: nk(), isDisabled: g.materials < 3, onTap: () => _performAction('prayBusiness')),
          _ActionMenuRow(leadingEmoji: '📦', arrowText: '−5💰→', trailingEmoji: '✝️', tooltip: 'Verteilen', keyIndex: nk(), isDisabled: g.materials < 5, onTap: () => _performAction('distribute')),
        ];

      // ── Everything else ───────────────────────────────────────────────
      default:
        rows = [
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '→', trailingEmoji: '✝️', tooltip: 'Beten', keyIndex: nk(), onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '💬', arrowText: '−3💰→', trailingEmoji: '✝️', tooltip: 'Zeugnis geben', keyIndex: nk(), isDisabled: g.materials < 3, onTap: () => _performAction('witness')),
          _ActionMenuRow(leadingEmoji: '📦', arrowText: '−8💰→', trailingEmoji: '✝️', tooltip: 'Verteilen', keyIndex: nk(), isDisabled: g.materials < 8, onTap: () => _performAction('distribute')),
        ];
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows
          .map((r) => Padding(padding: const EdgeInsets.symmetric(vertical: 1), child: r))
          .toList(),
    );
  }


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
  /// 1-based keyboard shortcut shown as an amber badge (null = no badge).
  final int? keyIndex;
  /// When true the row is rendered at reduced opacity and taps are ignored.
  final bool isDisabled;

  const _ActionMenuRow({
    required this.leadingEmoji,
    required this.arrowText,
    required this.trailingEmoji,
    required this.tooltip,
    required this.onTap,
    this.keyIndex,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = keyIndex != null && _shouldShowKeyHints();
    return Opacity(
      opacity: isDisabled ? 0.35 : 1.0,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                if (showBadge)
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFA000), // amber 700
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$keyIndex',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                Text(leadingEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
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

/// Shared header bar used by both the NPC dialog and the building interior
/// overlays.
///
/// Layout:
/// ```
/// [leading]  [SizedBox(12)]  [Expanded(title + optional subtitle)]
///            [if showDots: SessionDotsRow + SizedBox(4)]  [CloseButton]
/// ```
///
/// Parameters:
/// * [bgColor] – background colour of the bar.
/// * [verticalPadding] – vertical inner padding (default: 10).
/// * [leading] – left-edge icon: a `CircleAvatar` for NPCs, an emoji `Text`
///   for buildings.
/// * [title] / [titleStyle] – main title text and its style.
/// * [titleBadge] – optional widget shown to the right of the title in the
///   same row (e.g. the "Mein Zuhause" label for the homebase).
/// * [subtitle] – optional widget shown below the title row (e.g. delta row
///   or resident summary).
/// * [showDots] – whether to show the `_SessionDotsRow` counter (default: true).
/// * [sessionDone] / [sessionMax] – values forwarded to `_SessionDotsRow`.
/// * [onClose] – close-button callback; `null` renders the button as disabled.
/// * [closeIconColor] – colour of the close icon (default: `Colors.white70`).
class _InteractionHeader extends StatelessWidget {
  final Color bgColor;
  final double verticalPadding;
  final Widget leading;
  final String title;
  final TextStyle titleStyle;
  final Widget? titleBadge;
  final Widget? subtitle;
  final bool showDots;
  final int sessionDone;
  final int sessionMax;
  final VoidCallback? onClose;
  final Color closeIconColor;

  const _InteractionHeader({
    required this.bgColor,
    this.verticalPadding = 10,
    required this.leading,
    required this.title,
    required this.titleStyle,
    this.titleBadge,
    this.subtitle,
    this.showDots = true,
    this.sessionDone = 0,
    this.sessionMax = 2,
    this.onClose,
    this.closeIconColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: titleStyle),
                    if (titleBadge != null) ...[
                      const SizedBox(width: 8),
                      titleBadge!,
                    ],
                  ],
                ),
                if (subtitle != null) subtitle!,
              ],
            ),
          ),
          if (showDots) ...[
            _SessionDotsRow(done: sessionDone, max: sessionMax),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: Icon(Icons.close, color: closeIconColor),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// A row of small dots showing how many session interactions have been used
/// out of the current [max].  Filled dots = used, hollow dots = remaining.
///
/// Used in the building interior header to give the player a quick visual cue
/// of how many more actions they can take before being asked to leave.
class _SessionDotsRow extends StatelessWidget {
  final int done;
  final int max;

  const _SessionDotsRow({required this.done, required this.max});

  @override
  Widget build(BuildContext context) {
    // Cap the display at 12 dots to avoid overflow on very high counts.
    final displayMax  = max.clamp(1, 12);
    final displayDone = done.clamp(0, displayMax);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < displayMax; i++)
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < displayDone
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.22),
            ),
          ),
        const SizedBox(width: 4),
        Text(
          '$displayDone/$displayMax',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Vertical faith-level bar shown on the right edge of an NPC dialog or
/// building interior overlay.
///
/// Works for any [BaseInteractableEntity] since [isFaithVague] and
/// [isFaithRevealed] are defined on the shared base class.
///
/// * Not vague (< 3 interactions) → question mark placeholder.
/// * Vague (3–5 interactions) → bar rounded to nearest 25 %.
/// * Revealed (6+ interactions) → exact bar + numeric label.
class _FaithBarWidget extends StatelessWidget {
  final BaseInteractableEntity entity;

  const _FaithBarWidget({required this.entity});

  @override
  Widget build(BuildContext context) {
    if (!entity.isFaithVague) {
      // Not enough interactions yet – show a question mark placeholder.
      return SizedBox(
        width: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

    final faithNorm = ((entity.faith + 100) / 200.0).clamp(0.0, 1.0);
    final barColor = Color.lerp(Colors.red[700]!, Colors.green[600]!, faithNorm)!;

    // Vague: round to nearest 25 %; revealed: exact value.
    final displayNorm = entity.isFaithRevealed
        ? faithNorm
        : ((faithNorm * 4).round() / 4.0).clamp(0.0, 1.0);

    const barHeight = 80.0;

    return SizedBox(
      width: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          if (entity.isFaithRevealed)
            Text(
              entity.faith.toStringAsFixed(0),
              style: const TextStyle(color: Colors.white60, fontSize: 9),
            )
          else
            const Text('~', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
