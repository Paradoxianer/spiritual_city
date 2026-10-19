part of '../spirit_world_game.dart';

/// Learning missions (release_roadmap.md §3.9): mentors in buildings teach
/// skills; practising them counts here.
extension GameLearning on SpiritWorldGame {
  /// Opens the lesson card of [lesson] (from a mentor's 🎓 button).
  void openLesson(Lesson lesson) {
    activeLessonOffer = lesson;
    overlays.add('LessonOverlay');
  }

  void closeLesson() {
    activeLessonOffer = null;
    overlays.remove('LessonOverlay');
  }

  /// Accepts the offered lesson; it replaces any other active lesson.
  void startLesson(Lesson lesson) {
    progress.lesson.start(lesson.skill);
    lessonNotifier.value++;
    closeLesson();
    _toast(lesson.progressLabel(0));
  }

  /// Counts one practice [task] towards the active lesson.
  void recordLessonTask(LessonTask task) {
    final active = progress.lesson.lesson;
    if (active == null || active.task != task) return;
    final learned = progress.lesson.record(task, progress.skills);
    lessonNotifier.value++;
    if (learned == null) {
      _toast(active.progressLabel(progress.lesson.progress));
      return;
    }
    dayStats.lessonsLearned++;
    GameSound.play(Sfx.learned);
    _toast('🎓✨ ${learned.emoji}');
    // A new prayer mode shows up in the dock right away.
    _updateHudVisibility();
  }

  /// Short centred emoji message (e.g. a newly unlocked ability).
  void announce(String msg) {
    GameSound.play(Sfx.learned);
    _toast(msg);
  }

  void _toast(String msg) {
    missionCompleteMessage.value = msg;
    Future.delayed(const Duration(seconds: 3), () {
      if (missionCompleteMessage.value == msg) missionCompleteMessage.value = null;
    });
  }
}
