part of '../spirit_world_game.dart';

extension GameBuildingActions on SpiritWorldGame {
  /// Performs [actionType] in the currently open building and returns the
  /// result.  The caller (overlay) is responsible for applying resource
  /// deltas to the game via [gainFaith], [gainMaterials] etc.
  BuildingInteractionResult handleBuildingAction(String actionType) {
    final data = activeBuildingData;
    if (data == null) {
      return const BuildingInteractionResult(reactionEmoji: '❓', success: false);
    }

    // 'missions' is handled at the game layer – open the mission board inline.
    if (actionType == 'missions') {
      openMissionBoard();
      return const BuildingInteractionResult(reactionEmoji: '📋', success: true);
    }

    // Check preconditions and costs *before* the service runs: the service
    // mutates the building, so a refused action must never reach it.
    final action = BuildingActions.find(data.building.type, actionType);
    if (action != null) {
      final availability = action.availability(data.building, this, difficulty);
      if (!availability.isOk) {
        return BuildingInteractionResult(
          reactionEmoji: availability.reason ?? '🚫',
          success: false,
        );
      }
    }

    // Learned abilities are handled here, not in the service (§3.9, M3).
    final special = _learnedAbility(actionType, data.building);
    if (special != null) return special;

    var result = buildingInteractionService.performAction(
      actionType,
      data.building,
      faith,
    );

    // Practice ("Übung", §3.4): the more often the pastor reads, prays and
    // worships, the more faith these actions give him.
    final discipline = action?.discipline;
    if (discipline != null && result.playerFaithDelta > 0) {
      result = result.withFaithDelta(
          (result.playerFaithDelta * progress.practice.multiplier(discipline)).roundToDouble());
    }
    if (discipline != null && result.success) recordPractice(discipline);
    if (result.success) {
      GameSound.playAction(actionType, discipline?.name);
      tutorialService.onBuildingAction(actionType);
    }
    if (result.success) {
      if (discipline == Discipline.prayer) recordLessonTask(LessonTask.pray);
      if (actionType == 'sundayService' || actionType == 'chapelService') {
        recordLessonTask(LessonTask.service);
      }
    }

    // Apply resource deltas immediately
    if (result.playerFaithDelta != 0) gainFaith(result.playerFaithDelta);
    if (result.playerMaterialsDelta > 0) {
      gainMaterials(result.playerMaterialsDelta);
    } else if (result.playerMaterialsDelta < 0) {
      spendMaterials(-result.playerMaterialsDelta);
    }
    if (result.playerHealthDelta > 0) {
      gainHealth(result.playerHealthDelta);
    } else if (result.playerHealthDelta < 0) {
      spendHealth(-result.playerHealthDelta);
    }
    if (result.playerHungerDelta > 0) {
      gainHunger(result.playerHungerDelta);
    } else if (result.playerHungerDelta < 0) {
      spendHunger(-result.playerHungerDelta);
    }
    // Geistliche Erkenntnis (Insight) from building actions.
    if (result.playerInsightDelta > 0) {
      progress.addInsight(result.playerInsightDelta);
    }
    // 'bless' and spiritual actions nudge the cell underneath the player.
    if (actionType == 'bless' || actionType == 'blessPolice' ||
        actionType == 'blessHousehold') {
      _nudgeCellUnderPlayer(0.02);
      missionService.onVisitPrayed();
    }
    // Pastor house prayer: massively brightens spiritual world in the area.
    if (actionType == 'pray' &&
        data.building.type == BuildingType.pastorHouse) {
      _brightenspiritualAreaAroundPosition(
        pastorhousePosition.value ?? player.position,
        radius: 12,
        amount: 0.12,
      );
    }
    // ── AoE influence with duration/decay (Issue #59) ─────────────────────
    // Applies a cell-level spiritual-state change in the visible world around
    // the building.  Each action carries a named delta/radius/duration combo.
    if (result.success) {
      _applyBuildingAoEInfluence(actionType, data.building);
    }
    // ── ActionType mission advancement (Issue #131) ───────────────────────
    // After a successful action, advance any matching active mission on this
    // building.  The MissionService callback handles rewards + new assignment.
    if (result.success) {
      final at = MissionService.buildingActionToType(
        actionType,
        data.building.type,
      );
      if (at != null) {
        missionService.advanceEntityMission(
          at,
          data.building,
          allNpcs:
              chunkManager.allActiveNPCs.map((c) => c.model).toList(),
          allBuildings: chunkManager.allActiveBuildings
              .map((c) => c.buildingModel)
              .toList(),
        );
      }
    }
    // Increment session interaction counter for buildings (mirrors NPC dialog
    // behaviour).  The homebase has an unlimited limit so this counter never
    // triggers an auto-leave there.
    if (result.success) {
      data.building.currentSessionInteractions++;
    }
    // Sleeping in the pastor house ends the day (§3.3).
    if (actionType == 'sleep' && result.success) endDay();
    return result;
  }

  /// Derives origin cell coordinates from the building's surrounding cells
  /// and fires the appropriate [InfluenceService.applyAoE] call.
  ///
  /// Building-type multipliers from [BuildingInfluenceConstants] ensure that
  /// larger/spiritual buildings have a proportionally stronger effect.
  void _applyBuildingAoEInfluence(String actionType, BuildingModel building) {
    // Resolve the building's rough world-cell position from the player's
    // location (best we have without a dedicated building-cell lookup).
    const cellSize = 32.0;
    final gx = (player.position.x / cellSize).floor();
    final gy = (player.position.y / cellSize).floor();

    final multiplier = _buildingMultiplier(building.type);

    switch (actionType) {
      // ── Residential ──────────────────────────────────────────────────────
      case 'practicalHelp':
        influenceService.applyAoE(
          grid: grid,
          originX: gx, originY: gy,
          delta: BuildingInfluenceConstants.deltaPracticalHelp,
          radius: BuildingInfluenceConstants.radiusPracticalHelp,
          durationType: InfluenceDurationType.temporary,
          durationSeconds: BuildingInfluenceConstants.gameHourSeconds,
          buildingMultiplier: multiplier,
        );

      case 'discipleshipGroup':
        influenceService.applyAoE(
          grid: grid,
          originX: gx, originY: gy,
          delta: BuildingInfluenceConstants.deltaDiscipleshipGroup,
          radius: BuildingInfluenceConstants.radiusDiscipleshipGroup,
          durationType: InfluenceDurationType.permanent,
          buildingMultiplier: multiplier,
        );

      // ── Church ────────────────────────────────────────────────────────────
      // Worship: permanent, positive faith boost in the surrounding area.
      case 'worship':
        influenceService.applyAoE(
          grid: grid,
          originX: gx, originY: gy,
          delta: BuildingInfluenceConstants.deltaWorship,
          radius: BuildingInfluenceConstants.radiusWorship,
          durationType: InfluenceDurationType.permanent,
          buildingMultiplier: multiplier,
        );

      // Sunday service: massive decaying AoE over half a game-day.
      case 'sundayService':
        influenceService.applyAoE(
          grid: grid,
          originX: gx, originY: gy,
          delta: BuildingInfluenceConstants.deltaWorship,
          radius: BuildingInfluenceConstants.radiusWorship,
          durationType: InfluenceDurationType.decaying,
          durationSeconds: BuildingInfluenceConstants.gameHalfDaySeconds,
          buildingMultiplier: multiplier,
        );

      // ── Bless actions (shop / police / commercial / household) ────────────
      case 'bless':
      case 'blessPolice':
      case 'blessHousehold':
        influenceService.applyAoE(
          grid: grid,
          originX: gx, originY: gy,
          delta: BuildingInfluenceConstants.deltaBless,
          radius: BuildingInfluenceConstants.radiusBless,
          durationType: InfluenceDurationType.temporary,
          durationSeconds: BuildingInfluenceConstants.gameHourSeconds,
          buildingMultiplier: multiplier,
        );

      // ── School prayer circle ──────────────────────────────────────────────
      case 'prayerCircle':
        influenceService.applyAoE(
          grid: grid,
          originX: gx, originY: gy,
          delta: BuildingInfluenceConstants.deltaPrayerCircle,
          radius: BuildingInfluenceConstants.radiusPrayerCircle,
          durationType: InfluenceDurationType.temporary,
          durationSeconds: BuildingInfluenceConstants.gameDaySeconds,
          buildingMultiplier: multiplier,
        );

      // ── All other actions: small generic nudge ────────────────────────────
      default:
        if (actionType == 'pray' || actionType == 'houseVisit') {
          influenceService.applyAoE(
            grid: grid,
            originX: gx, originY: gy,
            delta: 0.03,
            radius: 2.0,
            durationType: InfluenceDurationType.temporary,
            durationSeconds: BuildingInfluenceConstants.gameHourSeconds,
            buildingMultiplier: multiplier,
          );
        }
    }
  }

  /// Returns the named AoE power multiplier for [type].
  ///
  /// Reads from [BuildingInfluenceConstants] so no magic numbers are used here.
  double _buildingMultiplier(BuildingType type) {
    switch (type) {
      // Issue #144: `church` was grouped with hospital/school/shop below
      // (multiplierMedium, 1.5×) instead of with cathedral (multiplierSpiritual,
      // 5×) – contradicting building_actions.md's own table, which places
      // "Church, Cathedral" together in the "Spiritual" tier.  Church's AoE
      // worship/service influence on the surrounding cells was 3.3× weaker
      // than intended.
      case BuildingType.church:
      case BuildingType.cathedral:
      case BuildingType.pastorHouse:
        return BuildingInfluenceConstants.multiplierSpiritual;
      case BuildingType.stadium:
      case BuildingType.skyscraper:
      case BuildingType.cityHall:
        return BuildingInfluenceConstants.multiplierLarge;
      case BuildingType.hospital:
      case BuildingType.school:
      case BuildingType.university:
      case BuildingType.shop:
      case BuildingType.supermarket:
      case BuildingType.mall:
      case BuildingType.office:
      case BuildingType.policeStation:
        return BuildingInfluenceConstants.multiplierMedium;
      default:
        return BuildingInfluenceConstants.multiplierSmall;
    }
  }

  /// Attempts to access [building] on behalf of the player.
  ///
  /// Returns `true` if access is granted (always true for non-residential).
  bool attemptBuildingAccess(BuildingModel building) {
    // 🙏🏠 Interceded for today: the door opens far more easily.
    if (building.intercededDay == dayStats.day && !building.isAlwaysOpen) {
      final chance = (building.accessChance(faith) + SpiritWorldGame.intercessionAccessBonus).clamp(0.0, 1.0);
      return Random().nextDouble() < chance;
    }
    return buildingInteractionService.attemptAccess(building, faith);
  }

  /// Collects the room's hidden ✨ find (walkable interiors, §3.5): once per
  /// building, a little insight or supplies – deterministic from its id.
  String collectFind(BuildingModel building) {
    if (building.findCollected) return '✨✅';
    building.findCollected = true;
    final insight = stableStringHash('${building.buildingId}#find').isEven;
    if (insight) {
      progress.addInsight(SpiritWorldGame.roomFindInsight);
    } else {
      gainMaterials(SpiritWorldGame.roomFindMaterials);
    }
    GameSound.play(Sfx.learned, volume: 0.5);
    return insight ? '✨ +${SpiritWorldGame.roomFindInsight}📖' : '✨ +${SpiritWorldGame.roomFindMaterials.round()}📦';
  }

  /// 🙏🏠 / ➖🍞 / 📢 – effects of learned abilities.
  BuildingInteractionResult? _learnedAbility(String actionType, BuildingModel building) {
    switch (actionType) {
      case 'intercede':
        if (building.intercededDay == dayStats.day) {
          return const BuildingInteractionResult(reactionEmoji: '🙏🏠✅', success: false);
        }
        spendFaith(BuildingActions.intercessionFaithCost);
        building.intercededDay = dayStats.day;
        building.applyInfluence(5.0);
        recordPractice(Discipline.prayer);
        recordLessonTask(LessonTask.pray);
        building.currentSessionInteractions++;
        return const BuildingInteractionResult(
          reactionEmoji: '🙏🏠✨',
          playerFaithDelta: -BuildingActions.intercessionFaithCost,
        );
      case 'fast':
        if (isFasting) {
          return const BuildingInteractionResult(reactionEmoji: '➖🍞✅', success: false);
        }
        spendHunger(30);
        isFasting = true;
        recordPractice(Discipline.prayer);
        return const BuildingInteractionResult(reactionEmoji: '➖🍞🙏', playerHungerDelta: -30);
      case 'preach':
        if (building.preachedDay == dayStats.day) {
          return const BuildingInteractionResult(reactionEmoji: '📢✅', success: false);
        }
        spendFaith(30);
        building.preachedDay = dayStats.day;
        final reached = _preachAround(player.position);
        recordPractice(Discipline.bible);
        building.currentSessionInteractions++;
        return BuildingInteractionResult(
          reactionEmoji: '📢👥 $reached',
          playerFaithDelta: -30,
        );
    }
    return null;
  }

  /// Preaching (#172): everyone within [preachRadiusCells] hears at once –
  /// broad but flat. Liberated ground amplifies (×0.5 … ×1.5), every
  /// Christian nearby adds 10 %, very hostile people turn away (−5).
  /// Returns how many people were reached.
  int _preachAround(Vector2 at) {
    const cell = CellComponent.cellSize;
    final reach = SpiritWorldGame.preachRadiusCells * cell;
    final rng = Random();
    final near = chunkManager.allActiveNPCs
        .where((c) => c.position.distanceTo(at) <= reach)
        .toList();
    final christians = near.where((c) => c.model.isChristian).length;
    final community = 1.0 + 0.1 * christians;
    for (final c in near) {
      final npc = c.model;
      if (npc.isChristian) continue;
      if (npc.faith < -30) {
        npc.applyInfluence(-5);
        continue;
      }
      final st = grid
              .getCell((c.position.x / cell).floor(), (c.position.y / cell).floor())
              ?.spiritualState ??
          0.0;
      final cellFactor = (1.0 + st * 0.5).clamp(0.5, 1.5);
      final falloff = 1.0 - (c.position.distanceTo(at) / reach) * 0.5;
      npc.applyInfluence(((2 + rng.nextInt(3)) * cellFactor * community * falloff).roundToDouble());
    }
    return near.length;
  }

  /// Applies [delta] spiritual influence to the city cell directly beneath
  /// the player (used by 'prayBusiness').
  ///
  /// Positive [delta] increases the spiritual state towards +1.0 (green zone).
  void _nudgeCellUnderPlayer(double delta) {
    final gx = (player.position.x / 32).floor();
    final gy = (player.position.y / 32).floor();
    final cell = grid.getCell(gx, gy);
    if (cell != null) {
      cell.spiritualState = (cell.spiritualState + delta).clamp(-1.0, 1.0);
    }
  }

  /// Brightens all cells within [radius] grid cells of [centre] by [amount].
  ///
  /// Used for the pastor-house prayer which should have a massive positive
  /// effect on the surrounding area in the invisible world.
  void _brightenspiritualAreaAroundPosition(
    Vector2 centre, {
    required int radius,
    required double amount,
  }) {
    const cellSize = 32.0;
    final gx = (centre.x / cellSize).floor();
    final gy = (centre.y / cellSize).floor();
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        // Fade the effect linearly with distance (strongest at centre).
        final dist = (dx * dx + dy * dy).toDouble();
        final maxDist = (radius * radius).toDouble();
        if (dist > maxDist) continue;
        final fade = 1.0 - (dist / maxDist);
        final cell = grid.getCell(gx + dx, gy + dy);
        if (cell != null) {
          cell.spiritualState =
              (cell.spiritualState + amount * fade).clamp(-1.0, 1.0);
        }
      }
    }
  }
}
