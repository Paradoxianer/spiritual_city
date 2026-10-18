part of '../spirit_world_game.dart';

/// 📍 An accepted mission (playtest 2026-10-18): its target is shown on the
/// minimap, the city map and as an arrow in the HUD until it is done.
extension GameMissionTracking on SpiritWorldGame {
  /// Key of a mission target: `npc:<id>` or `b:<buildingId>`.
  static String npcKey(String id) => 'npc:$id';
  static String buildingKey(String id) => 'b:$id';

  /// 🎓 The nearest mentor for [skill] (learning path tab).
  static String lessonKey(Skill skill) => 'lesson:${skill.name}';

  /// Nearest building where a mentor teaches [lesson]: loaded buildings
  /// first, else the city plan's special buildings.
  Vector2? _nearestMentor(Lesson lesson) {
    Vector2? best;
    var bestD = double.infinity;
    void consider(Vector2 p) {
      final d = p.distanceToSquared(player.position);
      if (d < bestD) {
        bestD = d;
        best = p;
      }
    }

    for (final b in chunkManager.allActiveBuildings) {
      if (lesson.mentorAt.contains(b.buildingModel.type)) consider(b.position);
    }
    if (best != null) return best;
    for (final (x, y, t) in cityOverview?.landmarks ?? const <(int, int, BuildingType)>[]) {
      if (lesson.mentorAt.contains(t)) {
        consider(Vector2((x + 0.5) * CellComponent.cellSize, (y + 0.5) * CellComponent.cellSize));
      }
    }
    return best;
  }

  void toggleTrackedMission(String key) {
    trackedMission.value = trackedMission.value == key ? null : key;
    GameSound.play(Sfx.tap, volume: 0.4);
  }

  /// World position of the tracked target, if it is known right now.
  Vector2? get trackedTargetPosition {
    final key = trackedMission.value;
    if (key == null) return null;
    if (key.startsWith('lesson:')) {
      final skill = Skill.values.where((s) => 'lesson:${s.name}' == key).firstOrNull;
      return skill == null ? null : _nearestMentor(Lessons.of(skill));
    }
    if (key.startsWith('npc:')) {
      return chunkManager.findNpcComponent(key.substring(4))?.position;
    }
    final id = key.substring(2);
    for (final b in chunkManager.allActiveBuildings) {
      if (b.buildingModel.buildingId == id) return b.position;
    }
    // Not loaded: the lot root from the id (`b_<x>_<y>`), centre of the lot.
    final parts = id.split('_');
    if (parts.length == 3) {
      final x = int.tryParse(parts[1]), y = int.tryParse(parts[2]);
      if (x != null && y != null) {
        return Vector2((x + 4) * CellComponent.cellSize, (y + 4) * CellComponent.cellSize);
      }
    }
    return null;
  }

  /// Drops the 📍 once the target's mission is done (checked each second).
  void _checkTrackedMission() {
    final key = trackedMission.value;
    if (key == null) return;
    if (key.startsWith('lesson:')) {
      // Done once the skill is learned or its lesson has been accepted.
      final skill = Skill.values.where((s) => 'lesson:${s.name}' == key).firstOrNull;
      if (skill == null || progress.skills.has(skill) || progress.lesson.active == skill) {
        trackedMission.value = null;
      }
      return;
    }
    if (key.startsWith('npc:')) {
      final npc = chunkManager.findNpcModel(key.substring(4));
      if (npc != null && npc.activeMission == null) trackedMission.value = null;
    } else {
      final b = chunkManager.getBuildingModel(key.substring(2));
      if (b != null && b.activeMission == null) trackedMission.value = null;
    }
  }
}
