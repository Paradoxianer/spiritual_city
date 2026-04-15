import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../features/menu/domain/models/difficulty.dart';
import '../domain/models/building_model.dart';
import '../domain/models/npc_model.dart';
import '../domain/models/npc_reaction.dart';
import '../domain/services/building_interaction_service.dart';
import 'spirit_world_game.dart';

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;

  const GameScreen({super.key, this.difficulty = Difficulty.normal});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final SpiritWorldGame _game;

  @override
  void initState() {
    super.initState();
    _game = SpiritWorldGame(difficulty: widget.difficulty);
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
  /// Last interaction cost/gain string shown in the dialog header.
  String _lastFeedback = '';

  @override
  void initState() {
    super.initState();
    // If the NPC was already asking for a gift in a previous session, show
    // a reminder as the opening message so the player has context.
    final model = widget.game.activeDialog?.npcModel;
    if (model != null && model.wantsGift) {
      _messages.add(_ChatMessage(content: '📦❓', isPlayer: false));
    }
  }

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
      final model = widget.game.activeDialog?.npcModel;
      final reaction = widget.game.handleInteraction(type);
      _addMessage(reaction, false);

      // Show pending messages (life story reveals, gift requests)
      if (model != null && model.pendingMessages.isNotEmpty) {
        for (final msg in List<String>.from(model.pendingMessages)) {
          _addMessage(msg, false);
        }
        model.pendingMessages.clear();
      }

      // Show resource feedback in the header (not as a chat bubble)
      if (model != null) {
        final feedback = _buildFeedback(model);
        if (feedback.isNotEmpty) setState(() => _lastFeedback = feedback);
      }

      setState(() => _isWaiting = false);

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

  /// Builds a compact resource-feedback string from the model's last deltas.
  ///
  /// Canonical stat emoji (must match the HUD in prayer_hud_component.dart):
  ///   ❤️  = player health
  ///   🙏  = player faith
  ///   ✝️  = NPC faith  (distinct from the pray-action chip 🙏)
  ///   📦  = materials / supplies
  String _buildFeedback(NPCModel model) {
    final parts = <String>[];
    if (model.lastNpcFaithDelta != 0) {
      final delta = model.lastNpcFaithDelta;
      parts.add('${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}✝️');
    }
    if (model.lastPlayerFaithDelta != 0) {
      final delta = model.lastPlayerFaithDelta;
      parts.add('${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}🙏');
    }
    if (model.lastMaterialsDelta != 0) {
      final delta = model.lastMaterialsDelta;
      parts.add('${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}📦');
    }
    if (model.lastHealthDelta != 0) {
      final delta = model.lastHealthDelta;
      parts.add('${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}❤️');
    }
    return parts.join(' ');
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${dialog.npcName} (${model.age})',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_lastFeedback.isNotEmpty)
                          Text(
                            _lastFeedback,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => widget.game.closeDialog(),
                  ),
                ],
              ),
            ),

            // ── Chat body + Lebenslauf panel ──────────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Chat messages
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
                  // Lebenslauf sidebar
                  _LifeStoryPanel(model: model),
                ],
              ),
            ),

            // ── Action chips ──────────────────────────────────────────────────
            if (!_isSessionOver)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _EmojiChip(emoji: '💬', onTap: () => _handleInteraction('talk', '💬')),
                    _EmojiChip(emoji: '👂', onTap: () => _handleInteraction('counsel', '👂')),
                    _EmojiChip(emoji: '🙏', onTap: () => _handleInteraction('pray', '🙏')),
                    _EmojiChip(emoji: '📖', onTap: () => _handleInteraction('bible', '📖')),
                    _EmojiChip(emoji: '🔮', onTap: () => _handleInteraction('prophecy', '🔮')),
                    _EmojiChip(emoji: '💊', onTap: () => _handleInteraction('healing', '💊')),
                    // Gift chip only appears when NPC explicitly asked for it
                    if (model.wantsGift)
                      _EmojiChip(emoji: '📦', onTap: () => _handleInteraction('help', '📦')),
                    _EmojiChip(
                      emoji: '✝️🕊️',
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

/// Right-side panel inside the dialog showing all revealed life-story stages.
/// Only discovered stages are shown; unrevealed stages are hidden entirely.
/// Display order is reversed: the most recently revealed stage (highest index)
/// appears at the top, childhood at the bottom.
/// Each row: `👶  🏡😊🌈` (stage icon as label, then emoji segment).
class _LifeStoryPanel extends StatelessWidget {
  final NPCModel model;
  const _LifeStoryPanel({required this.model});

  @override
  Widget build(BuildContext context) {
    final revealed = model.revealedLifeStoryCount;
    if (revealed == 0) {
      return Container(
        width: 108,
        decoration: const BoxDecoration(
          color: Color(0xFF1A3A35),
          border: Border(left: BorderSide(color: Colors.white12)),
        ),
      );
    }
    // Show indices 0..revealed-1 in REVERSE order (newest/highest first).
    final indices = List.generate(revealed, (i) => revealed - 1 - i);
    return Container(
      width: 108,
      decoration: const BoxDecoration(
        color: Color(0xFF1A3A35),
        border: Border(left: BorderSide(color: Colors.white12)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        itemCount: indices.length,
        itemBuilder: (context, pos) {
          final i = indices[pos];
          final icon = (i < model.lifeStoryIcons.length)
              ? model.lifeStoryIcons[i]
              : '❓';
          final segment = model.lifeStory[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _RevealedTile(icon: icon, segment: segment),
          );
        },
      ),
    );
  }
}

class _RevealedTile extends StatelessWidget {
  final String icon;
  final String segment;
  const _RevealedTile({required this.icon, required this.segment});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF128C7E).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              segment,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.left,
              softWrap: true,
            ),
          ),
        ],
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

  const _EmojiChip({
    required this.emoji,
    required this.onTap,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(emoji, style: const TextStyle(fontSize: 22)),
      backgroundColor: isSpecial ? Colors.amber[800] : Colors.white70,
      onPressed: onTap,
      shape: StadiumBorder(side: BorderSide(color: isSpecial ? Colors.amber : Colors.transparent)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.game.activeBuildingData;
    if (data == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.center,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.88,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E).withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF283593),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Text(
            _categoryEmoji(building.category),
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _categoryName(building.category),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
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

  // ── Knock screen (residential only) ──────────────────────────────────────

  Widget _buildKnockScreen(BuildingModel building) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚪', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'Anklopfen?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _accessHint(building, widget.game.faith),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: const StadiumBorder(),
            ),
            icon: const Text('👊', style: TextStyle(fontSize: 22)),
            label: const Text('Anklopfen', style: TextStyle(fontSize: 16)),
            onPressed: _attemptKnock,
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
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
          const SizedBox(height: 24),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ASCII-art style interior
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              _asciiInterior(building.category),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.white70,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),

          // Residents summary
          if (building.residents.isNotEmpty) ...[
            Text(
              '${building.residents.length} Bewohner anwesend',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Reaction feedback
          if (_lastReaction != null) ...[
            Text(
              _lastReaction!,
              style: const TextStyle(fontSize: 34),
            ),
            const SizedBox(height: 8),
          ],

          // Action chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _buildActionChips(building.category),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionChips(BuildingCategory category) {
    switch (category) {
      case BuildingCategory.residential:
        return [
          _ActionChip(label: '💬', sublabel: 'Sprechen', onTap: () => _performAction('talk')),
          _ActionChip(label: '🙏', sublabel: 'Beten', onTap: () => _performAction('pray')),
          _ActionChip(label: '📦', sublabel: 'Hilfe', onTap: () => _performAction('help')),
          _ActionChip(label: '📖', sublabel: 'Bibel', onTap: () => _performAction('bible')),
        ];
      case BuildingCategory.commercial:
        return [
          _ActionChip(label: '💸', sublabel: 'Spenden', onTap: () => _performAction('donate')),
          _ActionChip(label: '👷', sublabel: 'Arbeiter', onTap: () => _performAction('worker')),
          _ActionChip(label: '🙏', sublabel: 'Beten', onTap: () => _performAction('prayBusiness')),
          _ActionChip(label: '📦', sublabel: 'Verteilen', onTap: () => _performAction('distribute')),
        ];
      case BuildingCategory.church:
        return [
          _ActionChip(label: '📖', sublabel: 'Bibellesen', onTap: () => _performAction('readBible')),
          _ActionChip(label: '🙏', sublabel: 'Beten', onTap: () => _performAction('pray')),
          _ActionChip(label: '🎵', sublabel: 'Gottesdienst', onTap: () => _performAction('worship')),
        ];
      default:
        return [
          _ActionChip(
            label: '👀',
            sublabel: 'Schauen',
            onTap: () => setState(() => _lastReaction = '👀'),
          ),
        ];
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _categoryEmoji(BuildingCategory cat) {
    switch (cat) {
      case BuildingCategory.residential: return '🏠';
      case BuildingCategory.commercial:  return '🏢';
      case BuildingCategory.church:      return '⛪';
      default:                           return '🏗️';
    }
  }

  String _categoryName(BuildingCategory cat) {
    switch (cat) {
      case BuildingCategory.residential: return 'Wohnhaus';
      case BuildingCategory.commercial:  return 'Geschäftsgebäude';
      case BuildingCategory.church:      return 'Kirchliches Gebäude';
      default:                           return 'Gebäude';
    }
  }

  String _asciiInterior(BuildingCategory cat) {
    switch (cat) {
      case BuildingCategory.residential:
        return '┌─────────────────────┐\n'
               '│  🪑       🛋️        │\n'
               '│                     │\n'
               '│   🖼️   [Wohnzimmer]  │\n'
               '│                     │\n'
               '│  🌿       ☕        │\n'
               '└─────────────────────┘';
      case BuildingCategory.commercial:
        return '┌─────────────────────┐\n'
               '│ 📦  📦  📦  📦  📦  │\n'
               '│                     │\n'
               '│   [Geschäftsraum]   │\n'
               '│                     │\n'
               '│  💼      🖥️         │\n'
               '└─────────────────────┘';
      case BuildingCategory.church:
        return '┌─────────────────────┐\n'
               '│       ✝️            │\n'
               '│  🕯️           🕯️   │\n'
               '│   [Kirchenraum]     │\n'
               '│  🪑 🪑 🪑 🪑 🪑   │\n'
               '│  🪑 🪑 🪑 🪑 🪑   │\n'
               '└─────────────────────┘';
      default:
        return '┌─────────────────────┐\n'
               '│                     │\n'
               '│      [Raum]         │\n'
               '│                     │\n'
               '└─────────────────────┘';
    }
  }
}

/// A compact action chip used inside [BuildingInteriorOverlay].
class _ActionChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
