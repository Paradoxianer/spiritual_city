import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/prayer_combat.dart';
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
    // 🌱 A disciple keeps their gift too.
    final disciple = g1.chunkManager.allNPCModels.first..isConverted = true;
    disciple.discipleProfile.getFor(PrayerMode.rebuke).strengthLevel = 2;
    walkTo(g1, far);
    final s1 = await save(g1);

    final g2 = await load(s1);
    expect(g2.chunkManager.getBuildingModel(shop.buildingId), isNull, reason: 'far away');
    final s2 = await save(g2); // saving again far away
    final g3 = await load(s2);
    walkTo(g3, home);
    final d = g3.chunkManager.allNPCModels.firstWhere((n) => n.id == disciple.id);
    expect(d.discipleProfile.getFor(PrayerMode.rebuke).strengthLevel, 2);
    expect(d.isDisciple, isTrue);
    for (final b in worked) {
      final back = g3.chunkManager.getBuildingModel(b.buildingId);
      expect(back?.interactionCount, 7, reason: '${b.buildingId} ${b.type}');
      expect(back?.faith, 80);
    }
  });

  // #194: a part of the city keeps living while the pastor is away – when
  // it is generated again, it catches up on the missed days (max 30).
  testWidgets('returning to a district catches up on the missed days', (tester) async {
    final dir = Directory.systemTemp.createTempSync('save_catchup');
    Hive.init(dir.path);
    final repo = MenuRepository();
    final fresh = GameSave(id: 'c${DateTime.now().millisecondsSinceEpoch}', name: 'c', createdAt: DateTime(2026), difficulty: Difficulty.normal, seed: 7);
    await tester.runAsync(() => repo.writeSave(fresh));

    final g1 = SpiritWorldGame(difficulty: fresh.difficulty, gameSave: fresh);
    await tester.runAsync(() async {
      g1.onGameResize(Vector2(800, 600));
      await g1.onLoad();
    });
    final home = Vector2(7040, 7168);
    g1.player.position.setFrom(home);
    g1.chunkManager.update(0.016);
    const side = 16 * 32;
    final chunk = g1.grid.getLoadedChunk((home.x / side).floor(), (home.y / side).floor())!;
    for (final c in chunk.cells.values) {
      c.spiritualState = -0.9;
    }
    g1.player.position.setFrom(Vector2(home.x + 40 * 512, home.y));
    g1.chunkManager.update(0.016);
    final state = g1.captureGameState();
    expect((state['chunkDays'] as Map)[chunk.id], 0);
    late GameSave s1;
    await tester.runAsync(() async {
      final saves = await repo.loadAllSaves();
      await repo.writeSave(saves.firstWhere((x) => x.id == fresh.id).copyWithState({...state, 'worldDay': 20}));
      s1 = (await repo.loadAllSaves()).firstWhere((x) => x.id == fresh.id);
    });

    final g2 = SpiritWorldGame(difficulty: s1.difficulty, gameSave: s1);
    await tester.runAsync(() async {
      g2.onGameResize(Vector2(800, 600));
      await g2.onLoad();
    });
    expect(g2.worldDay, 20);
    expect(g2.grid.getLoadedChunk(chunk.chunkX, chunk.chunkY), isNull, reason: 'far away');
    g2.player.position.setFrom(home);
    g2.chunkManager.update(0.016);
    final back = g2.grid.getLoadedChunk(chunk.chunkX, chunk.chunkY)!;
    final changed = back.cells.values.where((c) => (c.spiritualState + 0.9).abs() > 1e-6).length;
    expect(changed, greaterThan(0), reason: '20 days of world simulation happened');
    expect((g2.captureGameState()['chunkDays'] as Map)[chunk.id], 20);
  });
}
