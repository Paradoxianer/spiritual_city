part of '../spirit_world_game.dart';

/// Walkable building interiors – the third layer (playtest 2026-10-18):
/// entering switches the camera into the room, the pastor walks there with
/// the same joystick, furniture stands for the building's actions.
extension GameInterior on SpiritWorldGame {
  /// The building's actions without those that need an unlearned skill.
  List<GameAction<BuildingModel>> _offeredActions(BuildingType type) => [
        for (final a in BuildingActions.forType(type))
          if (a.needsSkill == null || progress.skills.has(a.needsSkill!)) a,
      ];

  /// Steps inside [building] ([activeBuildingData] is already set by
  /// [openBuildingInterior]).
  void enterInterior(BuildingModel building) {
    if (interior != null) return;
    overlays.remove('BuildingInteriorOverlay');
    paused = false;
    closeMenu();

    final offered = _offeredActions(building.type);
    final actions = [
      for (final a in offered) a.type,
      if (building.isHomebase) ...[InteriorLayout.churchOverview, InteriorLayout.upgrades],
    ];
    final layout = InteriorLayout.generate(
      buildingId: building.buildingId,
      type: building.type,
      actions: actions,
      residents: building.residents.length.clamp(0, 4) + 1,
    );
    final lessons = Lessons.offeredAt(building.type, progress.skills,
        awakenings: progress.awakenedQuarters.length);
    final room = InteriorWorld(
      building: building,
      layout: layout,
      stationEmoji: {
        for (final a in offered) a.type: a.emoji,
        InteriorLayout.churchOverview: '⛪👥',
        InteriorLayout.upgrades: '⚔️',
      },
      lesson: lessons.isEmpty ? null : lessons.first,
    );
    interior = room;
    _cityZoom = camera.viewfinder.zoom;
    add(room);
    camera.world = room;
    final vp = camera.viewport.size;
    final fit = min(vp.x / (room.size.x + 32), vp.y / (room.size.y + 32));
    camera.viewfinder.zoom = fit.clamp(0.85, 1.6);
    _interiorButtonEmoji = '';
    _updateHudVisibility();
    interiorActive.value = true;
    currentStreetLabel.value = ''; // the interior bar shows the address
    tutorialService.onEnteredBuilding(isHomebase: building.isHomebase);
  }

  void leaveInterior() {
    final room = interior;
    if (room == null) return;
    interior = null;
    camera.world = world;
    camera.viewfinder.zoom = _cityZoom;
    camera.viewfinder.position = player.position.clone();
    room.removeFromParent();
    interiorActive.value = false;
    _lastStreetCellX = -999999; // street label comes back on the next tick
    overlays.remove('UpgradeOverlay');
    activeBuildingData = null;
    _doorArmed = false;
    if (activeMissionBoardData != null) closeMissionBoard();
    GameSound.play(Sfx.door, volume: 0.4);
    _updateHudVisibility();
    _updateButtonStyles();
  }

  /// Camera follows the pastor but never shows much beyond the walls.
  void _updateInteriorCamera() {
    final room = interior!;
    final z = camera.viewfinder.zoom;
    final vis = camera.viewport.size / z;
    double axis(double p, double v, double len) =>
        len <= v ? len / 2 : p.clamp(v / 2, len - v / 2);
    camera.viewfinder.position = Vector2(
      axis(room.pastor.position.x, vis.x, room.size.x),
      axis(room.pastor.position.y, vis.y, room.size.y),
    );
    // The action button shows what the pastor can do right here.
    final t = room.target;
    final emoji = switch (t) {
      StationTarget() => room.stationEmoji[t.action] ?? '🖐️',
      ResidentTarget() => '💬',
      MentorTarget() => '🎓',
      DoorTarget() => '🚪',
      null => '🖐️',
    };
    if (emoji != _interiorButtonEmoji) {
      _interiorButtonEmoji = emoji;
      actionButton.updateContent(
        emoji,
        t == null ? Colors.blueGrey.withValues(alpha: 0.35) : Colors.amber.withValues(alpha: 0.7),
      );
    }
  }

  /// The action button (E / Space) inside.
  void interiorInteract() {
    final room = interior;
    if (room == null || room.isBusy || room.leaving) return;
    switch (room.target) {
      case StationTarget(:final action):
        _startStation(room, action);
      case ResidentTarget(:final npc):
        final comp = chunkManager.findNpcComponent(npc.id);
        if (comp == null) {
          room.float('💤');
          return;
        }
        _nearestInteractable = comp;
        comp.onInteract();
      case MentorTarget(:final lesson):
        openLesson(lesson);
      case DoorTarget():
        leaveInterior();
      case null:
        break;
    }
  }

  void _startStation(InteriorWorld room, String action) {
    if (action == InteriorLayout.churchOverview) {
      openChurchOverview();
      return;
    }
    if (action == InteriorLayout.upgrades) {
      overlays.add('UpgradeOverlay');
      return;
    }
    final b = room.building;
    final a = BuildingActions.find(b.type, action);
    if (a != null) {
      final av = a.availability(b, this, difficulty);
      if (!av.isOk) {
        GameSound.play(Sfx.denied, volume: 0.4);
        room.float(av.reason ?? '🚫');
        return;
      }
    }
    GameSound.play(Sfx.tap, volume: 0.4);
    if (a == null || a.baseSeconds == 0) {
      _runStation(room, action);
      return;
    }
    // Same scaling as before: easy is faster, hard slower.
    final factor = FaithCalculatorService.difficultyFactorFor(difficulty);
    final secs = (a.baseSeconds / factor).round().clamp(1, 60).toDouble();
    room
      ..busyAction = action
      ..busyEmoji = a.emoji
      ..busyLeft = secs
      ..busyTotal = secs;
  }

  /// The countdown of a timed station action ran out.
  void finishInteriorAction() {
    final room = interior;
    final action = room?.busyAction;
    if (room == null || action == null) return;
    room.busyAction = null;
    _runStation(room, action);
  }

  void _runStation(InteriorWorld room, String action) {
    final result = handleBuildingAction(action);
    room.float(result.reactionEmoji);
    // Session limit reached: the visit ends, the pastor is shown out.
    if (result.success && room.building.isReadyToLeave) {
      room.leaving = true;
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (interior == room) leaveInterior();
      });
    }
  }

  void collectInteriorFind() {
    final room = interior;
    if (room == null) return;
    room.float(collectFind(room.building));
  }
}
