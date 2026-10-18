part of '../game_screen.dart';

/// The church (#181): every member with role, name and the wounds they have
/// worked through. Tapping the role emoji gives the person another role.
/// Names are proper names; everything else is emoji.
class ChurchOverlay extends StatefulWidget {
  final SpiritWorldGame game;
  const ChurchOverlay({super.key, required this.game});

  @override
  State<ChurchOverlay> createState() => _ChurchOverlayState();
}

class _ChurchOverlayState extends State<ChurchOverlay> {
  @override
  Widget build(BuildContext context) {
    final church = widget.game.progress.church;
    final members = church.members.values.toList()
      ..sort((a, b) => a.role.index.compareTo(b.role.index));
    final y = church.dailyYield();

    return OverlayShell(
      theme: OverlayTheme.home,
      leading: Text('⛪ ${members.length}', style: const TextStyle(fontSize: 22, color: Colors.white)),
      title: Text(
        y.isEmpty ? '' : '${y.label} / 😴',
        style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 13),
      ),
      onClose: widget.game.closeChurchOverview,
      body: members.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('⛪ 🙏 ✝️ ❓', style: TextStyle(fontSize: 30))),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shrinkWrap: true,
              itemCount: members.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
              itemBuilder: (context, i) {
                final m = members[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // Tap = next role.
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => m.role = m.role.next),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(m.role.emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          m.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      // Healed wounds: 💔→🌱 …
                      Text(
                        m.healedGlyphs.values.map((g) => '$g→🌱').join(' '),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
