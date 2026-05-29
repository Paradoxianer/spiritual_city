import 'package:flutter/foundation.dart';
import 'prayer_combat.dart';

/// Tracks the progression of a single resource (Faith, Materials, etc.).
/// Issue #61
class ResourceStage {
  int stage = 1;
  double totalAccumulated = 0;

  /// Returns the threshold for the NEXT stage.
  /// Calculation: 250 * (1.5 ^ (stage - 1)) - rounded to nice numbers.
  double get nextThreshold {
    if (stage == 1) return 250;
    if (stage == 2) return 750;
    if (stage == 3) return 1750;
    if (stage == 4) return 3500;
    if (stage == 5) return 6500;
    return 6500 * (stage - 4) * 1.5; // Fallback
  }

  /// Returns the threshold of the CURRENT stage (for progress bar calculation).
  double get currentThreshold {
    if (stage == 1) return 0;
    if (stage == 2) return 250;
    if (stage == 3) return 750;
    if (stage == 4) return 1750;
    if (stage == 5) return 3500;
    return 3500; // Simplified
  }

  double get progress => ((totalAccumulated - currentThreshold) /
          (nextThreshold - currentThreshold))
      .clamp(0.0, 1.0);

  bool add(double amount) {
    totalAccumulated += amount.abs();
    if (totalAccumulated >= nextThreshold) {
      stage++;
      return true; // Level up!
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'stage': stage,
        'total': totalAccumulated,
      };

  void fromJson(Map<String, dynamic> json) {
    stage = (json['stage'] ?? 1) as int;
    totalAccumulated = (json['total'] ?? 0).toDouble();
  }
}

/// Tracks player activity counters used to unlock modifiers.
///
/// Counters are updated from NPC interactions, prayer combats, and missions.
/// Lastenheft §5.4
class PlayerProgress extends ChangeNotifier {
  // --- Combat tracking ---
  int prayerCombatsCompleted = 0;
  int bibleReadingsCompleted = 0;
  int npcsConverted = 0;
  int conversationsHeld = 0;
  int territoriesPartiallyTaken = 0;
  int territoriesFullyTaken = 0;
  int spiritualWorldEntries = 0;

  // --- Geistliche Erkenntnis (Spiritual Insight) – Issue #124 ─────────────
  /// Accumulated fractional insight from building actions.
  /// Grows in 0.5-point steps; only whole points are "displayed" / usable.
  double pendingInsight = 0.0;

  /// Total whole-point insight unlocked so far.
  int insight = 0;

  /// Add [amount] of insight (typically 0.5).  Whole points are cashed out
  /// immediately and accumulated into [insight].
  void addInsight(double amount) {
    pendingInsight += amount;
    if (pendingInsight >= 1.0) {
      final wholePoints = pendingInsight.floor();
      insight += wholePoints;
      pendingInsight -= wholePoints.toDouble();
      notifyListeners();
    }
  }

  /// Reduces [insight] by 10% (rounded up, minimum loss of 1) as a faint penalty.
  /// Does nothing when [insight] is already 0.
  void applyFaintInsightPenalty() {
    if (insight <= 0) return;
    final loss = (insight * 0.1).ceil().clamp(1, insight);
    insight = (insight - loss).clamp(0, insight);
    notifyListeners();
  }

  // --- Resource Stages (Issue #61) ---
  final ResourceStage faithStage = ResourceStage();
  final ResourceStage materialsStage = ResourceStage();
  final ResourceStage healthStage = ResourceStage();
  final ResourceStage hungerStage = ResourceStage();

  double get maxFaith => 100.0 + (faithStage.stage - 1) * 20.0;
  double get maxMaterials => 100.0 + (materialsStage.stage - 1) * 20.0;
  double get maxHealth => 100.0 + (healthStage.stage - 1) * 10.0;
  double get maxHunger => 100.0 + (hungerStage.stage - 1) * 10.0;

  // --- Combat Upgrades (Issue #4 / #9) ---
  final CombatProfile combatProfile = CombatProfile();

  // --- Territory tracking ---
  int maxChristiansInOneCell = 0;

  void recordPrayerCombat() => prayerCombatsCompleted++;
  void recordBibleReading() => bibleReadingsCompleted++;
  void recordConversion() {
    npcsConverted++;
    notifyListeners();
  }

  void recordConversation() => conversationsHeld++;
  void recordTerritoryTaken({bool full = false}) {
    territoriesPartiallyTaken++;
    if (full) territoriesFullyTaken++;
    notifyListeners();
  }

  void recordSpiritualWorldEntry() {
    spiritualWorldEntries++;
    notifyListeners();
  }

  /// Explicitly notify listeners that the max values or stages have changed.
  void notifyLevelUp() => notifyListeners();

  Map<String, dynamic> toJson() => {
        'prayerCombats': prayerCombatsCompleted,
        'bibleReadings': bibleReadingsCompleted,
        'npcsConverted': npcsConverted,
        'conversations': conversationsHeld,
        'territoriesPartially': territoriesPartiallyTaken,
        'territoriesFully': territoriesFullyTaken,
        'spiritualWorldEntries': spiritualWorldEntries,
        'maxChristians': maxChristiansInOneCell,
        'insight': insight,
        'pendingInsight': pendingInsight,
        'combatProfile': combatProfile.toJson(),
        'stages': {
          'faith': faithStage.toJson(),
          'materials': materialsStage.toJson(),
          'health': healthStage.toJson(),
          'hunger': hungerStage.toJson(),
        },
      };

  void loadFromJson(Map<String, dynamic> json) {
    prayerCombatsCompleted = (json['prayerCombats'] as num?)?.toInt() ?? 0;
    bibleReadingsCompleted = (json['bibleReadings'] as num?)?.toInt() ?? 0;
    npcsConverted = (json['npcsConverted'] as num?)?.toInt() ?? 0;
    conversationsHeld = (json['conversations'] as num?)?.toInt() ?? 0;
    territoriesPartiallyTaken =
        (json['territoriesPartially'] as num?)?.toInt() ?? 0;
    territoriesFullyTaken = (json['territoriesFully'] as num?)?.toInt() ?? 0;
    spiritualWorldEntries =
        (json['spiritualWorldEntries'] as num?)?.toInt() ?? 0;
    maxChristiansInOneCell = (json['maxChristians'] as num?)?.toInt() ?? 0;
    insight = (json['insight'] as num?)?.toInt() ?? 0;
    pendingInsight = (json['pendingInsight'] as num?)?.toDouble() ?? 0.0;

    if (json.containsKey('stages')) {
      final stagesRaw = json['stages'];
      if (stagesRaw is Map) {
        final s = stagesRaw.cast<String, dynamic>();
        if (s.containsKey('faith') && s['faith'] is Map) {
          faithStage.fromJson((s['faith'] as Map).cast<String, dynamic>());
        }
        if (s.containsKey('materials') && s['materials'] is Map) {
          materialsStage
              .fromJson((s['materials'] as Map).cast<String, dynamic>());
        }
        if (s.containsKey('health') && s['health'] is Map) {
          healthStage.fromJson((s['health'] as Map).cast<String, dynamic>());
        }
        if (s.containsKey('hunger') && s['hunger'] is Map) {
          hungerStage.fromJson((s['hunger'] as Map).cast<String, dynamic>());
        }
      }
    }

    if (json.containsKey('combatProfile')) {
      final profileRaw = json['combatProfile'];
      if (profileRaw is Map) {
        final profileJson = profileRaw.cast<String, dynamic>();
        final loadedProfile = CombatProfile.fromJson(profileJson);
        // Copy loaded level values into the existing instance.
        combatProfile.shieldLevel = loadedProfile.shieldLevel;
        combatProfile.helmLevel = loadedProfile.helmLevel;
        for (var mode in PrayerMode.values) {
          final loadedStats = loadedProfile.getFor(mode);
          final currentStats = combatProfile.getFor(mode);
          currentStats.radiusLevel = loadedStats.radiusLevel;
          currentStats.strengthLevel = loadedStats.strengthLevel;
          currentStats.durationLevel = loadedStats.durationLevel;
          currentStats.speedLevel = loadedStats.speedLevel;
        }
      }
    }
  }

  /// Spend [amount] whole-point Insight as upgrade currency.
  /// Returns `true` and deducts the cost if sufficient Insight is available,
  /// otherwise returns `false` without modifying anything.
  bool spendInsight(int amount) {
    if (insight < amount) return false;
    insight -= amount;
    notifyListeners();
    return true;
  }
}
