/// Shared base class for all entities in the world that can be interacted
/// with (NPCs and Buildings).
///
/// Centralises the faith system, unified interaction counter, session tracking,
/// mission attachment, and influence mechanics so that future features can
/// operate on any [BaseInteractableEntity] without knowing whether it is an
/// NPC or a building.
abstract class BaseInteractableEntity {
  /// Stable unique identifier for this entity.
  String get id;

  /// Faith Level: -100.0 to +100.0.
  ///
  /// Negative = hostile / dark;  Positive = open / holy.
  double faith;

  /// Unified interaction counter across all interaction types.
  ///
  /// Incremented by every successful interaction.  Used for probability
  /// calculations and to unlock higher session limits (see [maxSessionInteractions]).
  int interactionCount;

  /// Tracks interactions in the current active dialogue/visit session.
  ///
  /// Reset to 0 at the start of each new session via [resetSession].
  /// Always initialised to 0 – sessions begin fresh for every entity.
  int currentSessionInteractions = 0;

  /// Active mission attached to this entity (null = no mission).
  String? activeMissionDescription;

  BaseInteractableEntity({
    this.faith = 0.0,
    this.interactionCount = 0,
  });

  /// Bonus session slots unlocked by the total [interactionCount].
  ///
  /// Thresholds and the corresponding dots shown in the header:
  ///
  /// | interactionCount | extra bonus | default total (base = 2) |
  /// |------------------|-------------|--------------------------|
  /// |  < 3             | 0           | 2                        |
  /// |  3 – 8           | +1          | 3                        |
  /// |  9 – 20          | +2          | 4                        |
  /// |  21 – 64         | +3          | 5                        |
  /// |  65 – 194        | +4          | 6                        |
  /// |  195 – 584       | +5          | 7                        |
  /// |  585+            | +6          | 8  (etc.)                |
  ///
  /// [BuildingModel] adds the bonus on top of its type-specific base
  /// instead of the default base of 2.
  int get sessionBonus {
    const thresholds = [3, 9, 21, 65, 195, 585, 1755];
    int n = 0;
    for (final t in thresholds) {
      if (interactionCount >= t) n++;
      else break;
    }
    return n;
  }

  /// Max allowed interactions per session.
  ///
  /// Starts at 2 and grows via [sessionBonus] – reflecting that you naturally
  /// talk longer with people (or visit places) you know well.
  int get maxSessionInteractions => 2 + sessionBonus;

  /// Whether the session interaction limit has been reached for this entity.
  bool get isReadyToLeave => currentSessionInteractions >= maxSessionInteractions;

  // ── Progressive faith reveal ──────────────────────────────────────────────

  /// After 3 total interactions the player has a vague sense of the entity's
  /// faith level (shown as a bar rounded to the nearest 25 %).
  bool get isFaithVague => interactionCount >= 3;

  /// After 6 total interactions the player knows the entity's exact faith
  /// level.
  bool get isFaithRevealed => interactionCount >= 6;

  /// Apply a faith [amount] to this entity, clamped to the valid range
  /// -100..100.
  void applyInfluence(double amount) {
    faith = (faith + amount).clamp(-100.0, 100.0);
  }

  /// Reset session state.
  ///
  /// Subclasses should call `super.resetSession()` and add their own logic.
  void resetSession() {
    currentSessionInteractions = 0;
  }
}
