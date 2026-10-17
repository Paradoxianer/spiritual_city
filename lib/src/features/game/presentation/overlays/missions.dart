part of '../game_screen.dart';

/// A single mission entry shown in [MissionBoardOverlay].
class MissionEntry {
  final String targetEmoji;
  final String targetName;
  final String description;

  /// Emoji of the action button the player must press (e.g. '🙏', '✉️').
  final String actionEmoji;
  final int faithReward;
  final int materialsReward;
  final double insightReward;
  final int progress;
  final int targetCount;

  /// Formatted address, e.g. "Lindenallee 14" or "Nr. 22". May be null.
  final String? address;

  const MissionEntry({
    required this.targetEmoji,
    required this.targetName,
    required this.description,
    required this.actionEmoji,
    required this.faithReward,
    required this.materialsReward,
    this.insightReward = 0,
    this.progress = 0,
    this.targetCount = 1,
    this.address,
  });
}

/// Data passed to [MissionBoardOverlay].
class MissionBoardData {
  final List<MissionEntry> entries;
  const MissionBoardData({required this.entries});
}

// ── Mission Board Overlay ─────────────────────────────────────────────────────

/// Shows all active missions as an emoji-styled list with addresses.
/// Opened from inside the pastor house via the '📋 Missionen' action.
class MissionBoardOverlay extends StatelessWidget {
  final SpiritWorldGame game;
  const MissionBoardOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final data = game.activeMissionBoardData;
    if (data == null) return const SizedBox.shrink();

    return OverlayShell(
      theme: OverlayTheme.missions,
      leading: const Text('📋', style: TextStyle(fontSize: 22)),
      onClose: () => game.closeMissionBoard(),
      body: data.entries.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('📋💤', style: TextStyle(fontSize: 32))),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shrinkWrap: true,
              itemCount: data.entries.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white12),
              itemBuilder: (context, i) => _MissionRow(entry: data.entries[i]),
            ),
    );
  }
}

/// One mission: target → action ×count, progress, address, rewards.
class _MissionRow extends StatelessWidget {
  final MissionEntry entry;
  const _MissionRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final m = entry;
    final countLabel = m.targetCount > 1 ? ' ×${m.targetCount}' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(m.targetEmoji, style: const TextStyle(fontSize: 24)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('→', style: TextStyle(color: Colors.white54, fontSize: 14)),
          ),
          Text('${m.actionEmoji}$countLabel', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (m.targetCount > 1)
                  _MissionProgressBar(progress: m.progress, targetCount: m.targetCount),
                if (m.address != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '📍 ${m.address}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (m.insightReward > 0)
                Text(
                  '+${m.insightReward.toStringAsFixed(1)} 📖',
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (m.faithReward > 0)
                Text(
                  '+${m.faithReward}🙏',
                  style: const TextStyle(
                      color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              if (m.materialsReward > 0)
                Text(
                  '+${m.materialsReward}📦',
                  style: const TextStyle(color: Colors.lightBlue, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Mission progress bar ───────────────────────────────────────────────────────
