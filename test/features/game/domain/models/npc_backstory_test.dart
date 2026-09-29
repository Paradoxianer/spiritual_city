import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_backstory.dart';

void main() {
  group('kLifeEventCatalog consistency', () {
    test('every event has a unique id (across both catalogs)', () {
      final ids = [...kLifeEventCatalog, ...kChristPhaseCatalog].map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('isNegative matches the sign of severity', () {
      for (final e in [...kLifeEventCatalog, ...kChristPhaseCatalog]) {
        expect(e.isNegative, e.severity < 0, reason: e.id);
      }
    });

    test('every event applies to at least one phase', () {
      for (final e in [...kLifeEventCatalog, ...kChristPhaseCatalog]) {
        expect(e.phases, isNotEmpty, reason: e.id);
      }
    });

    test('kLifeEventCatalog never targets the christ phase (that catalog is '
        'separate)', () {
      for (final e in kLifeEventCatalog) {
        expect(e.phases.contains(LifePhase.christ), isFalse, reason: e.id);
      }
    });

    test('kChristPhaseCatalog only targets the christ phase', () {
      for (final e in kChristPhaseCatalog) {
        expect(e.phases, {LifePhase.christ}, reason: e.id);
      }
    });

    test('every non-loss category has at least one negative and one '
        'positive event', () {
      for (final category in LifeCategory.values) {
        final pool = kLifeEventCatalog.where((e) => e.category == category);
        expect(pool.any((e) => e.isNegative), isTrue, reason: '$category negative');
        if (category != LifeCategory.loss) {
          expect(pool.any((e) => !e.isNegative), isTrue, reason: '$category positive');
        }
      }
    });

    test('ordinary (mundane) events clearly outweigh dramatic ones by base '
        'weight, so a revealed backstory reads as mostly ordinary', () {
      final dramatic = kLifeEventCatalog.where((e) => e.severity <= -6);
      final ordinary = kLifeEventCatalog.where((e) => e.severity.abs() <= 2);
      expect(ordinary, isNotEmpty);
      expect(dramatic, isNotEmpty);
      for (final d in dramatic) {
        for (final o in ordinary.where((o) => o.category == d.category)) {
          expect(o.baseWeight, greaterThan(d.baseWeight),
              reason: '${o.id} should outweigh ${d.id}');
        }
      }
    });
  });

  group('NpcBackstoryService.generate determinism', () {
    test('the same id always yields the same event sequence', () {
      final a = NpcBackstoryService.generate('npc_house_1_0');
      final b = NpcBackstoryService.generate('npc_house_1_0');
      expect(a.events.map((o) => o.event.id).toList(),
          b.events.map((o) => o.event.id).toList());
      expect(a.events.map((o) => o.phase).toList(),
          b.events.map((o) => o.phase).toList());
    });

    test('different ids can yield different backstories (sanity)', () {
      final counts = {
        for (int i = 0; i < 100; i++)
          i: NpcBackstoryService.generate('npc_building_$i').events.length,
      };
      expect(counts.values.toSet().length, greaterThan(1));
    });
  });

  group('Acceptance: every phase tells a story (Issue: normal filler + '
      'guaranteed content)', () {
    test('childhood, youth and now each have at least one event for every '
        'generated NPC across a large sample', () {
      for (int i = 0; i < 500; i++) {
        final backstory = NpcBackstoryService.generate('npc_fill_test_$i');
        for (final phase in [LifePhase.childhood, LifePhase.youth, LifePhase.now]) {
          expect(
            backstory.events.any((o) => o.phase == phase),
            isTrue,
            reason: 'npc_fill_test_$i has no event in $phase',
          );
        }
      }
    });

    test('across a large sample, most generated events are ordinary '
        '(|severity| <= 2), not dramatic', () {
      final all = <OccurredEvent>[];
      for (int i = 0; i < 500; i++) {
        all.addAll(NpcBackstoryService.generate('npc_tone_test_$i').events);
      }
      final ordinary = all.where((o) => o.event.severity.abs() <= 2).length;
      expect(ordinary / all.length, greaterThan(0.4));
    });

    test('dramatic events (drugs, imprisonment, violent loss, alcohol '
        'abuse) stay rare across a large sample', () {
      const dramaticIds = {'drugs', 'imprisonment', 'violent_loss', 'alcohol_abuse'};
      int dramaticCount = 0;
      int total = 0;
      for (int i = 0; i < 1000; i++) {
        final events = NpcBackstoryService.generate('npc_rare_test_$i').events;
        total += events.length;
        dramaticCount += events.where((o) => dramaticIds.contains(o.event.id)).length;
      }
      expect(dramaticCount / total, lessThan(0.05));
    });
  });

  group('Acceptance: unprocessed childhood hardship cascades forward', () {
    bool hasVulnerabilitySensitiveLaterEvent(NpcBackstory b) => b.events.any(
          (o) =>
              o.phase != LifePhase.childhood &&
              o.event.isNegative &&
              o.event.vulnerabilityFactor > 0,
        );

    bool hadHardChildhood(NpcBackstory b) => b.events.any(
          (o) => o.phase == LifePhase.childhood && o.event.severity <= -4,
        );

    bool hadNoChildhoodHardship(NpcBackstory b) => !b.events.any(
          (o) => o.phase == LifePhase.childhood && o.event.isNegative,
        );

    test('NPCs with hard childhoods have a measurably higher rate of '
        'vulnerability-sensitive negative events later in life than NPCs '
        'with a calm childhood', () {
      final burdened = <NpcBackstory>[];
      final calm = <NpcBackstory>[];

      for (int i = 0; i < 6000; i++) {
        final backstory = NpcBackstoryService.generate('npc_cascade_test_$i');
        if (hadHardChildhood(backstory)) {
          burdened.add(backstory);
        } else if (hadNoChildhoodHardship(backstory)) {
          calm.add(backstory);
        }
      }

      expect(burdened.length, greaterThan(50));
      expect(calm.length, greaterThan(50));

      final burdenedRate =
          burdened.where(hasVulnerabilitySensitiveLaterEvent).length / burdened.length;
      final calmRate =
          calm.where(hasVulnerabilitySensitiveLaterEvent).length / calm.length;

      expect(burdenedRate, greaterThan(calmRate),
          reason: 'burdened=$burdenedRate calm=$calmRate');
    });
  });

  group('OccurredEvent.advanceWork – player-driven processing', () {
    LifeEvent negativeEvent() => kLifeEventCatalog.firstWhere((e) => e.id == 'drugs');
    LifeEvent positiveEvent() => kLifeEventCatalog.firstWhere((e) => e.id == 'first_love');

    test('starts unprocessed with zero progress', () {
      final occurred = OccurredEvent(event: negativeEvent(), phase: LifePhase.youth);
      expect(occurred.processed, isFalse);
      expect(occurred.workProgress, 0);
      expect(occurred.isWorkable, isTrue);
    });

    test('positive events are never workable', () {
      final occurred = OccurredEvent(event: positiveEvent(), phase: LifePhase.youth);
      expect(occurred.isWorkable, isFalse);
      expect(occurred.advanceWork(), isFalse);
      expect(occurred.workProgress, 0);
    });

    test('needs OccurredEvent.workRequired calls to become processed', () {
      final occurred = OccurredEvent(event: negativeEvent(), phase: LifePhase.youth);
      for (int i = 1; i < OccurredEvent.workRequired; i++) {
        expect(occurred.advanceWork(), isFalse, reason: 'call #$i');
        expect(occurred.processed, isFalse);
      }
      expect(occurred.advanceWork(), isTrue, reason: 'final call');
      expect(occurred.processed, isTrue);
      expect(occurred.isWorkable, isFalse);
    });

    test('already-processed events cannot be worked further', () {
      final occurred = OccurredEvent(
        event: negativeEvent(),
        phase: LifePhase.youth,
        processed: true,
        workProgress: OccurredEvent.workRequired,
      );
      expect(occurred.advanceWork(), isFalse);
      expect(occurred.workProgress, OccurredEvent.workRequired);
    });
  });

  group('NpcBackstory.vulnerability / resilience are live, not frozen', () {
    test('resilience grows and vulnerability shrinks as an event is worked '
        'through', () {
      final event = kLifeEventCatalog.firstWhere((e) => e.id == 'drugs'); // severity -8
      final occurred = OccurredEvent(event: event, phase: LifePhase.youth);
      final backstory = NpcBackstory(events: [occurred]);

      final vulnerabilityBefore = backstory.vulnerability;
      final resilienceBefore = backstory.resilience;
      expect(resilienceBefore, 0.0);
      expect(vulnerabilityBefore, greaterThan(0));

      while (occurred.advanceWork() == false) {}

      expect(backstory.resilience, greaterThan(resilienceBefore));
      expect(backstory.vulnerability, lessThan(vulnerabilityBefore));
    });

    test('resilienceDamping rises as more events are processed', () {
      final events = List.generate(
        5,
        (i) => OccurredEvent(
          event: kLifeEventCatalog.firstWhere((e) => e.id == 'church_disappointment'),
          phase: LifePhase.now,
        ),
      );
      final backstory = NpcBackstory(events: events);
      expect(backstory.resilienceDamping, 0.0);

      for (final o in events) {
        while (!o.processed) {
          o.advanceWork();
        }
      }
      expect(backstory.resilienceDamping, greaterThan(0.0));
    });
  });

  group('NpcBackstory progress persistence (captureProgress/restoreProgress)', () {
    test('captureProgress is empty for a fresh backstory', () {
      final backstory = NpcBackstoryService.generate('npc_progress_test_1');
      expect(backstory.captureProgress(), isEmpty);
    });

    test('captureProgress only includes events with non-zero progress', () {
      final event = kLifeEventCatalog.firstWhere((e) => e.id == 'drugs');
      final occurred = OccurredEvent(event: event, phase: LifePhase.youth);
      final untouched = OccurredEvent(
        event: kLifeEventCatalog.firstWhere((e) => e.id == 'imprisonment'),
        phase: LifePhase.youth,
      );
      final backstory = NpcBackstory(events: [occurred, untouched]);
      occurred.advanceWork();

      final progress = backstory.captureProgress();
      expect(progress, {'work': {'drugs': 1}});
    });

    test('restoreProgress round-trips through capture on a freshly '
        'regenerated backstory', () {
      final original = NpcBackstoryService.generate('npc_progress_test_2');
      // Work through every workable event by one step.
      for (final o in original.events) {
        if (o.isWorkable) o.advanceWork();
      }
      final captured = original.captureProgress();
      expect(captured, isNotEmpty);

      // Simulate a save/load cycle: regenerate (deterministic) and restore.
      final regenerated = NpcBackstoryService.generate('npc_progress_test_2');
      regenerated.restoreProgress(captured);

      expect(regenerated.captureProgress(), captured);
    });

    test('restoreProgress ignores unknown event ids without throwing '
        '(forward compatibility with catalog changes)', () {
      final backstory = NpcBackstoryService.generate('npc_progress_test_3');
      expect(
        () => backstory.restoreProgress({'some_removed_event_id': 2}),
        returnsNormally,
      );
    });
  });

  group('NpcBackstory.ensureChristPhaseFor (Issue: fills slowly, not '
      'upfront)', () {
    test('adds nothing when the NPC is not converted', () {
      final backstory = NpcBackstoryService.generate('npc_christ_test_1');
      final before = backstory.events.length;
      backstory.ensureChristPhaseFor('npc_christ_test_1', isConverted: false);
      expect(backstory.events.length, before);
    });

    test('adds nothing even once the NPC is converted – the chapter starts '
        'empty and only grows via workOn', () {
      final backstory = NpcBackstoryService.generate('npc_christ_test_2');
      final before = backstory.events.length;
      backstory.ensureChristPhaseFor('npc_christ_test_2', isConverted: true);
      expect(backstory.events.length, before);
      expect(backstory.events.any((o) => o.phase == LifePhase.christ), isFalse);
    });
  });

  group('NpcBackstory.workOn – "Als Christ" grows from worked-through '
      'challenges', () {
    // Scans for an id whose generated backstory has at least one workable
    // (negative, unprocessed) event – generation doesn't guarantee one on
    // every single id (only that *some* event occurs per phase), so a fixed
    // id could occasionally have none.
    (String, NpcBackstory) findWithWorkableEvent(String prefix) {
      for (int i = 0; i < 30; i++) {
        final id = '${prefix}_$i';
        final backstory = NpcBackstoryService.generate(id);
        if (backstory.events.any((o) => o.isWorkable)) return (id, backstory);
      }
      fail('No NPC with a workable event found for prefix $prefix');
    }

    test('processing a challenge before conversion does not grow the Christ '
        'chapter', () {
      final (id, backstory) = findWithWorkableEvent('npc_growth_test_1');
      final occurred = backstory.events.firstWhere((o) => o.isWorkable);
      while (!backstory.workOn(occurred, id, isConverted: false).completed) {}
      expect(backstory.events.any((o) => o.phase == LifePhase.christ), isFalse);
    });

    test('completing a challenge while converted adds exactly one Christ '
        'chapter entry', () {
      final (id, backstory) = findWithWorkableEvent('npc_growth_test_2');
      backstory.ensureChristPhaseFor(id, isConverted: true);
      final occurred = backstory.events.firstWhere((o) => o.isWorkable);
      final before = backstory.events.where((o) => o.phase == LifePhase.christ).length;

      bool completed = false;
      while (!completed) {
        completed = backstory.workOn(occurred, id, isConverted: true).completed;
      }

      final after = backstory.events.where((o) => o.phase == LifePhase.christ).length;
      expect(after, before + 1);
    });

    test('workOn\'s return record reports christGrowth accurately (the UI '
        'uses this to decide the Insight reward)', () {
      final (id, backstory) = findWithWorkableEvent('npc_growth_test_2b');
      final occurred = backstory.events.firstWhere((o) => o.isWorkable);

      // Not converted: completes, but never reports christGrowth.
      ({bool completed, bool christGrowth}) result;
      do {
        result = backstory.workOn(occurred, id, isConverted: false);
      } while (!result.completed);
      expect(result, (completed: true, christGrowth: false));

      // A second, converted NPC: the completing call reports christGrowth.
      final (id2, backstory2) = findWithWorkableEvent('npc_growth_test_2c');
      backstory2.ensureChristPhaseFor(id2, isConverted: true);
      final occurred2 = backstory2.events.firstWhere((o) => o.isWorkable);
      ({bool completed, bool christGrowth}) result2;
      do {
        result2 = backstory2.workOn(occurred2, id2, isConverted: true);
      } while (!result2.completed);
      expect(result2, (completed: true, christGrowth: true));
    });

    test('partial progress (not yet completed) does not grow the Christ '
        'chapter', () {
      final (id, backstory) = findWithWorkableEvent('npc_growth_test_3');
      backstory.ensureChristPhaseFor(id, isConverted: true);
      final occurred = backstory.events.firstWhere((o) => o.isWorkable);
      // One unit short of completing (workRequired defaults to 3).
      for (int i = 0; i < OccurredEvent.workRequired - 1; i++) {
        backstory.workOn(occurred, id, isConverted: true);
      }
      expect(backstory.events.any((o) => o.phase == LifePhase.christ), isFalse);
    });

    test('is deterministic: the same NPC working through the same '
        'challenge always yields the same growth entry', () {
      final (id, _) = findWithWorkableEvent('npc_growth_test_4');

      List<String> run() {
        final backstory = NpcBackstoryService.generate(id);
        backstory.ensureChristPhaseFor(id, isConverted: true);
        final occurred = backstory.events.firstWhere((o) => o.isWorkable);
        while (!backstory.workOn(occurred, id, isConverted: true).completed) {}
        return backstory.events
            .where((o) => o.phase == LifePhase.christ)
            .map((o) => o.event.id)
            .toList();
      }

      expect(run(), run());
    });

    test('never adds the same Christ-phase entry twice, even across many '
        'processed challenges', () {
      final (id, backstory) = findWithWorkableEvent('npc_growth_test_5');
      backstory.ensureChristPhaseFor(id, isConverted: true);

      for (final occurred in backstory.events.where((o) => o.isWorkable).toList()) {
        while (!backstory.workOn(occurred, id, isConverted: true).completed) {}
      }

      final christIds =
          backstory.events.where((o) => o.phase == LifePhase.christ).map((o) => o.event.id);
      expect(christIds.length, christIds.toSet().length);
    });
  });

  group('NpcBackstory derived effects', () {
    test('faithOffset is 0 when there are no faith-category events', () {
      final backstory = NpcBackstory(events: []);
      expect(backstory.faithOffset, 0.0);
    });

    test('faithOffset sums faith-category severities, scaled', () {
      final positive = kLifeEventCatalog.firstWhere((e) => e.id == 'conversion_experience');
      final negative = kLifeEventCatalog.firstWhere((e) => e.id == 'church_disappointment');
      final backstory = NpcBackstory(events: [
        OccurredEvent(event: positive, phase: LifePhase.now),
        OccurredEvent(event: negative, phase: LifePhase.now),
      ]);
      expect(backstory.faithOffset, (positive.severity + negative.severity) * 1.5);
    });

    test('faithOffset does not change when an event gets processed (fixed, '
        'not live like vulnerability/resilience)', () {
      final negative = kLifeEventCatalog.firstWhere((e) => e.id == 'church_disappointment');
      final occurred = OccurredEvent(event: negative, phase: LifePhase.now);
      final backstory = NpcBackstory(events: [occurred]);
      final before = backstory.faithOffset;
      while (!occurred.processed) {
        occurred.advanceWork();
      }
      expect(backstory.faithOffset, before);
    });

    test('wealthModifier ignores non-money events', () {
      final relationshipEvent = kLifeEventCatalog.firstWhere((e) => e.id == 'first_love');
      final backstory = NpcBackstory(
        events: [OccurredEvent(event: relationshipEvent, phase: LifePhase.youth)],
      );
      expect(backstory.wealthModifier, 0.0);
    });

    test('resilienceDamping is capped at 0.5 even for many processed events',
        () {
      final events = List.generate(
        20,
        (i) => OccurredEvent(
          event: kLifeEventCatalog.firstWhere((e) => e.id == 'drugs'),
          phase: LifePhase.youth,
          processed: true,
          workProgress: OccurredEvent.workRequired,
        ),
      );
      final backstory = NpcBackstory(events: events);
      expect(backstory.resilienceDamping, 0.5);
    });

    test('resilienceDamping is 0 for a fresh backstory with no events', () {
      final backstory = NpcBackstory(events: []);
      expect(backstory.resilienceDamping, 0.0);
    });
  });

  group('OccurredEvent presentation', () {
    test('caption combines phase and category labels', () {
      final event = kLifeEventCatalog.firstWhere((e) => e.id == 'neglect');
      final occurred = OccurredEvent(event: event, phase: LifePhase.childhood);
      expect(occurred.caption, 'Kindheit · Beziehung');
    });

    test('christ-phase caption uses its own phase label', () {
      final event = kChristPhaseCatalog.firstWhere((e) => e.id == 'baptism');
      final occurred = OccurredEvent(event: event, phase: LifePhase.christ);
      expect(occurred.caption, 'Als Christ · Glaube');
    });

    test('displayGlyph shows the unprocessed coping glyph before work is '
        'done', () {
      final event = kLifeEventCatalog.firstWhere((e) => e.id == 'drugs');
      final occurred = OccurredEvent(event: event, phase: LifePhase.youth);
      expect(occurred.displayGlyph, '${event.glyph}🌫️');
    });

    test('displayGlyph shows the processed coping glyph once fully worked '
        'through', () {
      final event = kLifeEventCatalog.firstWhere((e) => e.id == 'drugs');
      final occurred = OccurredEvent(event: event, phase: LifePhase.youth);
      while (!occurred.processed) {
        occurred.advanceWork();
      }
      expect(occurred.displayGlyph, '${event.glyph}🌱');
    });

    test('displayGlyph is just the event glyph for a positive event', () {
      final event = kLifeEventCatalog.firstWhere((e) => e.id == 'first_love');
      final occurred = OccurredEvent(event: event, phase: LifePhase.youth);
      expect(occurred.displayGlyph, event.glyph);
    });
  });
}
