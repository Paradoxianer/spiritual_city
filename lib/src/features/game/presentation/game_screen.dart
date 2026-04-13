import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../features/menu/domain/models/difficulty.dart';
import '../domain/models/building_model.dart';
import '../domain/models/cell_object.dart';
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
            _buildingTypeEmoji(building.type),
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _buildingTypeName(building.type),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
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

          // Residents detail list
          if (building.residents.isNotEmpty) ...[
            _buildResidentChips(building, compact: false),
            const SizedBox(height: 10),
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
          _ActionChip(
            label: '💬',
            sublabel: 'Gespräch',
            description: '+5 Glauben · Gespräch führen',
            onTap: () => _performAction('talk'),
          ),
          _ActionChip(
            label: '🙏',
            sublabel: 'Beten',
            description: '+15 Glauben · Familie segnen',
            onTap: () => _performAction('pray'),
          ),
          _ActionChip(
            label: '📦',
            sublabel: 'Helfen',
            description: '+10 Glauben · -10 Material',
            onTap: () => _performAction('help'),
          ),
          _ActionChip(
            label: '📖',
            sublabel: 'Bibel',
            description: '+10 Glauben · Familie +2',
            onTap: () => _performAction('bible'),
          ),
        ];
      case BuildingCategory.commercial:
        return [
          _ActionChip(
            label: '💸',
            sublabel: 'Spende',
            description: '+20–40 Material (50 % Chance)',
            onTap: () => _performAction('donate'),
          ),
          _ActionChip(
            label: '👷',
            sublabel: 'Arbeiter',
            description: '+8 Glauben · Mitarbeiter +3',
            onTap: () => _performAction('worker'),
          ),
          _ActionChip(
            label: '🙏',
            sublabel: 'Beten',
            description: '+10 Glauben · Stadteinfluss +',
            onTap: () => _performAction('prayBusiness'),
          ),
          _ActionChip(
            label: '📦',
            sublabel: 'Verteilen',
            description: '+15 Glauben · -5 Material',
            onTap: () => _performAction('distribute'),
          ),
        ];
      case BuildingCategory.church:
        return [
          _ActionChip(
            label: '📖',
            sublabel: 'Bibellesen',
            description: '+10 Glauben · Wissen vertiefen',
            onTap: () => _performAction('readBible'),
          ),
          _ActionChip(
            label: '🙏',
            sublabel: 'Beten',
            description: '+15 Glauben · Gemeinde +5',
            onTap: () => _performAction('pray'),
          ),
          _ActionChip(
            label: '🎵',
            sublabel: 'Gottesdienst',
            description: '+20 Glauben · Gemeinde +10',
            onTap: () => _performAction('worship'),
          ),
        ];
      case BuildingCategory.civic:
        return [
          _ActionChip(
            label: '🙏',
            sublabel: 'Beten',
            description: '+10 Glauben · Personal +2',
            onTap: () => _performAction('pray'),
          ),
          _ActionChip(
            label: '💬',
            sublabel: 'Zeugnis',
            description: '+8 Glauben · Personal +4',
            onTap: () => _performAction('witness'),
          ),
          _ActionChip(
            label: '📦',
            sublabel: 'Verteilen',
            description: '+12 Glauben · -8 Material',
            onTap: () => _performAction('distribute'),
          ),
        ];
      case BuildingCategory.industrial:
        return [
          _ActionChip(
            label: '🙏',
            sublabel: 'Beten',
            description: '+8 Glauben · Arbeiter +2',
            onTap: () => _performAction('pray'),
          ),
          _ActionChip(
            label: '💬',
            sublabel: 'Zeugnis',
            description: '+10 Glauben · Arbeiter +5',
            onTap: () => _performAction('witness'),
          ),
          _ActionChip(
            label: '📦',
            sublabel: 'Verteilen',
            description: '+15 Glauben · -10 Material',
            onTap: () => _performAction('distribute'),
          ),
        ];
      default:
        return [
          _ActionChip(
            label: '👀',
            sublabel: 'Schauen',
            description: 'Umgebung beobachten',
            onTap: () => setState(() => _lastReaction = '👀'),
          ),
        ];
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns a type-specific emoji for the building.
  String _buildingTypeEmoji(BuildingType type) {
    switch (type) {
      case BuildingType.house:        return '🏠';
      case BuildingType.apartment:    return '🏢';
      case BuildingType.shop:         return '🏪';
      case BuildingType.supermarket:  return '🛒';
      case BuildingType.mall:         return '🛍️';
      case BuildingType.office:       return '🏢';
      case BuildingType.skyscraper:   return '🏙️';
      case BuildingType.factory:      return '🏭';
      case BuildingType.warehouse:    return '🏗️';
      case BuildingType.church:       return '⛪';
      case BuildingType.cathedral:    return '⛪';
      case BuildingType.trainStation: return '🚉';
      case BuildingType.policeStation:return '🚔';
      case BuildingType.fireStation:  return '🚒';
      case BuildingType.postOffice:   return '📮';
      case BuildingType.hospital:     return '🏥';
      case BuildingType.school:       return '🏫';
      case BuildingType.university:   return '🎓';
      case BuildingType.library:      return '📚';
      case BuildingType.museum:       return '🏛️';
      case BuildingType.stadium:      return '🏟️';
      case BuildingType.cityHall:     return '🏛️';
      case BuildingType.cemetery:     return '🪦';
      case BuildingType.powerPlant:   return '⚡';
      default:                        return '🏗️';
    }
  }

  /// Returns the human-readable German name for a specific building type.
  String _buildingTypeName(BuildingType type) {
    switch (type) {
      case BuildingType.house:        return 'Wohnhaus';
      case BuildingType.apartment:    return 'Wohnblock';
      case BuildingType.shop:         return 'Geschäft';
      case BuildingType.supermarket:  return 'Supermarkt';
      case BuildingType.mall:         return 'Einkaufszentrum';
      case BuildingType.office:       return 'Bürogebäude';
      case BuildingType.skyscraper:   return 'Hochhaus';
      case BuildingType.factory:      return 'Fabrik';
      case BuildingType.warehouse:    return 'Lagerhaus';
      case BuildingType.church:       return 'Kirche';
      case BuildingType.cathedral:    return 'Dom';
      case BuildingType.trainStation: return 'Bahnhof';
      case BuildingType.policeStation:return 'Polizeiwache';
      case BuildingType.fireStation:  return 'Feuerwehr';
      case BuildingType.postOffice:   return 'Postamt';
      case BuildingType.hospital:     return 'Krankenhaus';
      case BuildingType.school:       return 'Schule';
      case BuildingType.university:   return 'Universität';
      case BuildingType.library:      return 'Bibliothek';
      case BuildingType.museum:       return 'Museum';
      case BuildingType.stadium:      return 'Stadion';
      case BuildingType.cityHall:     return 'Rathaus';
      case BuildingType.cemetery:     return 'Friedhof';
      case BuildingType.powerPlant:   return 'Kraftwerk';
      default:                        return 'Gebäude';
    }
  }

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

  String _asciiInterior(BuildingCategory cat) {
    switch (cat) {
      case BuildingCategory.residential:
        return '+-----------------------+\n'
               '|  [Wohnzimmer]         |\n'
               '|                       |\n'
               '|  Sofa    Tisch        |\n'
               '|  Pflanze Fenster      |\n'
               '+-----------+-----------+\n'
               '| Schlafzim | Kueche    |\n'
               '+-----------+-----------+';
      case BuildingCategory.commercial:
        return '+-----------------------+\n'
               '|  [Geschaeftsraum]     |\n'
               '|                       |\n'
               '|  Regal  Regal  Regal  |\n'
               '|  Tresen        Buero  |\n'
               '+-----------------------+';
      case BuildingCategory.church:
        return '+-----------------------+\n'
               '|     [Kirchenraum]     |\n'
               '|         Altar         |\n'
               '|  Kerze         Kerze  |\n'
               '|  Bank  Bank  Bank     |\n'
               '|  Bank  Bank  Bank     |\n'
               '+-----------[=]---------+';
      case BuildingCategory.civic:
        return '+-----------------------+\n'
               '|   [Oeffentl. Gebaeude]|\n'
               '|                       |\n'
               '|  Empfang  Buero       |\n'
               '|  Wartezimmer          |\n'
               '+-----------------------+';
      case BuildingCategory.industrial:
        return '+-----------------------+\n'
               '|   [Produktionshalle]  |\n'
               '|                       |\n'
               '|  Masch.  Masch.       |\n'
               '|  Lager        Buero   |\n'
               '+-----------------------+';
      default:
        return '+-----------------------+\n'
               '|                       |\n'
               '|        [Raum]         |\n'
               '|                       |\n'
               '+-----------------------+';
    }
  }
}

/// A compact action chip used inside [BuildingInteriorOverlay].
class _ActionChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final String description;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.sublabel,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
