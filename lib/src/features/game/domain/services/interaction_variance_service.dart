import '../models/npc_model.dart';

/// Breaks up the dominant "always the same action" strategy in NPC
/// interactions (Issue #171).
///
/// Combines three effects into one multiplier applied to an interaction's
/// faith gain:
///  - **Repeat decay**: reusing the same action type on the same NPC within
///    a session yields less each time.
///  - **Variance bonus**: switching to a different action type than the last
///    one used this session is rewarded.
///  - **Need multiplier**: every NPC has one hidden need ([NpcNeed]); the
///    matching action type is strong, everything else is weak.
///
/// See `docs/game_design/progression_and_unlocks.md` §6 for the design.
class InteractionVarianceService {
  /// Repeat-decay factors by how many times [actionType] was already used on
  /// this NPC *this session*, before the interaction currently being scored.
  static const double repeatFactorFirstUse = 1.0;
  static const double repeatFactorSecondUse = 0.6;
  static const double repeatFactorThirdUsePlus = 0.35;

  /// Bonus applied when the action type differs from the last one used this
  /// session (no bonus for the very first action, or for repeating).
  static const double varianceBonus = 1.2;

  /// Multiplier when [actionType] matches the NPC's hidden [NpcNeed].
  static const double needStrongMultiplier = 2.0;

  /// Multiplier when it doesn't.
  static const double needWeakMultiplier = 0.75;

  /// Repeat-decay factor for the [priorUses]-th reuse of an action type.
  static double repeatFactorFor(int priorUses) => switch (priorUses) {
        0 => repeatFactorFirstUse,
        1 => repeatFactorSecondUse,
        _ => repeatFactorThirdUsePlus,
      };

  /// Combined multiplier for performing [actionType] on [npc] *right now*.
  ///
  /// Reads [npc]'s session history (so call this **before**
  /// [NPCModel.recordAction] for the same interaction – recording first
  /// would make every action look like a fresh first use).
  static double multiplierFor(NPCModel npc, String actionType) {
    final repeatFactor = repeatFactorFor(npc.sessionCountFor(actionType));
    final changedAction =
        npc.lastActionType != null && npc.lastActionType != actionType;
    final varianceFactor = changedAction ? varianceBonus : 1.0;
    final needFactor = npc.needMatchesAction(actionType)
        ? needStrongMultiplier
        : needWeakMultiplier;
    return repeatFactor * varianceFactor * needFactor;
  }
}
