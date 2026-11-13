part of '../game_screen.dart';

/// 🌱 tab of a Christian (#193): the same ⚔️ upgrades as in the pastor
/// house, for this person – only what the pastor has learned, never beyond
/// the pastor's own level (`🔒⚔️`), paid with 📖.
class _DiscipleTab extends StatelessWidget {
  final NPCModel model;
  final SpiritWorldGame game;
  final VoidCallback onTaught;
  const _DiscipleTab({required this.model, required this.game, required this.onTaught});

  @override
  Widget build(BuildContext context) {
    final pastor = game.progress.combatProfile;
    return ListenableBuilder(
      listenable: game.progress,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          Center(
            child: Text(
              '📖 ${game.progress.insight}   🌐 🙏〰️',
              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          for (final mode in Discipleship.teachable(game.progress.skills))
            _UpgradeGroup(
              icon: mode.icon,
              color: mode.color,
              title: AppStrings.get('mode.${mode.id}'),
              badge: '${CombatAbilities.modeLevel(model.discipleProfile.getFor(mode))}'
                  '/${CombatAbilities.modeLevel(pastor.getFor(mode))}',
              children: [
                for (final stat in CombatStat.values)
                  _UpgradeTile(
                    emoji: stat.emoji,
                    label: AppStrings.get('upgrade.${stat.name}'),
                    level: stat.of(model.discipleProfile.getFor(mode)),
                    effect: _pct(stat.valueOf(model.discipleProfile.getFor(mode))),
                    insight: game.progress.insight,
                    lock: switch (game.discipleBlocker(model, mode, stat)) {
                      '🔒⚔️' => const Locked('🔒⚔️'),
                      _ => null,
                    },
                    onBuy: () {
                      if (game.teachDisciple(model, mode, stat)) onTaught();
                    },
                  ),
              ],
            ),
          const SizedBox(height: 8),
          const Center(
            child: Text('2 Tim 2,2', style: TextStyle(color: Color(0xFFFFD54F), fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
