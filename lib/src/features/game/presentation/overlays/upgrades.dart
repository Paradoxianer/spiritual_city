part of '../game_screen.dart';

/// Upgrade panel in the pastor house (⚔️ tab). Every upgrade is an
/// [ActionButton] costing 📖 insight; level and effect sit below it as
/// numbers only – no text to translate.
class _UpgradePanel extends StatefulWidget {
  final SpiritWorldGame game;
  const _UpgradePanel({required this.game});

  @override
  State<_UpgradePanel> createState() => _UpgradePanelState();
}

class _UpgradePanelState extends State<_UpgradePanel> {
  PlayerProgress get _progress => widget.game.progress;
  CombatProfile get _profile => _progress.combatProfile;

  void _buy(int level, VoidCallback apply) {
    setState(() {
      final before = widget.game.combatAbilityTiers;
      if (_progress.spendInsight(upgradeInsightCost(level))) {
        apply();
        // A new ability (#179) is announced, not just a bigger number.
        final after = widget.game.combatAbilityTiers;
        for (final m in PrayerMode.values) {
          if ((after[m] ?? 0) > (before[m] ?? 0)) {
            widget.game.announce('✨ ${CombatAbilities.emoji[m]![after[m]! - 1]}');
          }
        }
        // Daemons keep their strength for a few visits (#178 grace period).
        _progress.onUpgradeBought();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _progress,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  '📖 ${_insightLabel(_progress)}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // ── Defence ───────────────────────────────────────────────────
              _UpgradeGroup(
                icon: '🛡️',
                color: Colors.white70,
                title: '',
                children: [
                  _UpgradeTile(
                    emoji: '🛡️',
                    label: AppStrings.get('upgrade.shield'),
                    level: _profile.shieldLevel,
                    effect: '−${(_profile.shieldDamageReduction * 100).toStringAsFixed(0)}%🙏',
                    insight: _progress.insight,
                    onBuy: () => _buy(_profile.shieldLevel, () => _profile.shieldLevel++),
                  ),
                  _UpgradeTile(
                    emoji: '⛑️',
                    label: AppStrings.get('upgrade.helm'),
                    level: _profile.helmLevel,
                    effect: '−${(_profile.helmHungerReduction * 100).toStringAsFixed(0)}%🍞',
                    insight: _progress.insight,
                    onBuy: () => _buy(_profile.helmLevel, () => _profile.helmLevel++),
                  ),
                ],
              ),
              // ── Attack: one group per prayer mode ───────────────────────
              for (final mode in PrayerMode.values) _buildModeGroup(mode),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeGroup(PrayerMode mode) {
    final s = _profile.getFor(mode);
    final skills = _progress.skills;
    final tier = CombatAbilities.tier(s);
    final level = CombatAbilities.modeLevel(s);
    // Not learned yet, or at the mentor cap: the next step is a 🎓 lesson.
    final modeSkill = CombatAbilities.modeSkill(mode);
    final cap = CombatAbilities.levelCap(mode, skills);
    final next = CombatAbilities.nextMastery(mode, skills);
    final Availability? lock = !CombatAbilities.canUse(mode, skills)
        ? Locked('🎓${modeSkill!.emoji}')
        : level >= cap
            ? (next == null ? const Locked('✅') : const Locked('🔒'))
            : null;
    // At the cap the next mentor step is shown with what it still needs and
    // a 📍 to follow it (playtest 2026-10-19: the way on was not visible).
    final teach = !CombatAbilities.canUse(mode, skills) ? modeSkill : (level >= cap ? next : null);
    _UpgradeTile tile(String emoji, String key, int level, double value, VoidCallback apply) =>
        _UpgradeTile(
          emoji: emoji,
          label: AppStrings.get('upgrade.$key'),
          level: level,
          effect: _pct(value),
          insight: _progress.insight,
          lock: lock,
          onBuy: () => _buy(level, apply),
        );
    return _UpgradeGroup(
      icon: mode.icon,
      color: mode.color,
      title: AppStrings.get('mode.${mode.id}'),
      badge: '$level/$cap',
      // Abilities: unlocked ones bright, the next with the level it needs.
      footer: Wrap(
        spacing: 10,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (teach != null) _NextLesson(game: widget.game, skill: teach),
          for (var i = 0; i < CombatAbilities.milestones.length; i++)
            Opacity(
              opacity: i < tier ? 1.0 : 0.45,
              child: Text(
                i < tier
                    ? CombatAbilities.emoji[mode]![i]
                    : '${CombatAbilities.emoji[mode]![i]} 🔒$level/${CombatAbilities.milestones[i]}',
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
        ],
      ),
      children: [
        tile('🎯', 'radius', s.radiusLevel, s.radius, () => s.radiusLevel++),
        tile('⚡', 'strength', s.strengthLevel, s.strength, () => s.strengthLevel++),
        tile('⏱️', 'duration', s.durationLevel, s.duration, () => s.durationLevel++),
        tile('💨', 'speed', s.speedLevel, s.speed, () => s.speedLevel++),
      ],
    );
  }
}

/// The mentor step that opens the next upgrades: `🎓🕊️⭐⭐ ⛪ 📍`, or what
/// is still missing (`🔒 🏰🔥 0/1`), or the running count (`7/20 👹`).
class _NextLesson extends StatelessWidget {
  final SpiritWorldGame game;
  final Skill skill;
  const _NextLesson({required this.game, required this.skill});

  @override
  Widget build(BuildContext context) {
    final p = game.progress;
    final l = Lessons.of(skill);
    final awakenings = p.awakenedQuarters.length;
    final key = GameMissionTracking.lessonKey(skill);
    final String status;
    if (p.lesson.active == skill) {
      status = '${p.lesson.progress}/${l.count} ${l.task.emoji}';
    } else if (l.isOpen(p.skills, awakenings)) {
      status = l.mentorAt.map(BuildingComponent.buildingEmoji).join(' ');
    } else {
      status = '🔒 ${[
        for (final r in l.requires)
          if (!p.skills.has(r)) r.emoji,
        if (awakenings < l.minAwakenings) '🏰🔥 $awakenings/${l.minAwakenings}',
      ].join(' ')}';
    }
    return ValueListenableBuilder<String?>(
      valueListenable: game.trackedMission,
      builder: (context, tracked, _) => Container(
        padding: const EdgeInsets.fromLTRB(8, 2, 2, 2),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎓${skill.emoji}  $status',
                style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(36, 30),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              onPressed: () => game.toggleTrackedMission(key),
              child: Text(tracked == key ? '📍✅' : '📍', style: const TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A section like the original panel: a header (icon, name, level/cap)
/// and the upgrades as equal tiles side by side.
class _UpgradeGroup extends StatelessWidget {
  final String icon;
  final Color color;
  final String title;
  final String? badge;
  final List<Widget> children;
  final Widget? footer;

  const _UpgradeGroup({
    required this.icon,
    required this.color,
    required this.title,
    required this.children,
    this.badge,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              if (title.isNotEmpty)
                Text(title,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Lv $badge', style: const TextStyle(color: Colors.amber, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(child: children[i]),
              ],
              // Defence has two upgrades: keep tiles as wide as attack ones.
              for (var i = children.length; i < 4; i++) ...[
                const SizedBox(width: 4),
                const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 6), footer!],
        ],
      ),
    );
  }
}

/// One upgrade as in the original panel: icon, name, `Lv n`, effect and a
/// 📖 cost button (🔒🎓 when a mentor has to teach the next step).
class _UpgradeTile extends StatelessWidget {
  final String emoji;
  final String label;
  final int level;
  final String effect;
  final int insight;
  final VoidCallback onBuy;

  /// Set when a mentor has to teach the next step first.
  final Availability? lock;

  const _UpgradeTile({
    required this.emoji,
    required this.label,
    required this.level,
    required this.effect,
    required this.insight,
    required this.onBuy,
    this.lock,
  });

  @override
  Widget build(BuildContext context) {
    final cost = upgradeInsightCost(level);
    final canAfford = insight >= cost;
    final locked = lock;
    final active = locked == null && canAfford;
    final buyLabel = locked is Locked ? locked.emoji : '📖 $cost';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Lv $level', style: const TextStyle(color: Colors.amber, fontSize: 9)),
          ),
          const SizedBox(height: 2),
          Text(effect,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: active ? onBuy : null,
            child: Opacity(
              opacity: active ? 1.0 : 0.45,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? Colors.amber.withValues(alpha: 0.25) : Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active ? Colors.amber.withValues(alpha: 0.7) : Colors.white24,
                  ),
                ),
                child: Text(buyLabel,
                    style: TextStyle(
                      color: active ? Colors.amber : Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
