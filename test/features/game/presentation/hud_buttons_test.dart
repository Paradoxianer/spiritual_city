import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/skills.dart';
import 'package:spiritual_city/src/features/game/presentation/spirit_world_game.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

void main() {
  // Playtest 2026-11-13: in portrait, after a while 🙏 and 🖐️ in the city
  // often did not react – the hidden prayer-mode buttons of the invisible
  // world lay over them and took the taps.
  testWidgets('in the city, taps on 🙏 and 🖐️ reach them after a visit to the invisible world', (tester) async {
    final g = SpiritWorldGame(difficulty: Difficulty.normal);
    await tester.runAsync(() async {
      g.onGameResize(Vector2(412, 860)); // a phone in portrait
      // ignore: invalid_use_of_internal_member
      await g.load();
      // ignore: invalid_use_of_internal_member
      g.mount();
      g.update(0);
      await g.ready();
    });
    for (final s in Skill.values) {
      g.progress.skills.learn(s); // every prayer mode in the dock
    }
    g.gainFaith(500);
    g.toggleWorld(); // in: the dock lays out every mode
    g.update(0.016);
    g.toggleWorld(); // back to the city
    g.update(0.016);

    for (final button in [g.worldToggleButton, g.actionButton]) {
      for (final dx in [-25.0, 0.0, 25.0]) {
        final p = button.absoluteCenter + Vector2(dx, 0);
        final first = g.componentsAtPoint(p).whereType<TapCallbacks>().first;
        expect(first, same(button), reason: 'tap at $p');
      }
    }
    await tester.pump(const Duration(seconds: 5));
  });
}
