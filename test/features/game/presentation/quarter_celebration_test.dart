import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/quarter.dart';
import 'package:spiritual_city/src/features/game/presentation/spirit_world_game.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

void main() {
  const all = Quarter.sizeCells * Quarter.sizeCells;

  test('95 % of the whole neighbourhood must be green – unseen ground is not', () {
    expect(Awakening.prayedFree(const Tally(all, all)), isTrue);
    expect(Awakening.prayedFree(Tally((all * 0.95).ceil(), all)), isTrue);
    expect(Awakening.prayedFree(Tally((all * 0.95).ceil() - 1, all)), isFalse);
    // Only the part walked through so far, all of it green.
    expect(Awakening.prayedFree(const Tally(500, 500)), isFalse);
  });

  test('celebrated neighbourhoods are saved', () {
    final p = PlayerProgress()..celebratedQuarters.add('0,1');
    expect((PlayerProgress()..loadFromJson(p.toJson())).celebratedQuarters, {'0,1'});
  });

  testWidgets('back from the invisible world: a green neighbourhood is celebrated once', (tester) async {
    final g = SpiritWorldGame(difficulty: Difficulty.normal);
    await tester.runAsync(() async {
      g.onGameResize(Vector2(800, 600));
      // ignore: invalid_use_of_internal_member
      await g.load();
      // ignore: invalid_use_of_internal_member
      g.mount();
      g.update(0);
      await g.ready();
    });
    g.gainFaith(500);
    final q = g.currentQuarter;
    var cells = 0;
    for (final chunk in g.grid.getLoadedChunks()) {
      if (Liberation.quarterOfChunk(chunk.chunkX, chunk.chunkY) != q) continue;
      for (final c in chunk.cells.values) {
        c.spiritualState = 1.0;
        cells++;
      }
    }
    expect(cells, all, reason: 'the whole neighbourhood is generated around the start');

    g.toggleWorld(); // in
    expect(g.quarterCelebration.value, isNull);
    final insight = g.progress.insight;
    g.toggleWorld(); // out
    final c = g.quarterCelebration.value;
    expect(c, isNotNull);
    expect(c!.quarter, q);
    expect(c.percent, greaterThanOrEqualTo(95));
    expect(g.progress.insight, greaterThan(insight));
    expect(g.progress.celebratedQuarters, {q.key});

    g.quarterCelebration.value = null;
    g.toggleWorld();
    g.toggleWorld();
    expect(g.quarterCelebration.value, isNull, reason: 'only once');
    await tester.pump(const Duration(seconds: 5)); // narrator toasts
  });
}
