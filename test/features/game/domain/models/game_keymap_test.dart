import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/game_keymap.dart';

void main() {
  group('GameKeymap', () {
    test('all movement keys are distinct', () {
      final movementKeys = {
        GameKeymap.moveUp,
        GameKeymap.moveDown,
        GameKeymap.moveLeft,
        GameKeymap.moveRight,
        GameKeymap.moveUpAlt,
        GameKeymap.moveDownAlt,
        GameKeymap.moveLeftAlt,
        GameKeymap.moveRightAlt,
      };
      expect(movementKeys.length, 8);
    });

    test('action keys are non-null and distinct from movement keys', () {
      final actionKeys = [
        GameKeymap.interact,
        GameKeymap.action,
        GameKeymap.worldToggle,
        GameKeymap.close,
        GameKeymap.keymapOverlay,
        GameKeymap.keymapOverlayAlt,
      ];
      for (final key in actionKeys) {
        expect(key, isA<LogicalKeyboardKey>());
      }
      // All action keys must be unique
      final unique = actionKeys.toSet();
      expect(unique.length, actionKeys.length);
    });

    test('radial keys cover 1 through 5', () {
      expect(GameKeymap.radial1, equals(LogicalKeyboardKey.digit1));
      expect(GameKeymap.radial2, equals(LogicalKeyboardKey.digit2));
      expect(GameKeymap.radial3, equals(LogicalKeyboardKey.digit3));
      expect(GameKeymap.radial4, equals(LogicalKeyboardKey.digit4));
      expect(GameKeymap.radial5, equals(LogicalKeyboardKey.digit5));
    });

    test('entries list is non-empty and all entries have non-empty fields', () {
      expect(GameKeymap.entries, isNotEmpty);
      for (final entry in GameKeymap.entries) {
        expect(entry.keys, isNotEmpty);
        expect(entry.action, isNotEmpty);
        expect(entry.category, isNotEmpty);
      }
    });

    test('entries cover all expected categories', () {
      final categories = GameKeymap.entries.map((e) => e.category).toSet();
      expect(categories, containsAll(['Bewegung', 'Interaktion', 'Unsichtbare Welt', 'Allgemein']));
    });

    test('entries list contains the keymap toggle shortcut', () {
      final hasKeymapEntry = GameKeymap.entries.any(
        (e) => e.category == 'Allgemein' && e.keys.contains('F1'),
      );
      expect(hasKeymapEntry, isTrue);
    });

    test('entries list contains the world-toggle shortcut', () {
      final hasWorldToggle = GameKeymap.entries.any(
        (e) => e.keys.contains('Tab'),
      );
      expect(hasWorldToggle, isTrue);
    });
  });
}
