import '../models/cell_object.dart';
import '../models/prayer_combat.dart';
import '../models/skills.dart';

/// What has to be done to finish a lesson.
enum LessonTask {
  /// 👂 counselling with people.
  counsel('👂'),

  /// 👹 daemons defeated in prayer.
  defeatDaemons('👹'),

  /// 🙏 prayers (any building or person).
  pray('🙏'),

  /// ⛪ services held in a church.
  service('⛪'),

  /// 👹 defeated with one particular prayer mode (mastery lessons).
  defeatLiberation('🕊️👹'),
  defeatRebuke('🫸👹'),
  defeatSlow('⏳👹'),
  defeatDrain('🪫👹');

  /// The mastery task of [mode].
  static LessonTask defeatWith(PrayerMode mode) => switch (mode) {
        PrayerMode.liberation => defeatLiberation,
        PrayerMode.rebuke => defeatRebuke,
        PrayerMode.slow => defeatSlow,
        PrayerMode.drain => defeatDrain,
      };

  final String emoji;
  const LessonTask(this.emoji);
}

/// A learning mission (docs/game_design/release_roadmap.md §3.9): a mentor
/// in a certain kind of building teaches a [skill]; after a short lesson
/// the pastor practises it ([task] × [count]) and then has learned it.
class Lesson {
  final Skill skill;

  /// Where a mentor for this lesson can be found.
  final Set<BuildingType> mentorAt;

  final LessonTask task;
  final int count;

  /// Skills that must be learned first.
  final Set<Skill> requires;

  /// Only offered after this many awakened neighbourhoods (preaching is
  /// the reward of the first stage goal, #172/#173).
  final int minAwakenings;

  /// AppStrings key of the Bible verse (several mastery lessons share one).
  final String? verse;

  /// Bible reference shown with the lesson (the verse text is localised –
  /// the only real text of a lesson; everything else is emoji).
  final String reference;

  /// Emoji sentence of what the lesson unlocks, e.g. `⚔️ ➡️ 🫸 ⏳ 🪫`.
  final String unlocks;

  const Lesson({
    required this.skill,
    required this.mentorAt,
    required this.task,
    required this.count,
    required this.reference,
    required this.unlocks,
    this.requires = const {},
    this.minAwakenings = 0,
    this.verse,
  });

  String get verseKey => verse ?? 'lesson.${skill.name}.verse';

  /// Can be taken now (not learned, prerequisites met).
  bool isOpen(LearnedSkills learned, int awakenings) =>
      !learned.has(skill) && requires.every(learned.has) && awakenings >= minAwakenings;

  /// `🎓⚔️ 1/3 👹`
  String progressLabel(int progress) =>
      '🎓${skill.emoji} $progress/$count ${task.emoji}';
}

/// All lessons and the rules for starting and finishing them. The state
/// (active lesson, progress, learned skills) lives in `PlayerProgress`.
abstract final class Lessons {
  static const List<Lesson> all = [
    Lesson(
      skill: Skill.pastoralCare,
      mentorAt: {BuildingType.hospital},
      task: LessonTask.counsel,
      count: 3,
      reference: '2 Kor 1,4',
      unlocks: '🫂 ➡️ 📜🗣️',
    ),
    Lesson(
      skill: Skill.spiritualWarfare,
      mentorAt: {BuildingType.church, BuildingType.cathedral},
      task: LessonTask.defeatDaemons,
      count: 8,
      reference: 'Eph 6,12',
      unlocks: '⚔️ ➡️ 🫸',
    ),
    Lesson(
      skill: Skill.binding,
      mentorAt: {BuildingType.cathedral, BuildingType.library},
      task: LessonTask.defeatDaemons,
      count: 15,
      reference: 'Mt 18,18',
      unlocks: '⏳ ➡️ 👹🐢',
      requires: {Skill.spiritualWarfare},
    ),
    Lesson(
      skill: Skill.disarming,
      mentorAt: {BuildingType.cathedral},
      task: LessonTask.defeatDaemons,
      count: 25,
      reference: 'Kol 2,15',
      unlocks: '🪫 ➡️ 👹➡️🙏',
      requires: {Skill.binding},
      minAwakenings: 1,
    ),
    Lesson(
      skill: Skill.discernment,
      mentorAt: {BuildingType.library, BuildingType.museum, BuildingType.cathedral},
      task: LessonTask.defeatDaemons,
      count: 5,
      reference: '1 Joh 4,1',
      unlocks: '👁️ ➡️ 🐍 🪨 🦇 👁️',
      requires: {Skill.spiritualWarfare},
    ),
    Lesson(
      skill: Skill.intercession,
      mentorAt: {BuildingType.house, BuildingType.apartment},
      task: LessonTask.pray,
      count: 5,
      reference: '1 Tim 2,1',
      unlocks: '🙏🏠 ➡️ ✨🤝',
    ),
    Lesson(
      skill: Skill.fasting,
      mentorAt: {BuildingType.church, BuildingType.cemetery},
      task: LessonTask.pray,
      count: 3,
      reference: 'Mt 6,17–18',
      unlocks: '➖🍞 ➡️ ➖🙏⚔️',
      requires: {Skill.intercession},
    ),
    Lesson(
      skill: Skill.preaching,
      mentorAt: {BuildingType.church, BuildingType.cathedral},
      task: LessonTask.service,
      count: 1,
      reference: 'Röm 10,14',
      minAwakenings: 1,
      unlocks: '📢⛪ ➡️ 👥✝️',
      requires: {Skill.spiritualWarfare},
    ),
  ];

  static Lesson of(Skill s) => all.firstWhere((l) => l.skill == s);

  /// [of], or null for a skill without a lesson (old mastery lessons).
  static Lesson? maybeOf(Skill s) => all.where((l) => l.skill == s).firstOrNull;

  /// Lessons a mentor in [type] offers to a pastor who knows [learned]:
  /// not yet learned, prerequisites met.
  static List<Lesson> offeredAt(BuildingType type, LearnedSkills learned, {int awakenings = 0}) => [
        for (final l in all)
          if (l.mentorAt.contains(type) && l.isOpen(learned, awakenings)) l,
      ];
}

/// The active lesson and its progress (part of the player progress).
class LessonState {
  Skill? active;
  int progress = 0;

  /// Steps of the active lesson bought with 📖 at the mentor.
  int studied = 0;

  /// 📖 studying with the mentor (playtest 2026-10-31: insight piled up):
  /// one step of the lesson for [studyInsightCost] 📖 – but at most half
  /// of it; the rest is practised ("doers of the word", Jas 1:22).
  static const int studyInsightCost = 3;

  Lesson? get lesson => active == null ? null : Lessons.maybeOf(active!);

  void start(Skill s) {
    active = s;
    progress = 0;
    studied = 0;
  }

  /// Steps of [l] that can still be studied (it need not be active yet).
  int studyLeft(Lesson l) {
    final max = l.count ~/ 2;
    if (active != l.skill) return max;
    return (max - studied).clamp(0, l.count - progress);
  }

  /// Studies one step of [l] (starting it if needed); returns the learned
  /// skill when this finished it. Paying is the caller's job.
  Skill? study(Lesson l, LearnedSkills learned) {
    if (studyLeft(l) <= 0) return null;
    if (active != l.skill) start(l.skill);
    studied++;
    return _step(l, learned);
  }

  /// Counts one [task]; returns the learned skill when this finished the
  /// active lesson (it is then added to [learned] and cleared).
  Skill? record(LessonTask task, LearnedSkills learned) {
    final l = lesson;
    if (l == null || l.task != task) return null;
    return _step(l, learned);
  }

  Skill? _step(Lesson l, LearnedSkills learned) {
    progress++;
    if (progress < l.count) return null;
    learned.learn(l.skill);
    active = null;
    progress = 0;
    studied = 0;
    return l.skill;
  }

  Map<String, dynamic> toJson() => {
        if (active != null) 'active': active!.name,
        'progress': progress,
        if (studied > 0) 'studied': studied,
      };

  void loadFromJson(Object? raw) {
    active = null;
    progress = 0;
    studied = 0;
    if (raw is! Map) return;
    for (final s in Skill.values) {
      if (s.name == raw['active']) active = s;
    }
    // An old save in a mastery lesson that no longer exists.
    if (active != null && Lessons.maybeOf(active!) == null) active = null;
    progress = (raw['progress'] as num?)?.toInt() ?? 0;
    studied = (raw['studied'] as num?)?.toInt() ?? 0;
  }
}
