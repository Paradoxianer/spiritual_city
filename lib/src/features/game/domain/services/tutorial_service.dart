import 'package:flutter/foundation.dart';

/// All interactive tutorial steps shown to new players.
enum TutorialStep {
  welcome,       // Step 1:  Welcome dialog (manual advance)
  movement,      // Step 2:  Move around (auto-advance on cell change)
  spiritWorld,   // Step 3:  Enter spiritual world (auto-advance)
  prayer,        // Step 4:  Pray / combat in spirit world (auto-advance)
  returnToCity,  // Step 5:  Return to city (auto-advance)
  radialMenu,    // Step 6:  Use radial menu near an NPC (auto-advance)
  npcTalk,       // Step 7:  Open NPC dialog and interact (auto-advance)
  hudExplain,    // Step 8:  HUD / resource explanation (manual advance)
  homebase,      // Step 9:  Pastor house / homebase (manual advance)
  firstMission,  // Step 10: First mission – enter a building (auto-advance)
  completed,     // Step 11: Tutorial completed (manual dismiss)
}

/// Manages the interactive tutorial for new players.
///
/// Call [startTutorial] once on a fresh game session to begin the tutorial.
/// Hook the event methods ([onPlayerMoved], [onNpcDialogOpened] etc.) into the
/// appropriate game-logic callsites so steps advance automatically.
class TutorialService {
  /// Current active tutorial step.  `null` while the tutorial is inactive.
  final ValueNotifier<TutorialStep?> currentStepNotifier =
      ValueNotifier<TutorialStep?>(null);

  /// Whether the tutorial has already been completed (persisted to save data).
  bool isTutorialCompleted = false;

  TutorialStep? get currentStep => currentStepNotifier.value;

  bool get isActive => currentStepNotifier.value != null;

  /// Whether the skip button should be shown for the current step.
  ///
  /// Skip is allowed from the very first step so that returning players are not
  /// forced through the tutorial again.
  bool get canSkip {
    final step = currentStepNotifier.value;
    if (step == null) return false;
    return step != TutorialStep.completed;
  }

  /// Starts the tutorial from the welcome step.
  ///
  /// Does nothing when the tutorial has already been completed.
  void startTutorial() {
    if (isTutorialCompleted) return;
    currentStepNotifier.value = TutorialStep.welcome;
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

  /// Skips the tutorial entirely (available from step 4 onward).
  void skipTutorial() {
    isTutorialCompleted = true;
    currentStepNotifier.value = null;
  }

  void dispose() => currentStepNotifier.dispose();

  // ── Event hooks ──────────────────────────────────────────────────────────

  /// Call when the player moves to a new grid cell.
  void onPlayerMoved() {
    if (currentStep == TutorialStep.movement) nextStep();
  }

  /// Call when an NPC dialog overlay opens.
  ///
  /// No longer auto-advances the tutorial; [TutorialStep.npcTalk] is a
  /// manual-advance step so the player can read the info and press "Weiter".
  void onNpcDialogOpened() {
    // npcTalk is now a manual-advance step – nothing to do here.
  }

  /// Call when the player selects any action from the radial menu.
  void onRadialMenuActionSelected() {
    if (currentStep == TutorialStep.radialMenu) nextStep();
  }

  /// Call when the player enters the spiritual world.
  void onEnteredSpiritWorld() {
    if (currentStep == TutorialStep.spiritWorld) nextStep();
  }

  /// Call when the player performs a prayer / combat action in the spiritual
  /// world (i.e. releases a prayer charge).
  void onPrayerPerformed() {
    if (currentStep == TutorialStep.prayer) nextStep();
  }

  /// Call when the player returns to the visible (city) world.
  void onReturnedToCity() {
    if (currentStep == TutorialStep.returnToCity) nextStep();
  }

  /// Call when the player opens a building interior.
  void onBuildingInteracted() {
    if (currentStep == TutorialStep.firstMission) nextStep();
  }
}
