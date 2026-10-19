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
                children: [
                  _UpgradeTile(
                    emoji: '🛡️',
                    level: _profile.shieldLevel,
                    effect: '−${(_profile.shieldDamageReduction * 100).toStringAsFixed(0)}%🙏',
                    insight: _progress.insight,
                    onBuy: () => _buy(_profile.shieldLevel, () => _profile.shieldLevel++),
                  ),
                  _UpgradeTile(
                    emoji: '⛑️',
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
    _UpgradeTile tile(String emoji, int level, double value, VoidCallback apply) => _UpgradeTile(
          emoji: emoji,
          level: level,
          effect: _pct(value),
          insight: _progress.insight,
          onBuy: () => _buy(level, apply),
        );
    final tier = CombatAbilities.tier(s);
    final level = CombatAbilities.modeLevel(s);
    return _UpgradeGroup(
      icon: mode.icon,
      color: mode.color,
      // Abilities: unlocked ones bright, the next with the level it needs.
      footer: Wrap(
        spacing: 10,
        children: [
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
        tile('🎯', s.radiusLevel, s.radius, () => s.radiusLevel++),
        tile('⚡', s.strengthLevel, s.strength, () => s.strengthLevel++),
        tile('⏱️', s.durationLevel, s.duration, () => s.durationLevel++),
        tile('💨', s.speedLevel, s.speed, () => s.speedLevel++),
      ],
    );
  }
}

/// A row of upgrades under a leading emoji (🛡️ or a prayer mode).
class _UpgradeGroup extends StatelessWidget {
  final String icon;
  final Color color;
  final List<Widget> children;
  final Widget? footer;

  const _UpgradeGroup({
    required this.icon,
    required this.color,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
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
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(child: ActionBar(children: children)),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 6), footer!],
        ],
      ),
    );
  }
}

/// One upgrade: [ActionButton] (cost `−N📖`) plus `level · effect` below.
class _UpgradeTile extends StatelessWidget {
  final String emoji;
  final int level;
  final String effect;
  final int insight;
  final VoidCallback onBuy;

  const _UpgradeTile({
    required this.emoji,
    required this.level,
    required this.effect,
    required this.insight,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final cost = upgradeInsightCost(level);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionButton(
          emoji: emoji,
          hint: '−$cost📖',
          availability: insight >= cost
              ? const AvailableNow()
              : const CannotAfford(Resource.insight),
          onTap: onBuy,
        ),
        const SizedBox(height: 2),
        Text(
          '$level · $effect',
          style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
        ),
      ],
    );
  }
}
