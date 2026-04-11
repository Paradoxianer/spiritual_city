import 'dart:math';
import 'package:flame/components.dart';

enum NPCType {
  citizen,
  merchant,
  priest,
  officer,
}

/// State machine states for NPC AI behaviour.
enum NPCAIState { idle, walking, talking, praying, working, eating, sleeping }

/// Personality archetype that influences AI decision-making.
enum NPCPersonality { friendly, cautious, busy, sad, helpful }

// Shared Random instance – avoids creating many short-lived Random objects.
final _sharedRandom = Random();

/// NPC Data Model based on Lastenheft Section 6.2
class NPCModel {
  final String id;
  final String name;
  final NPCType type;
  final Vector2 homePosition;
  
  /// Faith Level: -100.0 to +100.0
  /// < -50: Opposed/Negative
  /// > 50: Christian/Believer
  double faith; 
  
  int conversationCount;
  int prayerCount;
  
  /// Tracks interactions in the current active dialogue session
  int currentSessionInteractions = 0;
  
  String? currentMessage;

  // ── AI State Machine ──────────────────────────────────────────────────────

  /// Current behaviour state.
  NPCAIState currentState;

  /// Personality archetype – affects how often an NPC talks, prays, etc.
  NPCPersonality personality;

  /// Current movement destination in world pixels.
  Vector2? currentTarget;

  /// Ordered list of waypoints to reach [currentTarget].
  /// NPCComponent consumes waypoints from the front as it reaches each one.
  List<Vector2> currentPath;

  /// Identifier for the current routine ('work', 'home', 'church', 'park', 'wander').
  String? currentJob;

  /// Assigned work-place position (world pixels).  Null for unemployed NPCs.
  Vector2? workLocation;

  /// Energy level 0–100; drains while active, recovers while sleeping.
  double energyLevel;

  NPCModel({
    required this.id,
    required this.name,
    required this.type,
    required this.homePosition,
    this.faith = 0.0,
    this.conversationCount = 0,
    this.prayerCount = 0,
    this.currentMessage,
    NPCAIState? currentState,
    NPCPersonality? personality,
    this.currentTarget,
    List<Vector2>? currentPath,
    this.currentJob,
    this.workLocation,
    this.energyLevel = 100.0,
  })  : currentState = currentState ?? NPCAIState.idle,
        personality = personality ?? _randomPersonality(),
        currentPath = currentPath ?? [];

  /// An NPC is considered a Christian if faith is above 50 (Lastenheft 6.2)
  bool get isChristian => faith > 50;

  /// Logic to update faith based on interaction and environment
  void applyInfluence(double amount) {
    faith = (faith + amount).clamp(-100.0, 100.0);
  }

  void resetSession() {
    currentSessionInteractions = 0;
  }

  /// Clears the current navigation path and target.
  void clearPath() {
    currentPath = [];
    currentTarget = null;
  }

  static NPCPersonality _randomPersonality() {
    final values = NPCPersonality.values;
    return values[_sharedRandom.nextInt(values.length)];
  }
}
