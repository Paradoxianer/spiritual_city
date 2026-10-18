part of '../game_screen.dart';

/// End of the day (sleeping in the pastor house, release_roadmap.md §3.3):
/// what happened today, emoji only, and the button into the next day.
class DaySummaryOverlay extends StatelessWidget {
  final SpiritWorldGame game;
  const DaySummaryOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final d = game.dayStats;
    final rows = d.rows;
    final tomorrowSunday = (d.day + 1) % 7 == 0;
    final quarter = game.quarterStatus.value;

    return OverlayShell(
      theme: OverlayTheme.home,
      leading: Text('🌙 ${d.day}', style: const TextStyle(fontSize: 22, color: Colors.white)),
      showClose: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            if (rows.isEmpty)
              const Text('😴🙏', style: TextStyle(fontSize: 36))
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 18,
                runSpacing: 12,
                children: [
                  for (final (emoji, n) in rows)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 32)),
                        Text(
                          '$n',
                          style: const TextStyle(
                            color: Color(0xFFFFD54F),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            if (!game.lastChurchYield.isEmpty) ...[
              const SizedBox(height: 18),
              Text(
                game.lastChurchYield.label,
                style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 18),
              ),
            ],
            if (quarter != null) ...[
              const SizedBox(height: 18),
              Text(quarter.label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
            ],
            const SizedBox(height: 14),
            Text(
              '📖 ${game.progress.insight}   ✝️ ${game.knownChristianCount}',
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
      actions: Center(
        child: ActionButton(
          emoji: tomorrowSunday ? '☀️ ${d.day + 1} ⛪' : '☀️ ${d.day + 1}',
          highlighted: true,
          keyIndex: 1,
          onTap: game.startNextDay,
        ),
      ),
    );
  }
}

/// HUD chips under the resources: day (☀️ 3, ⛪ on Sundays) and the
/// current neighbourhood's progress towards its awakening.
class _DayQuarterChips extends StatelessWidget {
  final SpiritWorldGame game;
  const _DayQuarterChips({required this.game});

  Widget _chip(String text) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<int>(
          valueListenable: game.dayNotifier,
          builder: (_, __, ___) =>
              _chip(game.dayStats.isSunday ? '☀️ ${game.dayStats.day} ⛪' : '☀️ ${game.dayStats.day}'),
        ),
        ValueListenableBuilder<QuarterStatus?>(
          valueListenable: game.quarterStatus,
          builder: (_, status, __) =>
              status == null ? const SizedBox.shrink() : _chip(status.label),
        ),
      ],
    );
  }
}
