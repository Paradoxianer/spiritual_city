import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' show Random, min;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show compute, ValueListenable, ValueNotifier, kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../../core/audio/game_sound.dart';
import '../../../core/utils/seed_manager.dart';
import '../../../core/utils/stable_hash.dart';
import '../../../features/menu/domain/models/difficulty.dart';
import '../../../features/menu/domain/models/game_save.dart';
import '../domain/actions/building_actions.dart';
import '../domain/actions/game_action.dart';
import '../domain/actions/npc_actions.dart';
import '../domain/interior/interior_layout.dart';
import '../domain/city_generation/city_overview.dart';
import '../domain/services/faith_calculator_service.dart';
import '../domain/models/daemon_model.dart';
import '../domain/models/day_stats.dart';
import '../domain/models/quarter.dart';
import 'components/cell_component.dart';
import 'components/daemon_component.dart';
import 'components/character_sprites.dart';
import 'components/kenney_city_renderer.dart';
import 'components/interior/interior_renderer.dart';
import 'components/interior/interior_world.dart';
import 'components/stronghold_component.dart';
import '../domain/models/skills.dart';
import '../domain/services/combat_abilities.dart';
import '../domain/services/daemon_combat_rules.dart';
import '../domain/services/learning_service.dart';
import '../domain/actions/practice.dart';
import '../domain/actions/resource.dart';
import '../domain/city_generator.dart';
import '../domain/models/building_model.dart';
import '../domain/models/city_chunk.dart';
import '../domain/models/city_grid.dart';
import '../domain/models/interactions.dart';
import '../domain/models/mission_model.dart';
import '../domain/models/modifier_manager.dart';
import '../domain/models/npc_model.dart';
import '../domain/models/player_progress.dart';
import '../domain/models/player_resources.dart';
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

part 'game/learning_control.dart';
part 'game/quarters.dart';
part 'game/save_state.dart';
part 'game/overlay_control.dart';
part 'game/building_actions.dart';
part 'game/interior_control.dart';
part 'game/mission_tracking.dart';

/// Whether keyboard shortcut hint badges should be shown on HUD buttons.
/// True on desktop (Windows / Linux / macOS) and web; false on mobile.
bool _shouldShowKeyHints() {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

class SpiritWorldGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection, TapCallbacks
    implements ResourceWallet {
  final _log = Logger('SpiritWorldGame');

  // ── Spiritual-world button dock constants (Issue #174) ────────────────────

  /// Distance of the action/world-toggle button centers from the left/right
  /// screen edge; both buttons use the default [HudButton] size below.
  static const double _sideButtonCenterOffset = 42.0;

  /// Size (both dimensions) of the action and world-toggle buttons.
  static const double _sideButtonSize = 75.0;

  /// Mode-button size while not selected / while actively selected. The
  /// selected size is what must be kept clear of the side buttons, since any
  /// mode button can become the selected (larger) one at any time.
  static const double _modeButtonSizeUnselected = 45.0;
  static const double _modeButtonSizeSelected = 60.0;

  /// Minimum gap kept between the edges of two touch targets (see
  /// `docs/game_design/mobile_ui.md` §2).
  static const double _touchTargetGap = 8.0;

  /// Minimum pixel gap between adjacent mode-button centers on very small
  /// screens.  25 px keeps buttons selectable even when spacing is compressed.
  static const double _minModeButtonSpacing = 25.0;

  /// Maximum pixel gap between adjacent mode-button centers on large screens.
  /// 65 px matches the legacy fixed 60 px spacing with a small visual margin.
  static const double _maxModeButtonSpacing = 65.0;

  /// Horizontal margin reserved for the action/world-toggle buttons before
  /// the mode-button row may start.
  ///
  /// Derived from actual button geometry so a selected mode button (the
  /// largest state, and the one that sits closest to the edge) never reaches
  /// the action/world-toggle button, with [_touchTargetGap] to spare:
  /// `sideButtonCenterOffset + sideButtonHalfWidth + gap + selectedModeButtonHalfWidth`.
  ///
  /// Was a bare `90`, which only worked out for the *unselected* (45 px)
  /// mode-button size.  Whenever the row's natural spacing landed between
  /// the min/max clamp below – the common case on mid-size screens, since
  /// the row is centred so its edge sits exactly at the margin in that case –
  /// mode button 0 (Liberation, the *default* starting mode – see
  /// `PlayerComponent._currentMode`) sat with its edge inside the action
  /// button the moment the spiritual world opened, matching the reported
  /// "hit the wrong button while fighting" symptom.
  static const double _modeRowMargin = _sideButtonCenterOffset +
      _sideButtonSize / 2 +
      _touchTargetGap +
      _modeButtonSizeSelected / 2;

  // ── Save-data schema versioning ───────────────────────────────────────────
  /// Increment this constant whenever the structure of [captureGameState]
  /// changes in a way that is incompatible with older saved data.
  ///
  /// Migration logic lives in [_migrateGameState]:
  ///   • version 0 (missing key) → version 1: initial schema.
  ///   • version 1 → version 2: NPC counters unified into interactionCount
  ///     ('conv' key); separate 'pray' and 'counsel' keys removed.
  ///   • version 2 → version 3: Added PlayerProgress and CombatProfile persistence.
  static const int kSaveDataVersion = 4;

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
  RadialMenu? _currentMenu;
  bool isSpiritualWorld = false;

  /// System bars, notch and gesture zones (#190): HUD buttons and the
  /// joystick stay clear of them. Set by the GameScreen from MediaQuery.
  EdgeInsets safeInsets = EdgeInsets.zero;

  void setSafeInsets(EdgeInsets insets) {
    if (insets == safeInsets) return;
    safeInsets = insets;
    if (!isLoaded || !isWorldReady.value) return;
    joystick.margin = EdgeInsets.only(
      left: _kJoystickMarginLeft + insets.left,
      bottom: _kJoystickMarginBottom + insets.bottom,
    );
    if (joystick.isMounted) joystick.onGameResize(size);
    _updateHudVisibility();
  }

  /// The building the pastor is inside right now (third layer), if any.
  InteriorWorld? interior;

  /// True while inside a building (drives the Flutter interior bar).
  final ValueNotifier<bool> interiorActive = ValueNotifier(false);
  double _cityZoom = 1.0;
  String _interiorButtonEmoji = '';
  double _ambienceTimer = 0;
  double _daemonCryTimer = 2;
  final Random _cryRandom = Random();

  /// A daemon close by cries now and then – louder the nearer it is.
  void _daemonCry(double dt) {
    _daemonCryTimer -= dt;
    if (_daemonCryTimer > 0) return;
    _daemonCryTimer = 3 + _cryRandom.nextDouble() * 4;
    const reach = 9 * CellComponent.cellSize;
    var best = reach;
    for (final d in world.children.whereType<DaemonComponent>()) {
      final dist = d.position.distanceTo(player.position);
      if (dist < best) best = dist;
    }
    if (best >= reach) return;
    GameSound.play(Sfx.daemonNear, volume: 0.15 + 0.45 * (1 - best / reach));
  }

  // ── City map (whole city, playtest 2026-10-18) ────────────────────────────

  CityOverview? cityOverview;
  final ValueNotifier<ui.Image?> cityMapImage = ValueNotifier(null);
  bool _cityMapLoading = false;

  /// Computes the city plan once per game, off the UI thread.
  Future<void> loadCityMap() async {
    if (_cityMapLoading || cityMapImage.value != null) return;
    _cityMapLoading = true;
    try {
      final o = await compute(CityOverview.build, seedManager.seed);
      cityOverview = o;
      ui.decodeImageFromPixels(o.pixels, CityOverview.size, CityOverview.size,
          ui.PixelFormat.rgba8888, (img) => cityMapImage.value = img);
    } catch (e) {
      _log.warning('City map failed: $e');
      _cityMapLoading = false;
    }
  }

  /// Tutorial step from the save (resumed instead of starting over).
  TutorialStep? _savedTutorialStep;

  /// Where the current tutorial step wants the pastor to go, if anywhere:
  /// the pastor house, or the nearest person not yet a Christian.
  Vector2? get tutorialTargetPosition {
    switch (tutorialService.currentStep) {
      case TutorialStep.goHome || TutorialStep.readBible || TutorialStep.mission:
        return pastorhousePosition.value;
      case TutorialStep.talk || TutorialStep.prayPerson:
        Vector2? best;
        var bestD = double.infinity;
        for (final n in chunkManager.allActiveNPCs) {
          if (n.model.isChristian) continue;
          final d = n.position.distanceToSquared(player.position);
          if (d < bestD) {
            bestD = d;
            best = n.position;
          }
        }
        return best;
      default:
        return null;
    }
  }

  /// Until the first daemon is beaten in the tutorial, the invisible world
  /// holds just one weak daemon (see SpiritualDynamicsSystem).
  bool get tutorialCalmSpirit => switch (tutorialService.currentStep) {
        TutorialStep.enterSpirit || TutorialStep.liberate || TutorialStep.defeatDaemon => true,
        _ => false,
      };

  /// What to do right here for the tutorial (playtest: a new player did
  /// not know to walk to the house and press 🖐️): inside, the station or
  /// the door to go to; outside, 🖐️ once the target is in reach.
  String? get tutorialHint {
    final step = tutorialService.currentStep;
    if (step == null || step.isInfo) return null;
    final room = interior;
    if (room != null) {
      final g = room.guide;
      if (g == null) return null;
      return g == InteriorWorld.guideDoor ? '🚪' : room.stationEmoji[g];
    }
    return _tutorialPressHere ? '🖐️' : null;
  }

  /// The pastor stands where the step's action button press is due.
  bool get _tutorialPressHere {
    final near = _nearestInteractable;
    switch (tutorialService.currentStep) {
      case TutorialStep.goHome || TutorialStep.readBible || TutorialStep.mission:
        return near is BuildingComponent && near.buildingModel.isHomebase && !isSpiritualWorld;
      case TutorialStep.talk || TutorialStep.prayPerson:
        return near is NPCComponent && !isSpiritualWorld;
      default:
        return false;
    }
  }

  /// The button the current tutorial step is about pulses golden; inside
  /// a building the station (or the door) to go to pulses cyan.
  void _updateTutorialHighlights() {
    final step = tutorialService.currentStep;
    final room = interior;
    if (room != null) {
      room.guide = switch (step) {
        null || TutorialStep.quarter || TutorialStep.completed => null,
        TutorialStep.readBible when room.building.isHomebase => 'readBible',
        TutorialStep.mission when room.building.isHomebase => 'missions',
        (TutorialStep.talk || TutorialStep.prayPerson) when room.residents.isNotEmpty &&
            !room.building.isHomebase => null,
        _ => InteriorWorld.guideDoor,
      };
      final t = room.target;
      actionButton.highlight = room.guide != null &&
          switch (t) {
            StationTarget() => t.action == room.guide,
            DoorTarget() => room.guide == InteriorWorld.guideDoor,
            _ => false,
          };
      worldToggleButton.highlight = false;
      return;
    }
    actionButton.highlight = _tutorialPressHere ||
        isSpiritualWorld && (step == TutorialStep.liberate || step == TutorialStep.defeatDaemon);
    worldToggleButton.highlight = (step == TutorialStep.enterSpirit && !isSpiritualWorld) ||
        (step == TutorialStep.returnCity && isSpiritualWorld);
  }

  /// 📍 Accepted mission target (see GameMissionTracking).
  final ValueNotifier<String?> trackedMission = ValueNotifier(null);

  /// The city map sits above the HUD (not a Flame overlay), so nothing
  /// covers its close button.
  final ValueNotifier<bool> cityMapOpen = ValueNotifier(false);

  void openCityMap() {
    if (cityMapOpen.value) return;
    cityMapOpen.value = true;
    paused = true;
  }

  void closeCityMap() {
    if (!cityMapOpen.value) return;
    cityMapOpen.value = false;
    paused = false;
  }

  /// Background sound for where the pastor is.
  Ambience _ambienceHere() {
    final inside = interior;
    if (inside != null) {
      return switch (inside.building.type) {
        BuildingType.house || BuildingType.apartment || BuildingType.pastorHouse => Ambience.home,
        BuildingType.church || BuildingType.cathedral || BuildingType.cemetery => Ambience.church,
        _ => Ambience.hall,
      };
    }
    return isSpiritualWorld ? Ambience.spirit : Ambience.city;
  }
  final ValueNotifier<bool> isWorldReady = ValueNotifier<bool>(false);

  // Progress & Modifiers
  late final PlayerProgress progress;
  late final ModifierManager modifiers;

  /// Faith, health, hunger, materials (PlayerResources). The getters below
  /// keep the existing call sites short.
  late final PlayerResources resources = PlayerResources(() => progress);

  ValueNotifier<double> get faithNotifier => resources.faithNotifier;
  ValueNotifier<double> get healthNotifier => resources.healthNotifier;
  ValueNotifier<double> get hungerNotifier => resources.hungerNotifier;
  ValueNotifier<double> get materialsNotifier => resources.materialsNotifier;

  double get faith => resources.faith;
  set faith(double v) => resources.faith = v;
  double get health => resources.health;
  set health(double v) => resources.health = v;
  double get hunger => resources.hunger;
  set hunger(double v) => resources.hunger = v;
  double get materials => resources.materials;
  set materials(double v) => resources.materials = v;

  @override
  double amountOf(Resource r) => resources.amountOf(r);

  void spendFaith(double amount) => resources.spendFaith(amount);
  void spendHealth(double amount) => resources.spendHealth(amount);
  void spendHunger(double amount) => resources.spendHunger(amount);
  bool spendMaterials(double amount) => resources.spendMaterials(amount);
  void gainFaith(double amount) => resources.gainFaith(amount);
  void gainHealth(double amount) => resources.gainHealth(amount);
  void gainHunger(double amount) => resources.gainHunger(amount);
  void gainMaterials(double amount) => resources.gainMaterials(amount);

  static const double worldToggleCost = 10.0;

  // ── Daemons (#178) ────────────────────────────────────────────────────────

  /// Unlocked combat abilities per mode (0–2, #179).
  Map<PrayerMode, int> get combatAbilityTiers => {
        for (final m in PrayerMode.values)
          m: CombatAbilities.tier(progress.combatProfile.getFor(m)),
      };

  /// Tier of new spawns, fixed when entering the spirit world.
  int daemonTier = 1;

  /// 👁️ Discernment of spirits learned: daemon kinds are shown.
  bool get canDiscernSpirits => progress.skills.has(Skill.discernment);

  /// A 👁️ possessor can only be fought once its host was cared for in the
  /// real world (Mark 9:29 – prayer *and* care, npc_influence.md).
  bool isPossessorVulnerable(DaemonModel daemon) {
    final host = daemon.hostNpcId;
    if (host == null) return true;
    final npc = chunkManager.findNpcModel(host);
    return npc == null || npc.possessionWeakened;
  }

  /// Insight for freeing a possessed person.
  static const double possessionReleaseInsight = 0.5;

  /// Faith a person gains when freed from possession.
  static const double possessionReleaseFaith = 40.0;

  /// Both worlds came together: the possessor was beaten after the person
  /// was cared for. The person is free and much more open (#180).
  void _releaseFromPossession(NPCModel npc) {
    npc.possessed = false;
    npc.possessionWeakened = false;
    npc.applyInfluence(possessionReleaseFaith);
    progress.addInsight(possessionReleaseInsight);
    final comp = chunkManager.findNpcComponent(npc.id);
    if (comp != null) {
      _brightenspiritualAreaAroundPosition(comp.position, radius: 4, amount: 0.3);
    }
    _toast('👁️➡️🕊️ ${npc.name.split(' ').first}');
  }

  // ── Neighbourhoods (§3.3) ─────────────────────────────────────────────────

  /// ➖🍞 Fasting: prayer waves cost less until leaving the invisible world.
  bool isFasting = false;
  static const double fastingWaveCostFactor = 0.6;

  /// 🙏🏠 Intercession today: knock chance bonus and NPC gain factor.
  static const double intercessionAccessBonus = 0.3;
  static const double intercessionGainFactor = 1.5;

  /// ✨ Room find rewards (walkable interiors).
  static const double roomFindInsight = 0.3;
  static const double roomFindMaterials = 6.0;

  /// 📢 Preaching radius in cells.
  static const int preachRadiusCells = 8;

  /// Internal day counter: sleeping starts a new one. Not shown in the UI
  /// (playtest: visible days added too much complexity) – it only paces
  /// once-per-sleep actions (🙏🏠, 📢, 🩹) and the church yield.
  DayStats get dayStats => progress.dayStats;

  /// Sleeping in the pastor house: the church's yield (#181) arrives, then a
  /// new day starts – no real-time ticking, nothing is lost while paused.
  void endDay() {
    // The 😴 lullaby (Sfx.sleep) is played by the sleep action itself.
    final y = progress.church.dailyYield();
    if (y.faith > 0) gainFaith(y.faith);
    if (y.materials > 0) gainMaterials(y.materials);
    if (y.insight > 0) progress.addInsight(y.insight);
    dayStats.nextDay();
    lootPickupMessage.value = y.isEmpty ? '😴 → ☀️' : '😴 → ☀️  ⛪ ${y.label}';
  }

  /// Church overview (pastor house ⛪👥).
  void openChurchOverview() => overlays.add('ChurchOverlay');
  void closeChurchOverview() => overlays.remove('ChurchOverlay');

  /// Status of the neighbourhood the pastor is in.
  final ValueNotifier<QuarterStatus?> quarterStatus = ValueNotifier(null);
  double _quarterTimer = 0.0;

  /// Overall progress for the second HUD bar (🌐 prayed free / 🏙️ ✝️).
  final ValueNotifier<CityProgress?> cityProgress = ValueNotifier(null);

  /// [_savedCellStates] per chunk, counted once (see [Liberation.savedByChunk]).
  Map<String, Tally>? _savedChunkTallies;

  // ── Learning missions (§3.9) ──────────────────────────────────────────────

  /// Lesson card currently shown (LessonOverlay), if any.
  Lesson? activeLessonOffer;

  /// Bumped whenever the active lesson changes (HUD chip listens).
  final ValueNotifier<int> lessonNotifier = ValueNotifier(0);

  /// The Slow → Drain → Rebuke chain completed on a daemon.
  void onDaemonChain() {
    GameSound.play(Sfx.chain);
    lootPickupMessage.value = '⏳🪫🫸⚡';
  }

  /// A daemon was defeated by prayer (not dissolved on its own).
  void onDaemonKilled(DaemonModel daemon, {PrayerMode? mode}) {
    dayStats.daemonsDefeated++;
    tutorialService.onDaemonKilled();
    GameSound.play(Sfx.daemonDefeated, volume: 0.4);
    recordLessonTask(LessonTask.defeatDaemons);
    if (mode != null) recordLessonTask(LessonTask.defeatWith(mode));
    if (daemon.hostNpcId != null) {
      final npc = chunkManager.findNpcModel(daemon.hostNpcId!);
      if (npc != null && npc.possessionWeakened) _releaseFromPossession(npc);
    }
  }

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
  // Issue #176: was `22`, computed as `ceil(690 / 32)` – but CityChunk.chunkSize
  // is 16, not 32, so the scan only ever covered a ±352-cell box while the
  // scope check itself (`_isCellWithinCityScope`) tested against the full
  // 690-cell radius.  Chunks between ±352 and ±690 were never visited by the
  // global scan, so cells/NPCs out there could never block (or complete) the
  // win condition.
  static const int _cityScopeChunkRadius = 44; // ceil(690 / CityChunk.chunkSize)

  /// Chunks generated purely for the global win-check scan (Issue #176), kept
  /// so repeated scans (the check re-runs on every conversion once the
  /// player is close to winning) don't regenerate the same never-visited
  /// chunk's terrain from scratch each time.  Entries become stale once a
  /// chunk is actually loaded through normal play, but `_chunkForGlobalWinCheck`
  /// always prefers the live chunk from [grid] first, so a stale entry here is
  /// simply never read again for that key.
  final Map<String, CityChunk> _winCheckChunkCache = {};

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
    GameSound.preload();
    await CharacterSprites.load(images);
    await KenneyCityRenderer.load(images);
    await InteriorRenderer.load(images);
    try {
      _log.info('--- INITIALIZING GAME ---');
      // ── Restore save state ──────────────────────────────────────────────────
      final rawState = gameSave?.gameState;
      // Run migration so the rest of onLoad always sees the current schema.
      final savedState = rawState != null && rawState.isNotEmpty
          ? _migrateGameState(Map<String, dynamic>.from(rawState))
          : null;
      final hasSavedState = savedState != null && savedState.isNotEmpty;

      final worldSeed = SeedManager.resolveWorldSeed(
        savedWorldSeed: (savedState?['worldSeed'] as num?)?.toInt(),
        hasSavedProgress: hasSavedState,
        saveSeed: gameSave?.seed,
      );
      _log.info('World seed: $worldSeed');
      seedManager = SeedManager(worldSeed);
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

      chunkManager = ChunkManager(
        grid: grid,
        generator: generator,
        target: player,
        seed: seedManager.seed,
      );
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
          // Placeholder size/position – _updateHudVisibility() (called once
          // the world is ready) immediately lays out the real dock row.
          size: Vector2.all(_modeButtonSizeUnselected),
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
      final pending = safeInsets;
      safeInsets = EdgeInsets.zero;
      setSafeInsets(pending);
      _sessionStartTime = DateTime.now();
      loadCityMap(); // ready before the first tap on the minimap
      _log.info(
        '--- GAME READY --- '
        'pastorhousePos=${pastorhousePosition.value} '
        'playerPos=${player.position}',
      );

      // Start tutorial for new players (or players who haven't finished it yet).
      if (!tutorialService.isTutorialCompleted) {
        // Short delay so the loading overlay has faded before the tutorial appears.
        Future.delayed(const Duration(milliseconds: 600),
            () => tutorialService.startTutorial(at: _savedTutorialStep));
      }

      // Assign starting missions to NPCs / buildings in the spawn chunk.
      // Run after a short delay so chunk NPCs/buildings are all registered.
      Future.delayed(const Duration(milliseconds: 500), _tryAssignStartMissions);
    } catch (e, stack) {
      _log.severe('CRITICAL ERROR DURING GAME LOAD: $e', e, stack);
      isWorldReady.value = true;
    }
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

  // ── Known Christian count (Issue #170) ─────────────────────────────────────

  /// Number of converted NPCs the game currently *knows about*: every
  /// currently-active NPC (its chunk has been loaded this session) plus
  /// every converted NPC recorded in the save for a chunk that has **not**
  /// been loaded this session yet.
  ///
  /// Before this fix, the HUD and win-screen counted only
  /// `chunkManager.allNPCModels` – NPCs are created lazily the first time
  /// their chunk is loaded (see [ChunkManager._loadChunk]), so right after
  /// loading a save the count only reflected the handful of chunks around
  /// the player's spawn point, not the Christians made in previous sessions
  /// elsewhere in the city.  This is still not the *true* city-wide count
  /// (that would require generating every chunk – the expensive path
  /// `_checkWinCondition` only takes once the game is nearly won, see
  /// #176); it is the best count obtainable without that cost.
  int get knownChristianCount => knownNpcCounts.converted;

  /// Merged live+saved (converted, total) NPC counts – see
  /// [knownChristianCount].  Returned together so UI that shows "X / Y"
  /// (e.g. the win screen) never shows a converted count exceeding the
  /// total, which independently recomputing each half could risk.
  ({int converted, int total}) get knownNpcCounts {
    final activeIds = <String>{};
    int converted = 0;
    for (final npc in chunkManager.allNPCModels) {
      activeIds.add(npc.id);
      if (npc.isConverted) converted++;
    }
    int total = activeIds.length;
    final saved = _savedNPCStates;
    if (saved != null) {
      for (final entry in saved.entries) {
        if (activeIds.contains(entry.key)) continue; // already counted live
        total++;
        if (entry.value['converted'] == true) converted++;
      }
    }
    return (converted: converted, total: total);
  }

  // ── State capture (called when the player saves and quits) ────────────────

  void toggleWorld() {
    if (interior != null) return; // no world switch inside a building
    if (!isSpiritualWorld && faith < worldToggleCost) {
      // Say why nothing happens: entering costs faith (playtest).
      GameSound.play(Sfx.denied, volume: 0.5);
      _toast('🙏 ${faith.floor()}/${worldToggleCost.round()} ❌');
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
      isFasting = false; // the fast ends with the battle
      tutorialService.onReturnedToCity();
    }

    // Daemon strength follows the player's power, delayed by the grace
    // period after an upgrade (#178).
    if (isSpiritualWorld) {
      daemonTier = DaemonCombatRules.tierFor(
          progress.onSpiritWorldEntered(extraPower: awakeningPower));
      _updateQuarter();
    }

    // Immediately spawn daemons around the player when entering the spiritual
    // world so they are visible from the first moment (difficulty-scaled count).
    if (isSpiritualWorld) {
      final entryCount = switch (difficulty) {
        Difficulty.easy   => _entryDaemonsEasy,
        Difficulty.normal => _entryDaemonsNormal,
        Difficulty.hard   => _entryDaemonsHard,
      };
      if (tutorialCalmSpirit) {
        spiritualDynamics.spawnTutorialDaemon();
      } else {
        spiritualDynamics.spawnDaemonsAroundPlayer(entryCount);
      }
    }
  }

  void handleActionDown() {
    if (isSpiritualWorld) {
      player.startChargingIntensity();
    }
  }

  void handleActionUp() {
    if (interior != null && activeDialog == null) {
      interiorInteract();
      return;
    }
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
    // Keep every button out of the system bars and gesture zones (#190).
    final inL = safeInsets.left, inR = safeInsets.right, inB = safeInsets.bottom;
    final bottomY = size.y - 80 - inB;
    if (interior != null) {
      if (joystick.parent == null) camera.viewport.add(joystick);
      actionButton.position = Vector2(size.x - 80 - inR, bottomY);
      actionButton.keyLabel = 'E';
      worldToggleButton.position = Vector2(-1000, -1000);
      for (final btn in modeButtons) {
        btn.opacity = 0.0;
      }
      return;
    }
    if (isSpiritualWorld) {
      if (joystick.parent != null) joystick.removeFromParent();

      // ── Spiritual-world dock layout (Issue #174) ────────────────────────────
      // Lay all bottom buttons in a single non-overlapping row:
      //   [combat btn]  [── mode buttons ──]  [return btn]
      //
      // The two side buttons (size _sideButtonSize) are anchored at
      // x = _sideButtonCenterOffset (left) and x = size.x - _sideButtonCenterOffset
      // (right).  Mode buttons are distributed evenly in the gap between
      // x = _modeRowMargin and x = size.x - _modeRowMargin – sized so even a
      // *selected* mode button can never reach the side buttons (see the
      // constant's doc comment for why the old fixed 90 px wasn't enough).

      actionButton.position = Vector2(_sideButtonCenterOffset + inL, bottomY);
      actionButton.keyLabel = 'Space';

      worldToggleButton.position =
          Vector2(size.x - _sideButtonCenterOffset - inR, bottomY);

      // Only learned modes are shown (⚔️ lesson unlocks all but Liberation).
      final shown = [
        for (int i = 0; i < modeButtons.length; i++)
          if (player.canUseMode(PrayerMode.values[i])) i,
      ];
      for (int i = 0; i < modeButtons.length; i++) {
        if (shown.contains(i)) continue;
        modeButtons[i].opacity = 0.0;
        modeButtons[i].position = Vector2(-1000, -1000);
      }
      final n = shown.length;
      if (n > 0) {
        // Available width between the mode-row margins.  Clamp individual
        // spacing so buttons never overlap each other even on very small
        // screens; on screens narrower than the row genuinely needs, spacing
        // bottoms out at _minModeButtonSpacing and the row may symmetrically
        // spill past the margin rather than overlap on one side only.
        final available = size.x - _modeRowMargin * 2 - inL - inR;
        final spacing = n > 1 ? (available / (n - 1)).clamp(_minModeButtonSpacing, _maxModeButtonSpacing) : 0.0;
        final totalModeWidth = (n - 1) * spacing;
        final modeStartX = inL + (size.x - inL - inR - totalModeWidth) / 2;

        for (int j = 0; j < n; j++) {
          final i = shown[j];
          final btn = modeButtons[i];
          btn.opacity = 1.0;
          final isSelected = player.currentMode == PrayerMode.values[i];
          btn.size = Vector2.all(
              isSelected ? _modeButtonSizeSelected : _modeButtonSizeUnselected);
          btn.position = Vector2(
            modeStartX + j * spacing,
            isSelected ? bottomY - 8.0 : bottomY,
          );
          btn.keyLabel = '${i + 1}';
        }
      }
    } else {
      if (joystick.parent == null) camera.viewport.add(joystick);
      // Normal-world layout: interaction button bottom-right, toggle left of it.
      actionButton.position = Vector2(size.x - 80 - inR, bottomY);
      actionButton.keyLabel = 'E';
      worldToggleButton.position = Vector2(size.x - 170 - inR, bottomY);
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
        // No translated type name – the emoji says what it is.
        sublabel: '',
        icon: Icons.meeting_room,
        onSelect: () {
          openBuildingInterior(model);
        },
      ));
    }

    // 📢🎺 Open-air meeting on the street (Salvation Army, once 📢 is learned).
    if (openAirOffered) {
      actions.add(RadialAction(
        label: '📢🎺',
        sublabel: openAirBlocker ?? '',
        icon: Icons.campaign,
        onSelect: holdOpenAirMeeting,
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

  // ── Mission helpers ───────────────────────────────────────────────────────

  /// Called by [MissionService] when a mission is completed via
  /// [advanceEntityMission].  Awards faith, materials and Insight and shows
  /// a brief toast message.

  void _onMissionCompleted(MissionModel mission) {
    dayStats.missionsCompleted++;
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

  // ── Mission board ─────────────────────────────────────────────────────────

  /// Active data for the mission-board overlay (null when closed).
  MissionBoardData? activeMissionBoardData;

  // ── Building interior ─────────────────────────────────────────────────────

  void closeMenu() { _currentMenu?.removeFromParent(); _currentMenu = null; }

  // ── ❓ Help overlay ───────────────────────────────────────────────────────

  /// Shown above the whole HUD (not as a Flame overlay, which lies below
  /// the tutorial chip and the resource bars).
  final ValueNotifier<bool> helpOpen = ValueNotifier(false);

  /// Back to the pause menu when the help closes (it was opened from there).
  bool _helpFromPause = false;

  /// Tab the help opens on (0 = 🎓 my tasks … 3 = ⌨️ keys).
  int helpTab = 0;

  // ── Pause menu (Issue #162) ───────────────────────────────────────────────
  //
  // The pause menu is the only way to reach Help, Save and Save & Quit –
  // there are no standalone buttons for them in the corners of the screen
  // anymore (Issue #174).  Opening it pauses the Flame engine so nothing
  // moves behind the menu; the Android/desktop back gesture opens it instead
  // of closing the app (see GameScreen's PopScope).

  bool _pauseMenuOpen = false;

  /// Re-armed once the pastor stops pushing into a door.
  bool _doorArmed = true;
  bool get isPauseMenuOpen => _pauseMenuOpen;

  // ── Escape / close helper ─────────────────────────────────────────────────

  // ── Radial-menu keyboard selection ────────────────────────────────────────

  // ── Dialog / building keyboard selection ──────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (_currentMenu != null) _currentMenu!.position = player.position;
    if (isWorldReady.value && !paused && interior != null) {
      _updateInteriorCamera();
      _updatePassiveResources(dt);
    } else if (isWorldReady.value && !paused) {
      _updateCamera(dt);
      _checkDoorStep();
      _updateNearestInteractable();
      _updatePassiveResources(dt);
      _updateStreetLabel();
      if (isSpiritualWorld) _updateHudVisibility(); // Dynamic dock update
      // Tick influence effects (decay / reversal of timed AoE events).
      influenceService.update(dt, grid);
      // Periodically check the win condition (spiritual state can change from
      // prayer combat and natural decay, not just NPC conversions).
      _quarterTimer += dt;
      if (_quarterTimer >= 1.0) {
        _quarterTimer = 0.0;
        _updateQuarter();
        _checkTrackedMission();
      }
      _winCheckTimer += dt;
      if (_winCheckTimer >= _winCheckInterval) {
        _winCheckTimer = 0.0;
        _checkWinCondition();
      }
    }
    if (isWorldReady.value) {
      _updateTutorialHighlights();
      _ambienceTimer += dt;
      if (_ambienceTimer >= 0.5) {
        _ambienceTimer = 0;
        GameAmbience.set(_ambienceHere());
      }
      if (isSpiritualWorld && interior == null) _daemonCry(dt);
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

    // Fire tutorial movement hook only after the initial position has been
    // established (first call sets the spawn-cell baseline, not real movement).

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
    leaveInterior();
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

  @override
  void onRemove() {
    resources.dispose();
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

  /// Record one use of a spiritual discipline ("Übung", §3.4). A new level
  /// is announced with a short toast, e.g. `⭐ 🙏 2`.
  void recordPractice(Discipline discipline) {
    if (!progress.practice.record(discipline)) return;
    GameSound.play(Sfx.learned);
    missionCompleteMessage.value =
        '⭐ ${discipline.emoji} ${progress.practice.level(discipline)}';
    Future.delayed(const Duration(seconds: 3), () {
      missionCompleteMessage.value = null;
    });
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
    dayStats.conversions++;
    GameSound.play(Sfx.conversion);
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

        // Whether this call is the very first time this chunk's NPCs are
        // generated (Issue #176).  NPCRegistry caches per chunk internally,
        // so on every later scan `alreadyGenerated` is true and the NPCs
        // returned below are the SAME live, possibly session-mutated model
        // instances the player has been interacting with – applying the
        // save on top of those would wipe out real progress.  Only truly
        // fresh (never-visited-this-session) NPCs get the save applied.
        final alreadyGenerated = chunkManager.npcRegistry.hasGeneratedChunk(cx, cy);
        final npcs =
            chunkManager.npcRegistry.getNPCsInChunk(cx, cy, chunk: chunk);
        if (!alreadyGenerated) {
          for (final npc in npcs) {
            applySavedNPCState(npc);
          }
        }
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
  ///
  /// Issue #176: a chunk the player never visited previously had no saved
  /// cell state applied, so a loaded save could never satisfy the win
  /// condition until every chunk in scope had been walked through at least
  /// once.  The temporary chunk now goes through the same
  /// [applySavedCellStatesToChunk] step [ChunkManager] uses for real loads.
  /// Already-loaded chunks are returned as-is (never re-patched from the
  /// save – their live, possibly session-mutated state is authoritative).
  CityChunk _chunkForGlobalWinCheck(int chunkX, int chunkY) {
    final loaded = grid.getLoadedChunk(chunkX, chunkY);
    if (loaded != null) return loaded;
    final key = '$chunkX,$chunkY';
    final cached = _winCheckChunkCache[key];
    if (cached != null) return cached;
    final chunk = CityChunk(chunkX: chunkX, chunkY: chunkY);
    generator.generateChunk(chunk);
    applySavedCellStatesToChunk(chunk);
    _winCheckChunkCache[key] = chunk;
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
    final portrait = viewportSize.y > viewportSize.x;

    // Playtest: in portrait the pastor could walk under the resource HUD
    // and the minimap, and so far to the edge that the action ring stuck
    // out of the screen. Keep him near the middle – a little below it,
    // because the HUD sits at the top.
    final target = Vector2(
      player.position.x,
      player.position.y - (portrait ? viewportSize.y * 0.08 : 0),
    );
    final limitX = viewportSize.x * (portrait ? 0.12 : 0.3);
    final limitY = viewportSize.y * (portrait ? 0.1 : 0.25);

    final dx = target.x - camPos.x;
    final dy = target.y - camPos.y;

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
  static const double _kJoystickKnobRadius   = 20.0;
  static const double _kJoystickTapTolerance = 6.0;

  /// Game-level tap handler.  Detects double-taps within the joystick area
  /// for desktop / web sprint activation.  This is more reliable than
  /// relying on TapCallbacks propagation through JoystickComponent's child
  /// hierarchy, where mouse events can be inconsistently routed.
  @override
  bool onTapDown(TapDownEvent event) {
    if (!isSpiritualWorld && isLoaded && joystick.parent != null) {
      final jCenter = Vector2(
        _kJoystickMarginLeft + safeInsets.left + _kJoystickBgRadius,
        camera.viewport.size.y - _kJoystickMarginBottom - safeInsets.bottom - _kJoystickBgRadius,
      );
      // Sprint double-tap must happen on the center joystick knob, not on the
      // outer joystick ring.
      if ((event.canvasPosition - jCenter).length <= _kJoystickKnobRadius + _kJoystickTapTolerance) {
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

  /// Pulsing golden ring: the tutorial points at this button.
  bool highlight = false;
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

    if (highlight) {
      final t = (DateTime.now().millisecondsSinceEpoch % 1000) / 1000.0;
      canvas.drawCircle(
        center,
        radius + 6 + 8 * t,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0xFFFFD54F).withValues(alpha: (1 - t) * opacity),
      );
    }

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
/// taps within a strict timing window and fires [onSprintStart].
/// Sprint ends automatically when the drag is released.
///
/// On desktop/web a second source of interactions comes from
/// [SpiritWorldGame.onTapDown], which calls [recordTapInteraction] when the
/// user double-clicks directly on the center joystick knob.
class _SprintJoystickComponent extends JoystickComponent {
  final VoidCallback onSprintStart;
  final VoidCallback onSprintEnd;

  static const int _kDoubleTapMinMs = 120;
  static const int _kDoubleTapMaxMs = 260;
  static const int _kNoPreviousInteractionElapsedMs = 99999;

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

  void _setSprintVisual(bool isActive) {
    if (knob is CircleComponent) {
      (knob as CircleComponent).paint.color = isActive
          ? Colors.orangeAccent.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.5);
    }
    if (background is CircleComponent) {
      (background as CircleComponent).paint.color = isActive
          ? Colors.orange.withValues(alpha: 0.35)
          : Colors.white.withValues(alpha: 0.2);
    }
  }

  /// Record an interaction start.  Returns true when sprint is activated.
  bool _recordInteraction() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = _lastInteractionMs > 0
        ? now - _lastInteractionMs
        : _kNoPreviousInteractionElapsedMs;

    if (!_sprinting &&
        elapsed >= _kDoubleTapMinMs &&
        elapsed <= _kDoubleTapMaxMs) {
      _sprinting = true;
      _setSprintVisual(true);
      onSprintStart();
      return true;
    }
    _lastInteractionMs = now;
    return false;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    if (_sprinting) {
      _sprinting = false;
      _setSprintVisual(false);
      onSprintEnd();
    }
    return super.onDragEnd(event);
  }

  @override
  bool onDragCancel(DragCancelEvent event) {
    if (_sprinting) {
      _sprinting = false;
      _setSprintVisual(false);
      onSprintEnd();
    }
    return super.onDragCancel(event);
  }
}
