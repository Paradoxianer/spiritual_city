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
    // Rebuilt while 📖 studying moves the lesson on and spends insight.
    return ListenableBuilder(
      listenable: Listenable.merge([game.lessonNotifier, game.progress]),
      builder: (context, _) => _build(lesson),
    );
  }

  Widget _build(Lesson lesson) {
    final state = game.progress.lesson;
    final replaces = state.lesson;
    final running = state.active == lesson.skill;
    const cost = LessonState.studyInsightCost;
    final studyLeft = state.studyLeft(lesson);
    final done = running ? state.progress : 0;
    // What it gives: the part of the unlock sentence after ➡️.
    final gives = lesson.unlocks.contains('➡️')
        ? lesson.unlocks.substring(lesson.unlocks.indexOf('➡️') + '➡️'.length).trim()
        : lesson.unlocks;
    final canStudy = game.progress.insight >= cost;

    return OverlayShell(
      theme: OverlayTheme.missions,
      leading: Text('🎓 ${LessonTexts.skillName(lesson.skill)}',
          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      onClose: game.closeLesson,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Compact rows, each "symbol: content" (playtest 2026-10-31):
            // 🎁 what you get, 💪 what to practise, 📖 the shortcut.
            _LessonRow(
              icon: '🎁',
              onTap: () => game.explainLesson(lesson, force: true),
              child: Text(gives, style: const TextStyle(fontSize: 22, color: Colors.white)),
            ),
            _LessonRow(
              icon: '💪',
              onTap: () => game.explainLesson(lesson, force: true),
              child: Row(
                children: [
                  Text('${lesson.task.emoji} ×${lesson.count}',
                      style: const TextStyle(fontSize: 22, color: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: lesson.count == 0 ? 0 : done / lesson.count,
                        minHeight: 8,
                        backgroundColor: Colors.white12,
                        color: const Color(0xFFFFD54F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$done/${lesson.count}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            if (studyLeft > 0 || state.studied > 0)
              _LessonRow(
                icon: '📖',
                child: Row(
                  children: [
                    Text('+1 ${lesson.task.emoji}', style: const TextStyle(fontSize: 18, color: Colors.white)),
                    const SizedBox(width: 10),
                    Text('${running ? state.studied : 0}/${lesson.count ~/ 2}',
                        style: const TextStyle(color: Colors.white60, fontSize: 13)),
                    const Spacer(),
                    if (studyLeft > 0)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB300),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.white12,
                          disabledForegroundColor: Colors.white38,
                          minimumSize: const Size(64, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: canStudy ? () => game.studyLesson(lesson) : null,
                        child: const Text('📖 $cost', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            // The Bible verse – small, below.
            Text(
              '„${AppStrings.get(lesson.verseKey)}“ – ${BibleRef.localized(lesson.reference)}',
              style: const TextStyle(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic, height: 1.4),
            ),
            if (replaces != null && replaces != lesson) ...[
              const SizedBox(height: 6),
              Text(
                '🎓${replaces.skill.emoji} ➡️ 🎓${lesson.skill.emoji}',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: running
          ? null
          : Center(
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

/// One row of the lesson card: "🎁:  content".
class _LessonRow extends StatelessWidget {
  final String icon;
  final Widget child;
  final VoidCallback? onTap;
  const _LessonRow({required this.icon, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text('$icon:', style: const TextStyle(fontSize: 20, color: Colors.white70)),
            ),
            const SizedBox(width: 8),
            Expanded(child: child),
          ],
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
        // Tap → ❓ help on "my tasks": how this lesson is done (playtest
        // 2026-10-20, stuck on 🎓📢).
        // Tap → the narrator tells how this lesson is done (playtest
        // 2026-10-31: what to do, where and how).
        return GestureDetector(
          onTap: () => game.explainLesson(l, force: true),
          child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x88FFD54F)),
          ),
          child: Text(
            '${l.progressLabel(game.progress.lesson.progress)}  ❓',
            style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12),
          ),
          ),
        );
      },
    );
  }
}
