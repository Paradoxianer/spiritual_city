import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../models/mission_model.dart';

/// Generates, tracks, and completes missions for the player.
///
/// Missions are generated lazily the first time the pastor house is visited
/// and whenever the active list drops below [_minActive].
///
/// The service is intentionally lightweight: no persistence between sessions
/// (missions reset on each new game) and no complex dependency graph.
class MissionService {
  static final _log = Logger('MissionService');

  static const int _minActive = 2;
  static const int _maxMissions = 5;

  final Random _rng;

  final List<MissionModel> _missions = [];
  int _nextId = 0;

  /// Notifies listeners whenever a mission is added or completed.
  final ValueNotifier<List<MissionModel>> missionsNotifier =
      ValueNotifier(const []);

  MissionService({int? seed}) : _rng = Random(seed);

  List<MissionModel> get activeMissions =>
      _missions.where((m) => !m.isCompleted).toList();

  List<MissionModel> get allMissions => List.unmodifiable(_missions);

  // ── Generation ────────────────────────────────────────────────────────────

  /// Called when the player enters the pastor house.
  /// Tops up the mission list to [_minActive] active missions.
  void generateForPastorhouseVisit() {
    final active = activeMissions.length;
    if (active >= _minActive) return;
    final toAdd = _minActive - active;
    for (int i = 0; i < toAdd; i++) {
      if (_missions.length < _maxMissions) _addRandomMission();
    }
    _notify();
  }

  void _addRandomMission() {
    final type = MissionType.values[_rng.nextInt(MissionType.values.length)];
    final m = _buildMission(type);
    _missions.add(m);
    _log.fine('New mission: ${m.description}');
  }

  MissionModel _buildMission(MissionType type) {
    final id = 'mission_${_nextId++}';
    return switch (type) {
      MissionType.dialog => MissionModel(
          id: id,
          type: type,
          description: 'Sprich mit 3 Bewohnern der Stadt',
          targetCount: 3,
          rewardFaith: 10,
        ),
      MissionType.service => MissionModel(
          id: id,
          type: type,
          description: 'Hilf 2 Bewohnern (📦 Hilfe-Aktion)',
          targetCount: 2,
          rewardFaith: 10,
          rewardMaterials: 10,
        ),
      MissionType.visit => MissionModel(
          id: id,
          type: type,
          description: 'Bete in einem Gebäude (🙏 Gebet-Aktion)',
          targetCount: 1,
          rewardFaith: 15,
        ),
      MissionType.prayer => MissionModel(
          id: id,
          type: type,
          description: '5× Gebet-Kampf gegen Dämonen',
          targetCount: 5,
          rewardFaith: 50,
        ),
      MissionType.collect => MissionModel(
          id: id,
          type: type,
          description: 'Sammle 10 Material-Pakete',
          targetCount: 10,
          rewardFaith: 15,
          rewardMaterials: 30,
        ),
    };
  }

  // ── Progress hooks (called by SpiritWorldGame) ────────────────────────────

  void onDialogCompleted() => _advanceType(MissionType.dialog);
  void onServiceCompleted() => _advanceType(MissionType.service);
  void onVisitPrayed()      => _advanceType(MissionType.visit);
  void onPrayerCombat()     => _advanceType(MissionType.prayer);
  void onMaterialCollected()=> _advanceType(MissionType.collect);

  void _advanceType(MissionType type) {
    for (final m in _missions) {
      if (m.type == type && !m.isCompleted) {
        if (m.advance()) {
          _log.info('Mission completed: ${m.description}');
          _notify();
        }
        return;
      }
    }
  }

  // ── Reward claim ──────────────────────────────────────────────────────────

  /// Returns the reward of a completed mission and removes it from the list.
  /// Returns null if the mission is not found or not completed.
  MissionModel? claimReward(String missionId) {
    final idx = _missions.indexWhere((m) => m.id == missionId && m.isCompleted);
    if (idx < 0) return null;
    final m = _missions.removeAt(idx);
    _notify();
    return m;
  }

  void _notify() {
    missionsNotifier.value = List.unmodifiable(_missions);
  }
}
