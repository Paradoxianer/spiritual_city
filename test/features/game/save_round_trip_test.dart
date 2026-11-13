import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:spiritual_city/src/features/game/presentation/spirit_world_game.dart';
import 'package:spiritual_city/src/features/menu/data/menu_repository.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';
import 'package:spiritual_city/src/features/menu/domain/models/game_save.dart';
import 'package:spiritual_city/src/features/menu/domain/models/app_settings.dart';

void main() {
  // Playtest 2026-10-19: resources and levels seemed reset after loading.
  // The whole path – capture, Hive, load – must give back the same values.
  testWidgets('play → save → load keeps resources, levels and insight', (tester) async {
    final dir = Directory.systemTemp.createTempSync('save_rt');
    Hive.init(dir.path);
    Hive.registerAdapter(GameSaveAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    final repo = MenuRepository();
    final fresh = GameSave(id: 's${DateTime.now().millisecondsSinceEpoch}', name: 's', createdAt: DateTime(2026), difficulty: Difficulty.normal, seed: 7);
    await tester.runAsync(() => repo.writeSave(fresh));

    final g1 = SpiritWorldGame(difficulty: Difficulty.normal, gameSave: fresh);
    await tester.runAsync(() async {
      g1.onGameResize(Vector2(800, 600));
      await g1.onLoad();
    });
    g1.gainFaith(500);
    g1.gainMaterials(300);
    g1.progress.addInsight(55);
    final state = g1.captureGameState();
    await tester.runAsync(() async {
      final saves = await repo.loadAllSaves();
      await repo.writeSave(saves.firstWhere((x) => x.id == fresh.id).copyWithState(state));
      await Hive.close();
      Hive.init(dir.path);
    });
    final loaded = (await tester.runAsync(() => repo.loadAllSaves()))!.firstWhere((x) => x.id == fresh.id);
    final g2 = SpiritWorldGame(difficulty: loaded.difficulty, gameSave: loaded);
    await tester.runAsync(() async {
      g2.onGameResize(Vector2(800, 600));
      await g2.onLoad();
    });
    expect(g2.progress.faithStage.stage, g1.progress.faithStage.stage);
    expect(g2.progress.materialsStage.stage, g1.progress.materialsStage.stage);
    expect(g2.materials, g1.materials);
    expect(g2.progress.insight, g1.progress.insight);
    expect(g2.faith, g1.faith);
  });
}
