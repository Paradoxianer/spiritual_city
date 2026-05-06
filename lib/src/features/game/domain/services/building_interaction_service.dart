import 'dart:math';
import '../models/building_model.dart';
import '../models/cell_object.dart';

/// Result returned by [BuildingInteractionService.performAction].
class BuildingInteractionResult {
  /// How much the player's faith changes (positive = gain, negative = loss).
  final double playerFaithDelta;

  /// How much the player's materials change (positive = gain, negative = cost).
  final double playerMaterialsDelta;

  /// How much the player's hunger changes (positive = gain, negative = cost).
  final double playerHungerDelta;

  /// How much the player's health changes (positive = heal, negative = cost).
  final double playerHealthDelta;

  /// Emoji string shown in the UI as feedback.
  final String reactionEmoji;

  /// Whether the action succeeded (e.g. donation may fail).
  final bool success;

  /// How many seconds the action takes to complete (0 = instant).
  ///
  /// When > 0 the UI should show a countdown and delay applying the result
  /// until the timer expires.
  final int actionDurationSeconds;

  /// How much Geistliche Erkenntnis (spiritual insight) the player gains.
  ///
  /// Insight accumulates in 0.5-point steps from special building actions.
  /// Only whole points are "cashed out" as usable insight.
  final double playerInsightDelta;

  const BuildingInteractionResult({
    this.playerFaithDelta = 0,
    this.playerMaterialsDelta = 0,
    this.playerHungerDelta = 0,
    this.playerHealthDelta = 0,
    required this.reactionEmoji,
    this.success = true,
    this.actionDurationSeconds = 0,
    this.playerInsightDelta = 0,
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
  /// Actions are dispatched by [BuildingType].
  BuildingInteractionResult performAction(
    String actionType,
    BuildingModel building,
    double playerFaith,
  ) {
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

      // ── Police Station ────────────────────────────────────────────────────
      case BuildingType.policeStation:
        return _policeAction(actionType, building);

      // ── City Hall ─────────────────────────────────────────────────────────
      case BuildingType.cityHall:
        return _cityHallAction(actionType, building);

      // ── Train Station ─────────────────────────────────────────────────────
      case BuildingType.trainStation:
        return _trainStationAction(actionType, building);

      // ── Stadium ───────────────────────────────────────────────────────────
      case BuildingType.stadium:
        return _stadiumAction(actionType, building);

      // ── Everything else (factory, warehouse, civic, …) ───────────────────
      default:
        return _genericAction(actionType, building);
    }
  }

  // ── Pastor's house ────────────────────────────────────────────────────────

  /// Base action durations (in seconds) for the pastor house.
  /// Easy difficulty shortens these; hard difficulty lengthens them.
  /// These are exposed as public constants so the UI layer can scale them.
  static const int pastorHouseReadBibleSeconds = 5;
  static const int pastorHouseEatSeconds = 3;
  static const int pastorHouseSleepSeconds = 8;
  static const int pastorHousePraySeconds = 5;

  BuildingInteractionResult _pastorHouseAction(
    String actionType,
    BuildingModel building,
  ) {
    // Pastor house is the player's base; interactions improve the building's
    // own sanctity so the faith bar reveals over repeated visits.
    building.interactionCount++;
    switch (actionType) {
      case 'readBible':
        building.applyInfluence(8.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 20.0,
          playerHealthDelta: -5.0,
          reactionEmoji: '📖✝️',
          actionDurationSeconds: pastorHouseReadBibleSeconds,
        );
      case 'eat':
        // Eating at home is free – materials come from the loot system.
        return const BuildingInteractionResult(
          playerHungerDelta: 50.0,
          reactionEmoji: '🍽️😊',
          actionDurationSeconds: pastorHouseEatSeconds,
        );
      case 'sleep':
        return const BuildingInteractionResult(
          playerHealthDelta: 50.0,
          reactionEmoji: '😴❤️',
          actionDurationSeconds: pastorHouseSleepSeconds,
        );
      case 'pray':
        // Faith gain + massive area spiritual influence (handled in game layer).
        building.applyInfluence(10.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 15.0,
          playerHealthDelta: -5.0,
          reactionEmoji: '🙏🕊️',
          actionDurationSeconds: pastorHousePraySeconds,
        );
      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Residential ───────────────────────────────────────────────────────────

  // Base duration (seconds) for time-based residential actions.
  static const int houseVisitSeconds = 10;

  BuildingInteractionResult _residentialAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      // ── Praktische Hilfe: -10 Materials → +5 Interaktionen, kleiner Impuls
      case 'practicalHelp':
        building.interactionCount += 5;
        building.applyInfluence(3.0);
        return const BuildingInteractionResult(
          playerMaterialsDelta: -10.0,
          reactionEmoji: '🛠️🤝',
        );

      // ── Gebet: -10 Faith → Zufallserfolg → +2 Interaktionen, Zelle grüner
      case 'pray':
        building.interactionCount++;
        final success = _rng.nextDouble() < 0.5;
        if (success) {
          building.interactionCount += 2;
          building.applyInfluence(5.0);
          return const BuildingInteractionResult(
            playerFaithDelta: -10.0,
            reactionEmoji: '🙏🕊️',
          );
        }
        return const BuildingInteractionResult(
          playerFaithDelta: -10.0,
          reactionEmoji: '🙏',
          success: false,
        );

      // ── Hausbesuch: >5 Interaktionen, Zeit → Health/Hunger Refill, Spenden-Chance
      case 'houseVisit':
        if (building.interactionCount <= 5) {
          return const BuildingInteractionResult(
            reactionEmoji: '🚫☕',
            success: false,
          );
        }
        building.interactionCount++;
        final hasDonation = _rng.nextDouble() < 0.45;
        if (hasDonation) {
          building.interactionCount += 4;
          final materials = (building.interactionCount * 0.5).clamp(3.0, 20.0);
          building.applyInfluence(3.0);
          return BuildingInteractionResult(
            playerHealthDelta: 100.0,
            playerHungerDelta: 100.0,
            playerFaithDelta: 5.0,
            playerMaterialsDelta: materials,
            reactionEmoji: '☕🎁',
            actionDurationSeconds: houseVisitSeconds,
          );
        }
        return const BuildingInteractionResult(
          playerHealthDelta: 100.0,
          playerHungerDelta: 100.0,
          reactionEmoji: '☕❤️',
          actionDurationSeconds: houseVisitSeconds,
        );

      // ── Jüngerschaftsgruppe: >20 Interaktionen + 1 Bekehrter, -50 Faith
      case 'discipleshipGroup':
        final hasChristianResident = building.residents.any((n) => n.isChristian);
        if (building.interactionCount <= 20 || !hasChristianResident) {
          return const BuildingInteractionResult(
            reactionEmoji: '🚫📖',
            success: false,
          );
        }
        building.interactionCount++;
        building.applyInfluence(50.0);
        building.influenceResidents(20.0);
        return const BuildingInteractionResult(
          playerFaithDelta: -50.0,
          playerInsightDelta: 0.5,
          reactionEmoji: '📖👥🔥',
          actionDurationSeconds: 2,
        );

      // ── Hausgemeinschaft segnen (Apartment only): +1 Interaktion bei allen Bewohnern
      case 'blessHousehold':
        building.interactionCount++;
        for (final npc in building.residents) {
          npc.interactionCount += 1;
        }
        building.applyInfluence(5.0);
        return const BuildingInteractionResult(
          playerFaithDelta: -10.0,
          reactionEmoji: '🏢🙏🕊️',
        );

      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Commercial ────────────────────────────────────────────────────────────

  // Base durations for time-based commercial actions.
  static const int talkBossSeconds = 8;

  BuildingInteractionResult _commercialAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      // ── Gespräch mit Chef: Zeit → +3 Interaktionen, Faith minimal
      case 'talkBoss':
        building.interactionCount += 3;
        building.applyInfluence(1.0);
        return const BuildingInteractionResult(
          reactionEmoji: '💼🤝',
          actionDurationSeconds: talkBossSeconds,
        );

      // ── Einkaufen: -5 Materials → +1 Interaktion, +20 Hunger/Health
      case 'shopping':
        building.interactionCount++;
        return const BuildingInteractionResult(
          playerMaterialsDelta: -5.0,
          playerHungerDelta: 20.0,
          playerHealthDelta: 10.0,
          reactionEmoji: '🛒🍎',
        );

      // ── Segnen: -15 Faith → +2 Interaktionen, Influence-Impuls
      case 'bless':
        building.interactionCount += 2;
        building.applyInfluence(5.0);
        return const BuildingInteractionResult(
          playerFaithDelta: -15.0,
          reactionEmoji: '🕊️🙌🙏',
        );

      // ── Um Spenden bitten: >2 Interaktionen, -10 Health/Hunger
      case 'requestDonation':
        if (building.interactionCount <= 2) {
          return const BuildingInteractionResult(
            reactionEmoji: '🚫🤲',
            success: false,
          );
        }
        building.interactionCount++;
        final faithScore = building.faith + building.interactionCount;
        final successChance = (faithScore / 200.0 + 0.2).clamp(0.0, 0.9);
        if (_rng.nextDouble() < successChance) {
          building.interactionCount += 4;
          final materials = 15.0 + _rng.nextDouble() * 25.0;
          building.applyInfluence(5.0);
          return BuildingInteractionResult(
            playerHealthDelta: -10.0,
            playerHungerDelta: -10.0,
            playerMaterialsDelta: materials,
            playerFaithDelta: 5.0,
            reactionEmoji: '🤲💰',
          );
        }
        return const BuildingInteractionResult(
          playerHealthDelta: -10.0,
          playerHungerDelta: -10.0,
          reactionEmoji: '🚫💸',
          success: false,
        );

      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Church ────────────────────────────────────────────────────────────────

  // Base durations for time-based church actions.
  static const int sundayServiceSeconds = 20;
  static const int worshipSeconds = 30;

  BuildingInteractionResult _churchAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      // ── Gottesdienst: (Sonntag), -80% Materials, -60% Health → massiver AOE
      case 'sundayService':
        building.interactionCount++;
        building.applyInfluence(80.0);
        building.influenceResidents(50.0);
        return const BuildingInteractionResult(
          playerMaterialsDelta: -50.0,
          playerHealthDelta: -60.0,
          reactionEmoji: '⛪🎹🔥🙌🕊️',
          actionDurationSeconds: sundayServiceSeconds,
        );

      // ── Anbetung/Gebet: Zeit → Faith regeneriert (+3/Sek beim Pastor), Kirche gestärkt
      case 'worship':
        building.interactionCount++;
        building.applyInfluence(20.0);
        building.influenceResidents(15.0);
        return const BuildingInteractionResult(
          playerFaithDelta: worshipSeconds * 3.0,
          reactionEmoji: '🧘‍♂️🙏🕊️🙌',
          actionDurationSeconds: worshipSeconds,
        );

      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Hospital ──────────────────────────────────────────────────────────────

  // Base durations for time-based hospital actions.
  static const int counselingSeconds = 12;

  BuildingInteractionResult _hospitalAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      // ── Medizinische Hilfe: -15 Materials → Health/Hunger auf 100%
      case 'medicalHelp':
        building.interactionCount++;
        return const BuildingInteractionResult(
          playerMaterialsDelta: -15.0,
          playerHealthDelta: 100.0,
          playerHungerDelta: 100.0,
          reactionEmoji: '🏥💊❤️',
        );

      // ── Seelsorge: >3 Interaktionen, Zeit → zufälliger NPC +15 Interaktionen
      case 'counseling':
        if (building.interactionCount <= 3) {
          return const BuildingInteractionResult(
            reactionEmoji: '🚫👂',
            success: false,
          );
        }
        building.interactionCount++;
        // Give all residents a boost (+15 faith ≈ proxy for +15 interactions)
        building.influenceResidents(8.0);
        return const BuildingInteractionResult(
          reactionEmoji: '👂🤝❤️',
          actionDurationSeconds: counselingSeconds,
        );

      // ── Gottesdienst (Kapelle): >10 Interaktionen, -30 Faith → alle NPCs +15 Faith
      case 'chapelService':
        if (building.interactionCount <= 10) {
          return const BuildingInteractionResult(
            reactionEmoji: '🚫⛪',
            success: false,
          );
        }
        building.interactionCount++;
        building.influenceResidents(15.0);
        building.applyInfluence(10.0);
        return const BuildingInteractionResult(
          playerFaithDelta: -30.0,
          reactionEmoji: '⛪🙏🎶🕊️',
        );

      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── School / University ───────────────────────────────────────────────────

  // Base durations for time-based school actions.
  static const int talkDirectorSeconds = 10;
  static const int valueLectureSeconds = 15;

  BuildingInteractionResult _schoolAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      // ── Brief an Schulleitung: -5 Materials → +2 Interaktionen
      case 'letterToManagement':
        building.interactionCount += 2;
        building.applyInfluence(2.0);
        return const BuildingInteractionResult(
          playerMaterialsDelta: -5.0,
          reactionEmoji: '✉️🏫',
        );

      // ── Gespräch mit Direktor: >5 Interaktionen, Zeit → +5 Interaktionen, unlock Vortrag
      case 'talkDirector':
        if (building.interactionCount <= 5) {
          return const BuildingInteractionResult(
            reactionEmoji: '🚫🏫',
            success: false,
          );
        }
        building.interactionCount += 5;
        building.isLecturePrepared = true;
        building.applyInfluence(3.0);
        return const BuildingInteractionResult(
          reactionEmoji: '🏫🤝🗣️',
          actionDurationSeconds: talkDirectorSeconds,
        );

      // ── Werte-Vortrag: >15 Interaktionen + isLecturePrepared, Zeit → viele NPC-Interaktionen
      case 'valueLecture':
        if (building.interactionCount <= 15 || !building.isLecturePrepared) {
          return const BuildingInteractionResult(
            reactionEmoji: '🚫🎤',
            success: false,
          );
        }
        building.interactionCount++;
        building.influenceResidents(3.0);
        building.applyInfluence(2.0);
        return const BuildingInteractionResult(
          reactionEmoji: '🎤📖🎓🏫',
          actionDurationSeconds: valueLectureSeconds,
        );

      // ── Gebetskreis: >30 Interaktionen, -60 Faith → täglicher Faith-Boost, +0.5 Insight
      case 'prayerCircle':
        if (building.interactionCount <= 30) {
          return const BuildingInteractionResult(
            reactionEmoji: '🚫⭕',
            success: false,
          );
        }
        building.interactionCount++;
        building.applyInfluence(20.0);
        building.influenceResidents(10.0);
        return const BuildingInteractionResult(
          playerFaithDelta: -60.0,
          playerInsightDelta: 0.5,
          reactionEmoji: '⭕🙏🔥👥',
        );

      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Cemetery ──────────────────────────────────────────────────────────────

  // Base duration for time-based cemetery actions.
  static const int funeralSeconds = 20;

  BuildingInteractionResult _cemeteryAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      // ── Beerdigung: Zeit → massive Interaktionsgewinne, schaltet Trost frei
      case 'funeral':
        building.interactionCount++;
        building.influenceResidents(10.0);
        building.applyInfluence(8.0);
        building.hasFuneralCompleted = true;
        return const BuildingInteractionResult(
          reactionEmoji: '⚰️🙏🕊️🤝',
          actionDurationSeconds: funeralSeconds,
        );

      // ── Trost: nur nach Beerdigung (einmalig), -75% Health & Hunger → NPC bekehrt sich
      case 'comfort':
        if (!building.hasFuneralCompleted) {
          return const BuildingInteractionResult(
            reactionEmoji: '🚫🤝',
            success: false,
          );
        }
        building.interactionCount++;
        building.hasFuneralCompleted = false;
        building.applyInfluence(15.0);
        building.influenceResidents(20.0);
        return const BuildingInteractionResult(
          playerHealthDelta: -75.0,
          playerHungerDelta: -75.0,
          reactionEmoji: '🤝❤️🕊️🩹',
        );

      default:
        return const BuildingInteractionResult(
          reactionEmoji: '❓',
          success: false,
        );
    }
  }

  // ── Police Station ────────────────────────────────────────────────────────

  BuildingInteractionResult _policeAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      // ── Polizei segnen: -15 Faith → Dämonenspawn für 1 Tag verlangsamt
      case 'blessPolice':
        building.interactionCount++;
        building.applyInfluence(8.0);
        return const BuildingInteractionResult(
          playerFaithDelta: -15.0,
          reactionEmoji: '👮‍♂️🛡️🙏🕊️',
        );

      default:
        return _genericAction(actionType, building);
    }
  }

  // ── City Hall ─────────────────────────────────────────────────────────────

  // Base durations for time-based city hall actions.
  static const int mayorAudienceSeconds = 8;
  static const int prayForPoliticiansSeconds = 30;

  BuildingInteractionResult _cityHallAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      // ── Audienz Bürgermeister: Zeit → +3 Interaktionen
      case 'mayorAudience':
        building.interactionCount += 3;
        building.applyInfluence(2.0);
        return const BuildingInteractionResult(
          reactionEmoji: '🏛️🤝🗣️',
          actionDurationSeconds: mayorAudienceSeconds,
        );

      // ── Für Politiker beten: >20 Interaktionen, -Max Faith, -50 Health/Hunger
      case 'prayForPoliticians':
        if (building.interactionCount <= 20) {
          return const BuildingInteractionResult(
            reactionEmoji: '🚫🏛️',
            success: false,
          );
        }
        building.interactionCount++;
        building.applyInfluence(50.0);
        return const BuildingInteractionResult(
          playerFaithDelta: -100.0,
          playerHealthDelta: -50.0,
          playerHungerDelta: -50.0,
          reactionEmoji: '🏛️🙏🙌🕊️',
          actionDurationSeconds: prayForPoliticiansSeconds,
        );

      default:
        return _genericAction(actionType, building);
    }
  }

  // ── Train Station ─────────────────────────────────────────────────────────

  BuildingInteractionResult _trainStationAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      // ── Reise: -10 Materials pauschal → Teleport zum gewählten Bahnhof
      // The actual teleport dialog is handled in the game layer.
      case 'travel':
        building.interactionCount++;
        return const BuildingInteractionResult(
          playerMaterialsDelta: -10.0,
          reactionEmoji: '🚂🛤️🗺️',
        );

      default:
        return _genericAction(actionType, building);
    }
  }

  // ── Stadium ───────────────────────────────────────────────────────────────

  BuildingInteractionResult _stadiumAction(
    String actionType,
    BuildingModel building,
  ) {
    switch (actionType) {
      // ── Großveranstaltung: >50 Interaktionen, -100 Faith, -100 Materials
      case 'majorEvent':
        if (building.interactionCount <= 50) {
          return const BuildingInteractionResult(
            reactionEmoji: '🚫🏟️',
            success: false,
          );
        }
        building.interactionCount++;
        building.applyInfluence(100.0);
        building.influenceResidents(20.0);
        return const BuildingInteractionResult(
          playerFaithDelta: -100.0,
          playerMaterialsDelta: -100.0,
          playerInsightDelta: 0.5,
          reactionEmoji: '🏟️🙌🔥🎶🕊️',
        );

      default:
        return _genericAction(actionType, building);
    }
  }

  // ── Generic (factory, warehouse, civic buildings, …) ─────────────────────

  BuildingInteractionResult _genericAction(
    String actionType,
    BuildingModel building,
  ) {
    building.interactionCount++;
    switch (actionType) {
      case 'pray':
        building.applyInfluence(5.0);
        building.influenceResidents(2.0);
        return const BuildingInteractionResult(
          playerFaithDelta: 8.0,
          reactionEmoji: '🙏🏗️',
        );
      case 'witness':
        building.applyInfluence(5.0);
        for (final npc in building.residents) {
          npc.applyInfluence(4.0);
        }
        return const BuildingInteractionResult(
          playerFaithDelta: 10.0,
          playerMaterialsDelta: -3.0,
          reactionEmoji: '💬✝️',
        );
      case 'distribute':
        building.applyInfluence(6.0);
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
