import 'cell_object.dart';
import 'npc_model.dart';

/// High-level category used to pick the right interaction menu.
enum BuildingCategory { residential, commercial, church, other }

/// Runtime state for one building in the city.
///
/// Each [BuildingModel] is keyed by the unique [buildingId] that is also
/// stored on every [BuildingData] cell.  The model tracks the residents
/// assigned to the building and any per-building interaction counters.
class BuildingModel {
  /// Stable unique identifier matching [BuildingData.buildingId].
  final String buildingId;

  /// The building-type enum value used for category classification.
  final BuildingType type;

  /// NPCs that live or work in this building.
  final List<NPCModel> residents;

  /// How many times the player has successfully interacted with this building.
  /// After 3 or more interactions the access-chance bonus of +30 % applies
  /// (Lastenheft §7.4 / Issue §A).
  int totalConversations = 0;

  BuildingModel({
    required this.buildingId,
    required this.type,
    List<NPCModel>? residents,
  }) : residents = residents ?? [];

  // ── Category helpers ──────────────────────────────────────────────────────

  /// Derives the interaction category from the building type.
  BuildingCategory get category {
    switch (type) {
      case BuildingType.house:
      case BuildingType.apartment:
        return BuildingCategory.residential;

      case BuildingType.shop:
      case BuildingType.supermarket:
      case BuildingType.mall:
      case BuildingType.office:
      case BuildingType.skyscraper:
      case BuildingType.factory:
      case BuildingType.warehouse:
        return BuildingCategory.commercial;

      case BuildingType.church:
      case BuildingType.cathedral:
        return BuildingCategory.church;

      default:
        return BuildingCategory.other;
    }
  }

  /// Commercial and church buildings are always accessible; residential ones
  /// require an access check (knocking).
  bool get isAlwaysOpen => category != BuildingCategory.residential;

  // ── Access logic (Lastenheft §7.4 / Issue §A) ─────────────────────────────

  /// Returns the probability [0.0 – 1.0] that the player can enter this
  /// building given the current player [faith] level.
  ///
  /// * faith > 30  → 85 %
  /// * faith −30 .. +30 → 50 %
  /// * faith < −30 → 15 %
  /// * After 3+ successful interactions: +30 % (capped at 1.0)
  double accessChance(double playerFaith) {
    if (isAlwaysOpen) return 1.0;

    double base;
    if (playerFaith > 30) {
      base = 0.85;
    } else if (playerFaith >= -30) {
      base = 0.50;
    } else {
      base = 0.15;
    }

    if (totalConversations >= 3) {
      base = (base + 0.30).clamp(0.0, 1.0);
    }
    return base;
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
