import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/base_interactable_entity.dart';

/// Minimal concrete subclass used only in tests.
class _TestEntity extends BaseInteractableEntity {
  @override
  final String id;

  _TestEntity({
    required this.id,
    double faith = 0.0,
    int interactionCount = 0,
  }) : super(faith: faith, interactionCount: interactionCount);
}

void main() {
  group('BaseInteractableEntity', () {
    _TestEntity make({double faith = 0.0, int interactionCount = 0}) =>
        _TestEntity(id: 'test', faith: faith, interactionCount: interactionCount);

    group('applyInfluence – faith clamping', () {
      test('adds positive influence correctly', () {
        final entity = make(faith: 50.0);
        entity.applyInfluence(20.0);
        expect(entity.faith, 70.0);
      });

      test('adds negative influence correctly', () {
        final entity = make(faith: -30.0);
        entity.applyInfluence(-40.0);
        expect(entity.faith, -70.0);
      });

      test('clamps at +100 when overflow', () {
        final entity = make(faith: 90.0);
        entity.applyInfluence(50.0);
        expect(entity.faith, 100.0);
      });

      test('clamps at -100 when underflow', () {
        final entity = make(faith: -90.0);
        entity.applyInfluence(-50.0);
        expect(entity.faith, -100.0);
      });

      test('stays at exact boundary +100', () {
        final entity = make(faith: 100.0);
        entity.applyInfluence(0.0);
        expect(entity.faith, 100.0);
      });

      test('stays at exact boundary -100', () {
        final entity = make(faith: -100.0);
        entity.applyInfluence(0.0);
        expect(entity.faith, -100.0);
      });
    });

    group('maxSessionInteractions', () {
      test('0 total interactions → limit 2', () {
        expect(make(interactionCount: 0).maxSessionInteractions, 2);
      });

      test('5 total interactions → limit 2 (not yet 6)', () {
        expect(make(interactionCount: 5).maxSessionInteractions, 2);
      });

      test('6 total interactions → limit 3', () {
        expect(make(interactionCount: 6).maxSessionInteractions, 3);
      });

      test('7 total interactions → still 3', () {
        expect(make(interactionCount: 7).maxSessionInteractions, 3);
      });

      test('11 total interactions → still 3 (not yet 12)', () {
        expect(make(interactionCount: 11).maxSessionInteractions, 3);
      });

      test('12 total interactions → limit 4', () {
        expect(make(interactionCount: 12).maxSessionInteractions, 4);
      });

      test('18 total interactions → limit 5', () {
        expect(make(interactionCount: 18).maxSessionInteractions, 5);
      });
    });

    group('isReadyToLeave', () {
      test('not ready after 0 session interactions (limit 2)', () {
        final entity = make(interactionCount: 0);
        entity.currentSessionInteractions = 0;
        expect(entity.isReadyToLeave, isFalse);
      });

      test('not ready after 1 session interaction (limit 2)', () {
        final entity = make(interactionCount: 0);
        entity.currentSessionInteractions = 1;
        expect(entity.isReadyToLeave, isFalse);
      });

      test('ready after 2 session interactions at default limit', () {
        final entity = make(interactionCount: 0);
        entity.currentSessionInteractions = 2;
        expect(entity.isReadyToLeave, isTrue);
      });

      test('NOT ready after 2 session interactions when limit is 3 (6 total)', () {
        final entity = make(interactionCount: 6); // limit = 3
        entity.currentSessionInteractions = 2;
        expect(entity.isReadyToLeave, isFalse);
      });

      test('ready after 3 session interactions when limit is 3 (6 total)', () {
        final entity = make(interactionCount: 6); // limit = 3
        entity.currentSessionInteractions = 3;
        expect(entity.isReadyToLeave, isTrue);
      });

      test('ready when exactly at limit for various total counts', () {
        for (final entry in {0: 2, 6: 3, 12: 4, 18: 5}.entries) {
          final entity = make(interactionCount: entry.key);
          entity.currentSessionInteractions = entry.value;
          expect(entity.isReadyToLeave, isTrue,
              reason: '${entry.key} total → limit ${entry.value}');
        }
      });
    });

    group('resetSession', () {
      test('resets currentSessionInteractions to 0', () {
        final entity = make();
        entity.currentSessionInteractions = 3;
        entity.resetSession();
        expect(entity.currentSessionInteractions, 0);
      });

      test('does not change interactionCount', () {
        final entity = make(interactionCount: 15);
        entity.resetSession();
        expect(entity.interactionCount, 15);
      });

      test('does not change faith', () {
        final entity = make(faith: 42.0);
        entity.resetSession();
        expect(entity.faith, 42.0);
      });
    });

    group('activeMissionDescription', () {
      test('defaults to null', () {
        expect(make().activeMissionDescription, isNull);
      });

      test('can be set and read', () {
        final entity = make();
        entity.activeMissionDescription = 'Help the community';
        expect(entity.activeMissionDescription, 'Help the community');
      });
    });

    group('isFaithVague / isFaithRevealed (progressive reveal)', () {
      test('not vague at 0 interactions', () {
        expect(make(interactionCount: 0).isFaithVague, isFalse);
      });

      test('not vague at 2 interactions', () {
        expect(make(interactionCount: 2).isFaithVague, isFalse);
      });

      test('vague at exactly 3 interactions', () {
        expect(make(interactionCount: 3).isFaithVague, isTrue);
      });

      test('vague but not revealed at 5 interactions', () {
        final e = make(interactionCount: 5);
        expect(e.isFaithVague, isTrue);
        expect(e.isFaithRevealed, isFalse);
      });

      test('revealed at exactly 6 interactions', () {
        expect(make(interactionCount: 6).isFaithRevealed, isTrue);
      });

      test('revealed at 100 interactions', () {
        expect(make(interactionCount: 100).isFaithRevealed, isTrue);
      });

      test('isFaithRevealed implies isFaithVague', () {
        final e = make(interactionCount: 10);
        expect(e.isFaithRevealed, isTrue);
        expect(e.isFaithVague, isTrue);
      });
    });
  });
}
