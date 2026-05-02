import '../../../../core/utils/game_time.dart';
import 'base_interactable_entity.dart';
import 'cell_object.dart';
import 'npc_model.dart';

/// Two-state category: residential buildings require knocking; everything else
/// is always open.
enum BuildingCategory { residential, other }

// ── Influence constants (Issue #118 AC: "agentenlesbare Formel") ─────────────

/// AoE building-influence constants shared by [InfluenceService] calls and
/// [NPCComponent] passive influence.
///
/// All multipliers and radii are named here so no magic numbers appear at
/// call sites.  The table below summarises the formula per action:
///
/// | Action                | delta | radius                         | duration                        | multiplier              |
/// |---|---|---|---|---|
/// | Praktische Hilfe (Resi)  | +0.05 | [radiusPracticalHelp]         | temporary 1 game-hour           | [multiplierSmall]       |
/// | Jüngerschaftsgruppe (Resi)| +0.3 | [radiusDiscipleshipGroup]    | permanent                       | [multiplierSmall]       |
/// | Gottesdienst (Kirche)    | +0.5  | [radiusWorship]               | decaying 12 game-hours          | [multiplierMedium]      |
/// | Segnen (Shop/Police/…)   | +0.2  | [radiusBless]                 | temporary 1 game-hour           | [multiplierMedium]      |
/// | Gebetskreis (School)     | +0.1  | [radiusPrayerCircle]          | temporary 1 game-day            | [multiplierMedium]      |
/// | Bekehrte NPCs (passiv)   | +0.02 | [radiusNpcPassive]            | permanent (per tick)            | [multiplierSmall]       |
abstract final class BuildingInfluenceConstants {
  // ── Power multipliers per building size ──────────────────────────────────

  /// Small residential (house, apartment): baseline influence multiplier.
  static const double multiplierSmall = 1.0;

  /// Medium civic / commercial (shop, church, school, hospital, …): 1.5× boost.
  static const double multiplierMedium = 1.5;

  /// Large public venues (stadium, skyscraper, cityHall, …): 2.5× boost.
  static const double multiplierLarge = 2.5;

  /// Spiritual / ministry buildings (cathedral, pastorHouse): 5× boost.
  static const double multiplierSpiritual = 5.0;

  // ── Default AoE radii (in grid cells) ────────────────────────────────────

  /// Residential practical help: 1-cell radius.
  static const double radiusPracticalHelp = 1.0;

  /// Discipleship group: 3-cell radius.
  static const double radiusDiscipleshipGroup = 3.0;

  /// Worship service: 10-cell radius (spec: 8–15).
  static const double radiusWorship = 10.0;

  /// Bless action (shop, police, commercial): 3-cell radius (spec: 1–5).
  static const double radiusBless = 3.0;

  /// Prayer circle (school): 3-cell radius.
  static const double radiusPrayerCircle = 3.0;

  /// Converted NPC passive influence: 1-cell radius.
  static const double radiusNpcPassive = 1.0;

  // ── Duration helpers (in real seconds, derived from GameTime) ────────────

  /// One in-game hour expressed as real seconds.
  static const double gameHourSeconds = GameTime.gameDaySeconds / 24.0;

  /// One in-game day expressed as real seconds.
  static const double gameDaySeconds = GameTime.gameDaySeconds;

  /// Twelve in-game hours expressed as real seconds.
  static const double gameHalfDaySeconds = GameTime.gameDaySeconds / 2.0;

  // ── Per-action deltas ────────────────────────────────────────────────────

  /// Spiritual-state delta for residential practical help.
  static const double deltaPracticalHelp = 0.05;

  /// Spiritual-state delta for a discipleship group meeting.
  static const double deltaDiscipleshipGroup = 0.3;

  /// Spiritual-state delta for a worship service.
  static const double deltaWorship = 0.5;

  /// Spiritual-state delta for a bless action (shop / police / commercial).
  static const double deltaBless = 0.2;

  /// Spiritual-state delta for a prayer circle.
  static const double deltaPrayerCircle = 0.1;

  /// Spiritual-state delta per passive NPC tick.
  static const double deltaNpcPassive = 0.02;
}

/// Runtime state for one building in the city.
///
/// Each [BuildingModel] is keyed by the unique [buildingId] that is also
/// stored on every [BuildingData] cell.  The model tracks the residents
/// assigned to the building and any per-building interaction counters.
class BuildingModel extends BaseInteractableEntity {
  /// Stable unique identifier matching [BuildingData.buildingId].
  final String buildingId;

  @override
  String get id => buildingId;

  /// The building-type enum value used for category classification.
  final BuildingType type;

  /// NPCs that live or work in this building.
  final List<NPCModel> residents;

  /// Whether this building is the pastor's own home (the player's base).
  /// Only one building in the city should have this set to `true`.
  final bool isHomebase;

  /// Cemetery: set to `true` after a funeral is held, enabling the one-time
  /// "Trost" (comfort) action.  Reset to `false` after comfort is used.
  bool hasFuneralCompleted = false;

  /// School/University: set to `true` after "Gespräch mit Direktor" unlocks
  /// the "Werte-Vortrag halten" action.
  bool isLecturePrepared = false;

  BuildingModel({
    required this.buildingId,
    required this.type,
    List<NPCModel>? residents,
    this.isHomebase = false,
    double faith = 0.0,
    int interactionCount = 0,
  })  : residents = residents ?? [],
        super(faith: faith, interactionCount: interactionCount);

  // ── Session limits ────────────────────────────────────────────────────────

  /// Type-specific minimum number of interactions allowed per visit session.
  ///
  /// Public / commercial buildings are visited for longer than private homes.
  ///
  /// | Category                        | Base |
  /// |---------------------------------|------|
  /// | Pastor house (homebase)         | ∞ (int.maxFinite – no forced leave) |
  /// | Residential (house, apartment)  | 2    |
  /// | Commercial (shop, market, …)    | 4    |
  /// | Church / cathedral              | 3    |
  /// | Civic / public (hospital, …)    | 3    |
  /// | Industrial / other              | 2    |
  int get baseSessionInteractions {
    if (isHomebase) return 999; // effectively unlimited
    switch (type) {
      case BuildingType.shop:
      case BuildingType.supermarket:
      case BuildingType.mall:
      case BuildingType.office:
      case BuildingType.skyscraper:
        return 4;
      case BuildingType.church:
      case BuildingType.cathedral:
        return 3;
      case BuildingType.hospital:
      case BuildingType.school:
      case BuildingType.university:
      case BuildingType.trainStation:
      case BuildingType.policeStation:
      case BuildingType.fireStation:
      case BuildingType.postOffice:
      case BuildingType.library:
      case BuildingType.museum:
      case BuildingType.stadium:
      case BuildingType.cityHall:
        return 3;
      case BuildingType.house:
      case BuildingType.apartment:
      default:
        return 2;
    }
  }

  /// Max interactions per session, floored by [baseSessionInteractions].
  ///
  /// Grows over time as the player visits more often (Issue #105), but never
  /// drops below the type-specific base.
  @override
  int get maxSessionInteractions => baseSessionInteractions + sessionBonus;

  // ── Combined faith ────────────────────────────────────────────────────────

  /// Combined faith of the building itself plus all its residents.
  ///
  /// Represents the overall spiritual atmosphere of the household: the
  /// building's own holiness value plus each resident NPC's faith level.
  double get combinedFaith =>
      faith + residents.fold(0.0, (sum, npc) => sum + npc.faith);

  // ── Influence radius ──────────────────────────────────────────────────────

  /// The radius (in cells) within which this building's faith influences the
  /// spiritual world.
  ///
  /// Buildings affect a larger area than individual NPCs (Issue #96, #116):
  /// "Häuser haben nicht den isChrist-Effekt, ihre Heiligkeit beeinflusst
  /// immer (minimal) die unsichtbare Welt, dafür aber in einem größeren Radius"
  double get influenceRadius => 3.0;

  // ── Category helpers ──────────────────────────────────────────────────────

  /// Residential buildings (house, apartment) need knocking; everything else
  /// is always open.
  BuildingCategory get category {
    switch (type) {
      case BuildingType.house:
      case BuildingType.apartment:
        return BuildingCategory.residential;
      default:
        return BuildingCategory.other;
    }
  }

  /// Non-residential buildings are always accessible without knocking.
  bool get isAlwaysOpen => category == BuildingCategory.other;

  // ── Access logic (building_actions.md §"Zugang & Interaktion") ───────────

  /// Returns the probability [0.0 – 1.0] that the player can enter this
  /// building given the current player [faith] level.
  ///
  /// Formula (per spec):  `base + interactionCount × 2 %`
  /// * faith > 30  → base 85 %
  /// * faith −30 .. +30 → base 50 %
  /// * faith < −30 → base 15 %
  /// * At 20 or more total interactions: always 100 % (guaranteed).
  double accessChance(double playerFaith) {
    if (isAlwaysOpen) return 1.0;
    if (interactionCount >= 20) return 1.0;

    double base;
    if (playerFaith > 30) {
      base = 0.85;
    } else if (playerFaith >= -30) {
      base = 0.50;
    } else {
      base = 0.15;
    }

    return (base + interactionCount * 0.02).clamp(0.0, 1.0);
  }

  // ── NPC group influence ───────────────────────────────────────────────────

  /// Apply [amount] faith to every resident NPC (for prayers / Bible reading
  /// that influence the whole household – Issue §A/D and §B).
  void influenceResidents(double amount) {
    for (final npc in residents) {
      npc.applyInfluence(amount);
    }
  }
}
