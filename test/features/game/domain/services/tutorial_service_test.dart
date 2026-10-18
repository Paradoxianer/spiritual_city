import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/services/tutorial_service.dart';

void main() {
  test('the first steps follow the core loop, each ended by doing it', () {
    final t = TutorialService()..startTutorial();
    expect(t.currentStep, TutorialStep.readBible);
    t.onNpcAction('talk');
    expect(t.currentStep, TutorialStep.readBible, reason: 'only the current step counts');
    t.onBuildingAction('readBible');
    t.onNpcAction('talk');
    t.onNpcAction('pray');
    t.onEnteredSpiritWorld();
    t.onPrayerPerformed();
    t.onDaemonKilled();
    t.onReturnedToCity();
    expect(t.currentStep, TutorialStep.quarter);
    t.confirmInfo();
    t.onMissionTracked();
    expect(t.currentStep, TutorialStep.completed);
    t.confirmInfo();
    expect(t.isActive, isFalse);
    expect(t.isTutorialCompleted, isTrue);
  });

  test('a save resumes at its step; a finished tutorial never restarts', () {
    final t = TutorialService()..startTutorial(at: TutorialStep.enterSpirit);
    expect(t.currentStep, TutorialStep.enterSpirit);
    t.skipTutorial();
    t.startTutorial();
    expect(t.isActive, isFalse);
  });
}
