import 'dart:math';
import 'package:logging/logging.dart';
import '../models/npc_model.dart';
import '../models/building_model.dart';

/// Lightweight mission service.
///
/// Missions are short tasks attached directly to a specific NPC or building.
/// When the player approaches the target they see a 📋 icon in-world and can
/// complete the mission via the radial menu for an instant reward.
class MissionService {
  static final _log = Logger('MissionService');

  static const int _startMissionCount = 4;
  static const int faithReward    = 10;
  static const int materialsReward = 5;

  // Keep old private names as aliases so nothing else breaks.
  static const int _faithReward    = faithReward;
  static const int _materialReward = materialsReward;

  static const List<String> _missionTexts = [
    'Sprich mit diesem Bewohner',
    'Bete für diesen Ort',
    'Bring Hilfe hierher',
    'Besuche diesen Ort',
    'Bitte um ein Gespräch',
    'Teile gute Neuigkeiten',
    'Hör diesem Menschen zu',
    'Segne diesen Ort',
  ];

  final Random _rng;
  MissionService({int? seed}) : _rng = Random(seed);

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
    for (int i = 0; i < _startMissionCount && i < targets.length; i++) {
      final text = _missionTexts[_rng.nextInt(_missionTexts.length)];
      targets[i].assign(text);
      _log.fine('Mission assigned: "$text"');
    }
  }

  // ── Completion ────────────────────────────────────────────────────────────

  /// Returns the faith reward and clears the mission from the target.
  /// After completion a new mission is assigned to a random idle target.
  (int faithDelta, int materialsDelta) completeNpcMission(
    NPCModel npc,
    List<NPCModel> allNpcs,
    List<BuildingModel> allBuildings,
  ) {
    npc.activeMissionDescription = null;
    _assignOneRandomMission(allNpcs, allBuildings);
    return (_faithReward, _materialReward);
  }

  (int faithDelta, int materialsDelta) completeBuildingMission(
    BuildingModel building,
    List<NPCModel> allNpcs,
    List<BuildingModel> allBuildings,
  ) {
    building.activeMissionDescription = null;
    _assignOneRandomMission(allNpcs, allBuildings);
    return (_faithReward, _materialReward);
  }

  void _assignOneRandomMission(
    List<NPCModel> npcs,
    List<BuildingModel> buildings,
  ) {
    final targets = <_Target>[
      for (final n in npcs) if (n.activeMissionDescription == null) _Target.npc(n),
      for (final b in buildings)
        if (b.activeMissionDescription == null) _Target.building(b),
    ];
    if (targets.isEmpty) return;
    final t = targets[_rng.nextInt(targets.length)];
    t.assign(_missionTexts[_rng.nextInt(_missionTexts.length)]);
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
  void assign(String text) {
    npc?.activeMissionDescription = text;
    building?.activeMissionDescription = text;
  }
}
