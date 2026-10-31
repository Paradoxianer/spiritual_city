part of '../game_screen.dart';

/// 🌱 tab of a Christian (#193): which prayer gift the pastor has taught
/// them, and what it does in the invisible world – emoji only.
class _DiscipleTab extends StatelessWidget {
  final NPCModel model;
  final SpiritWorldGame game;
  const _DiscipleTab({required this.model, required this.game});

  @override
  Widget build(BuildContext context) {
    final gift = model.discipleGift;
    final level = model.discipleLevel;
    return ListView(
      children: [
        const SizedBox(height: 8),
        Center(
          child: Text(
            model.isDisciple ? '${gift!.icon} ${Discipleship.stars(level)}' : '🌱 ❔',
            style: const TextStyle(fontSize: 34),
          ),
        ),
        const SizedBox(height: 10),
        // What it means: in the invisible world they pray along near you.
        Center(
          child: Text(
            model.isDisciple
                ? '🌐 ${gift!.icon}〰️ 👹🫸  ⏱️${Discipleship.interval(level).round()}s'
                : '📖 ➡️ 🌱 ➡️ 🌐🙏',
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            '📖 ${game.progress.insight}',
            style: const TextStyle(fontSize: 16, color: Colors.amber, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text('2 Tim 2,2', style: TextStyle(color: Color(0xFFFFD54F), fontSize: 11)),
        ),
      ],
    );
  }
}

/// Teaching buttons: every gift the pastor can pray (first step), or the
/// one gift deeper. One step per day, paid with 📖.
class _DiscipleActions extends StatelessWidget {
  final NPCModel model;
  final SpiritWorldGame game;
  final bool enabled;
  final void Function(PrayerMode mode) onTeach;
  const _DiscipleActions({
    required this.model,
    required this.game,
    required this.enabled,
    required this.onTeach,
  });

  @override
  Widget build(BuildContext context) {
    final modes = model.isDisciple
        ? [model.discipleGift!]
        : Discipleship.teachable(game.progress.skills);
    final cost = Discipleship.teachCost(model.discipleLevel);
    return ActionBar(
      children: [
        for (var i = 0; i < modes.length; i++)
          () {
            final m = modes[i];
            final blocker = discipleBlocker(model, m, game.progress.insight, game.dayStats.day);
            return ActionButton(
              emoji: '🌱${m.icon}${Discipleship.stars((model.discipleLevel + 1).clamp(1, Discipleship.maxLevel))}',
              hint: '−$cost📖',
              availability: switch (blocker) {
                null => const AvailableNow(),
                '🚫📖' => const CannotAfford(Resource.insight),
                final b => Locked(b),
              },
              keyIndex: i + 1,
              enabled: enabled,
              onTap: () => onTeach(m),
            );
          }(),
      ],
    );
  }
}
