import 'dart:math';
import 'package:flame/components.dart';
import '../models/city_grid.dart';
import '../models/npc_model.dart';
import 'pathfinder_service.dart';
import 'routine_scheduler.dart';

/// Central AI service that drives the [NPCAIState] machine for every active
/// NPC each game-loop tick.
///
/// Responsibilities:
/// 1. Decide which routine an NPC should follow (via [RoutineScheduler]).
/// 2. Request a path from [PathfinderService] when the NPC needs to move.
/// 3. Apply smooth movement along the path.
/// 4. Drive state transitions (idle → walking → working / praying / etc.).
/// 5. Update energy (drains while active, recovers while sleeping).
///
/// The service is *pure domain logic* – it has no Flame dependencies.
/// [NPCComponent] calls [updateNPC] from its own [update] method.
class NPCAIService {
  final PathfinderService pathfinder;
  final RoutineScheduler scheduler;
  final Random _rng;

  /// How fast NPCs walk in world pixels per second.
  static const double walkSpeed = 40.0;

  /// How close (in pixels) an NPC must be to a waypoint to consider it reached.
  static const double waypointReachRadius = 8.0;

  /// How far a wandering NPC will stray from home (in pixels).
  static const double wanderRadius = 256.0;

  /// Energy cost per second while active (walking / working).
  static const double energyDrainRate = 0.5;

  /// Energy recovery per second while sleeping.
  static const double energyRecoveryRate = 2.0;

  NPCAIService({
    PathfinderService? pathfinder,
    RoutineScheduler? scheduler,
    int? seed,
  })  : pathfinder = pathfinder ?? PathfinderService(),
        scheduler = scheduler ?? const RoutineScheduler(),
        _rng = Random(seed);

  // ─── Public update entry-point ────────────────────────────────────────────

  /// Advances the AI for one [npc] by [dt] seconds.
  ///
  /// [position] is the NPC's current world-space position.
  /// Returns the position delta to apply (may be [Vector2.zero]).
  Vector2 updateNPC(NPCModel npc, Vector2 position, double dt, CityGrid grid) {
    // NPCs that are talking are controlled by the interaction system.
    if (npc.currentState == NPCAIState.talking) return Vector2.zero();

    _updateEnergy(npc, dt);
    _checkRoutineTransition(npc, position, grid);

    return switch (npc.currentState) {
      NPCAIState.walking => _stepAlongPath(npc, position, dt),
      NPCAIState.idle    => _handleIdle(npc, position, dt, grid),
      NPCAIState.sleeping => Vector2.zero(),
      _                  => Vector2.zero(),
    };
  }

  /// Called by [NPCComponent.onInteract] – pauses AI movement.
  void beginTalking(NPCModel npc) {
    npc.currentState = NPCAIState.talking;
    npc.clearPath();
  }

  /// Called when a dialog session ends.
  void endTalking(NPCModel npc) {
    npc.currentState = NPCAIState.idle;
  }

  // ─── Routine / state transitions ──────────────────────────────────────────

  void _checkRoutineTransition(NPCModel npc, Vector2 position, CityGrid grid) {
    final desiredJob = scheduler.getScheduledRoutine(npc);

    if (desiredJob == 'sleep') {
      if (npc.currentState != NPCAIState.sleeping) {
        npc.currentState = NPCAIState.sleeping;
        npc.currentJob = 'sleep';
        npc.clearPath();
      }
      return;
    }

    if (desiredJob != npc.currentJob) {
      npc.currentJob = desiredJob;
      final target = scheduler.getRoutineTarget(npc, desiredJob);
      if (target != null) {
        _startWalkingTo(npc, position, target, grid);
      } else {
        npc.currentState = NPCAIState.idle;
      }
    }
  }

  void _startWalkingTo(
      NPCModel npc, Vector2 from, Vector2 to, CityGrid grid) {
    final path = pathfinder.findPath(from, to, grid);
    if (path != null && path.isNotEmpty) {
      npc.currentPath = path;
      npc.currentTarget = to;
      npc.currentState = NPCAIState.walking;
    } else {
      // Already at destination
      npc.clearPath();
      _arriveAtDestination(npc);
    }
  }

  void _arriveAtDestination(NPCModel npc) {
    switch (npc.currentJob) {
      case 'work':
        npc.currentState = NPCAIState.working;
      case 'church':
        npc.currentState = NPCAIState.praying;
      case 'home':
      case 'wander':
      default:
        npc.currentState = NPCAIState.idle;
    }
  }

  // ─── State handlers ───────────────────────────────────────────────────────

  Vector2 _stepAlongPath(NPCModel npc, Vector2 position, double dt) {
    if (npc.currentPath.isEmpty) {
      _arriveAtDestination(npc);
      return Vector2.zero();
    }

    final waypoint = npc.currentPath.first;
    final toWaypoint = waypoint - position;
    final dist = toWaypoint.length;

    if (dist < waypointReachRadius) {
      npc.currentPath.removeAt(0);
      if (npc.currentPath.isEmpty) {
        _arriveAtDestination(npc);
      }
      return Vector2.zero();
    }

    final step = walkSpeed * dt;
    if (step >= dist) {
      npc.currentPath.removeAt(0);
      return toWaypoint;
    }

    return toWaypoint.normalized() * step;
  }

  Vector2 _handleIdle(
      NPCModel npc, Vector2 position, double dt, CityGrid grid) {
    // Occasionally start a short wander
    if (_rng.nextDouble() < 0.005) {
      // Pick a random nearby walkable tile
      final offset = Vector2(
        (_rng.nextDouble() - 0.5) * wanderRadius * 2,
        (_rng.nextDouble() - 0.5) * wanderRadius * 2,
      );
      final target = position + offset;
      _startWalkingTo(npc, position, target, grid);
    }
    return Vector2.zero();
  }

  // ─── Energy ───────────────────────────────────────────────────────────────

  void _updateEnergy(NPCModel npc, double dt) {
    switch (npc.currentState) {
      case NPCAIState.sleeping:
        npc.energyLevel =
            (npc.energyLevel + energyRecoveryRate * dt).clamp(0, 100);
      case NPCAIState.walking:
      case NPCAIState.working:
        npc.energyLevel =
            (npc.energyLevel - energyDrainRate * dt).clamp(0, 100);
      default:
        break;
    }

    // If exhausted, navigate home first before sleeping (not in middle of road)
    if (npc.energyLevel <= 0 &&
        npc.currentState != NPCAIState.sleeping &&
        npc.currentState != NPCAIState.walking) {
      // Only trigger if not already walking (avoids interrupting a walk home)
      npc.currentJob = 'sleep';
      npc.currentState = NPCAIState.sleeping;
      npc.clearPath();
    } else if (npc.energyLevel <= 5 &&
        npc.currentState == NPCAIState.walking &&
        npc.currentJob != 'home' &&
        npc.currentJob != 'sleep') {
      // Very low energy while walking: redirect home so NPC reaches safety first
      npc.currentJob = 'home';
    }
  }
}
