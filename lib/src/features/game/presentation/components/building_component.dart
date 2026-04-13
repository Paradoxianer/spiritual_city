import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/models/building_model.dart';
import '../../domain/models/cell_object.dart';
import '../../domain/models/interactions.dart';
import '../spirit_world_game.dart';

/// A lightweight game-world component that marks a building entrance and
/// implements [Interactable] so that it appears in the radial menu when the
/// player is within interaction range.
///
/// One [BuildingComponent] is spawned per unique building when its chunk is
/// loaded (by [ChunkManager]).  Unlike [NPCComponent], it does not move.
class BuildingComponent extends PositionComponent
    with HasGameReference<SpiritWorldGame>
    implements Interactable {
  final BuildingModel buildingModel;

  /// Visual radius of the entrance marker (world units).
  static const double _markerRadius = 6.0;

  BuildingComponent({
    required this.buildingModel,
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2.all(_markerRadius * 2),
          anchor: Anchor.center,
          priority: 5,
        );

  // ── Interactable ──────────────────────────────────────────────────────────

  @override
  String get interactionLabel => _buildingName();

  @override
  String get interactionEmoji => _buildingEmoji();

  @override
  Vector2 get interactionPosition => position;

  @override
  void onInteract() {
    game.openBuildingInterior(buildingModel);
  }

  @override
  String handleInteraction(String type) => _buildingEmoji();

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _buildingName() {
    switch (buildingModel.type) {
      case BuildingType.house:        return 'Wohnhaus';
      case BuildingType.apartment:    return 'Wohnblock';
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

  String _buildingEmoji() {
    switch (buildingModel.type) {
      case BuildingType.house:        return '🏠';
      case BuildingType.apartment:    return '🏢';
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

  // ── Rendering ─────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    // Render an entrance-marker in the physical world.
    if (!game.isSpiritualWorld) {
      final category = buildingModel.category;
      // Pick marker colour by category
      final Color markerColor;
      switch (category) {
        case BuildingCategory.residential:
          markerColor = Colors.lightBlueAccent;
          break;
        case BuildingCategory.church:
          markerColor = Colors.amber;
          break;
        case BuildingCategory.civic:
          markerColor = Colors.greenAccent;
          break;
        case BuildingCategory.industrial:
          markerColor = Colors.orangeAccent;
          break;
        default:
          markerColor = Colors.amberAccent;
      }

      // Outer glow ring
      final glowPaint = Paint()
        ..color = markerColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        _markerRadius,
        glowPaint,
      );

      // Solid centre dot
      final dotPaint = Paint()
        ..color = markerColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        _markerRadius * 0.55,
        dotPaint,
      );
    }
  }
}
