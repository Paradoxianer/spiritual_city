import 'package:flame/components.dart';
import '../../domain/models/building_model.dart';
import '../../domain/models/cell_object.dart';
import '../../domain/models/interactions.dart';
import '../spirit_world_game.dart';

/// A game-world component that represents one building as an [Interactable].
///
/// It has no visual rendering – the tile renderer already draws the building.
/// The component exists purely so the radial menu can discover it when the
/// player walks up to a building wall.
class BuildingComponent extends PositionComponent
    with HasGameReference<SpiritWorldGame>
    implements Interactable {
  final BuildingModel buildingModel;

  BuildingComponent({
    required this.buildingModel,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2.all(4),
          anchor: Anchor.center,
          priority: 5,
        );

  // ── Interactable ──────────────────────────────────────────────────────────

  @override
  String get interactionLabel => buildingName(buildingModel.type);

  @override
  String get interactionEmoji => buildingEmoji(buildingModel.type);

  @override
  Vector2 get interactionPosition => position;

  @override
  void onInteract() => game.openBuildingInterior(buildingModel);

  @override
  String handleInteraction(String type) => buildingEmoji(buildingModel.type);

  // ── Static helpers (reused by the overlay) ────────────────────────────────

  static String buildingName(BuildingType type) {
    switch (type) {
      case BuildingType.house:        return 'Wohnhaus';
      case BuildingType.apartment:    return 'Wohnblock';
      case BuildingType.pastorHouse:  return 'Pastorhaus';
      case BuildingType.shop:         return 'Geschäft';
      case BuildingType.supermarket:  return 'Supermarkt';
      case BuildingType.mall:         return 'Einkaufszentrum';
      case BuildingType.office:       return 'Bürogebäude';
      case BuildingType.skyscraper:   return 'Hochhaus';
      case BuildingType.factory:      return 'Fabrik';
      case BuildingType.warehouse:    return 'Lagerhaus';
      case BuildingType.church:       return 'Kirche';
      case BuildingType.cathedral:    return 'Dom';
      case BuildingType.trainStation: return 'Bahnhof';
      case BuildingType.policeStation:return 'Polizeiwache';
      case BuildingType.fireStation:  return 'Feuerwehr';
      case BuildingType.postOffice:   return 'Postamt';
      case BuildingType.hospital:     return 'Krankenhaus';
      case BuildingType.school:       return 'Schule';
      case BuildingType.university:   return 'Universität';
      case BuildingType.library:      return 'Bibliothek';
      case BuildingType.museum:       return 'Museum';
      case BuildingType.stadium:      return 'Stadion';
      case BuildingType.cityHall:     return 'Rathaus';
      case BuildingType.cemetery:     return 'Friedhof';
      case BuildingType.powerPlant:   return 'Kraftwerk';
      default:                        return 'Gebäude';
    }
  }

  static String buildingEmoji(BuildingType type) {
    switch (type) {
      case BuildingType.house:        return '🏠';
      case BuildingType.apartment:    return '🏢';
      case BuildingType.pastorHouse:  return '🏡';
      case BuildingType.shop:         return '🏪';
      case BuildingType.supermarket:  return '🛒';
      case BuildingType.mall:         return '🛍️';
      case BuildingType.office:       return '🏢';
      case BuildingType.skyscraper:   return '🏙️';
      case BuildingType.factory:      return '🏭';
      case BuildingType.warehouse:    return '🏗️';
      case BuildingType.church:       return '⛪';
      case BuildingType.cathedral:    return '⛪';
      case BuildingType.trainStation: return '🚉';
      case BuildingType.policeStation:return '🚔';
      case BuildingType.fireStation:  return '🚒';
      case BuildingType.postOffice:   return '📮';
      case BuildingType.hospital:     return '🏥';
      case BuildingType.school:       return '🏫';
      case BuildingType.university:   return '🎓';
      case BuildingType.library:      return '📚';
      case BuildingType.museum:       return '🏛️';
      case BuildingType.stadium:      return '🏟️';
      case BuildingType.cityHall:     return '🏛️';
      case BuildingType.cemetery:     return '🪦';
      case BuildingType.powerPlant:   return '⚡';
      default:                        return '🏗️';
    }
  }
}
