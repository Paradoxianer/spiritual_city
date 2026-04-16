import 'dart:math';
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
  
  /// Faith Level: -100.0 to +100.0
  /// < -50: Opposed/Negative
  /// > 50: Christian/Believer
  double faith; 
  
  int conversationCount;
  int prayerCount;

  /// Number of counseling (Seelsorge) sessions applied.
  int counselingCount = 0;
  
  /// Tracks interactions in the current active dialogue session
  int currentSessionInteractions = 0;

  /// True once the NPC has received 3 interactions this session.
  bool get isReadyToLeave => currentSessionInteractions >= 3;

  /// Whether the player gave a gift (help action) during this session.
  bool hadGiftThisSession = false;

  /// Whether the NPC is currently asking for material support.
  /// Randomly set at session start (35% chance when faith < 30).
  bool wantsGift = false;

  /// Emoji of the last end-of-session reaction, e.g. '🙏'.
  String lastReactionEmoji = '';

  String? currentMessage;

  // ── Delta tracking – updated by each interaction for UI feedback ──────────

  /// NPC faith change from the most recent interaction.
  double lastNpcFaithDelta = 0.0;

  /// Player faith change from the most recent interaction (from resonance + action).
  double lastPlayerFaithDelta = 0.0;

  /// Materials change from the most recent interaction (negative = spent).
  double lastMaterialsDelta = 0.0;

  /// Player health change from the most recent interaction (negative = HP spent).
  double lastPlayerHealthDelta = 0.0;

  // ── Progressive faith reveal ───────────────────────────────────────────────

  /// After 3 conversations the player has a vague sense of the NPC's faith.
  bool get isFaithVague => conversationCount >= 3;

  /// After 6 conversations the player knows the NPC's exact faith level.
  bool get isFaithRevealed => conversationCount >= 6;

  /// ID of the building this NPC lives/works in.
  /// Prepared for future house-entry feature: when the player enters a
  /// building, all NPCs with a matching [homeBuildingId] can be interacted
  /// with or prayed for at once.
  final String? homeBuildingId;

  /// Whether this NPC has gone through the conversion prayer (Übergabegebet).
  /// Only true NPCs show the cross badge and influence the spiritual world.
  bool isConverted;

  NPCModel({
    required this.id,
    required this.name,
    required this.type,
    required this.homePosition,
    this.homeBuildingId,
    this.faith = 0.0,
    this.conversationCount = 0,
    this.prayerCount = 0,
    this.currentMessage,
    this.isConverted = false,
  });

  /// An NPC is considered a Christian once they have prayed the conversion
  /// prayer (Übergabegebet) with the player.  High faith alone is not enough.
  bool get isChristian => isConverted;

  /// Logic to update faith based on interaction and environment
  void applyInfluence(double amount) {
    faith = (faith + amount).clamp(-100.0, 100.0);
  }

  void resetSession() {
    currentSessionInteractions = 0;
    hadGiftThisSession = false;
    lastReactionEmoji = '';
    lastNpcFaithDelta = 0.0;
    lastPlayerFaithDelta = 0.0;
    lastMaterialsDelta = 0.0;
    lastPlayerHealthDelta = 0.0;
    // 35% chance to request material help when faith is low
    wantsGift = faith < 30 && Random().nextDouble() < 0.35;
  }
}
