import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_backstory.dart';

void main() {
  group('kLifeEventCatalog consistency', () {
    test('every event has a unique id', () {
      final ids = kLifeEventCatalog.map((e) => e.id).toSet();
      expect(ids.length, kLifeEventCatalog.length);
    });

    test('isNegative matches the sign of severity', () {
      for (final e in kLifeEventCatalog) {
        expect(e.isNegative, e.severity < 0, reason: e.id);
      }
    });

    test('every event applies to at least one phase', () {
      for (final e in kLifeEventCatalog) {
        expect(e.phases, isNotEmpty, reason: e.id);
      }
    });

    test('every category has at least one negative and one positive event, '
        'except loss (negative-only by design)', () {
      for (final category in LifeCategory.values) {
        final pool = kLifeEventCatalog.where((e) => e.category == category);
        final hasNegative = pool.any((e) => e.isNegative);
        final hasPositive = pool.any((e) => !e.isNegative);
        expect(hasNegative, isTrue, reason: '$category has no negative event');
        if (category != LifeCategory.loss) {
          expect(hasPositive, isTrue, reason: '$category has no positive event');
        }
      }
    });
  });

  group('NpcBackstoryService.generate determinism', () {
    test('the same id always yields the same backstory', () {
      final a = NpcBackstoryService.generate('npc_house_1_0');
      final b = NpcBackstoryService.generate('npc_house_1_0');
      expect(a.vulnerability, b.vulnerability);
      expect(a.resilience, b.resilience);
      expect(a.events.map((o) => o.event.id).toList(),
          b.events.map((o) => o.event.id).toList());
      expect(a.events.map((o) => o.phase).toList(),
          b.events.map((o) => o.phase).toList());
      expect(a.events.map((o) => o.processed).toList(),
          b.events.map((o) => o.processed).toList());
    });

    test('different ids can yield different backstories (sanity)', () {
      final results = {
        for (int i = 0; i < 100; i++)
          i: NpcBackstoryService.generate('npc_building_$i'),
      };
      final distinctEventCounts =
          results.values.map((b) => b.events.length).toSet();
      expect(distinctEventCounts.length, greaterThan(1),
          reason: '100 different ids all produced the same event count – '
              'the generator is not varying at all');
    });
  });

  group('Acceptance: unprocessed childhood hardship cascades forward', () {
    // Sensitive to vulnerability: alcohol_abuse, drugs, imprisonment,
    // failed_relationship, unemployment, debt.
    bool hasVulnerabilitySensitiveLaterEvent(NpcBackstory b) => b.events.any(
          (o) =>
              o.phase != LifePhase.childhood &&
              o.event.isNegative &&
              o.event.vulnerabilityFactor > 0,
        );

    bool hadSevereUnprocessedChildhoodEvent(NpcBackstory b) => b.events.any(
          (o) =>
              o.phase == LifePhase.childhood &&
              o.event.severity <= -5 &&
              o.processed == false,
        );

    bool hadNoChildhoodHardship(NpcBackstory b) => !b.events.any(
          (o) => o.phase == LifePhase.childhood && o.event.isNegative,
        );

    test('NPCs with severe, unprocessed childhood hardship have a measurably '
        'higher rate of vulnerability-sensitive negative events later in '
        'life than NPCs with a calm childhood', () {
      final burdened = <NpcBackstory>[];
      final calm = <NpcBackstory>[];

      for (int i = 0; i < 4000; i++) {
        final backstory = NpcBackstoryService.generate('npc_cascade_test_$i');
        if (hadSevereUnprocessedChildhoodEvent(backstory)) {
          burdened.add(backstory);
        } else if (hadNoChildhoodHardship(backstory)) {
          calm.add(backstory);
        }
      }

      // Sanity: both buckets are large enough for the comparison to mean
      // something (fails loudly if the catalog/probabilities change enough
      // to make either bucket vanish).
      expect(burdened.length, greaterThan(50));
      expect(calm.length, greaterThan(50));

      final burdenedRate = burdened
              .where(hasVulnerabilitySensitiveLaterEvent)
              .length /
          burdened.length;
      final calmRate =
          calm.where(hasVulnerabilitySensitiveLaterEvent).length / calm.length;

      expect(burdenedRate, greaterThan(calmRate),
          reason: 'burdened=$burdenedRate calm=$calmRate – unprocessed '
              'childhood hardship should raise the vulnerability-sensitive '
              'event rate later in life');
    });

    test('vulnerability accumulates far more from an unprocessed event than '
        'a processed one of the same severity (reason the cascade above '
        'works at all)', () {
      // -8 severity: processed vs. unprocessed vulnerability contribution.
      const severity = 8;
      const processedGain =
          severity * NpcBackstoryService.processedVulnerabilityGain;
      const unprocessedGain =
          severity * NpcBackstoryService.unprocessedVulnerabilityGain;
      expect(unprocessedGain, greaterThan(processedGain * 2));
    });

    test('processed events grant resilience far more than vulnerability '
        '("post-traumatic growth")', () {
      const severity = 8;
      const vulnerabilityGain =
          severity * NpcBackstoryService.processedVulnerabilityGain;
      const resilienceGain =
          severity * NpcBackstoryService.processedResilienceGain;
      expect(resilienceGain, greaterThan(vulnerabilityGain));
    });
  });

  group('NpcBackstory derived effects', () {
    test('faithOffset is 0 when there are no faith-category events', () {
      const backstory = NpcBackstory(events: [], vulnerability: 0, resilience: 0);
      expect(backstory.faithOffset, 0.0);
    });

    test('faithOffset sums faith-category severities, scaled', () {
      final positive = kLifeEventCatalog.firstWhere((e) => e.id == 'conversion_experience');
      final negative = kLifeEventCatalog.firstWhere((e) => e.id == 'church_disappointment');
      final backstory = NpcBackstory(
        events: [
          OccurredEvent(event: positive, phase: LifePhase.now),
          OccurredEvent(event: negative, phase: LifePhase.now, processed: false),
        ],
        vulnerability: 0,
        resilience: 0,
      );
      expect(backstory.faithOffset, (positive.severity + negative.severity) * 1.5);
    });

    test('wealthModifier ignores non-money events', () {
      final relationshipEvent =
          kLifeEventCatalog.firstWhere((e) => e.id == 'first_love');
      final backstory = NpcBackstory(
        events: [OccurredEvent(event: relationshipEvent, phase: LifePhase.youth)],
        vulnerability: 0,
        resilience: 0,
      );
      expect(backstory.wealthModifier, 0.0);
    });

    test('resilienceDamping is capped at 0.5 even for very high resilience', () {
      const backstory = NpcBackstory(events: [], vulnerability: 0, resilience: 1000);
      expect(backstory.resilienceDamping, 0.5);
    });

    test('resilienceDamping is 0 for a fresh NPC with no resilience', () {
      const backstory = NpcBackstory(events: [], vulnerability: 0, resilience: 0);
      expect(backstory.resilienceDamping, 0.0);
    });
  });

  group('OccurredEvent presentation', () {
    test('caption combines phase and category labels', () {
      final event = kLifeEventCatalog.firstWhere((e) => e.id == 'neglect');
      final occurred = OccurredEvent(event: event, phase: LifePhase.childhood, processed: false);
      expect(occurred.caption, 'Kindheit · Beziehung');
    });

    test('displayGlyph appends the unprocessed glyph for an unprocessed '
        'negative event', () {
      final event = kLifeEventCatalog.firstWhere((e) => e.id == 'drugs');
      final occurred = OccurredEvent(event: event, phase: LifePhase.youth, processed: false);
      expect(occurred.displayGlyph, '${event.glyph}🌫️');
    });

    test('displayGlyph appends the processed glyph for a processed negative '
        'event', () {
      final event = kLifeEventCatalog.firstWhere((e) => e.id == 'drugs');
      final occurred = OccurredEvent(event: event, phase: LifePhase.youth, processed: true);
      expect(occurred.displayGlyph, '${event.glyph}🌱');
    });

    test('displayGlyph is just the event glyph for a positive event', () {
      final event = kLifeEventCatalog.firstWhere((e) => e.id == 'first_love');
      final occurred = OccurredEvent(event: event, phase: LifePhase.youth);
      expect(occurred.displayGlyph, event.glyph);
    });
  });
}
