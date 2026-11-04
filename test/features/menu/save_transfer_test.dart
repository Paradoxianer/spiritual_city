import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/presentation/spirit_world_game.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';
import 'package:spiritual_city/src/features/menu/domain/models/game_save.dart';
import 'package:spiritual_city/src/features/menu/domain/save_transfer.dart';

void main() {
  const max = SpiritWorldGame.kSaveDataVersion;

  // #192: a save travels as a file from phone to web and back.
  testWidgets('play → export → import → load gives the same game', (tester) async {
    final fresh = GameSave(id: 'a', name: 'Mein Spiel', createdAt: DateTime(2026), difficulty: Difficulty.hard, seed: 7);
    final g1 = SpiritWorldGame(difficulty: Difficulty.hard, gameSave: fresh);
    await tester.runAsync(() async {
      g1.onGameResize(Vector2(800, 600));
      await g1.onLoad();
    });
    g1.gainFaith(500);
    g1.gainMaterials(300);
    g1.progress.addInsight(55);
    final save = fresh.copyWithState(g1.captureGameState());

    final file = SaveTransfer.export(save);
    final back = SaveTransfer.import(file, newId: 'b', maxSchemaVersion: max);
    expect(back.id, 'b');
    expect(back.name, save.name);
    expect(back.seed, 7);
    expect(back.difficulty, Difficulty.hard);
    expect(back.createdAt, save.createdAt);
    // Exported again it is the same file (apart from the id).
    expect(jsonDecode(SaveTransfer.export(back))['save']['gameState'],
        jsonDecode(file)['save']['gameState']);

    final g2 = SpiritWorldGame(difficulty: back.difficulty, gameSave: back);
    await tester.runAsync(() async {
      g2.onGameResize(Vector2(800, 600));
      await g2.onLoad();
    });
    expect(g2.faith, g1.faith);
    expect(g2.materials, g1.materials);
    expect(g2.progress.insight, g1.progress.insight);
    expect(g2.progress.faithStage.stage, g1.progress.faithStage.stage);

    // A file from the web has whole numbers without ".0" (JavaScript):
    // the phone must read it all the same.
    final fromWeb = file.replaceAllMapped(RegExp(r'(\d)\.0(?!\d)'), (m) => m[1]!);
    expect(fromWeb, isNot(file));
    final g3 = SpiritWorldGame(difficulty: Difficulty.hard,
        gameSave: SaveTransfer.import(fromWeb, newId: 'c', maxSchemaVersion: max));
    await tester.runAsync(() async {
      g3.onGameResize(Vector2(800, 600));
      await g3.onLoad();
    });
    expect(g3.faith, g1.faith);
    expect(g3.materials, g1.materials);
  });

  group('broken or foreign files are refused', () {
    final good = jsonDecode(SaveTransfer.export(
        GameSave(id: 'a', name: 'x', createdAt: DateTime(2026), difficulty: Difficulty.normal))) as Map<String, dynamic>;
    String withSave(Map<String, dynamic> change) =>
        jsonEncode({...good, 'save': {...good['save'] as Map, ...change}});

    for (final (what, text) in [
      ('no json', 'hello'),
      ('json, not ours', '{"a":1}'),
      ('a list', '[1,2]'),
      ('newer file', jsonEncode({...good, 'formatVersion': 99})),
      ('no name', withSave({'name': null})),
      ('bad date', withSave({'createdAt': 'gestern'})),
      ('bad difficulty', withSave({'difficulty': 9})),
      ('state is no map', withSave({'gameState': 'x'})),
      ('newer game', withSave({'gameState': {'schemaVersion': max + 1}})),
    ]) {
      test(what, () {
        expect(() => SaveTransfer.import(text, newId: 'n', maxSchemaVersion: max),
            throwsA(isA<SaveImportException>()));
      });
    }
  });

  test('older saves are taken (the game migrates them on load)', () {
    final s = GameSave(id: 'a', name: 'x', createdAt: DateTime(2026), difficulty: Difficulty.easy,
        gameState: {'schemaVersion': 1, 'faith': 20.0, 'cells': {'1,2': 0.5}});
    final back = SaveTransfer.import(SaveTransfer.export(s), newId: 'n', maxSchemaVersion: max);
    expect(back.gameState['schemaVersion'], 1);
    expect(back.gameState['faith'], 20.0);
  });

  test('file name is safe', () {
    final s = GameSave(id: '17', name: 'Mein Spiel / Tag 3!', createdAt: DateTime(2026), difficulty: Difficulty.easy);
    expect(SaveTransfer.fileName(s), 'spiritworld-Mein_Spiel_Tag_3_.json');
  });
}
