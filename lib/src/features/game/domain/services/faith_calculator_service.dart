import 'dart:math';
import '../../../menu/domain/models/difficulty.dart';

/// Calculates faith gain / loss amounts that are randomised and scaled by the
/// active [Difficulty].
///
/// Pass a [rng] instance in tests for deterministic results.
class FaithCalculatorService {
  final Difficulty difficulty;
  final Random _random;

  FaithCalculatorService({required this.difficulty, Random? rng})
      : _random = rng ?? Random();

  /// Talking with an NPC: base gain 0–2.
  int calculateConversationGain() {
    final base = _random.nextInt(3); // 0, 1, or 2
    return _applyMultiplier(base);
  }

  /// Giving a gift / helping an NPC: base gain 1–3.
  int calculateGiftGain() {
    final base = 1 + _random.nextInt(3); // 1, 2, or 3
    return _applyMultiplier(base);
  }

  /// Praying for an NPC: base gain 2–5.
  int calculatePrayerGain() {
    final base = 2 + _random.nextInt(4); // 2, 3, 4, or 5
    return _applyMultiplier(base);
  }

  /// Counseling / Seelsorge – active listening: base gain 1–3.
  int calculateCounselingGain() {
    final base = 1 + _random.nextInt(3); // 1, 2, or 3
    return _applyMultiplier(base);
  }

  /// Reading the Bible with an NPC: base gain 3–6.
  int calculateBibleGain() {
    final base = 3 + _random.nextInt(4); // 3, 4, 5, or 6
    return _applyMultiplier(base);
  }

  /// Faith lost per time-unit spent in a darkness zone.
  int calculateDarknessLoss() {
    const baseLoss = 1;
    return switch (difficulty) {
      Difficulty.easy => 1, // (baseLoss * 0.5).ceil()
      Difficulty.normal => baseLoss,
      Difficulty.hard => baseLoss * 2,
    };
  }

  int _applyMultiplier(int base) {
    return switch (difficulty) {
      Difficulty.easy => (base * 1.5).ceil(), // +50 %
      Difficulty.normal => base,
      Difficulty.hard => (base * 0.5).ceil(), // −50 %
    };
  }
}
