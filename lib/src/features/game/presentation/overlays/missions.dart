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

  /// 📍 key to accept / follow this mission (see GameMissionTracking).
  final String? trackKey;

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
    this.trackKey,
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
              itemBuilder: (context, i) => ValueListenableBuilder<String?>(
                valueListenable: game.trackedMission,
                builder: (context, tracked, _) => _MissionRow(
                  entry: data.entries[i],
                  tracked: tracked != null && tracked == data.entries[i].trackKey,
                  onTrack: data.entries[i].trackKey == null
                      ? null
                      : () => game.toggleTrackedMission(data.entries[i].trackKey!),
                ),
              ),
            ),
    );
  }
}

/// One mission as an emoji equation (no sentences to translate):
///
/// ```
/// 👤 Anna · 📍 Lindenallee 14    🙏 ×3   ⇒   +10🙏 +0.5📖
///    who / where                 do this     you get
/// ```
class _MissionRow extends StatelessWidget {
  final MissionEntry entry;

  /// 📍 This mission is accepted and shown on the map.
  final bool tracked;
  final VoidCallback? onTrack;
  const _MissionRow({required this.entry, this.tracked = false, this.onTrack});

  @override
  Widget build(BuildContext context) {
    final m = entry;
    final who = [
      if (m.targetName.isNotEmpty) m.targetName.split(' ').first,
      if (m.address != null) '📍 ${m.address}',
    ].join(' · ');
    final rewards = [
      if (m.faithReward > 0) '+${m.faithReward}🙏',
      if (m.materialsReward > 0) '+${m.materialsReward}📦',
      if (m.insightReward > 0) '+${m.insightReward.toStringAsFixed(1)}📖',
    ].join(' ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(m.targetEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (who.isNotEmpty)
                  Text(
                    who,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${m.actionEmoji} ×${m.targetCount}',
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    if (m.targetCount > 1) ...[
                      const SizedBox(width: 8),
                      _MissionProgressBar(progress: m.progress, targetCount: m.targetCount),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('⇒', style: TextStyle(color: Colors.white54, fontSize: 20)),
          ),
          Text(
            rewards,
            style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 13, fontWeight: FontWeight.bold),
          ),
          if (onTrack != null) ...[
            const SizedBox(width: 8),
            ActionButton(emoji: tracked ? '📍✅' : '📍', highlighted: tracked, onTap: onTrack!),
          ],
        ],
      ),
    );
  }
}

// ── Mission progress bar ───────────────────────────────────────────────────────
