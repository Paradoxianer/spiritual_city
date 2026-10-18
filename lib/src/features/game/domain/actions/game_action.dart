import '../../../menu/domain/models/difficulty.dart';
import '../models/skills.dart';
import 'practice.dart';
import 'resource.dart';

/// Every action the player can take on an NPC or inside a building
/// (docs/game_design/release_roadmap.md §2.1).
///
/// Building actions that share a wire type (`'pray'` exists in the pastor
/// house, in homes and in generic buildings) still get their own id because
/// they cost and do different things.
enum ActionId {
  // ── NPC dialog ──────────────────────────────────────────────────────────
  talk,
  counsel,
  pray,
  bible,
  help,
  convert,
  lifeTalk,

  // ── Pastor house ────────────────────────────────────────────────────────
  readBible,
  eat,
  sleep,
  homePray,
  missions,

  // ── Homes ───────────────────────────────────────────────────────────────
  practicalHelp,
  housePray,
  houseVisit,
  discipleshipGroup,
  blessHousehold,

  // ── Church ──────────────────────────────────────────────────────────────
  sundayService,
  worship,

  // ── Hospital ────────────────────────────────────────────────────────────
  medicalHelp,
  counseling,
  chapelService,

  // ── School / university ─────────────────────────────────────────────────
  letterToManagement,
  talkDirector,
  valueLecture,
  prayerCircle,

  // ── Cemetery ────────────────────────────────────────────────────────────
  funeral,
  comfort,

  // ── Police / city hall / station / stadium ──────────────────────────────
  blessPolice,
  intercede,
  fast,
  preach,
  mayorAudience,
  prayForPoliticians,
  travel,
  majorEvent,

  // ── Commercial ──────────────────────────────────────────────────────────
  talkBoss,
  shopping,
  bless,
  requestDonation,

  // ── Generic buildings ───────────────────────────────────────────────────
  genericPray,
  witness,
  distribute,

  // ── Civic & work places (playtest 2026-10-18: what a pastor really does
  //    there; only prayer refreshes his own faith) ───────────────────────
  blessVehicles,
  chaplaincy,
  bringMeal,
  sendCards,
  study,
  bookCircle,
  churchHistory,
  workShift,
  prayWorkers,
}

/// Whether an action can be used right now, and if not, why.
sealed class Availability {
  const Availability();

  bool get isOk => this is AvailableNow;

  /// Emoji explaining why the action is unavailable (`null` when available).
  String? get reason => switch (this) {
        AvailableNow() => null,
        Locked(:final emoji) => emoji,
        CannotAfford(:final resource) => '🚫${resource.emoji}',
      };
}

class AvailableNow extends Availability {
  const AvailableNow();
}

/// A precondition of the subject is not met yet (e.g. too few visits).
class Locked extends Availability {
  final String emoji;
  const Locked(this.emoji);
}

/// The player lacks [resource].
class CannotAfford extends Availability {
  final Resource resource;
  const CannotAfford(this.resource);
}

/// One action = one definition (emoji, cost, hint, timing, preconditions).
///
/// [T] is the subject the action is used on: an `NPCModel` or a
/// `BuildingModel`. Executing the action stays in the domain services
/// (`NpcInteractionService`, `BuildingInteractionService`), which receive
/// [type] as before.
class GameAction<T> {
  final ActionId id;

  /// Wire type understood by the interaction services and `MissionService`.
  final String type;

  final String emoji;

  /// Emoji describing the effect, shown after the generated cost hint
  /// (`−5🙏 → 🌱`).
  final String effect;

  final ResourceCost Function(Difficulty d) _cost;

  /// Base duration in seconds (0 = instant). Scaled by difficulty in the UI.
  final int baseSeconds;

  /// Session points used; counselling takes two.
  final int sessionPoints;

  /// Spiritual discipline the action trains (see [Practice]), if any.
  final Discipline? discipline;

  /// Only offered once this skill was learned (learning missions, §3.9).
  final Skill? needsSkill;

  /// Shown at all for this subject? (e.g. 📦 only when the NPC wants a gift)
  final bool Function(T subject)? _visible;

  /// Returns a lock emoji while a precondition of the subject is unmet.
  final String? Function(T subject)? _lockedBy;

  const GameAction({
    required this.id,
    required this.type,
    required this.emoji,
    required this.effect,
    ResourceCost Function(Difficulty d) cost = _free,
    this.baseSeconds = 0,
    this.sessionPoints = 1,
    this.discipline,
    this.needsSkill,
    bool Function(T subject)? visible,
    String? Function(T subject)? lockedBy,
  })  : _cost = cost,
        _visible = visible,
        _lockedBy = lockedBy;

  static ResourceCost _free(Difficulty _) => ResourceCost.none;

  ResourceCost cost(Difficulty d) => _cost(d);

  bool isVisibleFor(T subject) => _visible?.call(subject) ?? true;

  Availability availability(T subject, ResourceWallet wallet, Difficulty d) {
    final lock = _lockedBy?.call(subject);
    if (lock != null) return Locked(lock);
    final missing = cost(d).missing(wallet);
    if (missing != null) return CannotAfford(missing);
    return const AvailableNow();
  }

  /// Generated hint, e.g. `−5🙏−2❤️→🌱` or `→✝️` for free actions.
  String hint(Difficulty d) => '${cost(d).hint}→$effect';
}
