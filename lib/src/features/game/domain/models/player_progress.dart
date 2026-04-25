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
}
