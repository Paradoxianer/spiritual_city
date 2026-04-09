import 'package:flutter/foundation.dart';
import '../entities/player_state.dart';
import '../../../../core/constants/game_constants.dart';

class PlayerService extends ChangeNotifier {
  PlayerState state = const PlayerState();

  void consumeFocus(double amount) {
    state = state.copyWith(
      focus: (state.focus - amount).clamp(0.0, 100.0),
    );
    notifyListeners();
  }

  void consumeEnergy(double amount) {
    state = state.copyWith(
      energy: (state.energy - amount).clamp(0.0, 100.0),
    );
    notifyListeners();
  }

  void gainSpiritualStrength(double amount) {
    state = state.copyWith(
      spiritualStrength:
          (state.spiritualStrength + amount).clamp(0.0, 100.0),
    );
    notifyListeners();
  }

  void toggleWorld() {
    if (state.focus >= GameConstants.worldToggleFocusCost) {
      state = state.copyWith(
        isInSpiritualWorld: !state.isInSpiritualWorld,
      );
      consumeFocus(GameConstants.worldToggleFocusCost);
    }
  }
}
