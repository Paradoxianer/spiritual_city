import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/models/building_model.dart';
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
  static const double _markerRadius = 4.0;

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
  String get interactionLabel => _label();

  @override
  String get interactionEmoji => _emoji();

  @override
  Vector2 get interactionPosition => position;

  @override
  void onInteract() {
    game.openBuildingInterior(buildingModel);
  }

  @override
  String handleInteraction(String type) => _emoji();

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _label() {
    switch (buildingModel.category) {
      case BuildingCategory.residential:
        return 'Haus';
      case BuildingCategory.commercial:
        return 'Geschäft';
      case BuildingCategory.church:
        return 'Kirche';
      default:
        return 'Gebäude';
    }
  }

  String _emoji() {
    switch (buildingModel.category) {
      case BuildingCategory.residential:
        return '🏠';
      case BuildingCategory.commercial:
        return '🏢';
      case BuildingCategory.church:
        return '⛪';
      default:
        return '🏗️';
    }
  }

  // ── Rendering ─────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    // Render a small amber entrance-marker dot in the physical world.
    if (!game.isSpiritualWorld) {
      final paint = Paint()
        ..color = Colors.amber.withValues(alpha: 0.65)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        _markerRadius,
        paint,
      );
    }
  }
}
