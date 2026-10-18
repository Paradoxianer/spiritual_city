import 'package:flutter/foundation.dart';

/// "First steps" along the core loop (playtest 2026-10-18): faith from the
/// Bible, people come to faith through talk and prayer, prayer liberates
/// the city in the invisible world, daemons, the neighbourhood, missions.
///
/// Shown as a slim goal chip that never covers the game; 📍 on the map and
/// a pulsing button show where to go and what to press. Each step ends
/// when the player does the thing (info steps end with ✓).
enum TutorialStep {
  goHome('🏠🚪'),
  readBible('📖'),
  talk('👤💬'),
  prayPerson('👤🙏'),
  enterSpirit('🙏🌐'),
  liberate('✝️🟩'),
  defeatDaemon('👹'),
  returnCity('🏙️'),
  quarter('🏘️🏰'),
  mission('📋📍'),
  completed('🎉');

  final String emoji;
  const TutorialStep(this.emoji);

  /// Steps that only explain something: the player confirms with ✓.
  bool get isInfo => this == quarter || this == completed;
}

class TutorialService {
  /// Current active tutorial step.  `null` while the tutorial is inactive.
  final ValueNotifier<TutorialStep?> currentStepNotifier =
      ValueNotifier<TutorialStep?>(null);

  /// Whether the tutorial has already been completed (persisted to save data).
  bool isTutorialCompleted = false;

  TutorialStep? get currentStep => currentStepNotifier.value;

  bool get isActive => currentStepNotifier.value != null;

  /// Starts the tutorial (at [at] when resuming a save).
  void startTutorial({TutorialStep? at}) {
    if (isTutorialCompleted) return;
    currentStepNotifier.value = at ?? TutorialStep.values.first;
  }

  /// Advances to the next tutorial step.
  void nextStep() {
    final step = currentStepNotifier.value;
    if (step == null) return;
    final nextIdx = step.index + 1;
    if (nextIdx < TutorialStep.values.length) {
      currentStepNotifier.value = TutorialStep.values[nextIdx];
    }
  }

  /// Marks the tutorial as complete and deactivates it.
  void completeTutorial() {
    isTutorialCompleted = true;
    currentStepNotifier.value = null;
  }

  /// Skips the tutorial entirely (pause menu).
  void skipTutorial() => completeTutorial();

  /// Starts over from the first step (pause menu).
  void restartTutorial() {
    isTutorialCompleted = false;
    currentStepNotifier.value = TutorialStep.values.first;
  }

  void dispose() => currentStepNotifier.dispose();

  void _done(TutorialStep step) {
    if (currentStep == step) nextStep();
  }

  // ── Event hooks ──────────────────────────────────────────────────────────

  /// The pastor stepped into a building.
  void onEnteredBuilding({required bool isHomebase}) {
    if (isHomebase) _done(TutorialStep.goHome);
  }

  /// A building action succeeded ([type] as in BuildingActions).
  void onBuildingAction(String type) {
    if (type == 'readBible') {
      _done(TutorialStep.goHome); // read without the step being noticed
      _done(TutorialStep.readBible);
    }
  }

  /// An action in the dialog with a person ([type] as in NpcActions).
  void onNpcAction(String type) {
    if (type == 'talk') _done(TutorialStep.talk);
    if (type == 'pray') _done(TutorialStep.prayPerson);
  }

  void onEnteredSpiritWorld() => _done(TutorialStep.enterSpirit);

  /// A prayer wave was released in the invisible world.
  void onPrayerPerformed() => _done(TutorialStep.liberate);

  void onDaemonKilled() => _done(TutorialStep.defeatDaemon);

  void onReturnedToCity() => _done(TutorialStep.returnCity);

  /// A mission or lesson was accepted with 📍.
  void onMissionTracked() => _done(TutorialStep.mission);

  /// ✓ on an info step.
  void confirmInfo() {
    final step = currentStep;
    if (step == null || !step.isInfo) return;
    if (step == TutorialStep.completed) {
      completeTutorial();
    } else {
      nextStep();
    }
  }
}
