part of '../game_screen.dart';

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

  /// Street address at the door, e.g. "Lindenallee 14" (null if unknown).
  final String? address;

  GameBuildingData({required this.building, this.address});
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
  State<BuildingInteriorOverlay> createState() => _BuildingInteriorOverlayState();
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

  /// Actions of the current building in keyboard order – populated when
  /// [_accessGranted] becomes true.
  List<GameAction<BuildingModel>> _actions = const [];

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
    final type = widget.game.activeBuildingData?.building.type;
    final action = type == null ? null : BuildingActions.find(type, actionType);
    if (action == null || action.baseSeconds == 0) return 0;
    return _scaledDuration(action.baseSeconds);
  }

  @override
  void initState() {
    super.initState();
    widget.game.buildingActionIndex.addListener(_onBuildingKey);
    final data = widget.game.activeBuildingData;
    if (data == null) return;

    if (data.building.isAlwaysOpen) {
      _accessGranted = true;
      _actions = BuildingActions.forType(data.building.type);
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
    final data = widget.game.activeBuildingData;
    if (data == null || idx >= _actions.length) return;
    final action = _actions[idx];
    if (!action.availability(data.building, widget.game, widget.game.difficulty).isOk) return;
    _performAction(action.type);
  }

  void _attemptKnock() {
    final data = widget.game.activeBuildingData;
    if (data == null) return;
    final granted = widget.game.attemptBuildingAccess(data.building);
    setState(() {
      _accessGranted = granted;
      _lastReaction = null;
      if (granted) _actions = BuildingActions.forType(data.building.type);
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
        if (!mounted) {
          t.cancel();
          return;
        }
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
    final building = data.building;
    final isHome = building.isHomebase;
    final inside = _accessGranted == true;
    final showUpgrades = isHome && _homeTab == 1;

    final Widget body;
    if (_accessGranted == null) {
      body = _buildKnockScreen(building);
    } else if (_accessGranted == false) {
      body = _buildDeniedScreen();
    } else if (showUpgrades) {
      body = SingleChildScrollView(child: _UpgradePanel(game: widget.game));
    } else {
      body = SingleChildScrollView(child: _buildInteriorScreen(building));
    }

    return OverlayShell(
      theme: isHome ? OverlayTheme.home : OverlayTheme.building,
      leading: Text(
        BuildingComponent.buildingEmoji(building.type),
        style: const TextStyle(fontSize: 30),
      ),
      title: _buildTitle(data),
      trailing: [
        if (isHome) _HomeTabs(selected: _homeTab, onSelect: (t) => setState(() => _homeTab = t)),
        if (!isHome)
          SessionDots(
              done: building.currentSessionInteractions, max: building.maxSessionInteractions),
      ],
      onClose: () => widget.game.closeBuildingInterior(),
      banner: building.activeMission != null && inside ? _buildMissionBanner(building) : null,
      body: body,
      actions: inside && !showUpgrades
          ? (_isActionBusy ? _buildActionCountdown() : _buildActionBar(building))
          : null,
    );
  }

  /// Which pastor-house tab is shown: 0 = actions, 1 = upgrades.
  int _homeTab = 0;

  /// Address (a proper name, no translation needed) and the residents.
  Widget _buildTitle(GameBuildingData data) {
    final residents = data.building.residents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data.address != null)
          Text(
            data.address!,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: data.building.isHomebase ? const Color(0xFFFFD54F) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        if (residents.isNotEmpty)
          Text(
            residents.map((r) => r.name.split(' ').first).join(' · '),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
          ),
      ],
    );
  }

  // ── Mission banner ────────────────────────────────────────────────────────

  /// Thin banner below the header when the building has an active mission:
  /// the action emoji tells the player which button to press.
  Widget _buildMissionBanner(BuildingModel building) {
    final mission = building.activeMission;
    if (mission == null) return const SizedBox.shrink();
    final countLabel = mission.targetCount > 1 ? ' ×${mission.targetCount}' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: const Color(0xFF1B4A1B).withValues(alpha: 0.85),
      child: Row(
        children: [
          const Text('📋', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text('${mission.actionEmoji}$countLabel', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          if (mission.targetCount > 1)
            _MissionProgressBar(progress: mission.progress, targetCount: mission.targetCount)
          else
            Text(
              '${mission.progress}/${mission.targetCount}',
              style: const TextStyle(color: Colors.amber, fontSize: 11),
            ),
          const SizedBox(width: 6),
          Text(
            '+${mission.insightReward.toStringAsFixed(1)} 📖',
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Knock screen (residential only) ──────────────────────────────────────

  Widget _buildKnockScreen(BuildingModel building) {
    final chance = (building.accessChance(widget.game.faith) * 100).round();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚪', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          // Success chance, with the known-house bonus as 🤝.
          Text(
            '🎲 $chance %${building.interactionCount >= 3 ? '  🤝' : ''}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 15),
          ),
          if (building.residents.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildResidentChips(building, compact: true),
          ],
          const SizedBox(height: 18),
          ActionButton(emoji: '🔔', keyIndex: 1, highlighted: true, onTap: _attemptKnock),
        ],
      ),
    );
  }

  // ── Denied screen ─────────────────────────────────────────────────────────

  Widget _buildDeniedScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚪😤', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 18),
          ActionButton(emoji: '👋', onTap: () => widget.game.closeBuildingInterior()),
        ],
      ),
    );
  }

  // ── Interior screen ───────────────────────────────────────────────────────

  /// Same pattern as the NPC dialog: what you know in the middle (room,
  /// residents, reaction, faith bar), what you can do in the bar below.
  Widget _buildInteriorScreen(BuildingModel building) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
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
              const VerticalDivider(width: 1, thickness: 1, color: Colors.white12),
              Container(
                color: Colors.black26,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Center(child: _FaithBarWidget(entity: building)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Countdown shown in place of the action bar while an action is running.
  Widget _buildActionCountdown() {
    final type = widget.game.activeBuildingData?.building.type;
    final pending = _pendingActionType;
    final emoji =
        (type == null || pending == null) ? '⏳' : BuildingActions.find(type, pending)?.emoji ?? '⏳';
    return _Countdown(emoji: emoji, seconds: _actionSecondsLeft);
  }

  /// One [ActionButton] per [BuildingActions] entry; key numbers follow the
  /// list order. The active mission's action is highlighted.
  Widget _buildActionBar(BuildingModel building) {
    final g = widget.game;
    final missionEmoji = building.activeMission?.actionEmoji;
    return ActionBar(
      children: [
        for (var i = 0; i < _actions.length; i++)
          ActionButton.of(
            _actions[i],
            building,
            wallet: g,
            difficulty: g.difficulty,
            practice: g.progress.practice,
            keyIndex: i + 1,
            highlighted: missionEmoji != null && _actions[i].emoji.startsWith(missionEmoji),
            onTap: () => _performAction(_actions[i].type),
          ),
      ],
    );
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
      case NPCType.priest:
        return 'Pastor';
      case NPCType.merchant:
        return 'Händler';
      case NPCType.officer:
        return 'Beamter';
      default:
        return 'Bürger';
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
          (2, 2): '📚',
          (2, 9): '🛏️',
          (4, 4): '📖',
          (4, 8): '🕯️',
          (6, 5): '🙏',
          (8, 2): '🪴',
          (8, 8): '☕',
        }));
      case BuildingType.house:
        return EmojiGridArt(_makeRoom({
          (2, 2): '🛋️',
          (2, 8): '🛏️',
          (4, 5): '📺',
          (6, 2): '🍳',
          (6, 9): '🪑',
          (8, 4): '🪴',
          (8, 8): '🧸',
          (10, 5): '🐾',
        }));
      case BuildingType.apartment:
        return EmojiGridArt(_makeRoom({
          (2, 3): '🛏️',
          (2, 8): '🚿',
          (4, 6): '💻',
          (6, 2): '🛋️',
          (6, 8): '📺',
          (8, 4): '🍳',
          (8, 9): '☕',
          (10, 5): '🪴',
        }));
      // ── Religion ─────────────────────────────────────────────────────────────
      case BuildingType.church:
        return EmojiGridArt(_makeRoom({
          (1, 5): '✝️',
          (3, 2): '🕯️',
          (3, 9): '🕯️',
          (5, 5): '📖',
          (7, 2): '🪑',
          (7, 5): '🙏',
          (7, 9): '🪑',
          (9, 3): '🪑',
          (9, 8): '🪑',
        }));
      case BuildingType.cathedral:
        return EmojiGridArt(_makeRoom({
          (1, 5): '✝️',
          (2, 2): '🕯️',
          (2, 9): '🕯️',
          (3, 5): '🔔',
          (5, 3): '📖',
          (5, 8): '📖',
          (6, 5): '🙏',
          (8, 2): '🪑',
          (8, 9): '🪑',
          (10, 4): '🎵',
          (10, 7): '🎵',
        }));
      case BuildingType.cemetery:
        return EmojiGridArt(_makeRoom({
          (2, 3): '✝️',
          (2, 8): '✝️',
          (4, 1): '🌿',
          (4, 6): '✝️',
          (4, 10): '🌿',
          (6, 3): '🕯️',
          (6, 8): '🕯️',
          (8, 5): '⛪',
          (10, 2): '🌹',
          (10, 9): '🌹',
        }));
      // ── Health & Education ───────────────────────────────────────────────────
      case BuildingType.hospital:
        return EmojiGridArt(_makeRoom({
          (2, 2): '🛏️',
          (2, 7): '🛏️',
          (4, 4): '🩺',
          (6, 2): '💊',
          (6, 8): '🔬',
          (8, 5): '📋',
          (10, 2): '🏥',
          (10, 8): '🧴',
        }));
      case BuildingType.school:
        return EmojiGridArt(_makeRoom({
          (1, 5): '🖊️',
          (3, 2): '🪑',
          (3, 5): '🪑',
          (3, 9): '🪑',
          (6, 3): '📝',
          (6, 7): '📚',
          (8, 2): '🪑',
          (8, 5): '🪑',
          (8, 9): '🪑',
          (10, 5): '📐',
        }));
      case BuildingType.university:
        return EmojiGridArt(_makeRoom({
          (2, 3): '📚',
          (2, 8): '🔬',
          (4, 5): '🎓',
          (6, 2): '💻',
          (6, 9): '🗂️',
          (8, 4): '📖',
          (8, 8): '🧪',
          (10, 5): '🏛️',
        }));
      // ── Commercial ───────────────────────────────────────────────────────────
      case BuildingType.shop:
        return EmojiGridArt(_makeRoom({
          (2, 2): '📦',
          (2, 8): '📦',
          (4, 5): '🛒',
          (6, 2): '🏷️',
          (6, 5): '🛍️',
          (6, 9): '💰',
          (8, 3): '📦',
          (8, 8): '📦',
          (10, 5): '🪙',
        }));
      case BuildingType.supermarket:
        return EmojiGridArt(_makeRoom({
          (2, 2): '🥦',
          (2, 5): '🥩',
          (2, 9): '🥛',
          (4, 4): '🥫',
          (4, 8): '🍞',
          (6, 5): '🛒',
          (8, 2): '🧃',
          (8, 8): '🧴',
          (10, 4): '💳',
          (10, 7): '🧾',
        }));
      case BuildingType.mall:
        return EmojiGridArt(_makeRoom({
          (2, 2): '👗',
          (2, 9): '👟',
          (4, 5): '☕',
          (6, 2): '💎',
          (6, 5): '🛍️',
          (6, 9): '🍕',
          (8, 3): '👜',
          (8, 8): '🎁',
          (10, 5): '💳',
        }));
      case BuildingType.office:
        return EmojiGridArt(_makeRoom({
          (2, 2): '🖥️',
          (2, 8): '📁',
          (4, 5): '☕',
          (6, 2): '🪑',
          (6, 5): '📋',
          (6, 9): '🖊️',
          (8, 3): '📞',
          (8, 8): '💼',
          (10, 5): '📊',
        }));
      case BuildingType.skyscraper:
        return EmojiGridArt(_makeRoom({
          (2, 3): '📊',
          (2, 8): '💹',
          (4, 5): '💻',
          (6, 2): '📱',
          (6, 5): '🤝',
          (6, 9): '💼',
          (8, 3): '🖥️',
          (8, 8): '📋',
          (10, 5): '🏙️',
        }));
      // ── Industrial ───────────────────────────────────────────────────────────
      case BuildingType.factory:
        return EmojiGridArt(_makeRoom({
          (2, 2): '⚙️',
          (2, 8): '🔧',
          (4, 5): '⚡',
          (6, 2): '🔩',
          (6, 5): '📦',
          (6, 9): '🔨',
          (8, 3): '⚙️',
          (8, 8): '🪛',
          (10, 5): '🏭',
        }));
      case BuildingType.warehouse:
        return EmojiGridArt(_makeRoom({
          (2, 2): '📦',
          (2, 5): '📦',
          (2, 9): '📦',
          (4, 2): '📦',
          (4, 9): '📦',
          (5, 5): '📋',
          (7, 2): '📦',
          (7, 9): '📦',
          (9, 3): '🔦',
          (9, 7): '📦',
        }));
      case BuildingType.powerPlant:
        return EmojiGridArt(_makeRoom({
          (2, 2): '⚡',
          (2, 9): '⚡',
          (4, 4): '🔌',
          (4, 8): '🔌',
          (6, 5): '⚡',
          (8, 2): '🔧',
          (8, 5): '🔌',
          (8, 9): '🔧',
          (10, 5): '🏭',
        }));
      // ── Culture ──────────────────────────────────────────────────────────────
      case BuildingType.library:
        return EmojiGridArt(_makeRoom({
          (2, 1): '📚',
          (2, 4): '📚',
          (2, 8): '📚',
          (4, 1): '📚',
          (4, 10): '📚',
          (6, 4): '📖',
          (6, 7): '📖',
          (8, 2): '🪑',
          (8, 5): '📖',
          (8, 9): '🪑',
          (10, 5): '🔎',
        }));
      case BuildingType.museum:
        return EmojiGridArt(_makeRoom({
          (2, 2): '🖼️',
          (2, 9): '🖼️',
          (4, 5): '🏺',
          (6, 2): '🗿',
          (6, 9): '📜',
          (7, 5): '🔎',
          (8, 3): '🎭',
          (8, 8): '🪆',
          (10, 5): '🏛️',
        }));
      case BuildingType.stadium:
        return EmojiGridArt(_makeRoom({
          (2, 2): '📣',
          (2, 5): '⚽',
          (2, 9): '📣',
          (4, 5): '🏟️',
          (6, 2): '🏆',
          (6, 5): '🎫',
          (6, 9): '🎽',
          (8, 3): '🎵',
          (8, 8): '📸',
          (10, 5): '🏅',
        }));
      // ── Civic / Government ───────────────────────────────────────────────────
      case BuildingType.cityHall:
        return EmojiGridArt(_makeRoom({
          (2, 2): '⚖️',
          (2, 9): '📜',
          (4, 5): '🗳️',
          (6, 2): '📋',
          (6, 5): '🤝',
          (6, 9): '🏛️',
          (8, 3): '🖊️',
          (8, 8): '📁',
          (10, 5): '🔏',
        }));
      case BuildingType.postOffice:
        return EmojiGridArt(_makeRoom({
          (2, 2): '📮',
          (2, 9): '📫',
          (4, 5): '✉️',
          (6, 2): '📦',
          (6, 5): '💳',
          (6, 9): '📝',
          (8, 3): '📬',
          (8, 8): '🔖',
          (10, 5): '🏣',
        }));
      case BuildingType.policeStation:
        return EmojiGridArt(_makeRoom({
          (2, 2): '👮',
          (2, 9): '🔑',
          (4, 5): '🔵',
          (6, 2): '📋',
          (6, 5): '🔒',
          (6, 9): '📡',
          (8, 3): '🚓',
          (8, 8): '🔍',
          (10, 5): '🛡️',
        }));
      case BuildingType.fireStation:
        return EmojiGridArt(_makeRoom({
          (2, 2): '🧯',
          (2, 9): '🪓',
          (4, 5): '🔴',
          (6, 2): '🪣',
          (6, 5): '🚒',
          (6, 9): '📡',
          (8, 3): '🧰',
          (8, 8): '⛑️',
          (10, 5): '🔥',
        }));
      case BuildingType.trainStation:
        return EmojiGridArt(_makeRoom({
          (2, 2): '🚂',
          (2, 9): '🕐',
          (4, 5): '🎫',
          (6, 2): '🧳',
          (6, 5): '📋',
          (6, 9): '🚂',
          (8, 3): '🪑',
          (8, 8): '🗺️',
          (10, 5): '🚉',
        }));
    }
  }
}

/// 🏠 actions / ⚔️ upgrades switch in the pastor-house header.
class _HomeTabs extends StatelessWidget {
  final int selected;
  final void Function(int tab) onSelect;
  const _HomeTabs({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    Widget tab(String emoji, int i) => GestureDetector(
          onTap: () => onSelect(i),
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected == i ? const Color(0x55FFD54F) : Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [tab('🏠', 0), tab('⚔️', 1)]);
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
