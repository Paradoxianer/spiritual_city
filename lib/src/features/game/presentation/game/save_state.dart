part of '../spirit_world_game.dart';

extension GameSaveState on SpiritWorldGame {
  /// Upgrades a raw [state] map from any previous schema version to the
  /// current [SpiritWorldGame.kSaveDataVersion] schema, returning the upgraded map.
  ///
  /// Migration steps are applied sequentially so a save can be upgraded
  /// across multiple versions in a single load.  Add a new `if` block here
  /// whenever [SpiritWorldGame.kSaveDataVersion] is bumped:
  ///
  /// ```dart
  /// // v1 → v2: example – rename 'faith' to 'playerFaith'
  /// if (version < 2) {
  ///   state['playerFaith'] = state.remove('faith');
  ///   version = 2;
  /// }
  /// ```
  Map<String, dynamic> _migrateGameState(Map<String, dynamic> state) {
    // A missing key means the save pre-dates versioning — treat as v0.
    int version = (state['schemaVersion'] as int?) ?? 0;
    final originalVersion = version;

    // v0 → v1: initial schema (no structural changes needed, just stamp the
    // version so the save is recognised as current on next load).
    if (version < 1) {
      version = 1;
    }

    // ── Add future migration blocks here, in order ─────────────────────────
    // v1 → v2: merge separate 'pray' and 'counsel' NPC counters into 'conv'
    // (unified interactionCount), then remove the now-obsolete keys.
    if (version < 2) {
      final npcs = state['npcs'] as Map?;
      if (npcs != null) {
        for (final npcState in npcs.values) {
          if (npcState is Map) {
            final conv    = (npcState['conv']    as num?)?.toInt() ?? 0;
            final pray    = (npcState['pray']    as num?)?.toInt() ?? 0;
            final counsel = (npcState['counsel'] as num?)?.toInt() ?? 0;
            final merged  = conv + pray + counsel;
            // Only write 'conv' when non-zero; absent key is equivalent to 0
            // (consistent with how the original save code omits zero-value keys).
            if (merged != 0) npcState['conv'] = merged;
            npcState.remove('pray');
            npcState.remove('counsel');
          }
        }
      }
      version = 2;
    }

    // v3 → v4: the city generator's noise was fixed (rivers, parks,
    // industry, slums now appear), so the world under old saves changed.
    // Everything tied to places is dropped and the pastor starts at home
    // again; personal progress (resources, insight, skills, church) stays.
    if (version < 4) {
      state.remove('cells');
      state.remove('npcs');
      state.remove('buildings');
      state.remove('loot');
      state['playerX'] = 7040.0;
      state['playerY'] = 7168.0;
      state['isSpiritualWorld'] = false;
      version = 4;
    }

    if (originalVersion != SpiritWorldGame.kSaveDataVersion) {
      _log.info(
        'Save schema migrated: v$originalVersion → v$SpiritWorldGame.kSaveDataVersion',
      );
    }

    state['schemaVersion'] = SpiritWorldGame.kSaveDataVersion;
    return state;
  }

  /// Applies player-resource fields from a previously serialised [state] map.
  void _applyPlayerState(Map<String, dynamic> state) {
    faith     = (state['faith']     as num?)?.toDouble() ?? faith;
    health    = (state['health']    as num?)?.toDouble() ?? health;
    hunger    = (state['hunger']    as num?)?.toDouble() ?? hunger;
    materials = (state['materials'] as num?)?.toDouble() ?? materials;

    if (state.containsKey('progress')) {
      final progressData = state['progress'];
      if (progressData is Map) {
        progress.loadFromJson(progressData.cast<String, dynamic>());
        missionService.stage = progress.awakenedQuarters.length;
      }
      _checkAndApplyModifiers(); // Sync modifiers with loaded progress
    }

    // Restore tutorial completion flag so the tutorial isn't shown again.
    tutorialService.isTutorialCompleted = state['tutorialCompleted'] == true;
    trackedMission.value = state['trackedMission'] as String?;
  }

  /// Called by [ChunkManager] immediately after a chunk's cells are generated.
  ///
  /// Applies any saved spiritual-state overrides so the world looks exactly as
  /// the player left it.
  void applySavedCellStatesToChunk(CityChunk chunk) {
    final overrides = _savedCellStates;
    if (overrides == null || overrides.isEmpty) return;
    for (final entry in chunk.cells.entries) {
      final localKey = entry.key; // 'lx,ly'
      final parts    = localKey.split(',');
      final wx       = chunk.getWorldX(int.parse(parts[0]));
      final wy       = chunk.getWorldY(int.parse(parts[1]));
      final saved    = overrides['$wx,$wy'];
      if (saved != null) {
        final cell = entry.value;
        cell.spiritualState =
            (saved['s'] as num?)?.toDouble() ?? cell.spiritualState;
        if (saved['r'] == true) cell.hasResiduum = true;
      }
    }
  }

  /// Called by [ChunkManager] for every [NPCModel] after generation.
  ///
  /// Restores faith, conversation counts, conversion status and last known
  /// world-pixel position so NPC relationships and locations are preserved
  /// across sessions.
  void applySavedNPCState(NPCModel npc) {
    final saved = _savedNPCStates?[npc.id];
    if (saved == null) {
      _log.fine('applySavedNPCState: no saved state for ${npc.id} '
          '(faith=${npc.faith.toStringAsFixed(1)}, '
          'isConverted=${npc.isConverted})');
      return;
    }
    npc.faith             = ((saved['faith']   as num?)?.toDouble() ?? npc.faith).clamp(-100.0, 100.0);
    npc.interactionCount  = (saved['conv']    as num?)?.toInt()    ?? npc.interactionCount;
    npc.isConverted       = saved['converted'] as bool? ?? npc.isConverted;
    if (saved['possessed'] is bool) npc.possessed = saved['possessed'] as bool;
    npc.possessionWeakened = saved['possWeak'] as bool? ?? false;
    // NPC backstory (docs/game_design/npc_backstory.md): re-trigger in case
    // the save says converted but the fresh spawn roll didn't (idempotent –
    // a no-op if NPCRegistry already unlocked it for a pre-converted spawn).
    npc.unlockChristPhaseIfConverted();
    if (saved['backstoryProgress'] is Map) {
      npc.restoreBackstoryProgress(
        (saved['backstoryProgress'] as Map).cast<String, dynamic>(),
      );
    }
    final posX = (saved['posX'] as num?)?.toDouble();
    final posY = (saved['posY'] as num?)?.toDouble();
    if (posX != null && posY != null) {
      npc.savedPosition = Vector2(posX, posY);
    }
    // Restore active mission if one was saved.
    if (saved['mission'] is Map) {
      npc.activeMission = MissionModel.fromJson(
        (saved['mission'] as Map).cast<String, dynamic>(),
      );
      // Issue #163: a save written before this fix may still carry a
      // gospel-share mission on an NPC that is (now) already converted –
      // impossible to complete, since NPCComponent short-circuits 'convert'
      // to a no-op for Christians.  Drop it; assignStartMissions() will hand
      // the NPC a fresh, reachable mission.
      if (npc.isConverted &&
          npc.activeMission?.actionType == ActionType.npcGospelShare) {
        _log.info(
          'applySavedNPCState: dropping stale gospel-share mission on '
          'already-converted ${npc.id}',
        );
        npc.activeMission = null;
      }
    }
    _log.fine(
      'applySavedNPCState: restored ${npc.id} '
      '→ faith=${npc.faith.toStringAsFixed(1)}, '
      'conv=${npc.interactionCount}, '
      'isConverted=${npc.isConverted}',
    );
  }

  /// Called by [ChunkManager] for every [BuildingModel] after generation.
  ///
  /// Restores faith and interaction count so that the player's relationship
  /// with each building (access-chance bonus, spiritual state) is preserved
  /// across sessions.  Falls back to defaults when the save predates building
  /// persistence (backward-compatible with old save files).
  void applySavedBuildingState(BuildingModel building) {
    final saved = _savedBuildingStates?[building.buildingId];
    if (saved == null) return;
    building.faith            = (saved['faith'] as num?)?.toDouble() ?? building.faith;
    building.interactionCount = (saved['conv']  as num?)?.toInt()    ?? building.interactionCount;
    building.findCollected    = saved['found'] as bool? ?? false;
    // Restore active mission if one was saved.
    if (saved['mission'] is Map) {
      building.activeMission = MissionModel.fromJson(
        (saved['mission'] as Map).cast<String, dynamic>(),
      );
    }
  }

  /// Serialises the full game state into a [Map] suitable for storing in
  /// [GameSave.gameState].
  ///
  /// Only cells and NPCs whose values differ from generated defaults are
  /// included to keep the save file small.
  Map<String, dynamic> captureGameState() {
    // ── Cell states ──────────────────────────────────────────────────────────
    final Map<String, Map<String, dynamic>> cellStates = {};
    for (final chunk in grid.getLoadedChunks()) {
      for (final entry in chunk.cells.entries) {
        final cell = entry.value;
        if (cell.spiritualState != 0.0 || cell.hasResiduum) {
          final s = <String, dynamic>{'s': cell.spiritualState};
          if (cell.hasResiduum) s['r'] = true;
          cellStates['${cell.x},${cell.y}'] = s;
        }
      }
    }

    // ── NPC states ───────────────────────────────────────────────────────────
    // Iterate over NPCComponent instances so we can capture the current
    // world-pixel position (not just the fixed homePosition on the model).
    final Map<String, Map<String, dynamic>> npcStates = {};
    for (final npcComp in chunkManager.allActiveNPCs) {
      final npc = npcComp.model;
      if (npc.faith != 0.0 ||
          npc.interactionCount != 0 ||
          npc.isConverted) {
        final backstoryProgress = npc.captureBackstoryProgress();
        npcStates[npc.id] = {
          'faith': npc.faith.clamp(-100.0, 100.0),
          if (npc.interactionCount != 0) 'conv': npc.interactionCount,
          if (npc.isConverted)           'converted': true,
          // Possession (#180): stored once decided, so a released person
          // stays free even while still hostile.
          if (npc.faith < NPCModel.possessionFaithThreshold || !npc.possessed)
            'possessed': npc.possessed,
          if (npc.possessionWeakened)    'possWeak': true,
          'posX': npcComp.position.x,
          'posY': npcComp.position.y,
          if (npc.activeMission != null) 'mission': npc.activeMission!.toJson(),
          // NPC backstory (docs/game_design/npc_backstory.md): only the
          // player's processing progress on individual events, sparse –
          // everything else about the backstory is re-derived from the id.
          if (backstoryProgress.isNotEmpty) 'backstoryProgress': backstoryProgress,
        };
      }
    }
    // Preserve states for NPCs in chunks not visited during this session so
    // their faith / interactionCount survive repeated save→load cycles.
    _savedNPCStates?.forEach((id, saved) => npcStates.putIfAbsent(id, () => saved));
    final convertedCount = npcStates.values.where((s) => s['converted'] == true).length;
    _log.info(
      'captureGameState: saving ${npcStates.length} NPC states '
      '($convertedCount Christians)',
    );

    // ── Building states ──────────────────────────────────────────────────────
    final Map<String, Map<String, dynamic>> buildingStates = {};
    for (final comp in chunkManager.allActiveBuildings) {
      final building = comp.buildingModel;
      if (building.faith != 0.0 || building.interactionCount != 0 ||
          building.activeMission != null || building.findCollected) {
        buildingStates[building.buildingId] = {
          if (building.faith != 0.0)            'faith': building.faith,
          if (building.interactionCount != 0)   'conv':  building.interactionCount,
          if (building.activeMission != null)   'mission': building.activeMission!.toJson(),
          if (building.findCollected)           'found': true,
        };
      }
    }
    // Preserve states for buildings in chunks not visited during this session.
    _savedBuildingStates?.forEach(
      (id, saved) => buildingStates.putIfAbsent(id, () => saved),
    );

    return {
      'schemaVersion':      SpiritWorldGame.kSaveDataVersion,
      'worldSeed':          seedManager.seed,
      'faith':              faith,
      'health':             health,
      'hunger':             hunger,
      'materials':          materials,
      'playerX':            player.position.x,
      'playerY':            player.position.y,
      'isSpiritualWorld':   isSpiritualWorld,
      'tutorialCompleted':  tutorialService.isTutorialCompleted,
      'trackedMission':     trackedMission.value,
      'progress':           progress.toJson(),
      'cells':              cellStates,
      'npcs':               npcStates,
      'buildings':          buildingStates,
      'loot':               lootSystem.captureState(),
    };
  }
}
