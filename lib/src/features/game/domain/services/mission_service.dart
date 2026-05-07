import 'dart:math';
import 'package:logging/logging.dart';
import '../models/base_interactable_entity.dart';
import '../models/mission_model.dart';
import '../models/npc_model.dart';
import '../models/building_model.dart';
import '../models/cell_object.dart';

// ── Mission template ──────────────────────────────────────────────────────────

/// Immutable template used to stamp out [MissionModel] instances.
class _MissionTemplate {
  final String description;
  final ActionType actionType;
  final int targetCount;
  final double insightReward;
  final double rewardFaith;
  final double rewardMaterials;
  final MissionDifficulty difficulty;
  /// Building types this mission can be attached to (null = any / NPC).
  final List<BuildingType>? buildingTypes;
  /// If true, assign only to NPCs; if false, only to buildings.
  final bool? npcOnly;

  const _MissionTemplate({
    required this.description,
    required this.actionType,
    required this.targetCount,
    required this.insightReward,
    required this.rewardFaith,
    this.rewardMaterials = 0,
    this.difficulty = MissionDifficulty.small,
    this.buildingTypes,
    this.npcOnly,
  });
}

/// Central mission service.
///
/// Missions are short tasks attached directly to a specific NPC or building.
/// Each mission requires the player to perform a [ActionType] action at the
/// target entity a given number of times.  On completion the player earns
/// faith, materials and Insight via the [onMissionCompleted] callback.
///
/// Missions are spatially distributed across the city so the player must
/// travel to the target – this is what justifies the generous Insight rewards.
class MissionService {
  static final _log = Logger('MissionService');

  static const int _startMissionCount = 4;

  // ── Legacy reward constants (used by radial-menu completion path) ─────────
  static const int faithReward    = 10;
  static const int materialsReward = 5;

  // Keep old private names as aliases so nothing else breaks.
  static const int _faithReward    = faithReward;
  static const int _materialReward = materialsReward;

  // ── Mission templates (Issue #131 / #82) ─────────────────────────────────

  /// All available mission templates.
  ///
  /// Template [buildingTypes] restricts which buildings a template is assigned
  /// to.  [npcOnly] = true means it can only go to an NPC target.
  static const List<_MissionTemplate> _templates = [
    // ── Small: single-action ──────────────────────────────────────────────
    _MissionTemplate(
      description: '🙏 Bete für die Gegend (3×)',
      actionType: ActionType.residentialPrayer,
      targetCount: 3,
      insightReward: 1.0,
      rewardFaith: 10.0,
      difficulty: MissionDifficulty.small,
      buildingTypes: [BuildingType.house, BuildingType.apartment],
    ),
    _MissionTemplate(
      description: '🤲 Anbetung in der Kirche',
      actionType: ActionType.churchWorshipPrayer,
      targetCount: 1,
      insightReward: 1.0,
      rewardFaith: 15.0,
      difficulty: MissionDifficulty.small,
      buildingTypes: [BuildingType.church, BuildingType.cathedral],
    ),
    _MissionTemplate(
      description: '🏠 Segne ein Haus',
      actionType: ActionType.residentialApartmentBless,
      targetCount: 1,
      insightReward: 1.0,
      rewardFaith: 10.0,
      difficulty: MissionDifficulty.small,
      buildingTypes: [BuildingType.apartment],
    ),
    _MissionTemplate(
      description: '👮 Segne die Polizei',
      actionType: ActionType.policeBless,
      targetCount: 1,
      insightReward: 1.0,
      rewardFaith: 10.0,
      difficulty: MissionDifficulty.small,
      buildingTypes: [BuildingType.policeStation],
    ),
    // ── Medium: multi-step ────────────────────────────────────────────────
    _MissionTemplate(
      description: '📦 Bring Hilfsmittel (5×)',
      actionType: ActionType.residentialPracticalHelp,
      targetCount: 5,
      insightReward: 2.0,
      rewardFaith: 10.0,
      rewardMaterials: 3,
      difficulty: MissionDifficulty.medium,
      buildingTypes: [BuildingType.house, BuildingType.apartment],
    ),
    _MissionTemplate(
      description: '💬 Sprich mit jemandem (3×)',
      actionType: ActionType.npcConversation,
      targetCount: 3,
      insightReward: 1.0,
      rewardFaith: 10.0,
      difficulty: MissionDifficulty.medium,
      npcOnly: true,
    ),
    _MissionTemplate(
      description: '💡 Bring Licht ins Haus (Gottesdienst)',
      actionType: ActionType.churchService,
      targetCount: 1,
      insightReward: 2.0,
      rewardFaith: 0.0,
      rewardMaterials: 100,
      difficulty: MissionDifficulty.medium,
      buildingTypes: [BuildingType.church, BuildingType.cathedral],
    ),
    _MissionTemplate(
      description: '🏫 Brief an die Schulleitung (2×)',
      actionType: ActionType.schoolLetterToManagement,
      targetCount: 2,
      insightReward: 2.0,
      rewardFaith: 15.0,
      difficulty: MissionDifficulty.medium,
      buildingTypes: [BuildingType.school, BuildingType.university],
    ),
    // ── Large: chain / evangelist challenge ─────────────────────────────
    _MissionTemplate(
      description: '📖 Teile die Gute Nachricht',
      actionType: ActionType.npcGospelShare,
      targetCount: 1,
      insightReward: 3.0,
      rewardFaith: 25.0,
      difficulty: MissionDifficulty.large,
      npcOnly: true,
    ),
    _MissionTemplate(
      description: '🙏 Bete für die Politiker (2×)',
      actionType: ActionType.cityHallPrayForPoliticians,
      targetCount: 2,
      insightReward: 3.0,
      rewardFaith: 20.0,
      difficulty: MissionDifficulty.large,
      buildingTypes: [BuildingType.cityHall],
    ),
  ];

  final Random _rng;

  /// Called when a mission is completed.  Receives the completed mission so
  /// the caller can award faith, materials and Insight.
  final void Function(MissionModel mission)? onMissionCompleted;

  MissionService({int? seed, this.onMissionCompleted}) : _rng = Random(seed);

  // ── Startup ───────────────────────────────────────────────────────────────

  /// Assigns [_startMissionCount] missions to random NPCs and buildings.
  /// Call once after the spawn chunk is loaded.
  void assignStartMissions(
    List<NPCModel> npcs,
    List<BuildingModel> buildings,
  ) {
    final targets = <_Target>[
      for (final n in npcs) _Target.npc(n),
      for (final b in buildings) _Target.building(b),
    ];
    if (targets.isEmpty) return;
    targets.shuffle(_rng);
    int assigned = 0;
    for (final t in targets) {
      if (assigned >= _startMissionCount) break;
      if (_tryAssignTemplate(t, npcs, buildings)) assigned++;
    }
    _log.fine('Start missions assigned: $assigned');
  }

  // ── Action-based mission advancement (Issue #131) ─────────────────────────

  /// Advances the active mission on [entity] if its [ActionType] matches [at].
  ///
  /// Returns the completed [MissionModel] when this call finishes the mission,
  /// otherwise returns null.  On completion the entity's mission is cleared and
  /// a new mission is assigned to a random idle entity.
  MissionModel? advanceEntityMission(
    ActionType at,
    BaseInteractableEntity entity, {
    List<NPCModel> allNpcs = const [],
    List<BuildingModel> allBuildings = const [],
  }) {
    final mission = entity.activeMission;
    if (mission == null || mission.isCompleted) return null;
    if (mission.actionType != at) return null;
    if (!mission.advance()) return null;

    // Mission complete!
    _log.fine('Mission completed: "${mission.description}" on ${entity.id}');
    entity.activeMission = null; // also clears activeMissionDescription

    // Notify caller so it can award resources + Insight.
    onMissionCompleted?.call(mission);

    // Replace with a fresh mission on a random idle entity.
    _assignOneRandomMission(allNpcs, allBuildings);

    return mission;
  }

  // ── Legacy completion (radial-menu path) ──────────────────────────────────

  /// Returns the faith/materials reward and clears the mission from the target.
  /// After completion a new mission is assigned to a random idle target.
  (int faithDelta, int materialsDelta) completeNpcMission(
    NPCModel npc,
    List<NPCModel> allNpcs,
    List<BuildingModel> allBuildings,
  ) {
    // Honour structured mission rewards if present.
    final mission = npc.activeMission;
    final faith = mission != null ? mission.rewardFaith.round() : _faithReward;
    final mats  = mission != null ? mission.rewardMaterials.round() : _materialReward;
    if (mission != null) onMissionCompleted?.call(mission);
    npc.activeMission = null;
    _assignOneRandomMission(allNpcs, allBuildings);
    return (faith, mats);
  }

  (int faithDelta, int materialsDelta) completeBuildingMission(
    BuildingModel building,
    List<NPCModel> allNpcs,
    List<BuildingModel> allBuildings,
  ) {
    final mission = building.activeMission;
    final faith = mission != null ? mission.rewardFaith.round() : _faithReward;
    final mats  = mission != null ? mission.rewardMaterials.round() : _materialReward;
    if (mission != null) onMissionCompleted?.call(mission);
    building.activeMission = null;
    _assignOneRandomMission(allNpcs, allBuildings);
    return (faith, mats);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _assignOneRandomMission(
    List<NPCModel> npcs,
    List<BuildingModel> buildings,
  ) {
    final targets = <_Target>[
      for (final n in npcs) if (n.activeMission == null) _Target.npc(n),
      for (final b in buildings)
        if (b.activeMission == null) _Target.building(b),
    ];
    if (targets.isEmpty) return;
    targets.shuffle(_rng);
    for (final t in targets) {
      if (_tryAssignTemplate(t, npcs, buildings)) return;
    }
  }

  bool _tryAssignTemplate(
    _Target t,
    List<NPCModel> allNpcs,
    List<BuildingModel> allBuildings,
  ) {
    // Filter templates that match the target type.
    final candidates = _templates.where((tmpl) {
      if (t.npc != null) {
        // NPC target: only templates that allow NPC or have no building restriction.
        return tmpl.npcOnly == true ||
            (tmpl.npcOnly == null && tmpl.buildingTypes == null);
      } else {
        // Building target.
        final building = t.building!;
        if (tmpl.npcOnly == true) return false;
        if (tmpl.buildingTypes != null) {
          return tmpl.buildingTypes!.contains(building.type);
        }
        return true;
      }
    }).toList();

    if (candidates.isEmpty) return false;

    final tmpl = candidates[_rng.nextInt(candidates.length)];
    final id   = '${_rng.nextInt(99999)}';
    final mission = MissionModel(
      id: id,
      actionType: tmpl.actionType,
      description: tmpl.description,
      targetCount: tmpl.targetCount,
      rewardFaith: tmpl.rewardFaith,
      rewardMaterials: tmpl.rewardMaterials,
      insightReward: tmpl.insightReward,
      difficulty: tmpl.difficulty,
    );
    t.assign(mission);
    _log.fine('Mission assigned: "${mission.description}" → ${t.npc?.name ?? t.building?.buildingId}');
    return true;
  }

  // ── ActionType mapping ────────────────────────────────────────────────────

  /// Maps a building action string + building type to an [ActionType] enum
  /// value, or null if the action has no registered ActionType.
  static ActionType? buildingActionToType(
    String actionType,
    BuildingType buildingType,
  ) {
    switch (buildingType) {
      case BuildingType.house:
      case BuildingType.apartment:
        return switch (actionType) {
          'practicalHelp'    => ActionType.residentialPracticalHelp,
          'pray'             => ActionType.residentialPrayer,
          'houseVisit'       => ActionType.residentialHouseVisit,
          'discipleshipGroup'=> ActionType.residentialDiscipleshipGroup,
          'blessHousehold'   => ActionType.residentialApartmentBless,
          _ => null,
        };
      case BuildingType.shop:
      case BuildingType.supermarket:
      case BuildingType.mall:
      case BuildingType.office:
      case BuildingType.skyscraper:
        return switch (actionType) {
          'talkBoss'        => ActionType.commercialTalkToBoss,
          'shopping'        => ActionType.commercialShopping,
          'bless'           => ActionType.commercialBless,
          'requestDonation' => ActionType.commercialAskForDonation,
          _ => null,
        };
      case BuildingType.hospital:
        return switch (actionType) {
          'medicalHelp'   => ActionType.hospitalMedicalHelp,
          'counseling'    => ActionType.hospitalPastoralCare,
          'chapelService' => ActionType.hospitalChurchService,
          _ => null,
        };
      case BuildingType.school:
      case BuildingType.university:
        return switch (actionType) {
          'letterToManagement' => ActionType.schoolLetterToManagement,
          'talkDirector'       => ActionType.schoolTalkToDirector,
          'valueLecture'       => ActionType.schoolValuesTalk,
          'prayerCircle'       => ActionType.schoolPrayerCircle,
          _ => null,
        };
      case BuildingType.policeStation:
        return actionType == 'blessPolice' ? ActionType.policeBless : null;
      case BuildingType.cityHall:
        return switch (actionType) {
          'mayorAudience'      => ActionType.cityHallAudience,
          'prayForPoliticians' => ActionType.cityHallPrayForPoliticians,
          _ => null,
        };
      case BuildingType.church:
      case BuildingType.cathedral:
        return switch (actionType) {
          'sundayService' => ActionType.churchService,
          'worship'       => ActionType.churchWorshipPrayer,
          _ => null,
        };
      case BuildingType.cemetery:
        return switch (actionType) {
          'funeral' => ActionType.cemeteryFuneral,
          'comfort' => ActionType.cemeteryComfort,
          _ => null,
        };
      case BuildingType.stadium:
        return actionType == 'majorEvent' ? ActionType.stadiumMajorEvent : null;
      default:
        return null;
    }
  }

  /// Maps an NPC interaction type string to an [ActionType].
  static ActionType? npcActionToType(String interactionType) {
    return switch (interactionType) {
      'talk'    => ActionType.npcConversation,
      'convert' => ActionType.npcGospelShare,
      _ => null,
    };
  }

  // ── Legacy hooks (kept for backward compatibility) ────────────────────────
  void onDialogCompleted()   {}
  void onServiceCompleted()  {}
  void onVisitPrayed()       {}
  void onPrayerCombat()      {}
  void onMaterialCollected() {}
  void generateForPastorhouseVisit() {}
}

class _Target {
  final NPCModel? npc;
  final BuildingModel? building;
  _Target.npc(this.npc) : building = null;
  _Target.building(this.building) : npc = null;
  void assign(MissionModel mission) {
    npc?.activeMission = mission;
    building?.activeMission = mission;
  }
}
