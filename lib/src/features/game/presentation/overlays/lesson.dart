part of '../game_screen.dart';

/// A mentor's lesson (learning missions, release_roadmap.md §3.9): what it
/// unlocks (emoji), a Bible verse (the only real text, chosen from public-
/// domain translations), the practice task and a 🎓✅ button.
class LessonOverlay extends StatelessWidget {
  final SpiritWorldGame game;
  const LessonOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final lesson = game.activeLessonOffer;
    if (lesson == null) return const SizedBox.shrink();
    final replaces = game.progress.lesson.lesson;

    return OverlayShell(
      theme: OverlayTheme.missions,
      leading: Text('🎓${lesson.skill.emoji}', style: const TextStyle(fontSize: 24)),
      onClose: game.closeLesson,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // What it unlocks, as an emoji sentence.
            Center(
              child: Text(lesson.unlocks, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 14),
            // The Bible verse – the lesson's only real text.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: const Border(left: BorderSide(color: Color(0xFFFFD54F), width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '„${AppStrings.get(lesson.verseKey)}“',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lesson.reference,
                    style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // The practice task: 👂 ×3
            Center(
              child: Text(
                '${lesson.task.emoji} ×${lesson.count}',
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
            if (replaces != null && replaces != lesson) ...[
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '🎓${replaces.skill.emoji} ➡️ 🎓${lesson.skill.emoji}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: Center(
        child: ActionButton(
          emoji: '🎓✅',
          highlighted: true,
          keyIndex: 1,
          onTap: () => game.startLesson(lesson),
        ),
      ),
    );
  }
}

/// Small HUD chip with the active lesson's progress: `🎓⚔️ 1/3 👹`.
class _LessonChip extends StatelessWidget {
  final SpiritWorldGame game;
  const _LessonChip({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.lessonNotifier,
      builder: (context, _, __) {
        final l = game.progress.lesson.lesson;
        if (l == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x88FFD54F)),
          ),
          child: Text(
            l.progressLabel(game.progress.lesson.progress),
            style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12),
          ),
        );
      },
    );
  }
}
