import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier, kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;
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
import '../domain/models/mission_model.dart';
import '../domain/models/modifier_manager.dart';
import '../domain/models/npc_model.dart';
import '../domain/models/player_progress.dart';
export '../domain/models/player_progress.dart';
import '../domain/models/prayer_combat.dart';
import '../domain/services/building_interaction_service.dart';
import '../domain/services/influence_service.dart';
import '../domain/services/mission_service.dart';
import '../domain/services/tutorial_service.dart';
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

  // ── Spiritual-world button dock constants ────────────────────────────────
  /// Minimum pixel gap between adjacent mode-button centers on very small
  /// screens.  25 px keeps buttons selectable even when spacing is compressed.
  static const double _minModeButtonSpacing = 25.0;

  /// Maximum pixel gap between adjacent mode-button centers on large screens.
  /// 65 px matches the legacy fixed 60 px spacing with a small visual margin.
  static const double _maxModeButtonSpacing = 65.0;

  // ── Save-data schema versioning ───────────────────────────────────────────
  /// Increment this constant whenever the structure of [captureGameState]
  /// changes in a way that is incompatible with older saved data.
  ///
  /// Migration logic lives in [_migrateGameState]:
  ///   • version 0 (missing key) → version 1: initial schema.
  ///   • version 1 → version 2: NPC counters unified into interactionCount
  ///     ('conv' key); separate 'pray' and 'counsel' keys removed.
  ///   • version 2 → version 3: Added PlayerProgress and CombatProfile persistence.
  static const int kSaveDataVersion = 3;

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
  late final _SprintJoystickComponent _sprintJoystick;
  late final ChunkManager chunkManager;
  late final SpiritualDynamicsSystem spiritualDynamics;
  late final HudButton actionButton;
  late final HudButton worldToggleButton;
  late final List<HudButton> modeButtons;
  late final PrayerHudComponent prayerHud;
  late final LootSystem lootSystem;

  /// Mission system – wired to all interaction hooks.
  late final MissionService missionService;

  /// Interactive tutorial – guides new players through the core mechanics.
  final TutorialService tutorialService = TutorialService();

  /// Brief mission-completion toast message (reuses the loot-toast widget).
  /// Set to null after the toast has been dismissed.
  final ValueNotifier<String?> missionCompleteMessage = ValueNotifier(null);

  /// Brief conversion toast shown when an NPC is converted (e.g. "+1 ✝").
  /// Set to null after the toast has been dismissed.
  final ValueNotifier<String?> conversionToastMessage = ValueNotifier(null);

  /// True while the faint/game-over animation is playing.
  /// Flutter overlays listen to this to show the blackout screen.
  final ValueNotifier<bool> isFainting = ValueNotifier(false);

  /// Wakeup message shown after a faint event.
  /// Set to null after the toast has been dismissed.
  final ValueNotifier<String?> wakeupMessage = ValueNotifier(null);

  /// True once the win condition has been met (all NPCs converted + all loaded
  /// cells positive).  Set to true at most once per session to prevent
  /// double-triggering.  Flutter overlays listen to this to show the win screen.
  final ValueNotifier<bool> isWon = ValueNotifier(false);

  /// Guards against re-triggering the win screen a second time.
  bool _winTriggered = false;

  /// Timestamp of the moment [onLoad] completed – used to compute the
  /// "time played" statistic shown on the win screen.
  late DateTime _sessionStartTime;

  /// The play time captured the moment the win condition was triggered.
  /// Fixed so the stats panel shows the time at which the player won, not a
  /// live clock that keeps incrementing after the win screen is shown.
  Duration sessionPlayTime = Duration.zero;

  /// Influence system – manages AoE spiritual-state effects with duration/decay.
  final InfluenceService influenceService = InfluenceService();

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
  /// True after [_updateStreetLabel] has run once (sets the spawn-position
  /// baseline).  Prevents firing the tutorial movement hook on the very first
  /// cell-position detection (which is not a real player movement).
  bool _streetLabelInitialized = false;
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

  // Faint / game-over state
  bool _faintTriggered = false;

  // Win-condition polling timer (checked every 5 seconds when the world is ready)
  double _winCheckTimer = 0.0;
  static const double _winCheckInterval = 5.0;

  // City scope for global win checks.
  // DistrictSelector uses _outskirtsRadius=650 and _ringNoiseAmp=40, so the
  // city can extend to roughly 690 cells from origin.
  static const double _cityScopeRadiusCells = 690.0;
  static const double _cityScopeRadiusCellsSquared =
      _cityScopeRadiusCells * _cityScopeRadiusCells;
  static const int _cityScopeChunkRadius = 22; // ceil(690 / 32)

  // Hunger mechanics thresholds (as fractions of maxHunger)
  static const double hungerWarnThreshold     = 0.30; // < 30%: slower movement
  static const double hungerCriticalThreshold = 0.10; // < 10%: even slower + faith cost +50%

  // Health alarm / faint thresholds
  static const double healthAlarmThreshold = 0.25; // < 25%: red screen edge
  static const double healthFaintThreshold = 1.0;  // ≤ 1 HP: trigger faint

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

  /// Saved loot-system state loaded from Hive.
  List<Map<String, dynamic>>? _savedLootState;

  @override
  Color backgroundColor() => isSpiritualWorld ? const Color(0xFF000511) : const Color(0xFF111111);

  @override
  Future<void> onLoad() async {
    try {
      _log.info('--- INITIALIZING GAME ---');
      seedManager = SeedManager(42);
      generator = CityGenerator(seedManager);
      grid = CityGrid();

      // Progress & modifiers
      progress = PlayerProgress();
      modifiers = ModifierManager(progress: progress);

      // Mission system – initialised here so the onMissionCompleted callback
      // can reference `progress`, `gainFaith` etc. which aren't available yet
      // at field initialisation time.
      missionService = MissionService(
        onMissionCompleted: _onMissionCompleted,
      );

      // Initialize dynamics system early so modifiers can be applied during state restoration.
      spiritualDynamics = SpiritualDynamicsSystem();

      // ── Restore save state ──────────────────────────────────────────────────
      final rawState = gameSave?.gameState;
      // Run migration so the rest of onLoad always sees the current schema.
      final savedState = rawState != null && rawState.isNotEmpty
          ? _migrateGameState(Map<String, dynamic>.from(rawState))
          : null;
      final hasSavedState = savedState != null && savedState.isNotEmpty;
      if (hasSavedState) {
        _applyPlayerState(savedState);
        _savedCellStates     = _parseSavedCellStates(savedState);
        _savedNPCStates      = _parseSavedNPCStates(savedState);
        _savedBuildingStates = _parseSavedBuildingStates(savedState);
        _savedLootState      = _parseSavedLootState(savedState);
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
              (savedState['playerX'] as num).toDouble(),
              (savedState['playerY'] as num).toDouble(),
            )
          : Vector2(7040, 7168);
      await world.add(player);

      chunkManager = ChunkManager(grid: grid, generator: generator, target: player);
      await world.add(chunkManager);

      // System already initialized, now add to world
      await world.add(spiritualDynamics);

      // Wire modifier values to the dynamics system
      spiritualDynamics.modifierSpreadMultiplier = modifiers.greenSpreadMultiplier;
      spiritualDynamics.modifierDecayReduction = modifiers.decayReduction;

      await camera.viewport.add(joystick);
      await _addHudButtons();

      modeButtons = [];
      const modes = PrayerMode.values;
      for (int i = 0; i < modes.length; i++) {
        final mode = modes[i];
        final btn = HudButton(
          icon: mode.icon,
          color: mode.color.withValues(alpha: 0.5),
          onDown: () => player.setMode(mode),
          isActive: () => player.currentMode == mode,
          plain: true,
          size: Vector2.all(55),
          position: Vector2(size.x - 170, size.y - 150 - (i * 65)),
        );
        btn.opacity = 0; // Hidden by default
        modeButtons.add(btn);
        await camera.viewport.add(btn);
      }
      
      prayerHud = PrayerHudComponent();
      await camera.viewport.add(prayerHud);

      lootSystem = LootSystem(seed: seedManager.seed);
      await world.add(lootSystem);
      // Restore loot positions from the save file so pickups reappear at their
      // original world positions rather than being re-spawned near the player.
      // On fresh games LootSystem's built-in startup grace period handles the
      // first spawn delay automatically.
      if (_savedLootState != null) {
        lootSystem.restoreState(_savedLootState!);
      }

      camera.viewfinder.anchor = Anchor.center;
      camera.viewfinder.position = player.position.clone();

      await Future.delayed(const Duration(milliseconds: 1000));
      if (hasSavedState && savedState['isSpiritualWorld'] == true) {
        isSpiritualWorld = true;
        _updateHudVisibility();
        _updateButtonStyles();
      }
      isWorldReady.value = true;
      _sessionStartTime = DateTime.now();
      _log.info(
        '--- GAME READY --- '
        'pastorhousePos=${pastorhousePosition.value} '
        'playerPos=${player.position}',
      );

      // Start tutorial for new players (or players who haven't finished it yet).
      if (!tutorialService.isTutorialCompleted) {
        // Short delay so the loading overlay has faded before the tutorial appears.
        Future.delayed(const Duration(milliseconds: 600), () => tutorialService.startTutorial());
      }

      // Assign starting missions to NPCs / buildings in the spawn chunk.
      // Run after a short delay so chunk NPCs/buildings are all registered.
      Future.delayed(const Duration(milliseconds: 500), _tryAssignStartMissions);
    } catch (e, stack) {
      _log.severe('CRITICAL ERROR DURING GAME LOAD: $e', e, stack);
      isWorldReady.value = true;
    }
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

    if (state.containsKey('progress')) {
      final progressData = state['progress'];
      if (progressData is Map) {
        progress.loadFromJson(progressData.cast<String, dynamic>());
      }
      _checkAndApplyModifiers(); // Sync modifiers with loaded progress
    }

    // Restore tutorial completion flag so the tutorial isn't shown again.
    tutorialService.isTutorialCompleted = state['tutorialCompleted'] == true;
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

  /// Parses the `loot` list from a serialised save.
  List<Map<String, dynamic>>? _parseSavedLootState(
      Map<String, dynamic> state) {
    final raw = state['loot'];
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
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
    if (saved == null) {
      _log.fine('applySavedNPCState: no saved state for ${npc.id} '
          '(faith=${npc.faith.toStringAsFixed(1)}, '
          'isConverted=${npc.isConverted})');
      return;
    }
    npc.faith             = ((saved['faith']   as num?)?.toDouble() ?? npc.faith).clamp(-100.0, 100.0);
    npc.interactionCount  = (saved['conv']    as num?)?.toInt()    ?? npc.interactionCount;
    npc.isConverted       = saved['converted'] as bool? ?? npc.isConverted;
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
    // Restore active mission if one was saved.
    if (saved['mission'] is Map) {
      building.activeMission = MissionModel.fromJson(
        (saved['mission'] as Map).cast<String, dynamic>(),
      );
    }
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
          'faith': npc.faith.clamp(-100.0, 100.0),
          if (npc.interactionCount != 0) 'conv': npc.interactionCount,
          if (npc.isConverted)           'converted': true,
          'posX': npcComp.position.x,
          'posY': npcComp.position.y,
          if (npc.activeMission != null) 'mission': npc.activeMission!.toJson(),
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
          building.activeMission != null) {
        buildingStates[building.buildingId] = {
          if (building.faith != 0.0)            'faith': building.faith,
          if (building.interactionCount != 0)   'conv':  building.interactionCount,
          if (building.activeMission != null)   'mission': building.activeMission!.toJson(),
        };
      }
    }
    // Preserve states for buildings in chunks not visited during this session.
    _savedBuildingStates?.forEach(
      (id, saved) => buildingStates.putIfAbsent(id, () => saved),
    );

    return {
      'schemaVersion':      kSaveDataVersion,
      'faith':              faith,
      'health':             health,
      'hunger':             hunger,
      'materials':          materials,
      'playerX':            player.position.x,
      'playerY':            player.position.y,
      'isSpiritualWorld':   isSpiritualWorld,
      'tutorialCompleted':  tutorialService.isTutorialCompleted,
      'progress':           progress.toJson(),
      'cells':              cellStates,
      'npcs':               npcStates,
      'buildings':          buildingStates,
      'loot':               lootSystem.captureState(),
    };
  }

  void toggleWorld() {
    if (!isSpiritualWorld && faith < worldToggleCost) {
      _log.warning('Not enough faith to enter spiritual world');
      return;
    }
    
    if (!isSpiritualWorld) {
      spendFaith(worldToggleCost);
    }
    
    final wasInSpiritWorld = isSpiritualWorld;
    isSpiritualWorld = !isSpiritualWorld;
    _updateHudVisibility();
    _updateButtonStyles();
    _log.info('Switched World: $isSpiritualWorld');

    // Tutorial hooks for world-switching steps.
    if (isSpiritualWorld) {
      tutorialService.onEnteredSpiritWorld();
    } else if (wasInSpiritWorld) {
      tutorialService.onReturnedToCity();
    }

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
    // keyLabel is set by _updateHudVisibility which always runs after this.

    worldToggleButton.updateContent(
      isSpiritualWorld ? '🏙️' : '🙏',
      isSpiritualWorld ? Colors.grey.withValues(alpha: 0.7) : Colors.purple.withValues(alpha: 0.6)
    );
  }

  void _updateHudVisibility() {
    if (isSpiritualWorld) {
      if (joystick.parent != null) joystick.removeFromParent();

      // ── Spiritual-world dock layout ────────────────────────────────────────
      // Lay all bottom buttons in a single non-overlapping row:
      //   [combat btn]  [── mode buttons ──]  [return btn]
      //
      // The two side buttons (size 75) are anchored at x = 42 (left) and
      // x = size.x - 42 (right), so their bounds are roughly [5, 79] and
      // [size.x - 79, size.x - 5].  Mode buttons (size 50/60 selected) are
      // distributed evenly in the gap between x = 90 and x = size.x - 90.

      actionButton.position = Vector2(42, size.y - 80);
      actionButton.keyLabel = 'Space';

      worldToggleButton.position = Vector2(size.x - 42, size.y - 80);

      final n = modeButtons.length;
      if (n > 0) {
        // Available width between the fixed side-button inner edges (≈ 90 px
        // on each side).  Clamp individual spacing so buttons never overlap
        // each other even on very small screens.
        final available = size.x - 180.0;
        final spacing = n > 1 ? (available / (n - 1)).clamp(_minModeButtonSpacing, _maxModeButtonSpacing) : 0.0;
        final totalModeWidth = (n - 1) * spacing;
        final modeStartX = (size.x - totalModeWidth) / 2;

        for (int i = 0; i < n; i++) {
          final btn = modeButtons[i];
          btn.opacity = 1.0;
          final isSelected = player.currentMode == PrayerMode.values[i];
          btn.size = Vector2.all(isSelected ? 60.0 : 45.0);
          btn.position = Vector2(
            modeStartX + i * spacing,
            isSelected ? size.y - 88.0 : size.y - 80.0,
          );
          btn.keyLabel = '${i + 1}';
        }
      }
    } else {
      if (joystick.parent == null) camera.viewport.add(joystick);
      // Normal-world layout: interaction button bottom-right, toggle left of it.
      actionButton.position = Vector2(size.x - 80, size.y - 80);
      actionButton.keyLabel = 'E';
      worldToggleButton.position = Vector2(size.x - 170, size.y - 80);
      for (final btn in modeButtons) {
        btn.opacity = 0.0;
      }
    }
  }

  void _openRadialMenu() {
    final actions = <RadialAction>[
      RadialAction(
        label: '👀',
        icon: Icons.search,
        onSelect: () {
          tutorialService.onRadialMenuActionSelected();
          openLookOverlay();
        },
      ),
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
      actions.add(RadialAction(
        label: target.interactionEmoji,
        sublabel: target.interactionLabel.split(' ').first,
        icon: Icons.chat_bubble,
        onSelect: () {
          tutorialService.onRadialMenuActionSelected();
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
        onSelect: () {
          tutorialService.onRadialMenuActionSelected();
          openBuildingInterior(model);
        },
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
    tutorialService.onNpcDialogOpened();
  }

  // ── Mission helpers ───────────────────────────────────────────────────────

  /// Called by [MissionService] when a mission is completed via
  /// [advanceEntityMission].  Awards faith, materials and Insight and shows
  /// a brief toast message.

  void _onMissionCompleted(MissionModel mission) {
    if (mission.rewardFaith > 0) gainFaith(mission.rewardFaith);
    if (mission.rewardMaterials > 0) gainMaterials(mission.rewardMaterials);
    if (mission.insightReward > 0) progress.addInsight(mission.insightReward);

    final insightStr = mission.insightReward > 0
        ? ' +${mission.insightReward.toStringAsFixed(1)} 📖'
        : '';
    missionCompleteMessage.value =
        '📋 Mission!$insightStr';
    Future.delayed(const Duration(seconds: 3), () {
      missionCompleteMessage.value = null;
    });

    _log.info(
      'Mission completed: "${mission.description}" '
      '→ +${mission.rewardFaith}🙏 +${mission.rewardMaterials}📦 '
      '+${mission.insightReward}📖',
    );
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
        targetName: BuildingComponent.buildingName(bld.type),
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

  // ── Building interior ─────────────────────────────────────────────────────

  /// Opens the building-interior overlay for [building].
  void openBuildingInterior(BuildingModel building) {
    building.resetSession();
    activeBuildingData = GameBuildingData(building: building);
    overlays.add('BuildingInteriorOverlay');
    paused = true;
    tutorialService.onBuildingInteracted();
  }

  /// Closes the building-interior overlay.
  void closeBuildingInterior() {
    activeBuildingData = null;
    overlays.remove('BuildingInteriorOverlay');
    // Also close the mission board if it was opened from inside the building.
    if (activeMissionBoardData != null) closeMissionBoard();
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
    // Guard: refuse if the player does not have enough hunger for the action.
    final hungerCost = -result.playerHungerDelta;
    if (hungerCost > 0 && hunger < hungerCost) {
      return const BuildingInteractionResult(
        reactionEmoji: '🚫🍞',
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
      case 'worship':
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
      case BuildingType.cathedral:
      case BuildingType.pastorHouse:
        return BuildingInfluenceConstants.multiplierSpiritual;
      case BuildingType.stadium:
      case BuildingType.skyscraper:
      case BuildingType.cityHall:
        return BuildingInfluenceConstants.multiplierLarge;
      case BuildingType.church:
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
      if (isSpiritualWorld) _updateHudVisibility(); // Dynamic dock update
      // Tick influence effects (decay / reversal of timed AoE events).
      influenceService.update(dt, grid);
      // Periodically check the win condition (spiritual state can change from
      // prayer combat and natural decay, not just NPC conversions).
      _winCheckTimer += dt;
      if (_winCheckTimer >= _winCheckInterval) {
        _winCheckTimer = 0.0;
        _checkWinCondition();
      }
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
    final wasInitialized = _streetLabelInitialized;
    _streetLabelInitialized = true;
    _lastStreetCellX = cx;
    _lastStreetCellY = cy;

    // Fire tutorial movement hook only after the initial position has been
    // established (first call sets the spawn-cell baseline, not real movement).
    if (wasInitialized) { tutorialService.onPlayerMoved(); }

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
      spendHunger(hungerDrainAmount);
      // If critically hungry (hunger < 10), health starts draining (1 HP per
      // hunger tick, i.e. every [hungerDrainInterval] seconds)
      if (hunger < 10.0) {
        spendHealth(1.0);
      }
    }
    // Check faint condition every frame (health can drop from combat too)
    _checkFaintCondition();
  }

  /// Checks whether the player should faint (health ≤ [healthFaintThreshold]).
  void _checkFaintCondition() {
    if (_faintTriggered || isFainting.value) return;
    if (health <= healthFaintThreshold) {
      _faintTriggered = true;
      _triggerFaint();
    }
  }

  /// Triggers the full faint sequence:
  /// 1. Shows the blackout overlay.
  /// 2. Teleports the player to the nearest recovery point (pastor house / hospital).
  /// 3. Resets resources and applies a spiritual setback around the faint location.
  /// 4. Shows the wakeup message.
  Future<void> _triggerFaint() async {
    final faintPosition = player.position.clone();
    isFainting.value = true;

    // Wait for the faint animation to play out
    await Future.delayed(const Duration(milliseconds: 2000));

    // Find the nearest recovery point (pastor house or hospital)
    final recoveryPos = _findNearestRecoveryPoint();
    if (recoveryPos != null) {
      player.position.setFrom(recoveryPos);
      camera.viewfinder.position = recoveryPos.clone();
    }

    // Reset resources (per spec)
    health    = progress.maxHealth;
    hunger    = progress.maxHunger;
    faith     = 0;
    materials = 0;

    // Insight: -10% (min 0)
    progress.applyFaintInsightPenalty();

    // Spiritual setback: darken the area around the faint location
    _applyFaintSetback(faintPosition);

    // Return to real world if the player was in the spiritual world
    if (isSpiritualWorld) {
      isSpiritualWorld = false;
      _updateHudVisibility();
      _updateButtonStyles();
    }

    isFainting.value = false;

    // Show wakeup message
    wakeupMessage.value =
        'Während du ohnmächtig warst, ist die Finsternis zurückgekehrt...';
    Future.delayed(const Duration(seconds: 6), () {
      wakeupMessage.value = null;
    });

    // Allow fainting again after a short grace period
    Future.delayed(const Duration(seconds: 3), () {
      _faintTriggered = false;
    });
  }

  /// Returns the world-pixel position of the nearest recovery building
  /// (pastor house first, then any loaded hospital).
  Vector2? _findNearestRecoveryPoint() {
    final pastorPos = pastorhousePosition.value;

    Vector2? bestPos = pastorPos;
    double bestDist = pastorPos != null
        ? player.position.distanceTo(pastorPos)
        : double.infinity;

    for (final comp in chunkManager.allActiveBuildings) {
      if (comp.buildingModel.type == BuildingType.hospital) {
        final dist = player.position.distanceTo(comp.position);
        if (dist < bestDist) {
          bestDist = dist;
          bestPos = comp.position.clone();
        }
      }
    }

    return bestPos;
  }

  /// Applies a negative spiritual influence around [faintPosition],
  /// darkening previously-liberated cells near the faint location.
  void _applyFaintSetback(Vector2 faintPosition) {
    const cellSize = 32.0;
    final gx = (faintPosition.x / cellSize).floor();
    final gy = (faintPosition.y / cellSize).floor();

    influenceService.applyAoE(
      grid: grid,
      originX: gx,
      originY: gy,
      delta: -0.8,
      radius: 12.0,
      durationType: InfluenceDurationType.permanent,
    );
  }

  /// Faith cost multiplier from hunger: +50% when hunger is critically low
  /// (below [hungerCriticalThreshold]).
  double get hungerFaithCostMultiplier {
    final hungerPct = hunger / progress.maxHunger;
    return hungerPct < hungerCriticalThreshold ? 1.5 : 1.0;
  }

  /// Spend resources (clamped to 0)
  void spendFaith(double amount) {
    if (progress.faithStage.add(amount)) {
      progress.notifyLevelUp();
    }
    faith = (faith - amount).clamp(0.0, progress.maxFaith);
  }

  void spendHealth(double amount) {
    if (progress.healthStage.add(amount)) {
      progress.notifyLevelUp();
    }
    health = (health - amount).clamp(0.0, progress.maxHealth);
  }

  void spendHunger(double amount) {
    if (progress.hungerStage.add(amount)) {
      progress.notifyLevelUp();
    }
    hunger = (hunger - amount).clamp(0.0, progress.maxHunger);
  }

  /// Spend materials (returns false if not enough)
  bool spendMaterials(double amount) {
    if (materials < amount) return false;
    if (progress.materialsStage.add(amount)) {
      progress.notifyLevelUp();
    }
    materials = (materials - amount).clamp(0.0, progress.maxMaterials);
    return true;
  }

  /// Gain resources (clamped to max)
  void gainFaith(double amount) {
    if (progress.faithStage.add(amount)) {
      progress.notifyLevelUp();
    }
    faith = (faith + amount).clamp(0.0, progress.maxFaith);
  }

  void gainHealth(double amount) {
    if (progress.healthStage.add(amount)) {
      progress.notifyLevelUp();
    }
    health = (health + amount).clamp(0.0, progress.maxHealth);
  }

  void gainHunger(double amount) {
    if (progress.hungerStage.add(amount)) {
      progress.notifyLevelUp();
    }
    hunger = (hunger + amount).clamp(0.0, progress.maxHunger);
  }

  void gainMaterials(double amount) {
    if (progress.materialsStage.add(amount)) {
      progress.notifyLevelUp();
    }
    materials = (materials + amount).clamp(0.0, progress.maxMaterials);
  }

  @override
  void onRemove() {
    faithNotifier.dispose();
    healthNotifier.dispose();
    hungerNotifier.dispose();
    materialsNotifier.dispose();
    missionCompleteMessage.dispose();
    conversionToastMessage.dispose();
    isFainting.dispose();
    isWon.dispose();
    wakeupMessage.dispose();
    tutorialService.dispose();
    super.onRemove();
  }

  /// Record a completed prayer combat and check modifier unlocks
  void recordPrayerCombat() {
    progress.recordPrayerCombat();
    missionService.onPrayerCombat();
    tutorialService.onPrayerPerformed();
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
    conversionToastMessage.value = '+1 ✝';
    _checkAndApplyModifiers();
    _checkWinCondition();
  }

  /// Checks whether the win condition is met and fires [isWon] if so.
  ///
  /// Win condition (both must be true simultaneously):
  /// 1. Every generated NPC in the whole city scope is Christian.
  /// 2. Every generated city cell in the whole city scope is positive (> 0).
  ///
  /// We first run a cheap loaded-world pre-check and only then run the global
  /// deterministic city-wide scan.
  void _checkWinCondition() {
    if (_winTriggered) return;

    // Cheap pre-check: if loaded entities already fail, city-wide scan can be skipped.
    final loadedNpcs = chunkManager.allNPCModels;
    if (!loadedNpcs.every((n) => n.isChristian)) return;
    for (final chunk in grid.getLoadedChunks()) {
      for (final cell in chunk.cells.values) {
        if (!_isCellWithinCityScope(cell.x, cell.y)) continue;
        if (cell.spiritualState <= 0) return;
      }
    }

    bool hasAnyNpc = false;

    // Global deterministic scan across the full city scope.
    for (int cy = -_cityScopeChunkRadius; cy <= _cityScopeChunkRadius; cy++) {
      for (int cx = -_cityScopeChunkRadius; cx <= _cityScopeChunkRadius; cx++) {
        final chunk = _chunkForGlobalWinCheck(cx, cy);

        bool chunkTouchesCityScope = false;
        for (final cell in chunk.cells.values) {
          if (!_isCellWithinCityScope(cell.x, cell.y)) continue;
          chunkTouchesCityScope = true;
          if (cell.spiritualState <= 0) return;
        }
        if (!chunkTouchesCityScope) continue;

        final npcs =
            chunkManager.npcRegistry.getNPCsInChunk(cx, cy, chunk: chunk);
        for (final npc in npcs) {
          final npcCellX = (npc.homePosition.x / 32).floor();
          final npcCellY = (npc.homePosition.y / 32).floor();
          if (!_isCellWithinCityScope(npcCellX, npcCellY)) continue;
          hasAnyNpc = true;
          if (!npc.isChristian) return;
        }
      }
    }

    if (!hasAnyNpc) return;

    _winTriggered = true;
    sessionPlayTime = DateTime.now().difference(_sessionStartTime);
    isWon.value = true;
    _log.info(
      'WIN CONDITION MET – all generated city NPCs are Christian and all city cells are positive',
    );
  }

  bool _isCellWithinCityScope(int wx, int wy) {
    final distSq = (wx * wx + wy * wy).toDouble();
    return distSq <= _cityScopeRadiusCellsSquared;
  }

  /// Instantly triggers the win screen without checking the normal win
  /// condition.  Only available in debug builds ([kDebugMode] must be true).
  void debugForceWin() {
    if (!kDebugMode) return;
    if (_winTriggered) return;
    if (!isWorldReady.value) return;
    _winTriggered = true;
    sessionPlayTime = DateTime.now().difference(_sessionStartTime);
    isWon.value = true;
    _log.info('DEBUG – win screen forced via F9 shortcut');
  }

  /// Returns an existing loaded chunk or a temporary generated chunk for
  /// deterministic city-wide win checks.
  CityChunk _chunkForGlobalWinCheck(int chunkX, int chunkY) {
    final loaded = grid.getLoadedChunk(chunkX, chunkY);
    if (loaded != null) return loaded;
    final chunk = CityChunk(chunkX: chunkX, chunkY: chunkY);
    generator.generateChunk(chunk);
    return chunk;
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

  _SprintJoystickComponent _createJoystick() {
    _sprintJoystick = _SprintJoystickComponent(
      onSprintStart: () => player.startSprintJoystick(),
      onSprintEnd:   () => player.stopSprintJoystick(),
      knob: CircleComponent(radius: 20, paint: Paint()..color = Colors.white.withValues(alpha: 0.5)),
      background: CircleComponent(radius: 50, paint: Paint()..color = Colors.white.withValues(alpha: 0.2)),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    return joystick = _sprintJoystick;
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
      _updateHudVisibility();
    }
  }

  // Joystick geometry constants (must match _createJoystick margin + background).
  static const double _kJoystickMarginLeft   = 40.0;
  static const double _kJoystickMarginBottom = 40.0;
  static const double _kJoystickBgRadius     = 50.0;

  /// Game-level tap handler.  Detects double-taps within the joystick area
  /// for desktop / web sprint activation.  This is more reliable than
  /// relying on TapCallbacks propagation through JoystickComponent's child
  /// hierarchy, where mouse events can be inconsistently routed.
  @override
  bool onTapDown(TapDownEvent event) {
    if (!isSpiritualWorld && isLoaded && joystick.parent != null) {
      final jCenter = Vector2(
        _kJoystickMarginLeft + _kJoystickBgRadius,
        camera.viewport.size.y - _kJoystickMarginBottom - _kJoystickBgRadius,
      );
      if ((event.canvasPosition - jCenter).length <= _kJoystickBgRadius + 15) {
        _sprintJoystick.recordTapInteraction();
      }
    }
    return false;
  }
}

class HudButton extends PositionComponent with TapCallbacks {
  final VoidCallback? onDown;
  final VoidCallback? onUp;
  final bool Function()? isActive;
  String icon;
  Color color;
  double opacity = 1.0;
  bool plain = false;
  /// Optional keyboard shortcut label shown as an amber badge (desktop/web only).
  String? keyLabel;
  
  HudButton({
    required this.icon,
    required this.color,
    this.onDown, 
    this.onUp,
    this.isActive,
    this.keyLabel,
    this.plain = false,
    required super.position,
    Vector2? size,
  }) : super(anchor: Anchor.center, size: size ?? Vector2.all(75)); // Einheitliche Größe

  void updateContent(String newIcon, Color newColor) {
    icon = newIcon;
    color = newColor;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0) return;

    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;
    final selected = isActive?.call() ?? false;

    if (!plain) {
      // 1. Schwarzer Rand / Schatten
      canvas.drawCircle(center, radius + 2, Paint()..color = Colors.black.withValues(alpha: 0.5 * opacity));
      
      // 2. Haupt-Button
      final paint = Paint()..color = color.withValues(alpha: color.a * opacity);
      
      // Shadow / Elevation effect
      canvas.drawCircle(center + const Offset(0, 4), radius, Paint()..color = Colors.black.withValues(alpha: 0.3 * opacity));
      
      canvas.drawCircle(center, radius, paint);
      
      if (selected) {
        canvas.drawCircle(center, radius, Paint()
          ..color = Colors.white.withValues(alpha: 0.7 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
      }

      // 3. Glanz-Effekt oben
      final shinePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.3 * opacity), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, shinePaint);
    } else if (selected) {
      // Plain selection marker: subtle glow behind the icon
      canvas.drawCircle(
        center, 
        radius * 0.8, 
        Paint()
          ..color = color.withValues(alpha: 0.4 * opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4),
      );
    }

    // 4. Icon
    final iconStyle = TextStyle(
      fontSize: size.x * (plain ? 0.8 : 0.4), 
      color: Colors.white.withValues(alpha: opacity),
      shadows: plain ? [
        Shadow(
          blurRadius: 10.0,
          color: Colors.black.withValues(alpha: 0.8 * opacity),
          offset: const Offset(2.0, 2.0),
        ),
      ] : null,
    );

    TextPainter(
      text: TextSpan(text: icon, style: iconStyle),
      textDirection: TextDirection.ltr
    )..layout()..paint(canvas, Offset(size.x / 2 - (size.x * (plain ? 0.4 : 0.2)), size.y / 2 - (size.y * (plain ? 0.45 : 0.25))));

    // 5. Keyboard shortcut badge (amber circle, top-right corner, desktop/web only)
    if (!plain && keyLabel != null && _shouldShowKeyHints()) {
      const badgeRadius = 11.0;
      final badgeCenter = Offset(size.x - badgeRadius + 2, badgeRadius - 2);
      canvas.drawCircle(badgeCenter, badgeRadius, Paint()..color = const Color(0xFFFFA000).withValues(alpha: opacity));
      TextPainter(
        text: TextSpan(
          text: keyLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black.withValues(alpha: opacity),
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
  void onTapDown(TapDownEvent event) {
    if (opacity > 0) onDown?.call();
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (opacity > 0) onUp?.call();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    if (opacity > 0) onUp?.call();
  }
}

/// A [JoystickComponent] that detects a "double-drag" gesture (two successive
/// drag starts within [_kDoubleTapWindowMs] ms) and fires [onSprintStart].
/// Sprint ends automatically when the drag is released.
///
/// On desktop/web a second source of interactions comes from
/// [SpiritWorldGame.onTapDown], which calls [recordTapInteraction] when the
/// user double-clicks inside the joystick area.  A 100 ms dedup guard
/// prevents [onDragStart] and the game-level tap from counting the same
/// physical pointer-down twice.
class _SprintJoystickComponent extends JoystickComponent {
  final VoidCallback onSprintStart;
  final VoidCallback onSprintEnd;

  static const int _kDoubleTapWindowMs  = 400;
  static const int _kSameEventDedupeMs  = 100;

  int _lastInteractionMs = 0;
  bool _sprinting = false;

  _SprintJoystickComponent({
    required this.onSprintStart,
    required this.onSprintEnd,
    required super.knob,
    required super.background,
    required super.margin,
  });

  /// Called by [SpiritWorldGame.onTapDown] when a tap lands within the joystick
  /// area.  Tracks double-taps for sprint activation on desktop / web.
  void recordTapInteraction() => _recordInteraction();

  /// Record an interaction start.  Returns true when sprint is activated.
  bool _recordInteraction() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = _lastInteractionMs > 0 ? now - _lastInteractionMs : 99999;

    if (!_sprinting &&
        elapsed > _kSameEventDedupeMs &&
        elapsed < _kDoubleTapWindowMs) {
      _sprinting = true;
      onSprintStart();
      return true;
    }
    if (elapsed > _kSameEventDedupeMs) {
      _lastInteractionMs = now;
    }
    return false;
  }

  // ── Mobile / mouse drag: two rapid drag starts ────────────────────────────
  @override
  bool onDragStart(DragStartEvent event) {
    _recordInteraction();
    return super.onDragStart(event);
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    _lastInteractionMs = DateTime.now().millisecondsSinceEpoch;
    if (_sprinting) {
      _sprinting = false;
      onSprintEnd();
    }
    return super.onDragEnd(event);
  }

  @override
  bool onDragCancel(DragCancelEvent event) {
    _lastInteractionMs = DateTime.now().millisecondsSinceEpoch;
    if (_sprinting) {
      _sprinting = false;
      onSprintEnd();
    }
    return super.onDragCancel(event);
  }
}
