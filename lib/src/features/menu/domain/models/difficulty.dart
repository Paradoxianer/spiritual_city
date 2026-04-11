/// Difficulty levels for the game. Lastenheft §5.4
enum Difficulty {
  easy,
  normal,
  hard;

  /// Opposition modifier relative to normal (0.0 = normal).
  double get oppositionModifier => switch (this) {
        Difficulty.easy => -0.30,
        Difficulty.normal => 0.0,
        Difficulty.hard => 0.30,
      };

  /// Faith regeneration modifier relative to normal (0.0 = normal).
  double get faithRegenModifier => switch (this) {
        Difficulty.easy => 0.50,
        Difficulty.normal => 0.0,
        Difficulty.hard => 0.0,
      };
}
