import '../models/cell_object.dart';
import '../models/prayer_combat.dart';
import '../models/skills.dart';
import 'combat_abilities.dart';

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

  /// A mastery lesson: taken again and again, each time one step further.
  final bool repeatable;

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
    this.repeatable = false,
  });

  String get verseKey => verse ?? 'lesson.${skill.name}.verse';

  /// Can be taken now (not learned, prerequisites met).
  bool isOpen(LearnedSkills learned, int awakenings) =>
      (repeatable || !learned.has(skill)) && requires.every(learned.has) && awakenings >= minAwakenings;

  /// Learned for good (a mastery lesson never is – the next one follows).
  bool learnedIn(LearnedSkills learned) => !repeatable && learned.has(skill);

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

  /// The lesson of [s] – for a mastery skill the next one of its chain
  /// for a pastor who knows [learned].
  static Lesson of(Skill s, [LearnedSkills? learned]) => maybeOf(s, learned)!;

  /// [of], or null for a skill without a lesson (the old ⭐⭐ skills).
  static Lesson? maybeOf(Skill s, [LearnedSkills? learned]) {
    final fixed = all.where((l) => l.skill == s).firstOrNull;
    if (fixed != null) return fixed;
    final mode = CombatAbilities.masteryMode(s);
    if (mode == null) return null;
    return mastery(mode, learned == null ? 0 : CombatAbilities.masteryStage(mode, learned));
  }

  static const Map<PrayerMode, Set<BuildingType>> _masteryMentors = {
    PrayerMode.liberation: {BuildingType.church, BuildingType.cemetery, BuildingType.cathedral},
    PrayerMode.rebuke: {BuildingType.church, BuildingType.cathedral},
    PrayerMode.slow: {BuildingType.library, BuildingType.cathedral},
    PrayerMode.drain: {BuildingType.cemetery, BuildingType.cathedral},
  };

  static const Map<PrayerMode, String> _masteryReference = {
    PrayerMode.liberation: 'Joh 8,36',
    PrayerMode.rebuke: 'Jak 4,7',
    PrayerMode.slow: 'Mk 3,27',
    PrayerMode.drain: 'Lk 10,19',
  };

  /// The mastery lesson of [mode] after [stage] passed ones – an endless
  /// chain: each lifts the upgrade cap one step ([CombatAbilities.capFor])
  /// and asks for more (10, 20, 30 … 👹 with this prayer).
  static Lesson mastery(PrayerMode mode, int stage) {
    final needs = CombatAbilities.modeSkill(mode);
    return Lesson(
      skill: CombatAbilities.masteryKey(mode),
      mentorAt: _masteryMentors[mode]!,
      task: LessonTask.defeatWith(mode),
      count: 10 * (stage + 1),
      reference: _masteryReference[mode]!,
      verse: 'lesson.mastery.${mode.id}.verse',
      unlocks: '${mode.icon}${'⭐' * (stage + 1)} ➡️ 🔓${CombatAbilities.capFor(stage + 1)}',
      requires: {if (needs != null) needs},
      repeatable: true,
    );
  }

  /// The next mastery lesson of every prayer mode.
  static List<Lesson> masteryFor(LearnedSkills learned) => [
        for (final m in PrayerMode.values) mastery(m, CombatAbilities.masteryStage(m, learned)),
      ];

  /// Every lesson there is now: the fixed ones and the next masteries.
  static List<Lesson> allFor(LearnedSkills learned) => [...all, ...masteryFor(learned)];

  /// Lessons a mentor in [type] offers to a pastor who knows [learned]:
  /// not yet learned, prerequisites met.
  static List<Lesson> offeredAt(BuildingType type, LearnedSkills learned, {int awakenings = 0}) => [
        for (final l in allFor(learned))
          if (l.mentorAt.contains(type) && l.isOpen(learned, awakenings)) l,
      ];
}

/// The active lesson and its progress (part of the player progress).
class LessonState {
  /// The pastor's skills – the step of a mastery lesson depends on them.
  final LearnedSkills? _skills;

  LessonState([this._skills]);

  Skill? active;
  int progress = 0;

  /// Steps of the active lesson bought with 📖 at the mentor.
  int studied = 0;

  /// 📖 studying with the mentor (playtest 2026-10-31: insight piled up):
  /// one step of the lesson for [studyInsightCost] 📖 – but at most half
  /// of it; the rest is practised ("doers of the word", Jas 1:22).
  static const int studyInsightCost = 3;

  Lesson? get lesson => active == null ? null : Lessons.maybeOf(active!, _skills);

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
    if (l.repeatable) {
      learned.raiseMastery(l.skill);
    } else {
      learned.learn(l.skill);
    }
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
    // An old save in a ⭐⭐ lesson that no longer exists: it goes on in the
    // mode's mastery chain (same stage, same count).
    if (active case final a? when Lessons.maybeOf(a) == null) {
      final base = a.name.replaceAll(RegExp(r'\d+$'), '1');
      active = Skill.values.where((s) => s.name == base && Lessons.maybeOf(s) != null).firstOrNull;
    }
    progress = (raw['progress'] as num?)?.toInt() ?? 0;
    studied = (raw['studied'] as num?)?.toInt() ?? 0;
  }
}
