import 'package:flame/components.dart';

enum NPCType {
  citizen,
  merchant,
  priest,
  officer,
}

/// NPC Data Model based on Lastenheft Section 6.2
class NPCModel {
  final String id;
  final String name;
  final NPCType type;
  final Vector2 homePosition;

  /// Age of the NPC (18–85).
  final int age;

  /// Life story as ordered emoji segments, generated at creation.
  /// Each segment represents one life area (childhood, school, family, …).
  final List<String> lifeStory;

  /// Single emoji icon for each life story segment (parallel to [lifeStory]).
  /// E.g. ['👶', '🏫', '👪', '🎓', '💼', '💑', '⛪']
  final List<String> lifeStoryIcons;

  /// Faith Level: -100.0 to +100.0
  /// < -50: Opposed/Negative
  /// > 50: Christian/Believer
  double faith;

  int conversationCount;
  int prayerCount;

  /// Number of counseling (👂) sessions held with this NPC.
  int counselingCount;

  /// How many life story segments have been revealed through counseling.
  int revealedLifeStoryCount = 0;

  /// Tracks interactions in the current active dialogue session.
  int currentSessionInteractions = 0;

  /// True once the NPC has received 3 interactions this session.
  bool get isReadyToLeave => currentSessionInteractions >= 3;

  /// Whether the player gave a gift (help action) during this session.
  bool hadGiftThisSession = false;

  /// True when the NPC is actively requesting material support.
  /// Set randomly during talk/counsel; cleared after gift is given.
  bool wantsGift = false;

  /// Emoji of the last end-of-session reaction, e.g. '🙏'.
  String lastReactionEmoji = '';

  String? currentMessage;

  // ── Resource feedback from the last interaction ───────────────────────────

  /// NPC faith delta from the most recent interaction (positive = gained).
  double lastNpcFaithDelta = 0.0;

  /// Player faith delta from the most recent interaction.
  double lastPlayerFaithDelta = 0.0;

  /// Player materials delta from the most recent interaction (negative = spent).
  double lastMaterialsDelta = 0.0;

  /// Player health delta from the most recent interaction (negative = spent).
  double lastHealthDelta = 0.0;

  // ── Pending messages shown in dialog after the main reaction ──────────────

  /// Extra NPC messages to display (life story reveals, gift requests, …).
  /// The dialog overlay drains this list after each interaction.
  final List<String> pendingMessages = [];

  /// ID of the building this NPC lives/works in.
  final String? homeBuildingId;

  NPCModel({
    required this.id,
    required this.name,
    required this.type,
    required this.homePosition,
    this.age = 30,
    this.lifeStory = const [],
    this.lifeStoryIcons = const [],
    this.homeBuildingId,
    this.faith = 0.0,
    this.conversationCount = 0,
    this.prayerCount = 0,
    this.counselingCount = 0,
    this.currentMessage,
  });

  /// An NPC is considered a Christian if faith is above 50 (Lastenheft 6.2)
  bool get isChristian => faith > 50;

  /// Issue #45: faith state is only revealed after enough conversations.
  /// 0–2 talks → unknown; 3–5 → vague; 6+ → fully revealed.
  bool get isFaithRevealed => conversationCount >= 6;
  bool get isFaithVague => conversationCount >= 3 && conversationCount < 6;

  /// Logic to update faith based on interaction and environment
  void applyInfluence(double amount) {
    faith = (faith + amount).clamp(-100.0, 100.0);
  }

  void resetSession() {
    currentSessionInteractions = 0;
    hadGiftThisSession = false;
    lastReactionEmoji = '';
    pendingMessages.clear();
    lastNpcFaithDelta = 0.0;
    lastPlayerFaithDelta = 0.0;
    lastMaterialsDelta = 0.0;
    lastHealthDelta = 0.0;
  }
}
