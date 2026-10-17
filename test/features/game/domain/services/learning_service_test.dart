import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
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
          [Skill.discernment]);
      expect(Lessons.offeredAt(BuildingType.church, warrior).map((l) => l.skill),
          isNot(contains(Skill.spiritualWarfare)));
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
}
