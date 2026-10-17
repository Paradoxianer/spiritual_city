import 'package:flutter/foundation.dart';

import '../actions/resource.dart';
import 'player_progress.dart';

/// The pastor's resources (docs/game_design/release_roadmap.md §2.1).
///
/// Backed by [ValueNotifier]s so Flutter overlays (resource HUD) react to
/// changes even while the Flame loop is paused. Every gain or spend also
/// feeds the resource stages of [PlayerProgress] (#61), which raise the
/// maxima the values are clamped to.
class PlayerResources implements ResourceWallet {
  final PlayerProgress Function() _progress;

  PlayerResources(this._progress);

  PlayerProgress get progress => _progress();

  final ValueNotifier<double> faithNotifier = ValueNotifier(100.0);
  final ValueNotifier<double> healthNotifier = ValueNotifier(100.0);
  final ValueNotifier<double> hungerNotifier = ValueNotifier(80.0);
  final ValueNotifier<double> materialsNotifier = ValueNotifier(40.0);

  double get faith => faithNotifier.value;
  set faith(double v) => faithNotifier.value = v;

  double get health => healthNotifier.value;
  set health(double v) => healthNotifier.value = v;

  double get hunger => hungerNotifier.value;
  set hunger(double v) => hungerNotifier.value = v;

  double get materials => materialsNotifier.value;
  set materials(double v) => materialsNotifier.value = v;

  @override
  double amountOf(Resource r) => switch (r) {
        Resource.faith => faith,
        Resource.health => health,
        Resource.hunger => hunger,
        Resource.materials => materials,
        Resource.insight => progress.insight.toDouble(),
      };

  void _track(ResourceStage stage, double amount) {
    if (stage.add(amount)) progress.notifyLevelUp();
  }

  /// Spend resources (clamped to 0).
  void spendFaith(double amount) {
    _track(progress.faithStage, amount);
    faith = (faith - amount).clamp(0.0, progress.maxFaith);
  }

  void spendHealth(double amount) {
    _track(progress.healthStage, amount);
    health = (health - amount).clamp(0.0, progress.maxHealth);
  }

  void spendHunger(double amount) {
    _track(progress.hungerStage, amount);
    hunger = (hunger - amount).clamp(0.0, progress.maxHunger);
  }

  /// Spend materials; returns false (and spends nothing) if not enough.
  bool spendMaterials(double amount) {
    if (materials < amount) return false;
    _track(progress.materialsStage, amount);
    materials = (materials - amount).clamp(0.0, progress.maxMaterials);
    return true;
  }

  /// Gain resources (clamped to max). Negative amounts reduce the value.
  void gainFaith(double amount) {
    _track(progress.faithStage, amount);
    faith = (faith + amount).clamp(0.0, progress.maxFaith);
  }

  void gainHealth(double amount) {
    _track(progress.healthStage, amount);
    health = (health + amount).clamp(0.0, progress.maxHealth);
  }

  void gainHunger(double amount) {
    _track(progress.hungerStage, amount);
    hunger = (hunger + amount).clamp(0.0, progress.maxHunger);
  }

  void gainMaterials(double amount) {
    _track(progress.materialsStage, amount);
    materials = (materials + amount).clamp(0.0, progress.maxMaterials);
  }

  void dispose() {
    faithNotifier.dispose();
    healthNotifier.dispose();
    hungerNotifier.dispose();
    materialsNotifier.dispose();
  }
}
