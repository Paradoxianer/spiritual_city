import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/prayer_combat.dart';
import 'package:spiritual_city/src/features/game/domain/services/combat_abilities.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_model.dart';
import 'package:spiritual_city/src/features/game/domain/models/player_progress.dart';
import 'package:spiritual_city/src/features/game/domain/models/skills.dart';
import 'package:spiritual_city/src/features/game/domain/services/learning_service.dart';
import 'package:spiritual_city/src/features/game/domain/services/npc_interaction_service.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

void main() {
  group('Skills', () {
    test('a new game knows nothing, an old save keeps what it could do', () {
      expect(PlayerProgress().skills.all, isEmpty);
      final old = PlayerProgress()..loadFromJson({'insight': 1});
      expect(old.skills.has(Skill.pastoralCare), isTrue);
      expect(old.skills.has(Skill.spiritualWarfare), isTrue);
      expect(old.skills.has(Skill.preaching), isFalse);
    });

    test('learned skills and the active lesson survive saving', () {
      final p = PlayerProgress()
        ..skills.learn(Skill.discernment)
        ..lesson.start(Skill.pastoralCare)
        ..lesson.progress = 2;
      final r = PlayerProgress()..loadFromJson(p.toJson());
      expect(r.skills.has(Skill.discernment), isTrue);
      expect(r.skills.has(Skill.pastoralCare), isFalse);
      expect(r.lesson.active, Skill.pastoralCare);
      expect(r.lesson.progress, 2);
    });
  });

  group('Lessons', () {
    test('mentors offer only unlearned lessons whose prerequisites are met', () {
      final none = LearnedSkills();
      final atLibrary = Lessons.offeredAt(BuildingType.library, none);
      expect(atLibrary, isEmpty, reason: 'discernment needs warfare first');
      final atChurch = Lessons.offeredAt(BuildingType.church, none).map((l) => l.skill);
      expect(atChurch, contains(Skill.spiritualWarfare));

      final warrior = LearnedSkills({Skill.spiritualWarfare});
      expect(Lessons.offeredAt(BuildingType.library, warrior).map((l) => l.skill),
          [Skill.binding, Skill.discernment]);
      expect(Lessons.offeredAt(BuildingType.church, warrior).map((l) => l.skill),
          isNot(contains(Skill.spiritualWarfare)));
    });

    test('prayer modes are learned one by one: 🫸 → ⏳ → 🪫 (needs an awakening)', () {
      final none = LearnedSkills();
      expect(CombatAbilities.canUse(PrayerMode.liberation, none), isTrue);
      expect(CombatAbilities.canUse(PrayerMode.rebuke, none), isFalse);
      final warrior = LearnedSkills({Skill.spiritualWarfare});
      expect(CombatAbilities.canUse(PrayerMode.rebuke, warrior), isTrue);
      expect(CombatAbilities.canUse(PrayerMode.slow, warrior), isFalse);
      final binder = LearnedSkills({Skill.spiritualWarfare, Skill.binding});
      final drain = Lessons.of(Skill.disarming);
      expect(drain.isOpen(binder, 0), isFalse, reason: 'needs an awakened quarter');
      expect(drain.isOpen(binder, 1), isTrue);
      expect(drain.isOpen(warrior, 1), isFalse, reason: 'needs ⏳ first');
    });

    // Playtest 2026-11-13: no top, but every step past the cap is a
    // lesson – the mastery chain never ends.
    test('mastery lessons follow one another without end, each lifting the cap', () {
      final learned = LearnedSkills({Skill.spiritualWarfare});
      const m = PrayerMode.rebuke;
      final caps = <int>[CombatAbilities.levelCap(m, learned)];
      final counts = <int>[];
      final state = LessonState(learned);
      for (var stage = 0; stage < 5; stage++) {
        final offer = Lessons.offeredAt(BuildingType.cathedral, learned)
            .firstWhere((l) => l.skill == CombatAbilities.masteryKey(m));
        expect(offer.isOpen(learned, 0), isTrue);
        counts.add(offer.count);
        state.start(offer.skill);
        Skill? done;
        for (var i = 0; i < offer.count; i++) {
          done = state.record(LessonTask.defeatRebuke, learned);
        }
        expect(done, offer.skill);
        caps.add(CombatAbilities.levelCap(m, learned));
      }
      expect(caps, [3, 5, 10, 15, 20, 25]);
      expect(counts, [10, 20, 30, 40, 50]);
      // ⏳ is not learned yet: no ⏳ mastery.
      expect(Lessons.offeredAt(BuildingType.cathedral, learned).map((l) => l.skill),
          isNot(contains(Skill.slowMastery1)));
    });

    test('mastery survives a save, and old ⭐ skills count', () {
      final learned = LearnedSkills({Skill.liberationMastery1, Skill.liberationMastery2, Skill.liberationMastery3});
      expect(CombatAbilities.levelCap(PrayerMode.liberation, learned), 15);
      learned.raiseMastery(Skill.liberationMastery1);
      final back = LearnedSkills()..loadFromJson(learned.toJson());
      expect(CombatAbilities.masteryStage(PrayerMode.liberation, back), 4);
      expect(CombatAbilities.levelCap(PrayerMode.liberation, back), 20);
      // A save in the middle of a mastery lesson keeps it.
      final s = LessonState(back)..loadFromJson({'active': 'liberationMastery1', 'progress': 4});
      expect(s.lesson?.count, 50);
      expect(s.progress, 4);
    });

    test('an old save in a ⭐⭐ lesson goes on in the mastery chain', () {
      final learned = LearnedSkills({Skill.liberationMastery1});
      final s = LessonState(learned)..loadFromJson({'active': 'liberationMastery2', 'progress': 15});
      expect(s.active, Skill.liberationMastery1);
      expect(s.lesson?.count, 20, reason: 'stage 1, as the old ⭐⭐');
      expect(s.progress, 15);
    });

    test('loading an old save without skills forgets earlier mastery', () {
      final learned = LearnedSkills()..raiseMastery(Skill.rebukeMastery1);
      learned.loadFromJson(null);
      expect(learned.masteryOf(Skill.rebukeMastery1), 0);
    });

    test('every skill has a lesson (but the old mastery ones)', () {
      final mastery = {for (final s in Skill.values) if (s.name.contains('Mastery')) s};
      expect(mastery, hasLength(9));
      for (final s in Skill.values.where((s) => !mastery.contains(s))) {
        expect(Lessons.all.where((l) => l.skill == s), hasLength(1), reason: '$s');
      }
    });

    test('practising the task finishes the lesson and teaches the skill', () {
      final learned = LearnedSkills();
      final state = LessonState()..start(Skill.pastoralCare);
      expect(state.record(LessonTask.defeatDaemons, learned), isNull, reason: 'wrong task');
      expect(state.record(LessonTask.counsel, learned), isNull);
      expect(state.record(LessonTask.counsel, learned), isNull);
      expect(state.record(LessonTask.counsel, learned), Skill.pastoralCare);
      expect(learned.has(Skill.pastoralCare), isTrue);
      expect(state.active, isNull);
    });

    test('every lesson has a verse reference and an emoji-only unlock sentence', () {
      final letters = RegExp(r'[A-Za-zÄÖÜäöüß]');
      for (final l in Lessons.all) {
        expect(l.reference, isNotEmpty);
        expect(letters.hasMatch(l.unlocks), isFalse, reason: l.unlocks);
      }
    });
  });

  group('Possession (#180)', () {
    NPCModel possessed() {
      for (var i = 0; i < 200; i++) {
        final n = NPCModel(
            id: 'p_$i', name: 'n', type: NPCType.citizen, homePosition: Vector2.zero(), faith: -80);
        if (n.possessed) return n;
      }
      fail('no possessed NPC');
    }

    test('only very hostile people can be possessed, deterministically', () {
      final friendly = NPCModel(
          id: 'p_0', name: 'n', type: NPCType.citizen, homePosition: Vector2.zero(), faith: 10);
      expect(friendly.possessed, isFalse);
      final a = possessed();
      final again = NPCModel(
          id: a.id, name: 'n', type: NPCType.citizen, homePosition: Vector2.zero(), faith: -80);
      expect(again.possessed, isTrue);
    });

    test('counselling loosens the possession (real-world half)', () {
      final npc = possessed();
      final r = NpcInteractionService(difficulty: Difficulty.normal).perform(
        'counsel',
        npc,
        spiritualState: 0,
        playerFaith: 100,
        playerHealth: 100,
        playerMaterials: 100,
      );
      expect(r.possessionWeakened, isTrue);
      expect(npc.possessionWeakened, isTrue);
      expect(npc.possessed, isTrue, reason: 'still needs the invisible-world half');
    });
  });

  test('📖 studying with the mentor: one step per 📖, at most half the lesson', () {
    final learned = LearnedSkills();
    final l = Lessons.all.firstWhere((l) => l.count >= 6);
    final st = LessonState();
    expect(st.studyLeft(l), l.count ~/ 2, reason: 'offered before it runs');
    expect(st.study(l, learned), isNull);
    expect(st.active, l.skill, reason: 'studying starts the lesson');
    while (st.studyLeft(l) > 0) {
      st.study(l, learned);
    }
    expect(st.progress, l.count ~/ 2);
    expect(st.study(l, learned), isNull);
    expect(st.progress, l.count ~/ 2, reason: 'the rest is practised');
    final r = LessonState()..loadFromJson(st.toJson());
    expect(r.studied, l.count ~/ 2);
    // Practising the rest finishes it.
    Skill? done;
    for (var i = st.progress; i < l.count; i++) {
      done = st.record(l.task, learned);
    }
    expect(done, l.skill);
    expect(st.studied, 0);
  });

  test('a lesson of one step cannot be studied', () {
    final st = LessonState();
    for (final l in Lessons.all.where((l) => l.count == 1)) {
      expect(st.studyLeft(l), 0);
    }
  });
}
