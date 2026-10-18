part of '../game_screen.dart';

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
    return (NpcActions.bible.baseSeconds / factor).round();
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
  /// Slots follow [NpcActions.chat] (1=💬 … 6=✝️🕊️) and never shift when an
  /// optional action is hidden. Hidden or unavailable actions are skipped.
  void _onDialogKey() {
    final idx = widget.game.dialogActionIndex.value;
    if (idx < 0 || _showLifeTab) return;
    final model = widget.game.activeDialog?.npcModel;
    if (model == null || idx >= NpcActions.chat.length) return;
    final action = NpcActions.chat[idx];
    if (!action.isVisibleFor(model)) return;
    if (!action.availability(model, widget.game, widget.game.difficulty).isOk) return;
    _handleInteraction(action.type, action.emoji);
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

  /// Which tab of the dialog is shown: the chat (💬) or the life story (📜).
  bool _showLifeTab = false;

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
        if (!mounted) {
          t.cancel();
          return;
        }
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

  /// Thin mission-progress banner shown between the NPC header and the chat.
  Widget _buildNpcMissionBanner(NPCModel model) {
    final mission = model.activeMission;
    if (mission == null) return const SizedBox.shrink();
    final countLabel = mission.targetCount > 1 ? ' ×${mission.targetCount}' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      color: const Color(0xFF1B4A1B).withValues(alpha: 0.85),
      child: Row(
        children: [
          const Text('📋', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text('${mission.actionEmoji}$countLabel', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          if (mission.targetCount > 1)
            _MissionProgressBar(
              progress: mission.progress,
              targetCount: mission.targetCount,
            )
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

  @override
  Widget build(BuildContext context) {
    final dialog = widget.game.activeDialog;
    if (dialog == null) return const SizedBox.shrink();
    final model = dialog.npcModel;

    return OverlayShell(
      theme: OverlayTheme.npc,
      placement: OverlayPlacement.bottom,
      leading: CircleAvatar(
        backgroundColor: Colors.white24,
        child: Text(dialog.npcEmoji),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dialog.npcName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (_showDelta) _buildDeltaRow(),
        ],
      ),
      trailing: [
        RelationshipHearts(level: Relationship.level(model.sessionBonus)),
        SessionDots(done: model.currentSessionInteractions, max: model.maxSessionInteractions),
      ],
      onClose: _isReadingBible ? null : () => widget.game.closeDialog(),
      banner: model.activeMission != null ? _buildNpcMissionBanner(model) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFFECE5DD).withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DialogTabBar(
                    showLifeTab: _showLifeTab,
                    lifeLocked: !widget.game.progress.skills.has(Skill.pastoralCare),
                    onSelect: (life) => setState(() => _showLifeTab = life),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: _showLifeTab
                        ? _NpcLifeTimeline(model: model)
                        : Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _messages.length,
                              itemBuilder: (context, index) =>
                                  _ChatBubble(message: _messages[index]),
                            ),
                          ),
                  ),
                  // The chat is hidden in the life tab, so its last reaction
                  // stays visible there.
                  if (_showLifeTab && _messages.isNotEmpty) _ChatBubble(message: _messages.last),
                ],
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
      actions: _isSessionOver ? null : _buildActions(model),
    );
  }

  Widget _buildActions(NPCModel model) {
    if (_isReadingBible) {
      return _Countdown(emoji: NpcActions.bible.emoji, seconds: _bibleSecondsLeft);
    }
    if (_showLifeTab) {
      return _LifeTalkButton(
        model: model,
        game: widget.game,
        enabled: !_isWaiting,
        onTap: () => _handleInteraction(NpcActions.lifeTalk.type, NpcActions.lifeTalk.emoji),
        onHealer: () => _handleInteraction(NPCComponent.healerTalkType, '🩹'),
      );
    }
    // Fixed key slots 1–6; hidden actions keep their number.
    return ActionBar(
      children: [
        for (var i = 0; i < NpcActions.chat.length; i++)
          if (NpcActions.chat[i].isVisibleFor(model))
            ActionButton.of(
              NpcActions.chat[i],
              model,
              wallet: widget.game,
              difficulty: widget.game.difficulty,
              practice: widget.game.progress.practice,
              keyIndex: i + 1,
              enabled: !_isWaiting,
              highlighted: NpcActions.chat[i] == NpcActions.convert ||
                  model.activeMission?.actionEmoji == NpcActions.chat[i].emoji,
              onTap: () => _handleInteraction(NpcActions.chat[i].type, NpcActions.chat[i].emoji),
            ),
      ],
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

/// Two-tab switch at the top of the NPC dialog: 💬 (chat + actions) and 📜
/// (life story with the single 🗣️ life-talk action).
class _DialogTabBar extends StatelessWidget {
  final bool showLifeTab;

  /// 📜 needs the 🫂 pastoral-care lesson (mentor in a 🏥 hospital).
  final bool lifeLocked;
  final void Function(bool life) onSelect;

  const _DialogTabBar({
    required this.showLifeTab,
    required this.lifeLocked,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    Widget tab(String emoji, bool life) {
      final selected = showLifeTab == life;
      return GestureDetector(
        onTap: () => onSelect(life),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? Colors.white24 : Colors.black26,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
      );
    }

    return Row(
      children: [
        tab('💬', false),
        const SizedBox(width: 6),
        if (lifeLocked)
          // Locked: shows where to learn it instead of opening.
          Tooltip(
            message: '🎓🫂 🏥',
            triggerMode: TooltipTriggerMode.tap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('📜🔒', style: TextStyle(fontSize: 18)),
            ),
          )
        else
          tab('📜', true),
      ],
    );
  }
}

/// The NPC's life as a CV-style list, one emoji "sentence" per line: birth
/// at the top, today at the bottom (docs/game_design/npc_backstory.md v5.2).
/// No text – emoji only, so nothing needs localising.
/// Revealed up to the earliest unresolved challenge – what lies beyond
/// stays "not told yet" until the player has talked their way there.
/// Worked-through challenges reappear just before "today" as "→🌱"
/// lines: the solution becomes part of the life story.
class _NpcLifeTimeline extends StatelessWidget {
  final NPCModel model;

  const _NpcLifeTimeline({required this.model});

  @override
  Widget build(BuildContext context) {
    final backstory = model.backstory;
    final current = backstory.currentChallenge;
    final revealed = backstory.revealedCount;

    final rows = <Widget>[
      const _LifeLine(age: 0, story: '👶🎉'),
    ];
    var hidden = 0;
    for (var i = 0; i < backstory.events.length; i++) {
      final o = backstory.events[i];
      if (o.phase == LifePhase.christ) continue;
      if (i >= revealed) {
        hidden++;
        continue;
      }
      rows.add(_LifeLine(
        age: o.age,
        story: o.event.story,
        isCurrent: o == current,
        progress: o == current ? o.workProgress : null,
        faded: o.event.isNegative && o.processed,
      ));
    }
    if (hidden > 0) {
      rows.add(const _LifeLine(story: '❓❓❓', faded: true));
    }

    // Recent life: what the pastor helped resolve, faith, then today.
    for (final o in backstory.resolvedChallenges) {
      if (o.phase == LifePhase.christ) continue;
      rows.add(_LifeLine(story: '${o.event.glyph}➡️🌱'));
    }
    if (model.isConverted) {
      rows.add(const _LifeLine(story: '🙏✝️🕊️'));
    }
    for (final o in backstory.events) {
      if (o.phase != LifePhase.christ) continue;
      rows.add(_LifeLine(
        story: o.event.story,
        isCurrent: o == current,
        progress: o == current ? o.workProgress : null,
      ));
    }
    rows.add(_LifeLine(age: backstory.age, story: '📍'));

    return ListView(children: rows);
  }
}

/// One line of [_NpcLifeTimeline]: age · emoji sentence, highlighted
/// (with ●○○ progress) when it is the challenge the next 🗣️ works on.
class _LifeLine extends StatelessWidget {
  final int? age;
  final String story;
  final bool isCurrent;
  final int? progress;
  final bool faded;

  const _LifeLine({
    this.age,
    required this.story,
    this.isCurrent = false,
    this.progress,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrent ? Colors.amber.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isCurrent ? Border.all(color: Colors.amber, width: 1) : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                age == null ? '' : '$age',
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(story, style: const TextStyle(fontSize: 18)),
            ),
            if (progress != null)
              Text(
                '●' * progress! + '○' * (OccurredEvent.workRequired - progress!),
                style: const TextStyle(color: Colors.amber, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}

/// The life tab's only action: talk about the next challenge (🗣️ + its
/// glyph). A normal session interaction – uses a session point like 💬/👂.
class _LifeTalkButton extends StatelessWidget {
  final NPCModel model;
  final SpiritWorldGame game;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onHealer;

  const _LifeTalkButton({
    required this.model,
    required this.game,
    required this.enabled,
    required this.onTap,
    required this.onHealer,
  });

  @override
  Widget build(BuildContext context) {
    final current = model.backstory.currentChallenge;
    if (current == null) {
      return const Center(child: Text('🌱✨', style: TextStyle(fontSize: 20)));
    }
    final healer = game.progress.church.healerFor(
      current.event.id,
      game.dayStats.day,
      exceptNpcId: model.id,
    );
    return ActionBar(
      children: [
        ActionButton.of(
          NpcActions.lifeTalk,
          model,
          emoji: '${NpcActions.lifeTalk.emoji}${current.event.glyph}',
          wallet: game,
          difficulty: game.difficulty,
          practice: game.progress.practice,
          enabled: enabled,
          onTap: onTap,
        ),
        // 🩹 A church member who went through the same wound helps – free.
        if (healer != null)
          ActionButton(
            emoji: '🩹${current.event.glyph}',
            hint: healer.name.split(' ').first,
            highlighted: true,
            enabled: enabled,
            onTap: onHealer,
          ),
      ],
    );
  }
}
