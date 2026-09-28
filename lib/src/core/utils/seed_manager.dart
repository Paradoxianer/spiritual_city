import 'dart:math';

/// Manages the deterministic randomness of the world.
/// A fixed seed ensures that the same city is generated every time.
class SeedManager {
  final int seed;
  late final Random _random;

  /// Seed of the fixed world every game used before seed support was wired in.
  /// Saves with progress but without a stored 'worldSeed' belong to this world.
  static const int legacyWorldSeed = 42;

  SeedManager(this.seed) {
    _random = Random(seed);
  }

  /// Decides which world seed a game session must use.
  ///
  /// * A stored [savedWorldSeed] always wins.
  /// * A save that already has progress ([hasSavedProgress]) but no stored seed
  ///   pre-dates seed support and was played in world [legacyWorldSeed]; its
  ///   cell / NPC states only match that layout.
  /// * A brand-new save uses the seed chosen in the difficulty selector
  ///   ([saveSeed]), falling back to [legacyWorldSeed].
  static int resolveWorldSeed({
    int? savedWorldSeed,
    required bool hasSavedProgress,
    int? saveSeed,
  }) {
    if (savedWorldSeed != null) return savedWorldSeed;
    if (hasSavedProgress) return legacyWorldSeed;
    return saveSeed ?? legacyWorldSeed;
  }

  /// Returns a new Random instance derived from the main seed.
  /// Useful for different generation layers (e.g. one for buildings, one for NPCs).
  Random nextRandom() {
    return Random(_random.nextInt(1000000));
  }
}
