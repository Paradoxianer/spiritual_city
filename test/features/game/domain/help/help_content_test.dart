import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/help/life_texts.dart';
import 'package:spiritual_city/src/features/game/domain/help/near_texts.dart';
import 'package:spiritual_city/src/features/game/domain/help/mission_texts.dart';
import 'package:spiritual_city/src/features/game/domain/models/mission_model.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_backstory.dart';
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
  test('every action has a short name in every language', () {
    complete('ActionId', ActionId.values, HelpContent.actionNames);
    for (final t in HelpContent.actionNames.values) {
      expect([t.es, t.fr, t.pt], everyElement(isNotNull), reason: t.en);
    }
  });
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

  test('every life event and mission kind is told in all five languages', () {
    for (final e in kLifeEventCatalog) {
      final t = LifeTexts.events[e.id];
      expect(t, isNotNull, reason: e.id);
      expect([t!.es, t.fr, t.pt], everyElement(isNotNull), reason: e.id);
    }
    for (final a in ActionType.values) {
      final t = MissionTexts.task[a];
      expect(t, isNotNull, reason: a.name);
      expect([t!.es, t.fr, t.pt], everyElement(isNotNull), reason: a.name);
      expect(t.de.contains('{n}') || !t.de.contains('×'), isTrue, reason: a.name);
    }
  });

  test('every help text has es, fr and pt', () {
    final all = <Tr>[
      ...HelpContent.resources.values,
      for (final (_, t) in HelpContent.symbols) t,
      ...HelpContent.toasts.values,
      ...HelpContent.labels.values,
      ...HelpContent.actions.values,
      ...HelpContent.prayerModes.values,
      ...HelpContent.daemons.values,
      ...HelpContent.skills.values,
      ...HelpContent.taskHowTo.values,
      ...HelpContent.buildings.values,
      for (final (_, a, b) in HelpContent.nextSteps) ...[a, b],
      ...HelpContent.sectionTitles.values,
    ];
    for (final t in all) {
      expect([t.es, t.fr, t.pt], everyElement(isNotNull), reason: t.en);
    }
  });

  test('the narrator has a sentence for every building, person and upgrade', () {
    for (final b in BuildingType.values) {
      final t = NearTexts.buildings[b];
      expect(t, isNotNull, reason: b.name);
      expect([t!.es, t.fr, t.pt], everyElement(isNotNull), reason: b.name);
    }
    for (final k in ['person', 'christian', 'shaken']) {
      expect(NearTexts.people[k]?.pt, isNotNull, reason: k);
    }
    for (final k in ['radius', 'strength', 'duration', 'speed', 'shield', 'helm']) {
      expect(NearTexts.upgrades[k]?.pt, isNotNull, reason: k);
    }
    for (final a in ActionId.values) {
      expect(HelpContent.explanations[a]?.pt, isNotNull, reason: a.name);
    }
  });
}
