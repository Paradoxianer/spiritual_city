import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/city_layout.dart';
import 'package:spiritual_city/src/features/game/domain/services/city_crossing.dart';
import 'package:spiritual_city/src/features/game/presentation/spirit_world_game.dart';
import 'package:spiritual_city/src/features/menu/domain/models/city_size.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';
import 'package:spiritual_city/src/features/menu/domain/models/game_save.dart';

// Playtest 2026-11-21: 🌉 after the win into a bigger city, the pastor
// comes along, the city stays behind.
void main() {
  test('each city leads to a bigger one, the big city to another', () {
    expect(CityCrossing.next(CitySize.village), CitySize.smallTown);
    expect(CityCrossing.next(CitySize.smallTown), CitySize.town);
    expect(CityCrossing.next(CitySize.town), CitySize.metropolis);
    expect(CityCrossing.next(CitySize.metropolis), CitySize.metropolis);
  });

  test('the pastor comes along, the city stays behind', () {
    final p = PlayerProgress()
      ..insight = 42
      ..celebratedQuarters.add('0,0')
      ..christianQuarters.add('0,0')
      ..awakenedQuarters.add('0,0')
      ..cityPrayedFree = true;
    final carried = PlayerProgress()..loadFromJson(CityCrossing.carry(p.toJson()));
    expect(carried.insight, 42);
    expect(carried.celebratedQuarters, isEmpty);
    expect(carried.christianQuarters, isEmpty);
    expect(carried.awakenedQuarters, isEmpty);
    expect(carried.cityPrayedFree, isFalse);
  });

  testWidgets('the next city starts at home with the pastor of the last', (tester) async {
    final p = PlayerProgress()
      ..insight = 42
      ..celebratedQuarters.add('0,0');
    final save = GameSave(id: 'b', name: 'b', createdAt: DateTime(2026),
        difficulty: Difficulty.normal, seed: 5, citySize: CitySize.smallTown,
        gameState: CityCrossing.startState(p.toJson(),
            schemaVersion: SpiritWorldGame.kSaveDataVersion, worldSeed: 5));
    final g = SpiritWorldGame(difficulty: Difficulty.normal, gameSave: save);
    await tester.runAsync(() async {
      g.onGameResize(Vector2(800, 600));
      // ignore: invalid_use_of_internal_member
      await g.load();
      // ignore: invalid_use_of_internal_member
      g.mount();
      g.update(0);
      await g.ready();
    });
    expect(CityLayout.current.size, CitySize.smallTown);
    expect(g.seedManager.seed, 5);
    expect(g.progress.insight, 42);
    expect(g.progress.celebratedQuarters, isEmpty);
    final spawn = CityLayout.current.spawnCell;
    expect((g.player.position.x / 32 - spawn.$1).abs(), lessThan(4));
    expect((g.player.position.y / 32 - spawn.$2).abs(), lessThan(4));
    await tester.pump(const Duration(seconds: 5));
    CityLayout.current = CityLayout(CitySize.metropolis);
  });
}
