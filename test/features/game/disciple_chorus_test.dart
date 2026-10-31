import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/prayer_combat.dart';
import 'package:spiritual_city/src/features/game/presentation/components/shockwave_component.dart';
import 'package:spiritual_city/src/features/game/presentation/spirit_world_game.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

void main() {
  // 📢🎺 An open-air meeting gathers the disciples; gathered, they pray
  // with each of the pastor's waves – each in their strongest mode.
  testWidgets('gathered disciples pray with the pastor', (tester) async {
    final g = SpiritWorldGame(difficulty: Difficulty.normal);
    await tester.runAsync(() async {
      g.onGameResize(Vector2(800, 600));
      await g.onLoad();
    });
    g.chunkManager.update(0.016);
    final npcs = g.chunkManager.allActiveNPCs
        .where((c) => c.position.distanceTo(g.player.position) < 600)
        .take(3)
        .toList();
    expect(npcs, hasLength(3));
    final modes = [PrayerMode.slow, PrayerMode.drain, PrayerMode.rebuke];
    for (var i = 0; i < 3; i++) {
      npcs[i].model.isConverted = true;
      npcs[i].model.discipleProfile.getFor(modes[i]).strengthLevel = 2;
    }
    expect(g.gatherDisciples(g.player.position), 3);
    expect(npcs.every((c) => c.isGathered), isTrue);

    final before = g.world.children.whereType<ShockwaveComponent>().length;
    g.disciplePrayer.joinPastorWave();
    final added = g.world.children.whereType<ShockwaveComponent>().length - before;
    expect(added, 3);
    expect(g.world.children.whereType<ShockwaveComponent>().map((w) => w.mode).toSet(), modes.toSet());

    // Not again at once (one wave each per second at most).
    g.disciplePrayer.joinPastorWave();
    expect(g.world.children.whereType<ShockwaveComponent>().length - before, 3);
  });
}
