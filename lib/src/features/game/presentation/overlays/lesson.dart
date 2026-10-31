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
                    BibleRef.localized(lesson.reference),
                    style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // The practice task: 👂 ×3, or how far it is: 👂 2/6
            Center(
              child: Text(
                running
                    ? '${lesson.task.emoji} ${state.progress}/${lesson.count}'
                    : '${lesson.task.emoji} ×${lesson.count}',
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
      actions: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!running)
            ActionButton(
              emoji: '🎓✅',
              highlighted: true,
              keyIndex: 1,
              onTap: () => game.startLesson(lesson),
            ),
          // 📖 Study with the mentor: one step for 📖, at most half – the
          // same tile as in the ⚔️ cabinet (playtest 2026-10-31).
          if (studyLeft > 0) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              child: _UpgradeTile(
                emoji: '📖➡️${lesson.task.emoji}',
                label: AppStrings.get('lesson.study'),
                level: state.studied,
                badge: '${running ? state.studied : 0}/${lesson.count ~/ 2}',
                effect: '+1 ${lesson.task.emoji}',
                insight: game.progress.insight,
                cost: cost,
                onBuy: () => game.studyLesson(lesson),
              ),
            ),
          ],
        ],
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
