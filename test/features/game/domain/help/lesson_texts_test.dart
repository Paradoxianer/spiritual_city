import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/core/i18n/app_strings.dart';
import 'package:spiritual_city/src/features/game/domain/help/lesson_texts.dart';
import 'package:spiritual_city/src/features/game/domain/models/prayer_combat.dart';
import 'package:spiritual_city/src/features/game/domain/models/skills.dart';
import 'package:spiritual_city/src/features/game/domain/services/learning_service.dart';

void main() {
  test('every lesson is explained in every state and language, without placeholders', () {
    for (final lang in ['de', 'en', 'es', 'fr', 'pt']) {
      AppStrings.setLanguage(lang);
      for (final l in Lessons.all) {
        for (final (learned, active) in [
          (LearnedSkills(), null),
          (LearnedSkills(), l.skill),
          (LearnedSkills({l.skill}), null),
          (LearnedSkills({...l.requires}), null),
        ]) {
          final t = LessonTexts.explain(l, learned: learned, awakenings: 0, active: active, progress: 1);
          expect(t, isNotEmpty);
          expect(t.contains('{'), isFalse, reason: '$lang ${l.skill}: $t');
        }
      }
      final m = LessonTexts.explainMode(PrayerMode.rebuke, level: 3, cap: 3, modeName: 'X', nextLesson: 'Y');
      expect(m.contains('{'), isFalse, reason: m);
    }
    AppStrings.setLanguage('de');
  });

  test('an open lesson says where to go and what to practise', () {
    AppStrings.setLanguage('de');
    final l = Lessons.of(Skill.pastoralCare);
    final t = LessonTexts.explain(l, learned: LearnedSkills({...l.requires}), awakenings: 9);
    expect(t, contains('Mentor'));
    expect(t, contains('${l.count}×'));
    expect(t, contains('📍'));
  });
}
