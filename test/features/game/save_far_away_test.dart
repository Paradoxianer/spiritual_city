import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/presentation/spirit_world_game.dart';
import 'package:spiritual_city/src/features/menu/data/menu_repository.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';
import 'package:spiritual_city/src/features/menu/domain/models/game_save.dart';
import 'package:spiritual_city/src/features/menu/domain/models/app_settings.dart';

void main() {
  // Playtest 2026-10-21: saved far from home, loaded, walked back – a shop
  // worked on before showed ✝️ "?" again.
  testWidgets('buildings keep their visits after saving far away', (tester) async {
    final dir = Directory.systemTemp.createTempSync('save_far');
    Hive.init(dir.path);
    Hive.registerAdapter(GameSaveAdapter());
    Hive.registerAdapter(AppSettingsAdapter());
    final repo = MenuRepository();
    final fresh = GameSave(id: 'f${DateTime.now().millisecondsSinceEpoch}', name: 'f', createdAt: DateTime(2026), difficulty: Difficulty.normal, seed: 7);
    await tester.runAsync(() => repo.writeSave(fresh));

    Future<SpiritWorldGame> load(GameSave s) async {
      final g = SpiritWorldGame(difficulty: s.difficulty, gameSave: s);
      await tester.runAsync(() async {
        g.onGameResize(Vector2(800, 600));
        await g.onLoad();
      });
      return g;
    }

    Future<GameSave> save(SpiritWorldGame g) async {
      final state = g.captureGameState();
      late GameSave out;
      await tester.runAsync(() async {
        final saves = await repo.loadAllSaves();
        await repo.writeSave(saves.firstWhere((x) => x.id == fresh.id).copyWithState(state));
        await Hive.close();
        Hive.init(dir.path);
        out = (await repo.loadAllSaves()).firstWhere((x) => x.id == fresh.id);
      });
      return out;
    }

    void walkTo(SpiritWorldGame g, Vector2 p) {
      g.player.position.setFrom(p);
      g.chunkManager.update(0.016);
    }

    final home = Vector2(7040, 7168);
    final far = Vector2(7040 + 40 * 512, 7168);

    final g1 = await load(fresh);
    walkTo(g1, home);
    final worked = g1.chunkManager.allActiveBuildings
        .map((c) => c.buildingModel)
        .where((b) => b.type != BuildingType.pastorHouse)
        .toList();
    for (final b in worked) {
      b.interactionCount = 7;
      b.faith = 80;
    }
    final shop = worked.first;
    walkTo(g1, far);
    final s1 = await save(g1);

    final g2 = await load(s1);
    expect(g2.chunkManager.getBuildingModel(shop.buildingId), isNull, reason: 'far away');
    final s2 = await save(g2); // saving again far away
    final g3 = await load(s2);
    walkTo(g3, home);
    for (final b in worked) {
      final back = g3.chunkManager.getBuildingModel(b.buildingId);
      expect(back?.interactionCount, 7, reason: '${b.buildingId} ${b.type}');
      expect(back?.faith, 80);
    }
  });
}
