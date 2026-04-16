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

  /// How many times the player counselled (Seelsorge) this NPC.
  int counselingCount;

  /// Tracks interactions in the current active dialogue session
  int currentSessionInteractions = 0;

  /// True once the NPC has received 3 interactions this session.
  bool get isReadyToLeave => currentSessionInteractions >= 3;

  /// Whether the player gave a gift (help action) during this session.
  bool hadGiftThisSession = false;

  /// Emoji of the last end-of-session reaction, e.g. '🙏'.
  String lastReactionEmoji = '';

  String? currentMessage;

  /// ID of the building this NPC lives/works in.
  final String? homeBuildingId;

  // ── Gift request (issue #46) ───────────────────────────────────────────────

  /// True when the NPC has requested materials this session.
  /// Set randomly in [resetSession]; the 📦 chip is only shown when true.
  bool wantsGift = false;

  // ── Delta tracking for header display (issue #46) ─────────────────────────

  /// Change in NPC faith from the last interaction (✝️).
  double lastNpcFaithDelta = 0.0;

  /// Change in player faith from the last interaction (🙏).
  double lastPlayerFaithDelta = 0.0;

  /// Change in player materials from the last interaction (📦).
  double lastMaterialsDelta = 0.0;

  static final _sessionRng = Random();

  /// Probability (0–100) that an NPC will request materials at session start
  /// when their faith is not yet positive.
  static const int _giftRequestChance = 35;

  NPCModel({
    required this.id,
    required this.name,
    required this.type,
    required this.homePosition,
    this.homeBuildingId,
    this.faith = 0.0,
    this.conversationCount = 0,
    this.prayerCount = 0,
    this.counselingCount = 0,
    this.currentMessage,
  });

  /// An NPC is considered a Christian if faith is above 50 (Lastenheft 6.2)
  bool get isChristian => faith > 50;

  // ── Faith visibility (issue #45) ──────────────────────────────────────────

  /// After 6+ conversations the player knows the NPC's true faith.
  bool get isFaithRevealed => conversationCount >= 6;

  /// After 3–5 conversations the player has a vague sense of the NPC's faith.
  bool get isFaithVague => conversationCount >= 3;

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
    // NPC randomly requests materials when their faith is not yet positive.
    wantsGift = faith < 30 && _sessionRng.nextInt(100) < _giftRequestChance;
  }
}
