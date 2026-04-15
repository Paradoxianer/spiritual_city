import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../features/menu/domain/models/difficulty.dart';
import '../domain/models/building_model.dart';
import '../domain/models/cell_object.dart';
import '../domain/models/npc_model.dart';
import '../domain/models/npc_reaction.dart';
import '../presentation/components/building_component.dart';
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

            // ── Chat body ─────────────────────────────────────────────────────
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

            // ── Action chips ──────────────────────────────────────────────────
            if (!_isSessionOver)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _EmojiChip(emoji: '💬', onTap: () => _handleInteraction('talk', '💬')),
                    _EmojiChip(emoji: '🙏', onTap: () => _handleInteraction('pray', '🙏')),
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

// ── Interior art abstraction ──────────────────────────────────────────────────

/// Sealed type for a building's interior visual.
///
/// Currently only [EmojiGridArt] is used, but switching to [ImageArt] for a
/// specific building requires changing only the corresponding entry in
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

/// Room art: drawn walls + sparsely placed furniture items.
///
/// The room boundary is rendered by [_RoomPainter] (CustomPaint lines), so
/// replacing this with [ImageArt] later requires zero changes to widget code.
///
/// Each entry in [furniture] is a record (normalised-x, normalised-y, emoji)
/// where x and y are in the range 0.0–1.0 relative to the room square.
class RoomArt extends InteriorArt {
  final List<(double, double, String)> furniture;
  /// Colour used for the drawn wall lines and door frame.
  final Color wallColor;
  RoomArt({required this.furniture, this.wallColor = const Color(0xFFC4A882)});
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
        width: MediaQuery.of(context).size.width * 0.88,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
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
              const SizedBox(width: 12),
              Tooltip(
                message: 'Brief einwerfen (+3 Glauben)',
                child: GestureDetector(
                  onTap: () {
                    _performAction('letter');
                    widget.game.closeBuildingInterior();
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Center(
                      child: Text('✉️', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                ),
              ),
            ],
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
          const SizedBox(height: 6),
          Text(
            'Du kannst trotzdem einen Brief einwerfen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  shape: const StadiumBorder(),
                ),
                icon: const Text('✉️', style: TextStyle(fontSize: 18)),
                label: const Text('Brief einwerfen',
                    style: TextStyle(fontSize: 13)),
                onPressed: () {
                  _performAction('letter');
                  widget.game.closeBuildingInterior();
                },
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => widget.game.closeBuildingInterior(),
                child: const Text('Weggehen',
                    style: TextStyle(color: Colors.amber)),
              ),
            ],
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
                      _InteriorArtWidget(art: _interiorArt(building.type)),
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
  /// The letter action is always the last entry.
  List<Widget> _buildActionMenuRows(BuildingModel building) {
    final letter = _ActionMenuRow(
      leadingEmoji: '✉️',
      arrowText: '→',
      trailingEmoji: '📬',
      tooltip: 'Brief einwerfen (+3 Glauben)',
      onTap: () => _performAction('letter'),
    );

    switch (building.type) {
      // ── Pastor's house ────────────────────────────────────────────────────
      case BuildingType.pastorHouse:
        return [
          _ActionMenuRow(leadingEmoji: '📖', arrowText: '→', trailingEmoji: '✝️↑', tooltip: 'Bibel lesen (+20 Glauben)', onTap: () => _performAction('readBible')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '→', trailingEmoji: '✝️↑', tooltip: 'Beten (+15 Glauben)', onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '😴', arrowText: '→', trailingEmoji: '✝️↑', tooltip: 'Ausruhen (+10 Glauben)', onTap: () => _performAction('rest')),
          letter,
        ];

      // ── Residential ───────────────────────────────────────────────────────
      case BuildingType.house:
      case BuildingType.apartment:
        return [
          _ActionMenuRow(leadingEmoji: '💬', arrowText: '→', trailingEmoji: '👥✝️', tooltip: 'Gespräch führen (+5 Glauben)', onTap: () => _performAction('talk')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '←', trailingEmoji: '❤️×5', tooltip: 'Für Familie beten (−5 HP, +15 Glauben)', onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '📦', arrowText: '←', trailingEmoji: '💰×10', tooltip: 'Hilfe anbieten (−10 Material, +10 Glauben)', onTap: () => _performAction('help')),
          _ActionMenuRow(leadingEmoji: '📖', arrowText: '←', trailingEmoji: '❤️×3💰×3', tooltip: 'Gemeinsam Bibel lesen (−3 HP, −3 Material, +10 Glauben)', onTap: () => _performAction('bible')),
          letter,
        ];

      // ── Church ────────────────────────────────────────────────────────────
      case BuildingType.church:
      case BuildingType.cathedral:
        return [
          _ActionMenuRow(leadingEmoji: '📖', arrowText: '←', trailingEmoji: '💰×3', tooltip: 'Bibel lesen (−3 Material, +10 Glauben)', onTap: () => _performAction('readBible')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '←', trailingEmoji: '💰×3', tooltip: 'Gemeinsam beten (−3 Material, +15 Glauben)', onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '🎵', arrowText: '←', trailingEmoji: '💰×8', tooltip: 'Gottesdienst halten (−8 Material, +20 Glauben)', onTap: () => _performAction('worship')),
          letter,
        ];

      // ── Hospital ──────────────────────────────────────────────────────────
      case BuildingType.hospital:
        return [
          _ActionMenuRow(leadingEmoji: '🤝', arrowText: '←', trailingEmoji: '💰×5', tooltip: 'Kranke besuchen (−5 Material, +12 Glauben)', onTap: () => _performAction('visitSick')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '←', trailingEmoji: '💰×3', tooltip: 'Für Heilung beten (−3 Material, +10 Glauben)', onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '💊', arrowText: '←', trailingEmoji: '💰×10', tooltip: 'Heilen lassen (−10 Material, +20 Glauben)', onTap: () => _performAction('heal')),
          letter,
        ];

      // ── School / University ───────────────────────────────────────────────
      case BuildingType.school:
      case BuildingType.university:
        return [
          _ActionMenuRow(leadingEmoji: '📚', arrowText: '←', trailingEmoji: '💰×5', tooltip: 'Glauben lehren (−5 Material, +8 Glauben)', onTap: () => _performAction('teach')),
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '←', trailingEmoji: '💰×3', tooltip: 'Für Schüler beten (−3 Material, +10 Glauben)', onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '📦', arrowText: '←', trailingEmoji: '💰×8', tooltip: 'Material spenden (−8 Material, +10 Glauben)', onTap: () => _performAction('distribute')),
          letter,
        ];

      // ── Cemetery ──────────────────────────────────────────────────────────
      case BuildingType.cemetery:
        return [
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '←', trailingEmoji: '💰×5', tooltip: 'Stille Andacht (−5 Material, +18 Glauben)', onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '🤝', arrowText: '←', trailingEmoji: '💰×3', tooltip: 'Trauernde trösten (−3 Material, +10 Glauben)', onTap: () => _performAction('comfort')),
          letter,
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
          letter,
        ];

      // ── Everything else ───────────────────────────────────────────────────
      default:
        return [
          _ActionMenuRow(leadingEmoji: '🙏', arrowText: '→', trailingEmoji: '🌿✝️', tooltip: 'Beten (+8 Glauben)', onTap: () => _performAction('pray')),
          _ActionMenuRow(leadingEmoji: '💬', arrowText: '←', trailingEmoji: '💰×3', tooltip: 'Zeugnis geben (−3 Material, +10 Glauben)', onTap: () => _performAction('witness')),
          _ActionMenuRow(leadingEmoji: '📦', arrowText: '←', trailingEmoji: '💰×8', tooltip: 'Material verteilen (−8 Material, +12 Glauben)', onTap: () => _performAction('distribute')),
          letter,
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

  /// Returns the [InteriorArt] for [type].
  ///
  /// All building types are covered. Swapping a type's art to a raster image
  /// only requires changing its return value to [ImageArt('assets/...')].
  InteriorArt _interiorArt(BuildingType type) {
    switch (type) {
      case BuildingType.pastorHouse:
        // Drawn room: warm parchment walls, sparsely placed furniture.
        // Coordinates are normalised (0–1) relative to the square room area.
        // Door opening is rendered by _RoomPainter at the bottom-centre.
        return RoomArt(
          wallColor: Color(0xFFD4A882), // warm parchment
          furniture: [
            (0.50, 0.08, '✝️'),   // cross, back wall centred – spiritual focus
            (0.18, 0.07, '🪟'),   // window, top-left
            (0.82, 0.07, '🪟'),   // window, top-right
            (0.08, 0.30, '📚'),   // bookshelf, left wall
            (0.28, 0.40, '📖'),   // open bible, desk area
            (0.44, 0.56, '🪑'),   // armchair
            (0.80, 0.22, '🛏️'), // bed, top-right corner
            (0.90, 0.48, '🕯️'),  // candle beside bed
            (0.10, 0.74, '🪴'),   // plant, bottom-left corner
            (0.68, 0.74, '🙏'),   // prayer corner, bottom-right
          ],
        );
      case BuildingType.house:
      case BuildingType.apartment:
        return EmojiGridArt([
          ['🛋️', '🪴', '🪟'],
          ['🍳', '🚪', '📺'],
          ['🛏️', '📚', '🪑'],
        ]);
      case BuildingType.church:
      case BuildingType.cathedral:
        return EmojiGridArt([
          ['⛪', '✝️', '⛪'],
          ['🕯️', '📖', '🕯️'],
          ['🪑', '🙏', '🪑'],
        ]);
      case BuildingType.hospital:
        return EmojiGridArt([
          ['🛏️', '🛏️', '🔬'],
          ['💊', '🏥', '🩺'],
          ['🛏️', '🛏️', '📋'],
        ]);
      case BuildingType.school:
      case BuildingType.university:
        return EmojiGridArt([
          ['📚', '🖊️', '📝'],
          ['🪑', '🏫', '🪑'],
          ['📖', '✏️', '📐'],
        ]);
      case BuildingType.cemetery:
        return EmojiGridArt([
          ['✝️', '🌿', '✝️'],
          ['🕯️', '⛪', '🕯️'],
          ['✝️', '🌿', '✝️'],
        ]);
      case BuildingType.shop:
      case BuildingType.supermarket:
      case BuildingType.mall:
        return EmojiGridArt([
          ['🛍️', '📦', '🏷️'],
          ['🛒', '🏪', '💳'],
          ['📦', '💰', '🛒'],
        ]);
      case BuildingType.office:
      case BuildingType.skyscraper:
        return EmojiGridArt([
          ['🖥️', '📁', '☕'],
          ['🪑', '🏢', '📞'],
          ['📋', '🖊️', '📎'],
        ]);
      case BuildingType.factory:
      case BuildingType.warehouse:
      case BuildingType.powerPlant:
        return EmojiGridArt([
          ['⚙️', '🔧', '⚡'],
          ['🏭', '📦', '🔩'],
          ['⚙️', '🔧', '⚡'],
        ]);
      case BuildingType.library:
        return EmojiGridArt([
          ['📚', '📖', '📚'],
          ['🪑', '📚', '🪑'],
          ['📖', '📚', '📖'],
        ]);
      case BuildingType.postOffice:
        return EmojiGridArt([
          ['📮', '✉️', '📦'],
          ['📪', '🏣', '📫'],
          ['📝', '💳', '📋'],
        ]);
      default:
        return EmojiGridArt([
          ['🖥️', '📁', '☕'],
          ['🪑', '🏛️', '📞'],
          ['📋', '🖊️', '📎'],
        ]);
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
/// [RoomArt] renders a drawn room (CustomPaint walls + absolute furniture).
class _InteriorArtWidget extends StatelessWidget {
  final InteriorArt art;
  const _InteriorArtWidget({required this.art});

  static const double _cellSize = 28.0;

  @override
  Widget build(BuildContext context) {
    return switch (art) {
      // ── Emoji grid ─────────────────────────────────────────────────────────
      EmojiGridArt(:final cells) => Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(8),
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
      // ── Drawn room ─────────────────────────────────────────────────────────
      RoomArt(:final furniture, :final wallColor) => AspectRatio(
          aspectRatio: 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LayoutBuilder(
              builder: (_, c) => _buildRoom(furniture, wallColor, c.maxWidth),
            ),
          ),
        ),
    };
  }

  /// Builds the drawn-room view: CustomPaint walls + sparsely placed items.
  Widget _buildRoom(
    List<(double, double, String)> furniture,
    Color wallColor,
    double side,
  ) {
    const double halfBox = 11.0; // half of the 22×22 emoji bounding box
    return Stack(
      children: [
        // Floor colour + drawn wall lines
        Positioned.fill(child: CustomPaint(painter: _RoomPainter(wallColor: wallColor))),
        // Furniture – positioned by normalised (x, y) coordinates
        for (final (nx, ny, emoji) in furniture)
          Positioned(
            left: nx * side - halfBox,
            top: ny * side - halfBox,
            width: halfBox * 2,
            height: halfBox * 2,
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
      ],
    );
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
                          style: const TextStyle(fontSize: 18),
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

/// Paints a simple room interior: warm floor fill, thin wall lines on all four
/// sides, and a door gap at the centre of the bottom wall.
///
/// Designed to be replaced by [ImageArt] when a real room illustration is
/// available — the [CustomPaint] approach ensures zero widget-level changes.
class _RoomPainter extends CustomPainter {
  final Color wallColor;
  const _RoomPainter({required this.wallColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Floor ───────────────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF2C1A0E).withValues(alpha: 0.60),
    );

    // ── Wall paint ──────────────────────────────────────────────────────────
    final wall = Paint()
      ..color = wallColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const e = 1.25; // half stroke-width offset so lines sit inside the rect

    // Top wall (full)
    canvas.drawLine(Offset(0, e), Offset(w, e), wall);
    // Left wall (full)
    canvas.drawLine(Offset(e, 0), Offset(e, h), wall);
    // Right wall (full)
    canvas.drawLine(Offset(w - e, 0), Offset(w - e, h), wall);

    // Bottom wall with door gap centred
    final doorHalf = w * 0.10;
    final mid = w / 2;
    canvas.drawLine(Offset(e, h - e), Offset(mid - doorHalf, h - e), wall);
    canvas.drawLine(Offset(mid + doorHalf, h - e), Offset(w - e, h - e), wall);
    // Small door-frame verticals
    canvas.drawLine(Offset(mid - doorHalf, h - e), Offset(mid - doorHalf, h - 9), wall);
    canvas.drawLine(Offset(mid + doorHalf, h - e), Offset(mid + doorHalf, h - 9), wall);
  }

  @override
  bool shouldRepaint(_RoomPainter old) => old.wallColor != wallColor;
}
