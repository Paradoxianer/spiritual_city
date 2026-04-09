import 'dart:math';

/// Manages the deterministic randomness of the world.
/// A fixed seed ensures that the same city is generated every time.
class SeedManager {
  final int seed;
  late final Random _random;

  SeedManager(this.seed) {
    _random = Random(seed);
  }

  /// Returns a new Random instance derived from the main seed.
  /// Useful for different generation layers (e.g. one for buildings, one for NPCs).
  Random nextRandom() {
    return Random(_random.nextInt(1000000));
  }
}
