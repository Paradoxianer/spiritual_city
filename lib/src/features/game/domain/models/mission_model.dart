/// Types of missions the player can accept from the pastor house.
enum MissionType {
  /// Sprich mit einem bestimmten NPC.  Reward: +Faith
  dialog,

  /// Hilf einem Bewohner (help-Action in einem Wohnhaus).  Reward: +Faith +Materials
  service,

  /// Besuche ein Gebäude und bete dort (prayBusiness).  Reward: temporary faith boost
  visit,

  /// Bete 5× im Kampf gegen Dämonen.  Reward: +Faith (big)
  prayer,

  /// Sammle Material-Pakete von der Straße.  Reward: +Materials +Faith
  collect,
}

enum MissionStatus { active, completed }

/// Describes a single mission handed out from the pastor house.
class MissionModel {
  final String id;
  final MissionType type;

  /// Short human-readable goal text (shown in the mission board).
  final String description;

  /// How many units of progress are needed to complete the mission.
  final int targetCount;

  /// Current progress (incremented by the [MissionService] hooks).
  int progress = 0;

  MissionStatus status = MissionStatus.active;

  // ── Rewards ───────────────────────────────────────────────────────────────

  final double rewardFaith;
  final double rewardMaterials;

  MissionModel({
    required this.id,
    required this.type,
    required this.description,
    required this.targetCount,
    required this.rewardFaith,
    this.rewardMaterials = 0,
  });

  bool get isCompleted => status == MissionStatus.completed;

  /// Increments progress; marks as completed when [targetCount] is reached.
  /// Returns `true` if this call completed the mission.
  bool advance([int amount = 1]) {
    if (isCompleted) return false;
    progress = (progress + amount).clamp(0, targetCount);
    if (progress >= targetCount) {
      status = MissionStatus.completed;
      return true;
    }
    return false;
  }
}
