import 'dart:math';
import 'package:flame/components.dart';
import '../../../../core/utils/stable_hash.dart';
import 'base_interactable_entity.dart';
import 'npc_backstory.dart';

enum NPCType {
  citizen,
  merchant,
  priest,
  officer,
}

/// A hidden, per-NPC need that makes one interaction type especially
/// effective on this NPC and the rest comparatively weaker (Issue #171).
///
/// Deterministic and derived from the NPC's [NPCModel.id] – never persisted,
/// so old saves automatically get a need without any migration, and it
/// survives regenerating the same NPC from the same seed.
enum NpcNeed {
  /// Einsam – craves conversation.
  lonely,

  /// Zweifelnd – craves counseling (Seelsorge).
  doubting,

  /// Suchend – craves Bible study.
  seeking,

  /// Bedürftig/krank – craves prayer or practical help.
  needy,
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

  // ── Interaction variance & needs (Issue #171) ──────────────────────────────

  /// This NPC's hidden need, deterministic from [id] (see [NpcNeed]).
  late final NpcNeed need = NpcNeed.values[stableStringHash(id) % NpcNeed.values.length];

  /// This NPC's generated life history – see `docs/game_design/npc_backstory.md`.
  /// Deterministic from [id], computed once. Not persisted itself, but the
  /// player's processing *progress* on individual events is – see
  /// [captureBackstoryProgress]/[restoreBackstoryProgress].
  late final NpcBackstory backstory = NpcBackstoryService.generate(id);

  /// Generates this NPC's "Als Christ" chapter once [isConverted] is true.
  /// Safe to call unconditionally, as often as needed (idempotent, no-op
  /// before conversion) – called after every place [isConverted] can become
  /// true: initial spawn, a live conversion, and restoring a save.
  void unlockChristPhaseIfConverted() {
    backstory.ensureChristPhaseFor(id, isConverted: isConverted);
  }

  /// Sparse `{ eventId: workProgress }` map for saving – see
  /// [NpcBackstory.captureProgress].
  Map<String, int> captureBackstoryProgress() => backstory.captureProgress();

  /// Restores processing progress captured by [captureBackstoryProgress].
  void restoreBackstoryProgress(Map<String, dynamic> saved) =>
      backstory.restoreProgress(saved);

  /// Whether [actionType] ('talk' / 'counsel' / 'bible' / 'pray' / 'help') is
  /// this NPC's strong need – see the table on [NpcNeed].
  bool needMatchesAction(String actionType) => switch (need) {
        NpcNeed.lonely => actionType == 'talk',
        NpcNeed.doubting => actionType == 'counsel',
        NpcNeed.seeking => actionType == 'bible',
        NpcNeed.needy => actionType == 'pray' || actionType == 'help',
      };

  /// How many times each action type has been used on this NPC in the
  /// current session (diminishing returns – reset by [resetSession]).
  final Map<String, int> _sessionActionCounts = {};

  /// The action type of the most recent interaction this session, or null at
  /// session start (used for the variance bonus).
  String? lastActionType;

  /// Prior uses of [actionType] *before* the interaction currently being
  /// resolved – i.e. call this before [recordAction] for the same call.
  int sessionCountFor(String actionType) => _sessionActionCounts[actionType] ?? 0;

  /// Records that [actionType] was just performed, for next time's repeat
  /// and variance calculations.
  void recordAction(String actionType) {
    _sessionActionCounts[actionType] = sessionCountFor(actionType) + 1;
    lastActionType = actionType;
  }

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
    // Issue #171: repeat-decay and variance-bonus tracking only spans a
    // single visit/session, like currentSessionInteractions above.
    _sessionActionCounts.clear();
    lastActionType = null;
  }
}
