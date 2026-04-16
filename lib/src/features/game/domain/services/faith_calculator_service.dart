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

  /// Unified difficulty factor:  easy = 1.5 ×, normal = 1.0 ×, hard = 0.5 ×.
  /// Gains are multiplied by this factor; costs use the inverse (1 / factor).
  double get _difficultyFactor => difficultyFactorFor(difficulty);

  /// Public static version so callers outside this service (e.g. the UI timer)
  /// can derive the same factor without duplicating the switch.
  static double difficultyFactorFor(Difficulty d) => switch (d) {
    Difficulty.easy   => 1.5,
    Difficulty.normal => 1.0,
    Difficulty.hard   => 0.5,
  };

  /// Faith cost paid by the player when praying for an NPC.
  /// Base 2 × inverse factor: easy ≈ 1, normal = 2, hard = 4.
  int calculatePrayerFaithCost() {
    return (2.0 / _difficultyFactor).round().clamp(1, 99);
  }

  /// Spiritual-state nudge applied to the NPC's cell when prayer is accepted.
  /// Base 0.025 × factor: easy ≈ 0.04, normal = 0.025, hard ≈ 0.013.
  double calculatePrayerCellDelta() {
    return (0.025 * _difficultyFactor).clamp(0.01, 0.10);
  }

  /// HP cost paid by the player when counseling an NPC (active listening is tiring).
  /// Base 2 × inverse factor: easy ≈ 1, normal = 2, hard = 4.
  int calculateCounselingHpCost() {
    return (2.0 / _difficultyFactor).round().clamp(1, 99);
  }

  /// Faith lost per time-unit spent in a darkness zone.
  /// Base 1 × inverse factor: easy ≈ 1, normal = 1, hard = 2.
  int calculateDarknessLoss() {
    return (1.0 / _difficultyFactor).round().clamp(1, 99);
  }

  int _applyMultiplier(int base) {
    return (base * _difficultyFactor).ceil();
  }
}
