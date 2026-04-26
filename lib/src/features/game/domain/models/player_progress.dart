import 'prayer_combat.dart';

/// Tracks player activity counters used to unlock modifiers.
///
/// Counters are updated from NPC interactions, prayer combats, and missions.
/// Lastenheft §5.4
class PlayerProgress {
  // --- Combat tracking ---
  int prayerCombatsCompleted = 0;
  int bibleReadingsCompleted = 0;
  int npcsConverted = 0;
  int conversationsHeld = 0;
  int territoriesPartiallyTaken = 0;
  int territoriesFullyTaken = 0;

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
  }

  Map<String, dynamic> toJson() => {
    'prayerCombats': prayerCombatsCompleted,
    'bibleReadings': bibleReadingsCompleted,
    'npcsConverted': npcsConverted,
    'conversations': conversationsHeld,
    'territoriesPartially': territoriesPartiallyTaken,
    'territoriesFully': territoriesFullyTaken,
    'maxChristians': maxChristiansInOneCell,
    'combatProfile': combatProfile.toJson(),
  };

  void loadFromJson(Map<String, dynamic> json) {
    prayerCombatsCompleted = (json['prayerCombats'] ?? 0) as int;
    bibleReadingsCompleted = (json['bibleReadings'] ?? 0) as int;
    npcsConverted = (json['npcsConverted'] ?? 0) as int;
    conversationsHeld = (json['conversations'] ?? 0) as int;
    territoriesPartiallyTaken = (json['territoriesPartially'] ?? 0) as int;
    territoriesFullyTaken = (json['territoriesFully'] ?? 0) as int;
    maxChristiansInOneCell = (json['maxChristians'] ?? 0) as int;
    
    if (json.containsKey('combatProfile')) {
      final profileJson = json['combatProfile'] as Map<String, dynamic>;
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
