import 'dart:math';
import 'package:flame/components.dart';
import 'base_interactable_entity.dart';

enum NPCType {
  citizen,
  merchant,
  priest,
  officer,
}

/// NPC Data Model based on Lastenheft Section 6.2
class NPCModel extends BaseInteractableEntity {
  @override
  final String id;

  final String name;
  final NPCType type;
  final Vector2 homePosition;

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

  /// ID of the building this NPC lives/works in.
  final String? homeBuildingId;

  /// Whether this NPC has gone through the conversion prayer (Übergabegebet).
  bool isConverted;

  /// Last saved world-pixel position.  Set by [SpiritWorldGame.applySavedNPCState]
  /// when loading a game; consumed once by [NPCComponent] to restore the NPC's
  /// position and then left in place.  Null for freshly-generated NPCs.
  Vector2? savedPosition;

  NPCModel({
    required this.id,
    required this.name,
    required this.type,
    required this.homePosition,
    this.homeBuildingId,
    double faith = 0.0,
    int interactionCount = 0,
    this.currentMessage,
    this.isConverted = false,
  }) : super(faith: faith, interactionCount: interactionCount);

  /// An NPC is considered a Christian once they have prayed the conversion
  /// prayer (Übergabegebet) with the player.  High faith alone is not enough.
  bool get isChristian => isConverted;

  @override
  void resetSession() {
    super.resetSession();
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
