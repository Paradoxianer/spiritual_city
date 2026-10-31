import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/presentation/spirit_world_game.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

void main() {
  // #194: a day of the world runs spread over frames inside the game and
  // reaches people everywhere, not only near the pastor.
  testWidgets('a world day runs over frames in the game', (tester) async {
    final g = SpiritWorldGame(difficulty: Difficulty.normal);
    await tester.runAsync(() async {
      g.onGameResize(Vector2(800, 600));
      await g.onLoad();
    });
    g.chunkManager.update(0.016);
    final far = g.chunkManager.allActiveNPCs
        .firstWhere((c) => c.position.distanceTo(g.player.position) > 400)
        .model
      ..isConverted = true
      ..faith = 80;
    expect(far.isShakenChristian, isFalse);
    final before = g.worldDay;
    g.spiritualDynamics.update(61); // starts the day
    for (var i = 0; i < 400; i++) {
      g.spiritualDynamics.update(0.016);
    }
    expect(g.worldDay, before + 1);
    expect(g.captureGameState()['worldDay'], before + 1);
  });
}
