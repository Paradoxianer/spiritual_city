import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/presentation/spirit_world_game.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

/// Long play without input: the pastor walks through the city and switches
/// worlds now and then. Nothing may pile up (playtest 2026-11-12: the game
/// stuttered after a while and crashed on the phone). SOAK=1.
void main() {
  testWidgets('long play keeps components and frame time flat', (tester) async {
    final g = SpiritWorldGame(difficulty: Difficulty.normal);
    await tester.runAsync(() async {
      g.onGameResize(Vector2(800, 600));
      // Like flame_test's initializeGame: a mounted game queues adds.
      // ignore: invalid_use_of_internal_member
      await g.load();
      // ignore: invalid_use_of_internal_member
      g.mount();
      g.update(0);
      await g.ready();
    });
    int count(Component c) => 1 + c.children.fold(0, (s, x) => s + count(x));
    final start = g.player.position.clone();
    const dt = 1 / 30;
    final minutes = int.tryParse(Platform.environment['SOAK_MIN'] ?? '') ?? 10;
    for (var m = 0; m < minutes; m++) {
      final sw = Stopwatch()..start();
      for (var f = 0; f < 60 * 30; f++) {
        final t = (m * 1800 + f) / 1800.0;
        // A big square walk around the start, about 3 quarters wide.
        final side = (t % 4).floor();
        final u = t % 1;
        const r = 1200.0;
        final o = switch (side) {
          0 => Vector2(-r + 2 * r * u, -r),
          1 => Vector2(r, -r + 2 * r * u),
          2 => Vector2(r - 2 * r * u, r),
          _ => Vector2(-r, r - 2 * r * u),
        };
        g.player.position.setFrom(start + o);
        if (f % 600 == 0) g.toggleWorld();
        g.update(dt);
      }
      sw.stop();
      // ignore: avoid_print
      print('min ${m + 1}: ${sw.elapsedMilliseconds} ms/1800 frames, '
          'components ${count(g)}, world ${g.world.children.length}, '
          'npcs ${g.chunkManager.npcCount}');
    }
    await tester.pump(const Duration(seconds: 5)); // narrator toasts
  }, skip: Platform.environment['SOAK'] != '1');
}
