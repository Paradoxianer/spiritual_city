import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../../core/utils/seed_manager.dart';
import '../../../features/menu/domain/models/difficulty.dart';
import '../../../features/menu/domain/models/game_save.dart';
import '../domain/city_generator.dart';
import '../domain/models/building_model.dart';
import '../domain/models/city_chunk.dart';
import '../domain/models/city_grid.dart';
import '../domain/models/interactions.dart';
import '../domain/models/modifier_manager.dart';
import '../domain/models/npc_model.dart';
import '../domain/models/player_progress.dart';
import '../domain/services/building_interaction_service.dart';
import '../domain/services/mission_service.dart';
import '../domain/models/cell_object.dart';
import 'components/building_component.dart';
import 'components/chunk_manager.dart';
import 'components/loot_system.dart';
import 'components/npc_component.dart';
import 'components/player_component.dart';
import 'components/radial_menu.dart';
import 'components/prayer_hud_component.dart';
import 'components/spiritual_dynamics_system.dart';
import 'game_screen.dart';

/// Whether keyboard shortcut hint badges should be shown on HUD buttons.
/// True on desktop (Windows / Linux / macOS) and web; false on mobile.
bool _shouldShowKeyHints() {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

class SpiritWorldGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection, TapCallbacks {
  final _log = Logger('SpiritWorldGame');

  // ── Save-data schema versioning ───────────────────────────────────────────
  /// Increment this constant whenever the structure of [captureGameState]
  /// changes in a way that is incompatible with older saved data.
  ///
  /// Migration logic lives in [_migrateGameState]:
  ///   • version 0 (missing key) → version 1: initial schema.
  ///   • version 1 → version 2: NPC counters unified into interactionCount
  ///     ('conv' key); separate 'pray' and 'counsel' keys removed.
  static const int kSaveDataVersion = 2;

  /// Difficulty level selected in the main menu.
  final Difficulty difficulty;

  /// The [GameSave] associated with this session.  Non-null for both new and
  /// loaded games once [onLoad] has run.  Used to persist cell / NPC state
  /// back to Hive when the player saves and quits.
  GameSave? gameSave;

  SpiritWorldGame({this.difficulty = Difficulty.normal, this.gameSave});
  
  late final CityGrid grid;
  late final SeedManager seedManager;
  late final CityGenerator generator;
  late final PlayerComponent player;
  late final JoystickComponent joystick;
  late final ChunkManager chunkManager;
  late final SpiritualDynamicsSystem spiritualDynamics;
  late final HudButton actionButton;
  late final HudButton worldToggleButton;
  late final PrayerHudComponent prayerHud;
  late final LootSystem lootSystem;

  /// Mission system – wired to all interaction hooks.
  final MissionService missionService = MissionService();

  /// World-pixel position of the pastor house once its chunk is first loaded.
  /// `null` until the first chunk containing the pastor house is generated.
  final ValueNotifier<Vector2?> pastorhousePosition = ValueNotifier(null);

  /// Current street / address label displayed top-center.
  /// Updated in [update()] every ~0.5 s when the player moves cells.
  final ValueNotifier<String> currentStreetLabel = ValueNotifier('');

  /// Short pickup-toast message shown when the player collects a material
  /// package on the street (e.g. "📦 +10 MP").  Set to null after the toast
  /// has been dismissed.
  final ValueNotifier<String?> lootPickupMessage = ValueNotifier(null);

  /// Player position in world pixels – updated every frame so Flutter HUD
  /// widgets (compass, street label) can react to movement.
  final ValueNotifier<Vector2> playerWorldPosition = ValueNotifier(Vector2.zero());

  int _lastStreetCellX = -999999;
  int _lastStreetCellY = -999999;
  RadialMenu? _currentMenu;
  bool isSpiritualWorld = false;
  final ValueNotifier<bool> isWorldReady = ValueNotifier<bool>(false);

  // Progress & Modifiers
  late final PlayerProgress progress;
  late final ModifierManager modifiers;

  // Ressourcen – backed by ValueNotifier so that Flutter overlay widgets (e.g.
  // the resource HUD) can react to changes even while the Flame game loop is
  // paused (e.g. while a building or dialog overlay is open).
  final ValueNotifier<double> faithNotifier     = ValueNotifier(100.0);
  final ValueNotifier<double> healthNotifier    = ValueNotifier(100.0);
  final ValueNotifier<double> hungerNotifier    = ValueNotifier(80.0);
  final ValueNotifier<double> materialsNotifier = ValueNotifier(40.0);

  double get faith     => faithNotifier.value;
  set faith(double v)  => faithNotifier.value = v;

  double get health    => healthNotifier.value;
  set health(double v) => healthNotifier.value = v;

  double get hunger    => hungerNotifier.value;
  set hunger(double v) => hungerNotifier.value = v;

  double get materials    => materialsNotifier.value;
  set materials(double v) => materialsNotifier.value = v;

  static const double maxFaith = 100.0;
  static const double maxHealth = 100.0;
  static const double maxHunger = 100.0;
  static const double maxMaterials = 100.0;
  static const double worldToggleCost = 10.0;

  /// Number of daemons spawned around the player on spiritual-world entry.
  /// Reduced so new players aren't overwhelmed immediately.
  static const int _entryDaemonsEasy   = 2;
  static const int _entryDaemonsNormal = 3;
  static const int _entryDaemonsHard   = 5;

  // Passive resource timers
  double _hungerDrainTimer = 0.0;
  static const double hungerDrainInterval = 30.0; // drain 1 hunger every 30 seconds
  static const double hungerDrainAmount = 1.0;
  static const double healthFromHungerThreshold = 20.0;

  /// Fired when the player presses digit 1–6 while a chat dialog is open.
  /// Value is the 0-based index of the action to trigger; -1 = idle.
  final ValueNotifier<int> _dialogActionIndex = ValueNotifier(-1);
  ValueListenable<int> get dialogActionIndex => _dialogActionIndex;

  /// Fired when the player presses digit 1–6 while a building interior is open.
  /// Value is the 0-based index of the action to trigger; -1 = idle.
  final ValueNotifier<int> _buildingActionIndex = ValueNotifier(-1);
  ValueListenable<int> get buildingActionIndex => _buildingActionIndex;

  Interactable? _nearestInteractable;
  Interactable? get nearestInteractable => _nearestInteractable;
  static const double interactionRange = 60.0;
  
  GameDialogData? activeDialog;

  /// Active building interior session (null when no building is open).
  GameBuildingData? activeBuildingData;

  /// Data for the look overlay (cell neighbourhood info).
  GameLookData? activeLookData;

  /// Building interaction logic (shared instance).
  final BuildingInteractionService buildingInteractionService =
      BuildingInteractionService();

  // ── Save / restore state ──────────────────────────────────────────────────

  /// Saved cell spiritual-state overrides loaded from Hive.
  /// Key: 'worldX,worldY'  Value: {s: double, r: bool}
  Map<String, Map<String, dynamic>>? _savedCellStates;

  /// Saved NPC-property overrides loaded from Hive.
  /// Key: npc.id  Value: {faith, conv, pray, counsel, converted}
  Map<String, Map<String, dynamic>>? _savedNPCStates;

  /// Saved building-property overrides loaded from Hive.
  /// Key: building.buildingId  Value: {faith, conv}
  Map<String, Map<String, dynamic>>? _savedBuildingStates;

  @override
  Color backgroundColor() => isSpiritualWorld ? const Color(0xFF000511) : const Color(0xFF111111);

  @override
  Future<void> onLoad() async {
    _log.info('--- INITIALIZING GAME ---');
    seedManager = SeedManager(42);
    generator = CityGenerator(seedManager);
    grid = CityGrid();

    // Progress & modifiers
    progress = PlayerProgress();
    modifiers = ModifierManager(progress: progress);

    // ── Restore save state ──────────────────────────────────────────────────
    final rawState = gameSave?.gameState;
    // Run migration so the rest of onLoad always sees the current schema.
    final savedState = rawState != null && rawState.isNotEmpty
        ? _migrateGameState(Map<String, dynamic>.from(rawState))
        : null;
    final hasSavedState = savedState != null && savedState.isNotEmpty;
    if (hasSavedState) {
      _applyPlayerState(savedState!);
      _savedCellStates     = _parseSavedCellStates(savedState);
      _savedNPCStates      = _parseSavedNPCStates(savedState);
      _savedBuildingStates = _parseSavedBuildingStates(savedState);
    }

    player = PlayerComponent(joystick: _createJoystick());
    // Spawn on the boulevard at grid cell (220, 224) = pixel (7040, 7168).
    // y=224 is always a boulevard road (224 % 32 == 0) so the cell is
    // guaranteed walkable regardless of lot generation.  The pastor house is
    // at (220, 222) — just 2 cells north — see SpecialBuildingRegistry.
    // (Previously (7000, 7000) = cell (218, 218) which ended up inside the
    // pastor-house lot block after the lot-wide special-building scan was
    // introduced, making the player spawn inside a solid building.)
    player.position = hasSavedState
        ? Vector2(
            (savedState!['playerX'] as num).toDouble(),
            (savedState['playerY'] as num).toDouble(),
          )
        : Vector2(7040, 7168);
    await world.add(player);

    chunkManager = ChunkManager(grid: grid, generator: generator, target: player);
    await world.add(chunkManager);

    spiritualDynamics = SpiritualDynamicsSystem();
    await world.add(spiritualDynamics);

    // Wire modifier values to the dynamics system
    spiritualDynamics.modifierSpreadMultiplier = modifiers.greenSpreadMultiplier;
    spiritualDynamics.modifierDecayReduction = modifiers.decayReduction;

    await camera.viewport.add(joystick);
    await _addHudButtons();
    
    prayerHud = PrayerHudComponent();
    await camera.viewport.add(prayerHud);

    lootSystem = LootSystem(seed: seedManager.seed);
    await world.add(lootSystem);

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = player.position.clone();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (hasSavedState && savedState!['isSpiritualWorld'] == true) {
      isSpiritualWorld = true;
      _updateButtonStyles();
    }
    isWorldReady.value = true;
    _log.info(
      '--- GAME READY --- '
      'pastorhousePos=${pastorhousePosition.value} '
      'playerPos=${player.position}',
    );

    // Assign starting missions to NPCs / buildings in the spawn chunk.
    // Run after a short delay so chunk NPCs/buildings are all registered.
    Future.delayed(const Duration(milliseconds: 500), _tryAssignStartMissions);
  }



  /// Upgrades a raw [state] map from any previous schema version to the
  /// current [kSaveDataVersion] schema, returning the upgraded map.
  ///
  /// Migration steps are applied sequentially so a save can be upgraded
  /// across multiple versions in a single load.  Add a new `if` block here
  /// whenever [kSaveDataVersion] is bumped:
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
            final conv    = (npcState['conv']    as int?) ?? 0;
            final pray    = (npcState['pray']    as int?) ?? 0;
            final counsel = (npcState['counsel'] as int?) ?? 0;
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

    if (originalVersion != kSaveDataVersion) {
      _log.info(
        'Save schema migrated: v$originalVersion → v$kSaveDataVersion',
      );
    }

    state['schemaVersion'] = kSaveDataVersion;
    return state;
  }

  /// Applies player-resource fields from a previously serialised [state] map.
  void _applyPlayerState(Map<String, dynamic> state) {
    faith     = (state['faith']     as num?)?.toDouble() ?? faith;
    health    = (state['health']    as num?)?.toDouble() ?? health;
    hunger    = (state['hunger']    as num?)?.toDouble() ?? hunger;
    materials = (state['materials'] as num?)?.toDouble() ?? materials;
  }

  /// Parses the `cells` sub-map from a serialised save into a flat lookup.
  Map<String, Map<String, dynamic>> _parseSavedCellStates(
      Map<String, dynamic> state) {
    final raw = state['cells'] as Map?;
    if (raw == null) return {};
    return {
      for (final e in raw.entries)
        e.key as String: (e.value as Map).cast<String, dynamic>(),
    };
  }

  /// Parses the `npcs` sub-map from a serialised save into a flat lookup.
  Map<String, Map<String, dynamic>> _parseSavedNPCStates(
      Map<String, dynamic> state) {
    final raw = state['npcs'] as Map?;
    if (raw == null) return {};
    return {
      for (final e in raw.entries)
        e.key as String: (e.value as Map).cast<String, dynamic>(),
    };
  }

  /// Parses the `buildings` sub-map from a serialised save into a flat lookup.
  Map<String, Map<String, dynamic>> _parseSavedBuildingStates(
      Map<String, dynamic> state) {
    final raw = state['buildings'] as Map?;
    if (raw == null) return {};
    return {
      for (final e in raw.entries)
        e.key as String: (e.value as Map).cast<String, dynamic>(),
    };
  }

  // ── ChunkManager callbacks (called when a chunk / NPC is first generated) ─

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
    if (saved == null) return;
    npc.faith             = (saved['faith']   as num?)?.toDouble() ?? npc.faith;
    npc.interactionCount  = saved['conv']     as int?  ?? npc.interactionCount;
    npc.isConverted       = saved['converted'] as bool? ?? npc.isConverted;
    final posX = (saved['posX'] as num?)?.toDouble();
    final posY = (saved['posY'] as num?)?.toDouble();
    if (posX != null && posY != null) {
      npc.savedPosition = Vector2(posX, posY);
    }
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
    building.interactionCount = saved['conv']   as int?              ?? building.interactionCount;
  }

  // ── State capture (called when the player saves and quits) ────────────────

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
        npcStates[npc.id] = {
          'faith': npc.faith,
          if (npc.interactionCount != 0) 'conv': npc.interactionCount,
          if (npc.isConverted)           'converted': true,
          'posX': npcComp.position.x,
          'posY': npcComp.position.y,
        };
      }
    }

    // ── Building states ──────────────────────────────────────────────────────
    final Map<String, Map<String, dynamic>> buildingStates = {};
    for (final comp in chunkManager.allActiveBuildings) {
      final building = comp.buildingModel;
      if (building.faith != 0.0 || building.interactionCount != 0) {
        buildingStates[building.buildingId] = {
          if (building.faith != 0.0)            'faith': building.faith,
          if (building.interactionCount != 0)   'conv':  building.interactionCount,
        };
      }
    }

    return {
      'schemaVersion':    kSaveDataVersion,
      'faith':            faith,
      'health':           health,
      'hunger':           hunger,
      'materials':        materials,
      'playerX':          player.position.x,
      'playerY':          player.position.y,
      'isSpiritualWorld': isSpiritualWorld,
      'cells':            cellStates,
      'npcs':             npcStates,
      'buildings':        buildingStates,
    };
  }

  void toggleWorld() {
    if (!isSpiritualWorld && faith < worldToggleCost) {
      _log.warning('Not enough faith to enter spiritual world');
      return;
    }
    
    if (!isSpiritualWorld) {
      faith -= worldToggleCost;
    }
    
    isSpiritualWorld = !isSpiritualWorld;
    _updateButtonStyles();
    _log.info('Switched World: $isSpiritualWorld');

    // Immediately spawn daemons around the player when entering the spiritual
    // world so they are visible from the first moment (difficulty-scaled count).
    if (isSpiritualWorld) {
      final entryCount = switch (difficulty) {
        Difficulty.easy   => _entryDaemonsEasy,
        Difficulty.normal => _entryDaemonsNormal,
        Difficulty.hard   => _entryDaemonsHard,
      };
      spiritualDynamics.spawnDaemonsAroundPlayer(entryCount);
    }
  }

  void handleActionDown() {
    if (isSpiritualWorld) {
      player.startChargingIntensity();
    }
  }

  void handleActionUp() {
    if (isSpiritualWorld) {
      player.releasePrayer();
    } else {
      if (activeDialog != null) { closeDialog(); return; }
      if (_currentMenu != null) { closeMenu(); return; }
      _openRadialMenu();
    }
  }

  void _updateButtonStyles() {
    actionButton.updateContent(
      isSpiritualWorld ? '✝️' : '🖐️',
      isSpiritualWorld ? Colors.amber.withValues(alpha: 0.7) : Colors.blue.withValues(alpha: 0.6)
    );
    worldToggleButton.updateContent(
      isSpiritualWorld ? '🏙️' : '🙏',
      isSpiritualWorld ? Colors.grey.withValues(alpha: 0.7) : Colors.purple.withValues(alpha: 0.6)
    );
  }

  void _openRadialMenu() {
    final actions = <RadialAction>[
      RadialAction(label: '👀', icon: Icons.search, onSelect: openLookOverlay),
    ];

    // Collect all interactables within range, sorted by distance (closest first)
    final Iterable<Interactable> all = [
      ...chunkManager.allActiveBuildings,
      ...chunkManager.allActiveNPCs,
    ];
    final nearby = all
        .map((i) => (i, player.position.distanceTo(i.interactionPosition)))
        .where((e) => e.$2 < interactionRange)
        .toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));

    // Track which building IDs are already offered (for deduplication).
    final offeredBuildingIds = <String>{};
    for (final (i, _) in nearby) {
      if (i is BuildingComponent) offeredBuildingIds.add(i.buildingModel.buildingId);
    }

    // Up to 3 enter/interact actions (NPCs + buildings)
    for (final (target, _) in nearby.take(3)) {
      // Mission action – shown before the normal enter action when the target
      // has an active mission so the player can complete it directly.
      if (target is NPCComponent &&
          target.model.activeMissionDescription != null) {
        final desc = target.model.activeMissionDescription!;
        actions.add(RadialAction(
          label: '📋',
          sublabel: desc.split(' ').first,
          icon: Icons.task_alt,
          onSelect: () => _completeMissionForNpc(target.model),
        ));
      } else if (target is BuildingComponent &&
          target.buildingModel.activeMissionDescription != null) {
        final desc = target.buildingModel.activeMissionDescription!;
        actions.add(RadialAction(
          label: '📋',
          sublabel: desc.split(' ').first,
          icon: Icons.task_alt,
          onSelect: () => _completeMissionForBuilding(target.buildingModel),
        ));
      }
      actions.add(RadialAction(
        label: target.interactionEmoji,
        sublabel: target.interactionLabel.split(' ').first,
        icon: Icons.chat_bubble,
        onSelect: () {
          _nearestInteractable = target;
          target.onInteract();
        },
      ));
    }

    // Collision query: buildings whose cells directly touch the player's grid
    // position.  This surfaces every drawn building regardless of whether it
    // has a pre-registered BuildingComponent interaction point.
    for (final model in _getAdjacentBuildingModels()) {
      if (!offeredBuildingIds.add(model.buildingId)) continue; // already offered
      actions.add(RadialAction(
        label: BuildingComponent.buildingEmoji(model.type),
        sublabel: BuildingComponent.buildingName(model.type).split(' ').first,
        icon: Icons.meeting_room,
        onSelect: () => openBuildingInterior(model),
      ));
    }

    _currentMenu = RadialMenu(actions: actions, position: player.position);
    world.add(_currentMenu!);
  }

  /// Returns the [BuildingModel]s for any building cells that directly adjoin
  /// (8-directional) the player's current grid cell.
  ///
  /// Acts as the collision query: every drawn building in the world can be
  /// detected here, not just those with a pre-registered [BuildingComponent].
  List<BuildingModel> _getAdjacentBuildingModels() {
    const cellSize = 32.0;
    final px = (player.position.x / cellSize).floor();
    final py = (player.position.y / cellSize).floor();

    final result = <BuildingModel>[];
    final seen = <String>{};

    for (final d in const [
      [-1, -1], [0, -1], [1, -1],
      [-1,  0],          [1,  0],
      [-1,  1], [0,  1], [1,  1],
    ]) {
      final cell = grid.getCell(px + d[0], py + d[1]);
      if (cell == null) continue;
      final data = cell.data;
      if (data is! BuildingData) continue;
      if (!seen.add(data.buildingId)) continue;
      final model = chunkManager.getBuildingModel(data.buildingId);
      if (model != null) result.add(model);
    }
    return result;
  }

  void showDialog(String name, String emoji, NPCModel model) {
    activeDialog = GameDialogData(npcName: name, npcEmoji: emoji, npcModel: model);
    overlays.add('DialogOverlay');
    paused = true; 
  }

  // ── Mission helpers ───────────────────────────────────────────────────────

  void _completeMissionForNpc(NPCModel npc) {
    final (faith, mats) = missionService.completeNpcMission(
      npc,
      chunkManager.allActiveNPCs.map((c) => c.model).toList(),
      chunkManager.allActiveBuildings.map((c) => c.buildingModel).toList(),
    );
    gainFaith(faith.toDouble());
    gainMaterials(mats.toDouble());
    _log.info('Mission completed for NPC ${npc.name} → +$faith🙏 +$mats📦');
  }

  void _completeMissionForBuilding(BuildingModel building) {
    final (faith, mats) = missionService.completeBuildingMission(
      building,
      chunkManager.allActiveNPCs.map((c) => c.model).toList(),
      chunkManager.allActiveBuildings.map((c) => c.buildingModel).toList(),
    );
    gainFaith(faith.toDouble());
    gainMaterials(mats.toDouble());
    _log.info('Mission completed for building ${building.buildingId} → +$faith🙏 +$mats📦');
  }

  /// Called once the first chunk is loaded and we have NPCs + buildings.
  void _tryAssignStartMissions() {
    final npcs = chunkManager.allActiveNPCs.map((c) => c.model).toList();
    final buildings = chunkManager.allActiveBuildings.map((c) => c.buildingModel).toList();
    if (npcs.isEmpty && buildings.isEmpty) return;
    missionService.assignStartMissions(npcs, buildings);
  }

  // ── Look overlay ──────────────────────────────────────────────────────────

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
        final name = BuildingComponent.buildingName(data.type);
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

  // ── Mission board ─────────────────────────────────────────────────────────

  /// Active data for the mission-board overlay (null when closed).
  MissionBoardData? activeMissionBoardData;

  /// Opens the mission board inline inside the current building overlay.
  void openMissionBoard() {
    final entries = <MissionEntry>[];
    for (final npcComp in chunkManager.allActiveNPCs) {
      final npc = npcComp.model;
      if (npc.activeMissionDescription == null) continue;
      entries.add(MissionEntry(
        targetEmoji: npcComp.interactionEmoji,
        targetName: npc.name,
        description: npc.activeMissionDescription!,
        faithReward: MissionService.faithReward,
        materialsReward: MissionService.materialsReward,
        address: _addressForPixelPos(npcComp.position),
      ));
    }
    for (final bldComp in chunkManager.allActiveBuildings) {
      final bld = bldComp.buildingModel;
      if (bld.activeMissionDescription == null) continue;
      entries.add(MissionEntry(
        targetEmoji: BuildingComponent.buildingEmoji(bld.type),
        targetName: BuildingComponent.buildingName(bld.type),
        description: bld.activeMissionDescription!,
        faithReward: MissionService.faithReward,
        materialsReward: MissionService.materialsReward,
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

  String handleInteraction(String type) {
    if (_nearestInteractable != null) {
      return _nearestInteractable!.handleInteraction(type);
    }
    return '❓';
  }

  void closeDialog() {
    activeDialog = null;
    overlays.remove('DialogOverlay');
    paused = false;
  }

  // ── Building interior ─────────────────────────────────────────────────────

  /// Opens the building-interior overlay for [building].
  void openBuildingInterior(BuildingModel building) {
    building.resetSession();
    activeBuildingData = GameBuildingData(building: building);
    overlays.add('BuildingInteriorOverlay');
    paused = true;
  }

  /// Closes the building-interior overlay.
  void closeBuildingInterior() {
    activeBuildingData = null;
    overlays.remove('BuildingInteriorOverlay');
    paused = false;
  }

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

    final result = buildingInteractionService.performAction(
      actionType,
      data.building,
      faith,
    );
    // Guard: refuse if the player cannot afford the material cost.
    // materialCost is negative when playerMaterialsDelta > 0 (a gain), so the
    // check `materialCost > 0` safely skips this guard for income actions.
    final materialCost = -result.playerMaterialsDelta;
    if (materialCost > 0 && materials < materialCost) {
      return const BuildingInteractionResult(
        reactionEmoji: '🚫💰',
        success: false,
      );
    }
    // Guard: refuse if the player does not have enough health for the action.
    final healthCost = -result.playerHealthDelta;
    if (healthCost > 0 && health < healthCost) {
      return const BuildingInteractionResult(
        reactionEmoji: '🚫❤️',
        success: false,
      );
    }
    // Apply resource deltas immediately
    if (result.playerFaithDelta != 0) gainFaith(result.playerFaithDelta);
    if (result.playerMaterialsDelta > 0) {
      gainMaterials(result.playerMaterialsDelta);
    } else if (result.playerMaterialsDelta < 0) {
      spendMaterials(-result.playerMaterialsDelta);
    }
    if (result.playerHealthDelta != 0) {
      health = (health + result.playerHealthDelta).clamp(0.0, maxHealth);
    }
    if (result.playerHungerDelta != 0) {
      gainHunger(result.playerHungerDelta);
    }
    // 'prayBusiness' also nudges the cell underneath the player positively
    if (actionType == 'prayBusiness') {
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
    // Increment session interaction counter for buildings (mirrors NPC dialog
    // behaviour).  The homebase has an unlimited limit so this counter never
    // triggers an auto-leave there.
    if (result.success) {
      data.building.currentSessionInteractions++;
    }
    return result;
  }

  /// Attempts to access [building] on behalf of the player.
  ///
  /// Returns `true` if access is granted (always true for non-residential).
  bool attemptBuildingAccess(BuildingModel building) {
    return buildingInteractionService.attemptAccess(building, faith);
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

  void closeMenu() { _currentMenu?.removeFromParent(); _currentMenu = null; }

  // ── Keymap overlay ────────────────────────────────────────────────────────

  bool _keymapOpen = false;

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

  // ── Escape / close helper ─────────────────────────────────────────────────

  /// Closes whichever overlay or menu is currently open, in priority order.
  void handleEscape() {
    if (_keymapOpen)          { closeKeymapOverlay();    return; }
    if (activeDialog != null) { closeDialog();            return; }
    if (activeBuildingData != null) { closeBuildingInterior(); return; }
    if (activeLookData != null)     { closeLookOverlay();      return; }
    if (activeMissionBoardData != null) { closeMissionBoard(); return; }
    if (_currentMenu != null) { closeMenu();              return; }
  }

  // ── Radial-menu keyboard selection ────────────────────────────────────────

  /// Selects the radial-menu action at [zeroBasedIndex] via keyboard (1–6).
  void selectRadialMenuAction(int zeroBasedIndex) {
    _currentMenu?.selectByIndex(zeroBasedIndex);
    _currentMenu = null; // selectByIndex removes the component already
  }

  // ── Dialog / building keyboard selection ──────────────────────────────────

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

  @override
  void update(double dt) {
    super.update(dt);
    if (_currentMenu != null) _currentMenu!.position = player.position;
    if (isWorldReady.value && !paused) {
      _updateCamera(dt);
      _updateNearestInteractable();
      _updatePassiveResources(dt);
      _updateStreetLabel();
    }
    // Always push player position so the Flutter HUD compass stays live.
    playerWorldPosition.value = player.position.clone();
  }

  /// Updates [currentStreetLabel] whenever the player moves to a new cell.
  void _updateStreetLabel() {
    const cellSize = 32.0;
    final cx = (player.position.x / cellSize).floor();
    final cy = (player.position.y / cellSize).floor();
    if (cx == _lastStreetCellX && cy == _lastStreetCellY) return;
    _lastStreetCellX = cx;
    _lastStreetCellY = cy;

    // Try the player's own cell first, then the 4 cardinal neighbours.
    // Accept ANY road cell (named or unnamed) for address lookup so the
    // label also appears on secondary streets with a house number.
    String? label;
    String? nearestRoadName;
    int? nearestHouseNumber;

    for (final d in const [
      [0, 0], [0, -1], [1, 0], [0, 1], [-1, 0],
    ]) {
      final cell = grid.getCell(cx + d[0], cy + d[1]);
      if (cell == null) continue;
      final data = cell.data;
      if (data is RoadData) {
        if (data.streetName != null && nearestRoadName == null) {
          nearestRoadName = data.streetName;
        }
      } else if (data is BuildingData && nearestHouseNumber == null) {
        nearestHouseNumber = data.houseNumber;
        // Also look for a named road adjacent to this building.
        if (nearestRoadName == null) {
          for (final rd in const [
            [0, -1], [1, 0], [0, 1], [-1, 0],
          ]) {
            final roadCell = grid.getCell(cx + d[0] + rd[0], cy + d[1] + rd[1]);
            if (roadCell?.data is RoadData &&
                (roadCell!.data as RoadData).streetName != null) {
              nearestRoadName = (roadCell.data as RoadData).streetName;
              break;
            }
          }
        }
      }
    }

    if (nearestRoadName != null && nearestHouseNumber != null) {
      label = '$nearestRoadName $nearestHouseNumber';
    } else if (nearestRoadName != null) {
      label = nearestRoadName;
    } else if (nearestHouseNumber != null) {
      // Unnamed secondary street: still show the house number so the player
      // always gets some address feedback.
      label = 'Nr.\u00a0$nearestHouseNumber';
    }
    // If still no name, keep empty so the label stays hidden.
    currentStreetLabel.value = label ?? '';
  }

  void _updatePassiveResources(double dt) {
    // Hunger drains slowly over time
    _hungerDrainTimer += dt;
    if (_hungerDrainTimer >= hungerDrainInterval) {
      _hungerDrainTimer = 0.0;
      hunger = (hunger - hungerDrainAmount).clamp(0.0, maxHunger);
      // If starving, health starts draining
      if (hunger < healthFromHungerThreshold) {
        health = (health - 0.5).clamp(0.0, maxHealth);
      }
    }
  }

  /// Spend materials (returns false if not enough)
  bool spendMaterials(double amount) {
    if (materials < amount) return false;
    materials = (materials - amount).clamp(0.0, maxMaterials);
    return true;
  }

  /// Gain resources (clamped to max)
  void gainFaith(double amount) => faith = (faith + amount).clamp(0.0, maxFaith);
  void gainHealth(double amount) => health = (health + amount).clamp(0.0, maxHealth);
  void gainHunger(double amount) => hunger = (hunger + amount).clamp(0.0, maxHunger);
  void gainMaterials(double amount) => materials = (materials + amount).clamp(0.0, maxMaterials);

  @override
  void onRemove() {
    faithNotifier.dispose();
    healthNotifier.dispose();
    hungerNotifier.dispose();
    materialsNotifier.dispose();
    super.onRemove();
  }

  /// Record a completed prayer combat and check modifier unlocks
  void recordPrayerCombat() {
    progress.recordPrayerCombat();
    missionService.onPrayerCombat();
    _checkAndApplyModifiers();
  }

  /// Record a completed conversation
  void recordConversation() {
    progress.recordConversation();
    missionService.onDialogCompleted();
    _checkAndApplyModifiers();
  }

  /// Record an NPC conversion
  void recordConversion() {
    progress.recordConversion();
    _checkAndApplyModifiers();
  }

  void _checkAndApplyModifiers() {
    final unlocked = modifiers.checkUnlocks();
    if (unlocked.isNotEmpty) {
      // Re-wire modifier values after new unlocks
      spiritualDynamics.modifierSpreadMultiplier = modifiers.greenSpreadMultiplier;
      spiritualDynamics.modifierDecayReduction = modifiers.decayReduction;
      _log.info('New modifiers unlocked: $unlocked');
    }
  }

  void _updateNearestInteractable() {
    Interactable? nearest;
    double minDistance = interactionRange;

    final Iterable<Interactable> all = [
      ...chunkManager.allActiveBuildings,
      ...chunkManager.allActiveNPCs,
    ];
    for (final interactable in all) {
      final dist = player.position.distanceTo(interactable.interactionPosition);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = interactable;
      }
    }

    // If no interactable found by distance, also check via grid adjacency.
    // This makes the interaction aura activate when the player is touching a
    // building wall, even for buildings without a registered component.
    if (nearest == null) {
      final adjacentModels = _getAdjacentBuildingModels();
      if (adjacentModels.isNotEmpty) {
        final buildingId = adjacentModels.first.buildingId;
        // Prefer the registered component so interactionLabel/onInteract work.
        nearest = chunkManager.allActiveBuildings
            .where((b) => b.buildingModel.buildingId == buildingId)
            .firstOrNull;
        // Fallback: any registered building component acts as a sentinel so
        // the player aura switches to its "nearby" colour.
        nearest ??= chunkManager.allActiveBuildings.firstOrNull;
      }
    }

    if (_nearestInteractable != nearest) {
      _nearestInteractable = nearest;
    }
  }

  void _updateCamera(double dt) {
    final viewportSize = camera.viewport.size;
    if (viewportSize.x <= 0) return;

    final camPos = camera.viewfinder.position;
    final pPos = player.position;

    final limitX = viewportSize.x * 0.375; 
    final limitY = viewportSize.y * 0.375;

    final dx = pPos.x - camPos.x;
    final dy = pPos.y - camPos.y;

    double pushX = 0;
    double pushY = 0;

    if (dx.abs() > limitX) pushX = dx - (limitX * dx.sign);
    if (dy.abs() > limitY) pushY = dy - (limitY * dy.sign);

    if (pushX != 0 || pushY != 0) {
      camera.viewfinder.position = Vector2(camPos.x + pushX, camPos.y + pushY);
    }
  }

  JoystickComponent _createJoystick() {
    return joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: Paint()..color = Colors.white.withValues(alpha: 0.5)),
      background: CircleComponent(radius: 50, paint: Paint()..color = Colors.white.withValues(alpha: 0.2)),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
  }

  Future<void> _addHudButtons() async {
    actionButton = HudButton(
      icon: '🖐️',
      color: Colors.blue.withValues(alpha: 0.6),
      onDown: handleActionDown, 
      onUp: handleActionUp, 
      keyLabel: 'E',
      position: Vector2(size.x - 80, size.y - 80)
    );
    await camera.viewport.add(actionButton);

    worldToggleButton = HudButton(
      icon: '🙏',
      color: Colors.purple.withValues(alpha: 0.6),
      onDown: toggleWorld,
      keyLabel: 'Q',
      position: Vector2(size.x - 170, size.y - 80)
    );
    await camera.viewport.add(worldToggleButton);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      actionButton.position = Vector2(size.x - 80, size.y - 80);
      worldToggleButton.position = Vector2(size.x - 170, size.y - 80);
    }
  }
}

class HudButton extends PositionComponent with TapCallbacks {
  final VoidCallback? onDown;
  final VoidCallback? onUp;
  String icon;
  Color color;
  /// Optional keyboard shortcut label shown as an amber badge (desktop/web only).
  final String? keyLabel;
  
  HudButton({
    required this.icon,
    required this.color,
    this.onDown, 
    this.onUp,
    this.keyLabel,
    required super.position
  }) : super(anchor: Anchor.center, size: Vector2.all(75)); // Einheitliche Größe

  void updateContent(String newIcon, Color newColor) {
    icon = newIcon;
    color = newColor;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;

    // 1. Schwarzer Rand / Schatten
    canvas.drawCircle(center, radius + 2, Paint()..color = Colors.black.withValues(alpha: 0.5));
    
    // 2. Haupt-Button
    canvas.drawCircle(center, radius, Paint()..color = color);

    // 3. Glanz-Effekt oben
    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha: 0.3), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shinePaint);

    // 4. Icon
    TextPainter(
      text: TextSpan(text: icon, style: const TextStyle(fontSize: 30)),
      textDirection: TextDirection.ltr
    )..layout()..paint(canvas, Offset(size.x / 2 - 15, size.y / 2 - 19));

    // 5. Keyboard shortcut badge (amber circle, top-right corner, desktop/web only)
    if (keyLabel != null && _shouldShowKeyHints()) {
      const badgeRadius = 11.0;
      final badgeCenter = Offset(size.x - badgeRadius + 2, badgeRadius - 2);
      canvas.drawCircle(badgeCenter, badgeRadius, Paint()..color = const Color(0xFFFFA000));
      TextPainter(
        text: TextSpan(
          text: keyLabel,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout()..paint(
        canvas,
        Offset(badgeCenter.dx - 5.5, badgeCenter.dy - 7),
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) => onDown?.call();

  @override
  void onTapUp(TapUpEvent event) => onUp?.call();

  @override
  void onTapCancel(TapCancelEvent event) => onUp?.call();
}
