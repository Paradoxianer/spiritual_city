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

  /// What a lesson gives, in the symbols of the ⚔️ cabinet (playtest
  /// 2026-10-31: "⏳ like in battle, not 👹🐢"): a new prayer mode with its
  /// first levels, a mastery with the next cap, or another skill.
  ({String icon, String name, String gain, Color color}) _reward(Lesson l) {
    for (final m in PrayerMode.values) {
      final caps = CombatAbilities.levelCaps(m);
      final name = AppStrings.get('mode.${m.id}');
      if (CombatAbilities.modeSkill(m) == l.skill) {
        return (icon: m.icon, name: name, gain: 'Lv ${caps.first}', color: m.color);
      }
      final k = CombatAbilities.mastery(m).indexOf(l.skill);
      if (k >= 0) {
        return (icon: '${m.icon}${'⭐' * (k + 1)}', name: name, gain: 'Lv ${caps[k + 1]}', color: m.color);
      }
    }
    final parts = l.unlocks.split('➡️');
    final full = LessonTexts.skillName(l.skill);
    final name = full.substring(full.indexOf(' ') + 1);
    return (
      icon: parts.first.trim(),
      name: name,
      gain: parts.length > 1 ? parts.last.trim() : l.unlocks,
      color: const Color(0xFFFFD54F),
    );
  }

  Widget _build(Lesson lesson) {
    final state = game.progress.lesson;
    final replaces = state.lesson;
    final running = state.active == lesson.skill;
    const cost = LessonState.studyInsightCost;
    final studyLeft = state.studyLeft(lesson);
    final done = running ? state.progress : 0;
    final r = _reward(lesson);
    final canStudy = studyLeft > 0 && game.progress.insight >= cost;
    const big = TextStyle(fontSize: 22, color: Colors.white);
    const label = TextStyle(fontSize: 20, color: Colors.white70);

    return OverlayShell(
      theme: OverlayTheme.missions,
      // The name once, in the title (playtest 2026-10-31).
      leading: Text('🎓 ${r.icon} ${r.name}',
          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      onClose: game.closeLesson,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => game.explainLesson(lesson, force: true),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🎁: what you get – in the symbols of the ⚔️ cabinet.
              Row(children: [
                const SizedBox(width: 44, child: Text('🎁:', style: label)),
                Text('${r.icon}  ${r.gain}', style: big),
              ]),
              const SizedBox(height: 10),
              // 💪: what to practise, and how far.
              Row(children: [
                const SizedBox(width: 44, child: Text('💪:', style: label)),
                Text('${lesson.task.emoji} ×${lesson.count}', style: big),
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
              ]),
              const SizedBox(height: 12),
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
      ),
      // 🎓✅ accept, and below it 📖 study (buy one step with insight).
      actions: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!running)
            ActionButton(
              emoji: '🎓✅',
              highlighted: true,
              keyIndex: 1,
              onTap: () => game.startLesson(lesson),
            ),
          if (studyLeft > 0) ...[
            const SizedBox(height: 8),
            // The same buy button as in the ⚔️ cabinet, and what it gives.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BuyButton(
                  label: '📖 $cost',
                  active: canStudy,
                  fontSize: 15,
                  onTap: () => game.studyLesson(lesson),
                ),
                const SizedBox(width: 10),
                Text(
                  '➡️ +1 ${lesson.task.emoji}  (${running ? state.studied : 0}/${lesson.count ~/ 2})',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
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
