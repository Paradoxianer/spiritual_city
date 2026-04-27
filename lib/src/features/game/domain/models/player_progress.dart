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

  double get progress => ((totalAccumulated - currentThreshold) / (nextThreshold - currentThreshold)).clamp(0.0, 1.0);

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
  void recordConversion() => npcsConverted++;
  void recordConversation() => conversationsHeld++;
  void recordTerritoryTaken({bool full = false}) {
    territoriesPartiallyTaken++;
    if (full) territoriesFullyTaken++;
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
    'maxChristians': maxChristiansInOneCell,
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
    territoriesPartiallyTaken = (json['territoriesPartially'] as num?)?.toInt() ?? 0;
    territoriesFullyTaken = (json['territoriesFully'] as num?)?.toInt() ?? 0;
    maxChristiansInOneCell = (json['maxChristians'] as num?)?.toInt() ?? 0;
    
    if (json.containsKey('stages')) {
      final stagesRaw = json['stages'];
      if (stagesRaw is Map) {
        final s = stagesRaw.cast<String, dynamic>();
        if (s.containsKey('faith')) faithStage.fromJson(s['faith']);
        if (s.containsKey('materials')) materialsStage.fromJson(s['materials']);
        if (s.containsKey('health')) healthStage.fromJson(s['health']);
        if (s.containsKey('hunger')) hungerStage.fromJson(s['hunger']);
      }
    }

    if (json.containsKey('combatProfile')) {
      final profileRaw = json['combatProfile'];
      if (profileRaw is Map) {
        final profileJson = profileRaw.cast<String, dynamic>();
        final loadedProfile = CombatProfile.fromJson(profileJson);
        // Copy loaded values into existing instance
        for (var mode in PrayerMode.values) {
          final loadedStats = loadedProfile.getFor(mode);
          final currentStats = combatProfile.getFor(mode);
          currentStats.radius = loadedStats.radius;
          currentStats.strength = loadedStats.strength;
          currentStats.duration = loadedStats.duration;
          currentStats.speed = loadedStats.speed;
        }
      }
    }
  }
}
