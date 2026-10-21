import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/actions/game_action.dart';
import 'package:spiritual_city/src/features/game/domain/actions/resource.dart';
import 'package:spiritual_city/src/features/game/domain/help/help_content.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/daemon_kind.dart';
import 'package:spiritual_city/src/features/game/domain/models/prayer_combat.dart';
import 'package:spiritual_city/src/features/game/domain/models/skills.dart';
import 'package:spiritual_city/src/features/game/domain/services/learning_service.dart';

// The ❓ glossary is generated from the registries; these tests make sure a
// new action, skill or building cannot appear there without its sentence.
void main() {
  void complete<T>(String what, List<T> values, Map<T, Tr> texts) {
    for (final v in values) {
      final t = texts[v];
      expect(t, isNotNull, reason: '$what $v has no help text');
      expect(t!.de.trim(), isNotEmpty, reason: '$what $v (de)');
      expect(t.en.trim(), isNotEmpty, reason: '$what $v (en)');
    }
  }

  test('every action has a sentence', () => complete('ActionId', ActionId.values, HelpContent.actions));
  test('every skill has a sentence', () => complete('Skill', Skill.values, HelpContent.skills));
  test('every lesson task says how to do it',
      () => complete('LessonTask', LessonTask.values, HelpContent.taskHowTo));
  test('every resource has a sentence', () => complete('Resource', Resource.values, HelpContent.resources));
  test('every prayer mode has a sentence',
      () => complete('PrayerMode', PrayerMode.values, HelpContent.prayerModes));
  test('every daemon kind has a sentence', () => complete('DaemonKind', DaemonKind.values, HelpContent.daemons));
  test('every building type has a name', () => complete('BuildingType', BuildingType.values, HelpContent.buildings));

  test('every lesson task used by a lesson is explained', () {
    for (final l in Lessons.all) {
      expect(HelpContent.taskHowTo[l.task], isNotNull, reason: l.skill.name);
    }
  });
}
