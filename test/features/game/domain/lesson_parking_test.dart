import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/skills.dart';
import 'package:spiritual_city/src/features/game/domain/services/learning_service.dart';

void main() {
  // Playtest 2026-11-12: switching lessons started them again from 0.
  test('a lesson switched away from goes on where it stopped', () {
    final s = LessonState();
    final learned = LearnedSkills();
    s.start(Skill.liberationMastery1);
    for (var i = 0; i < 4; i++) {
      s.record(LessonTask.defeatLiberation, learned);
    }
    s.start(Skill.pastoralCare);
    expect(s.progress, 0);
    expect(s.progressOf(Skill.liberationMastery1), 4);
    s.record(LessonTask.counsel, learned);

    // Saved and loaded in between.
    final back = LessonState()..loadFromJson(s.toJson());
    back.start(Skill.liberationMastery1);
    expect(back.progress, 4);
    expect(back.progressOf(Skill.pastoralCare), 1);
    // Starting the active one again changes nothing.
    back.start(Skill.liberationMastery1);
    expect(back.progress, 4);
  });
}
