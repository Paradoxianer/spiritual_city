// ── ActionType – central action registry (Issue #131) ─────────────────────

/// Every building and NPC action as a typed enum value.
///
/// Building actions are prefixed by building category so the same "verb"
/// (e.g. `pray`) can map to different gameplay contexts depending on where
/// it is performed.  NPC conversation actions have their own `npc` prefix.
enum ActionType {
  // ── Residential ──────────────────────────────────────────────────────────
  residentialPracticalHelp,
  residentialPrayer,
  residentialHouseVisit,
  residentialDiscipleshipGroup,
  residentialApartmentBless,
  // ── Commercial ───────────────────────────────────────────────────────────
  commercialTalkToBoss,
  commercialShopping,
  commercialBless,
  commercialAskForDonation,
  // ── Hospital ─────────────────────────────────────────────────────────────
  hospitalMedicalHelp,
  hospitalPastoralCare,
  hospitalChurchService,
  // ── School / University ───────────────────────────────────────────────────
  schoolLetterToManagement,
  schoolTalkToDirector,
  schoolValuesTalk,
  schoolPrayerCircle,
  // ── Police Station ────────────────────────────────────────────────────────
  policeBless,
  // ── City Hall ─────────────────────────────────────────────────────────────
  cityHallAudience,
  cityHallPrayForPoliticians,
  // ── Church / Cathedral ────────────────────────────────────────────────────
  churchService,
  churchWorshipPrayer,
  // ── Cemetery ─────────────────────────────────────────────────────────────
  cemeteryFuneral,
  cemeteryComfort,
  // ── Stadium ───────────────────────────────────────────────────────────────
  stadiumMajorEvent,
  // ── Library (via generic pray action) ────────────────────────────────────
  libraryBibleStudy,
  // ── NPC interactions ─────────────────────────────────────────────────────
  npcConversation,
  npcGospelShare,
}

/// Difficulty tier for a mission.  Controls the insight and faith rewards.
enum MissionDifficulty {
  /// Quick, single-action mission in one place – e.g. 1× bless.
  small,

  /// Multi-step mission across 2–3 buildings – e.g. 3× help.
  medium,

  /// City-spanning chain or evangelist challenge – e.g. convert an NPC.
  large,
}

enum MissionStatus { active, completed }

/// Describes a single mission attached to an NPC or building.
///
/// Progress advances each time the player performs the required [actionType]
/// at the entity that holds this mission.  On completion the player earns
/// faith, materials and – most importantly – [insightReward] Insight.
class MissionModel {
  final String id;

  /// The action the player must perform to advance this mission.
  final ActionType actionType;

  /// Short human-readable goal text shown in the building/NPC dialog and the
  /// mission board.
  final String description;

  /// How many times the action must be performed to complete the mission.
  final int targetCount;

  /// Current progress (incremented by [advance]).
  int progress = 0;

  MissionStatus status = MissionStatus.active;

  final MissionDifficulty difficulty;

  // ── Rewards ───────────────────────────────────────────────────────────────

  final double rewardFaith;
  final double rewardMaterials;

  /// Geistliche Erkenntnis (Insight) awarded on completion.
  ///
  /// Balancing: missions span the whole city so rewards are generous.
  /// small → 1.0, medium → 2.0, large → 3.0–5.0.
  final double insightReward;

  MissionModel({
    required this.id,
    required this.actionType,
    required this.description,
    required this.targetCount,
    required this.rewardFaith,
    this.rewardMaterials = 0,
    required this.insightReward,
    this.difficulty = MissionDifficulty.small,
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

  // ── Serialisation (for save/load) ─────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'actionType': actionType.name,
    'description': description,
    'targetCount': targetCount,
    'progress': progress,
    'rewardFaith': rewardFaith,
    'rewardMaterials': rewardMaterials,
    'insightReward': insightReward,
    'difficulty': difficulty.name,
  };

  // ── Emoji helper ─────────────────────────────────────────────────────────

  /// Returns the leading emoji of the action button the player must press to
  /// advance this mission.  Used in banners and the mission board so the UI
  /// stays language-agnostic.
  String get actionEmoji => actionTypeEmoji(actionType);

  /// Maps every [ActionType] to the emoji that is shown on the corresponding
  /// action button in buildings or NPC dialogs.  Kept in sync with
  /// `_buildBuildingChipsColumn` / NPC chips in game_screen.dart.
  static String actionTypeEmoji(ActionType at) {
    switch (at) {
      // Residential
      case ActionType.residentialPracticalHelp:    return '🛠️';
      case ActionType.residentialPrayer:           return '🙏';
      case ActionType.residentialHouseVisit:       return '☕';
      case ActionType.residentialDiscipleshipGroup:return '📖';
      case ActionType.residentialApartmentBless:   return '🏢';
      // Commercial
      case ActionType.commercialTalkToBoss:        return '💼';
      case ActionType.commercialShopping:          return '🛒';
      case ActionType.commercialBless:             return '🕊️';
      case ActionType.commercialAskForDonation:    return '🤲';
      // Hospital
      case ActionType.hospitalMedicalHelp:         return '🏥';
      case ActionType.hospitalPastoralCare:        return '👂';
      case ActionType.hospitalChurchService:       return '⛪';
      // School / University
      case ActionType.schoolLetterToManagement:    return '✉️';
      case ActionType.schoolTalkToDirector:        return '🏫';
      case ActionType.schoolValuesTalk:            return '🎤';
      case ActionType.schoolPrayerCircle:          return '⭕';
      // Police
      case ActionType.policeBless:                 return '👮';
      // City Hall
      case ActionType.cityHallAudience:            return '🏛️';
      case ActionType.cityHallPrayForPoliticians:  return '🙏';
      // Church / Cathedral
      case ActionType.churchService:               return '⛪';
      case ActionType.churchWorshipPrayer:         return '🧘';
      // Cemetery
      case ActionType.cemeteryFuneral:             return '⚰️';
      case ActionType.cemeteryComfort:             return '🤝';
      // Stadium
      case ActionType.stadiumMajorEvent:           return '🏟️';
      // Library
      case ActionType.libraryBibleStudy:           return '📚';
      // NPC
      case ActionType.npcConversation:             return '💬';
      case ActionType.npcGospelShare:              return '✝️';
    }
  }

  static MissionModel? fromJson(Map<String, dynamic> json) {
    try {
      final atName = json['actionType'] as String?;
      if (atName == null) return null;
      final at = ActionType.values.firstWhere(
        (e) => e.name == atName,
        orElse: () => ActionType.npcConversation,
      );
      final diff = MissionDifficulty.values.firstWhere(
        (e) => e.name == (json['difficulty'] as String? ?? 'small'),
        orElse: () => MissionDifficulty.small,
      );
      final m = MissionModel(
        id: json['id'] as String? ?? 'saved',
        actionType: at,
        description: json['description'] as String? ?? '📋',
        targetCount: (json['targetCount'] as num?)?.toInt() ?? 1,
        rewardFaith: (json['rewardFaith'] as num?)?.toDouble() ?? 0,
        rewardMaterials: (json['rewardMaterials'] as num?)?.toDouble() ?? 0,
        insightReward: (json['insightReward'] as num?)?.toDouble() ?? 1.0,
        difficulty: diff,
      );
      m.progress = (json['progress'] as num?)?.toInt() ?? 0;
      return m;
    } catch (_) {
      return null;
    }
  }
}
