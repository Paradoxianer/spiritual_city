import 'dart:math';
import '../models/building_model.dart';
import '../models/cell_object.dart';

/// Result returned by [BuildingInteractionService.performAction].
class BuildingInteractionResult {
  /// How much the player's faith changes (positive = gain, negative = loss).
  final double playerFaithDelta;

  /// How much the player's materials change (positive = gain, negative = cost).
  final double playerMaterialsDelta;

  /// Emoji string shown in the UI as feedback.
  final String reactionEmoji;

  /// Whether the action succeeded (e.g. donation may fail).
  final bool success;

  const BuildingInteractionResult({
    this.playerFaithDelta = 0,
    this.playerMaterialsDelta = 0,
    required this.reactionEmoji,
    this.success = true,
  });
}

/// Encapsulates all building-interaction logic so that it can be tested
/// independently from Flame / Flutter.
///
/// Pass a [rng] instance in unit tests for deterministic results.
class BuildingInteractionService {
  final Random _rng;

  BuildingInteractionService({Random? rng}) : _rng = rng ?? Random();

  // ── Access control ────────────────────────────────────────────────────────

  /// Returns `true` when the player is allowed to enter [building].
  bool attemptAccess(BuildingModel building, double playerFaith) {
    if (building.isAlwaysOpen) return true;
    return _rng.nextDouble() < building.accessChance(playerFaith);
  }

  // ── Action dispatch ───────────────────────────────────────────────────────

  /// Perform [actionType] inside [building] and return the result.
  ///
  /// `'letter'` works for every building type.
  /// All other actions are dispatched by [BuildingType].
  BuildingInteractionResult performAction(
    String actionType,
    BuildingModel building,
    double playerFaith,
  ) {
    // Letter is always available regardless of building type.
    if (actionType == 'letter') return _letterAction(building);

    switch (building.type) {
      // ── Pastor's house ────────────────────────────────────────────────────
      case BuildingType.pastorHouse:
        return _pastorHouseAction(actionType, building);

      // ── Residential ───────────────────────────────────────────────────────
      case BuildingType.house:
      case BuildingType.apartment:
        return _residentialAction(actionType, building);

      // ── Commercial ────────────────────────────────────────────────────────
      case BuildingType.shop:
      case BuildingType.supermarket:
      case BuildingType.mall:
      case BuildingType.office:
      case BuildingType.skyscraper:
        return _commercialAction(actionType, building);

      // ── Church ────────────────────────────────────────────────────────────
      case BuildingType.church:
      case BuildingType.cathedral:
        return _churchAction(actionType, building);

      // ── Hospital ──────────────────────────────────────────────────────────
      case BuildingType.hospital:
        return _hospitalAction(actionType, building);

      // ── School / University ───────────────────────────────────────────────
      case BuildingType.school:
      case BuildingType.university:
        return _schoolAction(actionType, building);

      // ── Cemetery ──────────────────────────────────────────────────────────
      case BuildingType.cemetery:
        return _cemeteryAction(actionType, building);

      // ── Everything else (factory, office, civic, …) ───────────────────────
      default:
        return _genericAction(actionType, building);
    }
  }

  // ── Letter (universal) ────────────────────────────────────────────────────

  BuildingInteractionResult _letterAction(BuildingModel building) {
    building.influenceResidents(1.0);
    return const BuildingInteractionResult(
      playerFaithDelta: 3.0,
      reactionEmoji: '✉️🙏',
    );
  }

  // ── Pastor's house ────────────────────────────────────────────────────────

  BuildingInteractionResult _pastorHouseAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      case 'readBible':
        return const BuildingInteractionResult(
          playerFaithDelta: 20.0,
          reactionEmoji: '📖✝️',
        );
      case 'pray':
        return const BuildingInteractionResult(
          playerFaithDelta: 15.0,
          reactionEmoji: '🙏🏠',
        );
      case 'rest':
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          reactionEmoji: '😴✝️',
        );
      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Residential ───────────────────────────────────────────────────────────

  BuildingInteractionResult _residentialAction(
    String actionType,
    BuildingModel building,
  ) {
    building.totalConversations++;

    switch (actionType) {
      case 'talk':
        for (final npc in building.residents) {
          npc.conversationCount++;
        }
        return const BuildingInteractionResult(
          playerFaithDelta: 5.0,
          reactionEmoji: '💬😊',
        );
      case 'pray':
        building.influenceResidents(3.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 15.0,
          playerMaterialsDelta: 5.0,
          reactionEmoji: '🙏❤️',
        );
      case 'help':
        for (final npc in building.residents) {
          npc.applyInfluence(5.0);
        }
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          playerMaterialsDelta: -10.0,
          reactionEmoji: '📦🙏',
        );
      case 'bible':
        building.influenceResidents(2.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          playerMaterialsDelta: -3.0,
          reactionEmoji: '📖✝️',
        );
      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Commercial ────────────────────────────────────────────────────────────

  BuildingInteractionResult _commercialAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      case 'donate':
        final manager =
            building.residents.isNotEmpty ? building.residents.first : null;
        final managerFaith = manager?.faith ?? 0.0;
        final successChance = (0.50 + managerFaith / 400.0).clamp(0.0, 1.0);
        if (_rng.nextDouble() < successChance) {
          return BuildingInteractionResult(
            playerMaterialsDelta: 20.0 + _rng.nextDouble() * 20.0,
            reactionEmoji: '💰🙏',
          );
        }
        return const BuildingInteractionResult(
          reactionEmoji: '🚫💸',
          success: false,
        );
      case 'worker':
        return const BuildingInteractionResult(
          playerFaithDelta: 5.0,
          reactionEmoji: '💬👷',
        );
      case 'prayBusiness':
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          playerMaterialsDelta: -3.0,
          reactionEmoji: '🙏🏢',
        );
      case 'distribute':
        building.influenceResidents(3.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 15.0,
          playerMaterialsDelta: -5.0,
          reactionEmoji: '📦👷',
        );
      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Church ────────────────────────────────────────────────────────────────

  BuildingInteractionResult _churchAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      case 'readBible':
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          playerMaterialsDelta: -3.0,
          reactionEmoji: '📖✝️',
        );
      case 'pray':
        building.influenceResidents(5.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 15.0,
          playerMaterialsDelta: -3.0,
          reactionEmoji: '🙏⛪',
        );
      case 'worship':
        building.influenceResidents(10.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 20.0,
          playerMaterialsDelta: -8.0,
          reactionEmoji: '🎵✝️',
        );
      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Hospital ──────────────────────────────────────────────────────────────

  BuildingInteractionResult _hospitalAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      case 'visitSick':
        building.influenceResidents(4.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 12.0,
          playerMaterialsDelta: -5.0,
          reactionEmoji: '🤝🏥',
        );
      case 'pray':
        building.influenceResidents(3.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          playerMaterialsDelta: -3.0,
          reactionEmoji: '🙏🏥',
        );
      case 'heal':
        return const BuildingInteractionResult(
          playerFaithDelta: 20.0,
          playerMaterialsDelta: -10.0,
          reactionEmoji: '💊✝️',
        );
      case 'distribute':
        building.influenceResidents(2.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 8.0,
          playerMaterialsDelta: -8.0,
          reactionEmoji: '📦🏥',
        );
      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── School / University ───────────────────────────────────────────────────

  BuildingInteractionResult _schoolAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      case 'teach':
        building.influenceResidents(5.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 8.0,
          playerMaterialsDelta: -5.0,
          reactionEmoji: '📚✝️',
        );
      case 'pray':
        building.influenceResidents(2.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          playerMaterialsDelta: -3.0,
          reactionEmoji: '🙏🏫',
        );
      case 'distribute':
        building.influenceResidents(3.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          playerMaterialsDelta: -8.0,
          reactionEmoji: '📦🏫',
        );
      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Cemetery ──────────────────────────────────────────────────────────────

  BuildingInteractionResult _cemeteryAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      case 'pray':
        return const BuildingInteractionResult(
          playerFaithDelta: 18.0,
          playerMaterialsDelta: -5.0,
          reactionEmoji: '🙏🪦',
        );
      case 'comfort':
        building.influenceResidents(6.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          playerMaterialsDelta: -3.0,
          reactionEmoji: '🤝🪦',
        );
      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Generic (factory, warehouse, civic buildings, …) ─────────────────────

  BuildingInteractionResult _genericAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      case 'pray':
        building.influenceResidents(2.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 8.0,
          reactionEmoji: '🙏🏗️',
        );
      case 'witness':
        for (final npc in building.residents) {
          npc.applyInfluence(4.0);
        }
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          playerMaterialsDelta: -3.0,
          reactionEmoji: '💬✝️',
        );
      case 'distribute':
        building.influenceResidents(3.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 12.0,
          playerMaterialsDelta: -8.0,
          reactionEmoji: '📦✝️',
        );
      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }
}
