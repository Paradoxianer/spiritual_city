import 'dart:math';
import '../models/building_model.dart';

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
  ///
  /// For commercial / church buildings this is always true.
  /// For residential buildings a random roll is compared against the
  /// faith-based access chance (Lastenheft §7.4 / Issue §A).
  bool attemptAccess(BuildingModel building, double playerFaith) {
    if (building.isAlwaysOpen) return true;
    return _rng.nextDouble() < building.accessChance(playerFaith);
  }

  // ── Action dispatch ───────────────────────────────────────────────────────

  /// Perform [actionType] inside [building] and return the result.
  ///
  /// [actionType] values per category:
  ///
  /// **Residential** – `'talk'`, `'pray'`, `'help'`, `'bible'`
  /// **Commercial**  – `'donate'`, `'worker'`, `'prayBusiness'`, `'distribute'`
  /// **Church**      – `'readBible'`, `'pray'`, `'worship'`
  /// **Civic**       – `'pray'`, `'witness'`, `'distribute'`
  /// **Industrial**  – `'pray'`, `'witness'`, `'distribute'`
  BuildingInteractionResult performAction(
    String actionType,
    BuildingModel building,
    double playerFaith,
  ) {
    switch (building.category) {
      case BuildingCategory.residential:
        return _residentialAction(actionType, building);
      case BuildingCategory.commercial:
        return _commercialAction(actionType, building);
      case BuildingCategory.church:
        return _churchAction(actionType, building);
      case BuildingCategory.civic:
        return _civicAction(actionType, building);
      case BuildingCategory.industrial:
        return _industrialAction(actionType, building);
      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Residential actions (Issue §A) ────────────────────────────────────────

  BuildingInteractionResult _residentialAction(
    String actionType,
    BuildingModel building,
  ) {
    // Every successful entry counts towards the conversation bonus.
    building.totalConversations++;

    switch (actionType) {
      // [A] Sprechen: +5 Faith, conversationCount +1 per resident
      case 'talk':
        for (final npc in building.residents) {
          npc.conversationCount++;
        }
        return const BuildingInteractionResult(
          playerFaithDelta: 5.0,
          reactionEmoji: '💬😊',
        );

      // [B] Beten: +15 Faith, +5 Material-Einfluss, Familie beeinflusst
      case 'pray':
        building.influenceResidents(3.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 15.0,
          playerMaterialsDelta: 5.0,
          reactionEmoji: '🙏❤️',
        );

      // [C] Hilfe: -10 MP, +10 Faith, NPC-faith +5
      case 'help':
        for (final npc in building.residents) {
          npc.applyInfluence(5.0);
        }
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          playerMaterialsDelta: -10.0,
          reactionEmoji: '📦🙏',
        );

      // [D] Bibellesen: +10 Faith, Family-faith +2
      case 'bible':
        building.influenceResidents(2.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          reactionEmoji: '📖✝️',
        );

      // [E] Brief einwerfen: kleiner Glaubenbonus, NPC-faith +1 (stille Handlung)
      case 'letter':
        building.influenceResidents(1.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 3.0,
          reactionEmoji: '✉️🙏',
        );

      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Commercial actions (Issue §B) ─────────────────────────────────────────

  BuildingInteractionResult _commercialAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      // [A] Um Spenden bitten: +20-40 MP (50 % Erfolgsrate, abhängig von Manager-Glaube)
      case 'donate':
        final manager =
            building.residents.isNotEmpty ? building.residents.first : null;
        final managerFaith = manager?.faith ?? 0.0;
        // Base 50 % ± up to 25 % from manager faith.
        // Manager faith range is −100..+100 → dividing by 400 gives ±0.25 modifier.
        final successChance = (0.50 + managerFaith / 400.0).clamp(0.0, 1.0);
        if (_rng.nextDouble() < successChance) {
          final amount = 20.0 + _rng.nextDouble() * 20.0;
          return BuildingInteractionResult(
            playerMaterialsDelta: amount,
            reactionEmoji: '💰🙏',
          );
        }
        return const BuildingInteractionResult(
          reactionEmoji: '🚫💸',
          success: false,
        );

      // [B] Mit Arbeiter sprechen: +5 Faith
      case 'worker':
        return const BuildingInteractionResult(
          playerFaithDelta: 5.0,
          reactionEmoji: '💬👷',
        );

      // [C] Für Betrieb beten: +10 Faith (cell influence handled by caller)
      case 'prayBusiness':
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          reactionEmoji: '🙏🏢',
        );

      // [D] Material verteilen: -5 MP, +15 Faith, Betrieb-Mitarbeiter +3 faith
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

  // ── Church actions (Lastenheft ch. 4) ─────────────────────────────────────

  BuildingInteractionResult _churchAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      case 'readBible':
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          reactionEmoji: '📖✝️',
        );

      case 'pray':
        building.influenceResidents(5.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 15.0,
          reactionEmoji: '🙏⛪',
        );

      case 'worship':
        building.influenceResidents(10.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 20.0,
          reactionEmoji: '🎵✝️',
        );

      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Civic actions (public buildings) ─────────────────────────────────────

  BuildingInteractionResult _civicAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      // Beten: +10 Faith, kleine Ausstrahlung auf Mitarbeiter
      case 'pray':
        building.influenceResidents(2.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          reactionEmoji: '🙏🏛️',
        );

      // Zeugnis geben: Mitarbeiter-Einfluss +4
      case 'witness':
        for (final npc in building.residents) {
          npc.applyInfluence(4.0);
        }
        return const BuildingInteractionResult(
          playerFaithDelta: 8.0,
          reactionEmoji: '💬✝️',
        );

      // Material verteilen: -8 MP, +12 Faith, Mitarbeiter +3 faith
      case 'distribute':
        building.influenceResidents(3.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 12.0,
          playerMaterialsDelta: -8.0,
          reactionEmoji: '📦🏛️',
        );

      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Industrial actions ────────────────────────────────────────────────────

  BuildingInteractionResult _industrialAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      // Beten: +8 Faith, kleine Ausstrahlung auf Arbeiter
      case 'pray':
        building.influenceResidents(2.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 8.0,
          reactionEmoji: '🙏🏭',
        );

      // Zeugnis geben: Arbeiter-Einfluss +5
      case 'witness':
        for (final npc in building.residents) {
          npc.applyInfluence(5.0);
        }
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          reactionEmoji: '💬👷',
        );

      // Material verteilen: -10 MP, +15 Faith, Arbeiter +4 faith
      case 'distribute':
        building.influenceResidents(4.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 15.0,
          playerMaterialsDelta: -10.0,
          reactionEmoji: '📦👷',
        );

      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }
}
