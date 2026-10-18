part of '../spirit_world_game.dart';

extension GameOverlayControl on SpiritWorldGame {
  void showDialog(String name, String emoji, NPCModel model) {
    activeDialog = GameDialogData(npcName: name, npcEmoji: emoji, npcModel: model);
    overlays.add('DialogOverlay');
    paused = true;
    tutorialService.onNpcDialogOpened();
  }

  /// Opens the look overlay, describing nearby cells around the player.
  void openLookOverlay() {
    const cellSize = 32.0;
    final px = (player.position.x / cellSize).floor();
    final py = (player.position.y / cellSize).floor();

    // Player's own spiritual state
    final selfCell = grid.getCell(px, py);
    final selfState = selfCell?.spiritualState ?? 0.0;

    final infos = <LookCellInfo>[];
    final seen = <String>{};

    for (final d in const [
      [0, -1], [1, 0], [0, 1], [-1, 0],
      [-1, -1], [1, -1], [1, 1], [-1, 1],
    ]) {
      final cell = grid.getCell(px + d[0], py + d[1]);
      if (cell == null) continue;
      final data = cell.data;

      String? label;
      String? npcName;
      String? streetName;

      if (data is BuildingData) {
        final name = BuildingComponent.buildingEmoji(data.type);
        final num  = data.houseNumber != null ? ' ${data.houseNumber}' : '';
        label = '$name$num';
        // Try to find a named road adjacent to this building cell.
        for (final rd in const [
          [0, -1], [1, 0], [0, 1], [-1, 0],
        ]) {
          final roadCell =
              grid.getCell(px + d[0] + rd[0], py + d[1] + rd[1]);
          if (roadCell?.data is RoadData) {
            final rdata = roadCell!.data as RoadData;
            if (rdata.streetName != null) {
              streetName = rdata.streetName;
              break;
            }
          }
        }
      } else if (data is RoadData) {
        if (data.streetName != null) {
          label = data.streetName!;
          streetName = data.streetName;
        }
      }

      if (label == null || !seen.add(label)) continue;

      // Find an NPC in this cell
      for (final npc in chunkManager.allActiveNPCs) {
        final nx = (npc.interactionPosition.x / cellSize).floor();
        final ny = (npc.interactionPosition.y / cellSize).floor();
        if (nx == px + d[0] && ny == py + d[1]) {
          npcName = npc.interactionLabel.split(' ').first;
          break;
        }
      }

      infos.add(LookCellInfo(
        label: label,
        spiritualState: cell.spiritualState,
        npcName: npcName,
        streetName: streetName,
      ));
    }

    activeLookData = GameLookData(cells: infos, playerSpiritualState: selfState);
    overlays.add('LookOverlay');
    // Auto-close after 4 seconds – only if the overlay is still active.
    Future.delayed(const Duration(seconds: 4), () {
      if (activeLookData != null) closeLookOverlay();
    });
  }

  void closeLookOverlay() {
    activeLookData = null;
    overlays.remove('LookOverlay');
  }

  /// Opens the mission board showing all active missions with addresses.
  void openMissionBoard() {
    final entries = <MissionEntry>[];
    for (final npcComp in chunkManager.allActiveNPCs) {
      final npc = npcComp.model;
      if (npc.activeMission == null) continue;
      final m = npc.activeMission!;
      entries.add(MissionEntry(
        targetEmoji: npcComp.interactionEmoji,
        targetName: npc.name,
        description: m.description,
        actionEmoji: m.actionEmoji,
        faithReward: m.rewardFaith.round(),
        materialsReward: m.rewardMaterials.round(),
        insightReward: m.insightReward,
        progress: m.progress,
        targetCount: m.targetCount,
        address: _addressForPixelPos(npcComp.position),
      ));
    }
    for (final bldComp in chunkManager.allActiveBuildings) {
      final bld = bldComp.buildingModel;
      if (bld.activeMission == null) continue;
      final m = bld.activeMission!;
      entries.add(MissionEntry(
        targetEmoji: BuildingComponent.buildingEmoji(bld.type),
        // Buildings are named by their address (a proper name), not by a
        // translated type name.
        targetName: '',
        description: m.description,
        actionEmoji: m.actionEmoji,
        faithReward: m.rewardFaith.round(),
        materialsReward: m.rewardMaterials.round(),
        insightReward: m.insightReward,
        progress: m.progress,
        targetCount: m.targetCount,
        address: _addressForPixelPos(bldComp.position),
      ));
    }
    activeMissionBoardData = MissionBoardData(entries: entries);
    overlays.add('MissionBoardOverlay');
  }

  /// Returns a formatted address string (e.g. "Lindenallee 14") for the cell
  /// at the given pixel position.  Returns null if no relevant data is found.
  String? _addressForPixelPos(Vector2 pixelPos) {
    const cellSize = 32.0;
    final gx = (pixelPos.x / cellSize).floor();
    final gy = (pixelPos.y / cellSize).floor();

    int? houseNumber;
    String? streetName;

    // Check the cell itself and its 4 cardinal neighbours for building/road data.
    for (final offset in const [
      [0, 0], [-1, 0], [1, 0], [0, -1], [0, 1],
    ]) {
      final c = grid.getCell(gx + offset[0], gy + offset[1]);
      if (c == null) continue;
      if (c.data is BuildingData && houseNumber == null) {
        houseNumber = (c.data as BuildingData).houseNumber;
      }
      if (c.data is RoadData && streetName == null) {
        final rn = (c.data as RoadData).streetName;
        if (rn != null) streetName = rn;
      }
      if (houseNumber != null && streetName != null) break;
    }

    if (streetName != null && houseNumber != null) return '$streetName $houseNumber';
    if (streetName != null) return streetName;
    if (houseNumber != null) return 'Nr. $houseNumber';
    return null;
  }

  void closeMissionBoard() {
    activeMissionBoardData = null;
    overlays.remove('MissionBoardOverlay');
  }

  void toggleMissionBoard() {
    if (activeMissionBoardData != null) {
      closeMissionBoard();
    } else {
      openMissionBoard();
    }
  }

  String handleInteraction(String type) {
    if (_nearestInteractable == null) return '❓';
    final result = _nearestInteractable!.handleInteraction(type);

    // ── ActionType mission advancement for NPC interactions (Issue #131) ──
    final at = MissionService.npcActionToType(type);
    if (at != null && _nearestInteractable is NPCComponent) {
      final npc = (_nearestInteractable as NPCComponent).model;
      missionService.advanceEntityMission(
        at,
        npc,
        allNpcs: chunkManager.allActiveNPCs.map((c) => c.model).toList(),
        allBuildings:
            chunkManager.allActiveBuildings.map((c) => c.buildingModel).toList(),
      );
    }

    return result;
  }

  void closeDialog() {
    activeDialog = null;
    overlays.remove('DialogOverlay');
    paused = false;
  }

  /// Opens the building-interior overlay for [building].
  /// Always-open buildings are entered straight away (walkable room); homes
  /// show the door to knock first.
  void openBuildingInterior(BuildingModel building) {
    if (interior != null) return;
    building.resetSession();
    GameSound.play(Sfx.door, volume: 0.5);
    activeBuildingData = GameBuildingData(
      building: building,
      address: _addressForPixelPos(player.position),
    );
    tutorialService.onBuildingInteracted();
    if (building.isAlwaysOpen) {
      enterInterior(building);
      return;
    }
    overlays.add('BuildingInteriorOverlay');
    paused = true;
  }

  /// Leaves the building (inside) or closes its door overlay.
  void closeBuildingInterior() {
    if (interior != null) {
      leaveInterior();
      return;
    }
    activeBuildingData = null;
    overlays.remove('BuildingInteriorOverlay');
    // Also close the mission board if it was opened from inside the building.
    if (activeMissionBoardData != null) closeMissionBoard();
    paused = false;
  }

  void openKeymapOverlay() {
    if (_keymapOpen) return;
    _keymapOpen = true;
    overlays.add('KeymapOverlay');
  }

  void closeKeymapOverlay() {
    if (!_keymapOpen) return;
    _keymapOpen = false;
    overlays.remove('KeymapOverlay');
  }

  void toggleKeymapOverlay() {
    if (_keymapOpen) {
      closeKeymapOverlay();
    } else {
      openKeymapOverlay();
    }
  }

  void openPauseMenu() {
    if (_pauseMenuOpen) return;
    _pauseMenuOpen = true;
    overlays.add('PauseMenuOverlay');
    pauseEngine();
  }

  void closePauseMenu() {
    if (!_pauseMenuOpen) return;
    _pauseMenuOpen = false;
    overlays.remove('PauseMenuOverlay');
    resumeEngine();
  }

  /// Closes whichever overlay or menu is currently open, in priority order.
  /// If nothing was open, opens the pause menu instead (so Escape / the
  /// Android back gesture always has somewhere safe to go – see #162).
  ///
  /// Returns `true` if it closed something or opened the pause menu (i.e. the
  /// caller should treat the back/escape action as handled), `false` only in
  /// the case that nothing exists to act on yet (world not loaded).
  bool handleEscape() {
    if (_pauseMenuOpen)              { closePauseMenu();         return true; }
    if (_keymapOpen)                 { closeKeymapOverlay();     return true; }
    if (overlays.isActive('CityMapOverlay')) { closeCityMap();   return true; }
    if (activeLessonOffer != null)   { closeLesson();            return true; }
    if (overlays.isActive('ChurchOverlay')) { closeChurchOverview(); return true; }
    if (overlays.isActive('UpgradeOverlay')) { overlays.remove('UpgradeOverlay'); return true; }
    if (activeDialog != null)        { closeDialog();            return true; }
    if (activeBuildingData != null)  { closeBuildingInterior();  return true; }
    if (activeLookData != null)      { closeLookOverlay();       return true; }
    if (activeMissionBoardData != null) { closeMissionBoard();   return true; }
    if (_currentMenu != null)        { closeMenu();              return true; }
    if (!isWorldReady.value) return false;
    openPauseMenu();
    return true;
  }

  /// Selects the radial-menu action at [zeroBasedIndex] via keyboard (1–6).
  void selectRadialMenuAction(int zeroBasedIndex) {
    _currentMenu?.selectByIndex(zeroBasedIndex);
    _currentMenu = null; // selectByIndex removes the component already
  }

  /// Triggers the chat-dialog action at [zeroBasedIndex] via keyboard (1–6).
  /// The [DialogOverlay] listens to [dialogActionIndex] and dispatches the
  /// interaction that corresponds to the visible chip at that position.
  void selectDialogAction(int zeroBasedIndex) {
    _dialogActionIndex.value = zeroBasedIndex;
    // Reset on the next microtask so the same index can fire multiple times.
    Future.microtask(() => _dialogActionIndex.value = -1);
  }

  /// Triggers the building-interior action at [zeroBasedIndex] via keyboard.
  /// The [BuildingInteriorOverlay] listens to [buildingActionIndex] and
  /// dispatches the action row at that position.
  void selectBuildingAction(int zeroBasedIndex) {
    _buildingActionIndex.value = zeroBasedIndex;
    Future.microtask(() => _buildingActionIndex.value = -1);
  }
}
