import 'package:flame/components.dart';

abstract class Interactable {
  String get interactionLabel;
  String get interactionEmoji;
  void onInteract();
  Vector2 get interactionPosition;
  String handleInteraction(String type);
}
