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

/// Mission board, opened in the pastor house (📋): two tabs –
/// 📋 the missions of the people and buildings around, 🎓 the learning path
/// (which skills there are, where their mentors are). Both can be accepted
/// with 📍 and are then shown on the map.
class MissionBoardOverlay extends StatefulWidget {
  final SpiritWorldGame game;
  const MissionBoardOverlay({super.key, required this.game});

  @override
  State<MissionBoardOverlay> createState() => _MissionBoardOverlayState();
}

class _MissionBoardOverlayState extends State<MissionBoardOverlay> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final data = game.activeMissionBoardData;
    if (data == null) return const SizedBox.shrink();

    Widget tab(String emoji, int i) => GestureDetector(
          onTap: () => setState(() => _tab = i),
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _tab == i ? const Color(0x55FFD54F) : Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
        );

    return OverlayShell(
      theme: OverlayTheme.missions,
      leading: Text(_tab == 0 ? '📋' : '🎓', style: const TextStyle(fontSize: 22)),
      trailing: [Row(mainAxisSize: MainAxisSize.min, children: [tab('📋', 0), tab('🎓', 1)])],
      onClose: () => game.closeMissionBoard(),
      body: _tab == 1
          ? _LearningPath(game: game)
          : data.entries.isEmpty
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

// ── 🎓 Learning path ───────────────────────────────────────────────────────────

/// All skills as emoji rows: ✅ learned, the running lesson with progress,
/// learnable ones with their mentors' buildings and 📍, 🔒 locked ones with
/// what they need first.
class _LearningPath extends StatelessWidget {
  final SpiritWorldGame game;
  const _LearningPath({required this.game});

  @override
  Widget build(BuildContext context) {
    final p = game.progress;
    final awakenings = p.awakenedQuarters.length;
    return ValueListenableBuilder<String?>(
      valueListenable: game.trackedMission,
      builder: (context, tracked, _) => ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shrinkWrap: true,
        itemCount: Lessons.all.length,
        separatorBuilder: (_, __) => const Divider(color: Colors.white12),
        itemBuilder: (context, i) {
          final l = Lessons.all[i];
          final learned = p.skills.has(l.skill);
          final active = p.lesson.active == l.skill;
          final open = !learned &&
              l.requires.every(p.skills.has) &&
              (!l.requiresAwakening || awakenings > 0);
          final key = GameMissionTracking.lessonKey(l.skill);
          final mentors = l.mentorAt.map(BuildingComponent.buildingEmoji).join(' ');
          final String status;
          if (learned) {
            status = '✅';
          } else if (active) {
            status = '${p.lesson.progress}/${l.count} ${l.task.emoji}';
          } else if (open) {
            status = '🎓 $mentors';
          } else {
            status = '🔒 ${[
              for (final r in l.requires)
                if (!p.skills.has(r)) r.emoji,
              if (l.requiresAwakening && awakenings == 0) '🏰🔥',
            ].join(' ')}';
          }
          return Opacity(
            opacity: learned ? 0.55 : (open || active ? 1 : 0.6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(l.skill.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(status,
                            style: TextStyle(
                              fontSize: 16,
                              color: active ? Colors.amber : Colors.white,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 2),
                        // What it unlocks, as an emoji sentence.
                        Text(l.unlocks,
                            style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.75))),
                      ],
                    ),
                  ),
                  if (open)
                    ActionButton(
                      emoji: tracked == key ? '📍✅' : '📍',
                      highlighted: tracked == key,
                      onTap: () => game.toggleTrackedMission(key),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
