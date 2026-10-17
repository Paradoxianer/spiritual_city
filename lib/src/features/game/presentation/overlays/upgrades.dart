part of '../game_screen.dart';

/// Full upgrade panel shown inside the pastor-house "Upgrades" tab.
/// Displays current Insight balance, two defense upgrades, and four prayer
/// mode sections with four upgrades each.
class _UpgradePanel extends StatefulWidget {
  final SpiritWorldGame game;
  const _UpgradePanel({required this.game});

  @override
  State<_UpgradePanel> createState() => _UpgradePanelState();
}

class _UpgradePanelState extends State<_UpgradePanel> {
  PlayerProgress get _progress => widget.game.progress;
  CombatProfile get _profile => _progress.combatProfile;

  void _buyUpgrade(VoidCallback apply, int cost) {
    setState(() {
      if (_progress.spendInsight(cost)) apply();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Insight balance ─────────────────────────────────────────
              _buildInsightHeader(),
              const SizedBox(height: 12),
              // ── Defense section ─────────────────────────────────────────
              _sectionTitle('🛡️ Verteidigung'),
              const SizedBox(height: 6),
              _buildDefenseRow(
                icon: '🛡️',
                label: 'Schild',
                description: 'Schadensreduktion (Faith-Drain)',
                level: _profile.shieldLevel,
                effectText:
                    '−${(_profile.shieldDamageReduction * 100).toStringAsFixed(0)}% Faith-Schaden',
                onBuy: () => _profile.shieldLevel++,
              ),
              const SizedBox(height: 6),
              _buildDefenseRow(
                icon: '⛑️',
                label: 'Helm',
                description: 'Hunger-Resistenz',
                level: _profile.helmLevel,
                effectText:
                    '−${(_profile.helmHungerReduction * 100).toStringAsFixed(0)}% Hunger-Schaden',
                onBuy: () => _profile.helmLevel++,
              ),
              const SizedBox(height: 14),
              // ── Attack section ──────────────────────────────────────────
              _sectionTitle('⚔️ Angriff'),
              ...PrayerMode.values.map((mode) => _buildModeSection(mode)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightHeader() {
    final label = _insightLabel(_progress);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📖', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '$label Erkenntnis verfügbar',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }

  Widget _buildDefenseRow({
    required String icon,
    required String label,
    required String description,
    required int level,
    required String effectText,
    required VoidCallback onBuy,
  }) {
    final cost = upgradeInsightCost(level);
    final canAfford = _progress.insight >= cost;
    return _UpgradeRow(
      icon: icon,
      label: label,
      level: level,
      description: description,
      effectText: effectText,
      cost: cost,
      canAfford: canAfford,
      onBuy: () => _buyUpgrade(onBuy, cost),
    );
  }

  Widget _buildModeSection(PrayerMode mode) {
    final stats = _profile.getFor(mode);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode header
          Row(
            children: [
              Text(mode.icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                _modeName(mode),
                style: TextStyle(
                  color: mode.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 4 tiles side by side
          Row(
            children: [
              Expanded(
                  child: _AttackTile(
                icon: '🎯',
                label: 'Radius',
                level: stats.radiusLevel,
                effectText: _pct(stats.radius),
                cost: upgradeInsightCost(stats.radiusLevel),
                canAfford: _progress.insight >= upgradeInsightCost(stats.radiusLevel),
                onBuy: () =>
                    _buyUpgrade(() => stats.radiusLevel++, upgradeInsightCost(stats.radiusLevel)),
              )),
              const SizedBox(width: 4),
              Expanded(
                  child: _AttackTile(
                icon: '⚡',
                label: 'Stärke',
                level: stats.strengthLevel,
                effectText: _pct(stats.strength),
                cost: upgradeInsightCost(stats.strengthLevel),
                canAfford: _progress.insight >= upgradeInsightCost(stats.strengthLevel),
                onBuy: () => _buyUpgrade(
                    () => stats.strengthLevel++, upgradeInsightCost(stats.strengthLevel)),
              )),
              const SizedBox(width: 4),
              Expanded(
                  child: _AttackTile(
                icon: '⏱️',
                label: 'Dauer',
                level: stats.durationLevel,
                effectText: _pct(stats.duration),
                cost: upgradeInsightCost(stats.durationLevel),
                canAfford: _progress.insight >= upgradeInsightCost(stats.durationLevel),
                onBuy: () => _buyUpgrade(
                    () => stats.durationLevel++, upgradeInsightCost(stats.durationLevel)),
              )),
              const SizedBox(width: 4),
              Expanded(
                  child: _AttackTile(
                icon: '💨',
                label: 'Geschw.',
                level: stats.speedLevel,
                effectText: _pct(stats.speed),
                cost: upgradeInsightCost(stats.speedLevel),
                canAfford: _progress.insight >= upgradeInsightCost(stats.speedLevel),
                onBuy: () =>
                    _buyUpgrade(() => stats.speedLevel++, upgradeInsightCost(stats.speedLevel)),
              )),
            ],
          ),
        ],
      ),
    );
  }

  static String _modeName(PrayerMode mode) {
    switch (mode) {
      case PrayerMode.liberation:
        return 'Befreiung';
      case PrayerMode.rebuke:
        return 'Zurechtweisung';
      case PrayerMode.slow:
        return 'Verlangsamung';
      case PrayerMode.drain:
        return 'Entziehung';
    }
  }
}

/// A single upgrade row with icon, label, level, effect text, cost, and buy button.
class _UpgradeRow extends StatelessWidget {
  final String icon;
  final String label;
  final int level;
  final String description;
  final String effectText;
  final int cost;
  final bool canAfford;
  final VoidCallback onBuy;

  const _UpgradeRow({
    required this.icon,
    required this.label,
    required this.level,
    required this.description,
    required this.effectText,
    required this.cost,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          if (icon.isNotEmpty) ...[
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Lv $level',
                        style: const TextStyle(color: Colors.amber, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                Text(
                  effectText,
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _BuyButton(cost: cost, canAfford: canAfford, onBuy: onBuy),
        ],
      ),
    );
  }
}

/// Small "Buy" button used in each upgrade row.
class _BuyButton extends StatelessWidget {
  final int cost;
  final bool canAfford;
  final VoidCallback onBuy;

  const _BuyButton({required this.cost, required this.canAfford, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canAfford ? onBuy : null,
      child: Opacity(
        opacity: canAfford ? 1.0 : 0.38,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: canAfford ? Colors.amber.withValues(alpha: 0.25) : Colors.white10,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: canAfford ? Colors.amber.withValues(alpha: 0.7) : Colors.white24,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📖', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 2),
              Text(
                '$cost',
                style: TextStyle(
                  color: canAfford ? Colors.amber : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact vertical tile for a single attack-stat upgrade.
/// Used inside the horizontal 4-column grid in [_UpgradePanelState._buildModeSection].
class _AttackTile extends StatelessWidget {
  final String icon;
  final String label;
  final int level;
  final String effectText;
  final int cost;
  final bool canAfford;
  final VoidCallback onBuy;

  const _AttackTile({
    required this.icon,
    required this.label,
    required this.level,
    required this.effectText,
    required this.cost,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          // Stat name
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Lv $level',
              style: const TextStyle(color: Colors.amber, fontSize: 8),
            ),
          ),
          const SizedBox(height: 2),
          // Effect
          Text(
            effectText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.greenAccent, fontSize: 9),
          ),
          const SizedBox(height: 4),
          // Buy button
          _BuyButton(cost: cost, canAfford: canAfford, onBuy: onBuy),
        ],
      ),
    );
  }
}

// ── Tutorial Overlay ──────────────────────────────────────────────────────────
