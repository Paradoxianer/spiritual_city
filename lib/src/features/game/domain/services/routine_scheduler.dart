import 'package:flame/components.dart';
import '../models/npc_model.dart';

/// Assigns daily routines to NPCs based on the current real-world hour.
///
/// The mapping intentionally uses [DateTime.now().hour] so that routines
/// naturally mirror the player's own day/night cycle – no separate in-game
/// clock is needed for this MVP.
///
/// Routine identifiers returned:
/// - `'work'`   – NPC heads to [NPCModel.workLocation]
/// - `'home'`   – NPC heads to [NPCModel.homePosition]
/// - `'church'` – only for NPCs with high faith; heads to a church POI
/// - `'wander'` – relaxed exploration (parks, streets)
/// - `'sleep'`  – NPC is off-map / inactive
class RoutineScheduler {
  const RoutineScheduler();

  // ─── Hour → routine mapping ───────────────────────────────────────────────
  //
  //  0 – 5   sleep
  //  6 – 8   home (breakfast / getting ready)
  //  9 – 16  work
  // 17 – 19  wander (after work relaxation, parks)
  // 20 – 21  home (evening)
  // 22 – 23  sleep

  /// Returns the routine identifier appropriate for [npc] at the current time.
  String getScheduledRoutine(NPCModel npc) {
    final hour = DateTime.now().hour;

    if (hour >= 0 && hour < 6) return 'sleep';
    if (hour >= 6 && hour < 9) return 'home';
    if (hour >= 9 && hour < 17) {
      return npc.workLocation != null ? 'work' : 'wander';
    }
    if (hour >= 17 && hour < 20) {
      // Christians may visit church in the evening
      if (npc.isChristian && npc.personality == NPCPersonality.friendly) {
        return 'church';
      }
      return 'wander';
    }
    if (hour >= 20 && hour < 22) return 'home';
    return 'sleep'; // 22–23
  }

  /// Returns the world-position target for [routine] given [npc].
  ///
  /// Returns `null` when no specific target exists (e.g. sleep is off-map)
  /// or when the required location has not been assigned to the NPC.
  Vector2? getRoutineTarget(NPCModel npc, String routine) {
    switch (routine) {
      case 'work':
        return npc.workLocation;
      case 'home':
        return npc.homePosition.clone();
      case 'church':
      case 'wander':
        // Caller is responsible for providing a POI; return home as fallback.
        return npc.homePosition.clone();
      case 'sleep':
        return null;
      default:
        return null;
    }
  }
}
