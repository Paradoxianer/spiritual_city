import 'package:flame/components.dart';

enum NPCType {
  citizen,
  merchant,
  priest,
  officer,
}

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
  
  String? currentMessage;

  NPCModel({
    required this.id,
    required this.name,
    required this.type,
    required this.homePosition,
    this.faith = 0.0,
    this.conversationCount = 0,
    this.prayerCount = 0,
    this.currentMessage,
  });

  /// An NPC is considered a Christian if faith is above 50 (Lastenheft 6.2)
  bool get isChristian => faith > 50;

  /// Logic to update faith based on interaction and environment
  void applyInfluence(double amount) {
    faith = (faith + amount).clamp(-100.0, 100.0);
  }
}
