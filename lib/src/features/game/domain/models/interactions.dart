import 'package:flame/components.dart';

abstract class Interactable {
  String get interactionLabel;
  void onInteract();
  Vector2 get interactionPosition;
}

class InteractionAction {
  final String title;
  final void Function() onExecute;

  InteractionAction({required this.title, required this.onExecute});
}
