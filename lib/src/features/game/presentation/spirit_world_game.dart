import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
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
import '../domain/models/cell_object.dart';
import 'components/building_component.dart';
import 'components/chunk_manager.dart';
import 'components/player_component.dart';
import 'components/radial_menu.dart';
import 'components/prayer_hud_component.dart';
import 'components/spiritual_dynamics_system.dart';
import 'game_screen.dart';

class SpiritWorldGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection, TapCallbacks {
  final _log = Logger('SpiritWorldGame');

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

  RadialMenu? _currentMenu;
  bool isSpiritualWorld = false;
  final ValueNotifier<bool> isWorldReady = ValueNotifier<bool>(false);

  // Progress & Modifiers
  late final PlayerProgress progress;
  late final ModifierManager modifiers;

  // Ressourcen
  double faith = 100.0;
  double health = 100.0;
  double hunger = 80.0;
  double materials = 40.0;

  static const double maxFaith = 100.0;
  static const double maxHealth = 100.0;
  static const double maxHunger = 100.0;
  static const double maxMaterials = 100.0;
  static const double worldToggleCost = 10.0;

  /// Number of daemons spawned around the player on spiritual-world entry.
  static const int _entryDaemonsEasy   = 3;
  static const int _entryDaemonsNormal = 5;
  static const int _entryDaemonsHard   = 8;

  // Passive resource timers
  double _hungerDrainTimer = 0.0;
  static const double hungerDrainInterval = 30.0; // drain 1 hunger every 30 seconds
  static const double hungerDrainAmount = 1.0;
  static const double healthFromHungerThreshold = 20.0;

  Interactable? _nearestInteractable;
  Interactable? get nearestInteractable => _nearestInteractable;
  static const double interactionRange = 60.0;
  
  GameDialogData? activeDialog;

  /// Active building interior session (null when no building is open).
  GameBuildingData? activeBuildingData;

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
    final savedState = gameSave?.gameState;
    final hasSavedState = savedState != null && savedState.isNotEmpty;
    if (hasSavedState) {
      _applyPlayerState(savedState!);
      _savedCellStates = _parseSavedCellStates(savedState);
      _savedNPCStates  = _parseSavedNPCStates(savedState);
    }

    player = PlayerComponent(joystick: _createJoystick());
    // Start in the suburbs so the player encounters residential streets first.
    // pixel (7000, 7000) → grid cell (floor(7000/32), floor(7000/32)) = (218, 218).
    // The pastor's house is placed at grid cell (220, 222) — just a few cells
    // away — see SpecialBuildingRegistry._pastorHouseX/Y.
    player.position = hasSavedState
        ? Vector2(
            (savedState!['playerX'] as num).toDouble(),
            (savedState['playerY'] as num).toDouble(),
          )
        : Vector2(7000, 7000);
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

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = player.position.clone();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (hasSavedState && savedState!['isSpiritualWorld'] == true) {
      isSpiritualWorld = true;
      _updateButtonStyles();
    }
    isWorldReady.value = true;
    _log.info('--- GAME READY ---');
  }

  // ── Save / Restore helpers ────────────────────────────────────────────────

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
  /// Restores faith, conversation counts and conversion status so NPC
  /// relationships are preserved across sessions.
  void applySavedNPCState(NPCModel npc) {
    final saved = _savedNPCStates?[npc.id];
    if (saved == null) return;
    npc.faith             = (saved['faith']   as num?)?.toDouble() ?? npc.faith;
    npc.conversationCount = saved['conv']     as int?  ?? npc.conversationCount;
    npc.prayerCount       = saved['pray']     as int?  ?? npc.prayerCount;
    npc.counselingCount   = saved['counsel']  as int?  ?? npc.counselingCount;
    npc.isConverted       = saved['converted'] as bool? ?? npc.isConverted;
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
    final Map<String, Map<String, dynamic>> npcStates = {};
    for (final npc in chunkManager.allNPCModels) {
      if (npc.faith != 0.0 ||
          npc.conversationCount != 0 ||
          npc.prayerCount != 0 ||
          npc.counselingCount != 0 ||
          npc.isConverted) {
        npcStates[npc.id] = {
          'faith': npc.faith,
          if (npc.conversationCount != 0) 'conv':      npc.conversationCount,
          if (npc.prayerCount       != 0) 'pray':      npc.prayerCount,
          if (npc.counselingCount   != 0) 'counsel':   npc.counselingCount,
          if (npc.isConverted)            'converted': true,
        };
      }
    }

    return {
      'faith':            faith,
      'health':           health,
      'hunger':           hunger,
      'materials':        materials,
      'playerX':          player.position.x,
      'playerY':          player.position.y,
      'isSpiritualWorld': isSpiritualWorld,
      'cells':            cellStates,
      'npcs':             npcStates,
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
      RadialAction(label: '👀', icon: Icons.search, onSelect: () => _log.info('Looking around')),
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
    // 'prayBusiness' also nudges the cell underneath the player positively
    if (actionType == 'prayBusiness') {
      _nudgeCellUnderPlayer(0.02);
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

  void closeMenu() { _currentMenu?.removeFromParent(); _currentMenu = null; }

  @override
  void update(double dt) {
    super.update(dt);
    if (_currentMenu != null) _currentMenu!.position = player.position;
    if (isWorldReady.value && !paused) {
      _updateCamera(dt);
      _updateNearestInteractable();
      _updatePassiveResources(dt);
    }
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

  /// Record a completed prayer combat and check modifier unlocks
  void recordPrayerCombat() {
    progress.recordPrayerCombat();
    _checkAndApplyModifiers();
  }

  /// Record a completed conversation
  void recordConversation() {
    progress.recordConversation();
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
      position: Vector2(size.x - 80, size.y - 80)
    );
    await camera.viewport.add(actionButton);

    worldToggleButton = HudButton(
      icon: '🙏',
      color: Colors.purple.withValues(alpha: 0.6),
      onDown: toggleWorld,
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
  
  HudButton({
    required this.icon,
    required this.color,
    this.onDown, 
    this.onUp, 
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
  }

  @override
  void onTapDown(TapDownEvent event) => onDown?.call();

  @override
  void onTapUp(TapUpEvent event) => onUp?.call();

  @override
  void onTapCancel(TapCancelEvent event) => onUp?.call();
}
