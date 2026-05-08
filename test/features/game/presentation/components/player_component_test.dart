import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/presentation/components/player_component.dart';

void main() {
  group('PlayerComponent joystick sprint threshold', () {
    test('does not sprint below 80% joystick magnitude', () {
      expect(PlayerComponent.isJoystickSprintThresholdReached(0.79), isFalse);
    });

    test('sprints at 80% joystick magnitude', () {
      expect(PlayerComponent.isJoystickSprintThresholdReached(0.8), isTrue);
    });

    test('sprints above 80% joystick magnitude', () {
      expect(PlayerComponent.isJoystickSprintThresholdReached(0.95), isTrue);
    });
  });
}
