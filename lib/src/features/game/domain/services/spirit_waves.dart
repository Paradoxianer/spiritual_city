import 'dart:math';

import '../../../menu/domain/models/difficulty.dart';
import '../models/daemon_kind.dart';
import '../models/quarter.dart';

/// The waves of one visit to the invisible world (playtest 2026-11-14,
/// docs/game_design/daemons_and_combat.md §4b): daemons come in waves 🌊,
/// each a little bigger, stronger and more mixed. A cleared wave ends in a
/// breakthrough – a thick green wave from the pastor that grows the longer
/// they hold out. Leaving keeps what was won; the next visit starts at 🌊1.
class SpiritWaves {
  /// The wave running now (1 on entering).
  int wave = 1;

  /// Daemons of [wave] spawned so far.
  int spawned = 0;

  /// Breath left before the next wave (0 = a wave runs).
  double pause = 0;

  /// The kinds the running wave is made of.
  List<DaemonKind> kinds = const [DaemonKind.leech];

  static const double pauseSeconds = 5;

  /// Seconds between two daemons of a wave.
  static const double spawnMin = 1.5;
  static const double spawnMax = 3.5;

  /// Daemons in [wave]: 4 / 6 / 8 to start, two more each wave.
  static int size(int wave, Difficulty d) =>
      switch (d) {
        Difficulty.easy => 4,
        Difficulty.normal => 6,
        Difficulty.hard => 8,
      } +
      2 * (wave - 1);

  /// Energy factor of the daemons in [wave]: +15 % per wave.
  static double energy(int wave) => 1 + 0.15 * (wave - 1);

  /// Radius (cells) of the breakthrough after [wave]: 6 more each wave, at
  /// most half a neighbourhood – the wave then covers about one.
  static int breakthroughCells(int wave) => min(6 * wave, Quarter.sizeCells ~/ 2);

  /// How much it greens the ground (wave strength, as the pastor's waves).
  static double breakthroughStrength(int wave) => min(50.0 + 10 * wave, 100);

  /// Faith people in the breakthrough gain – more open for the gospel.
  static double openness(int wave) => min(2.0 * wave, 12);

  /// On entering: 🌊1.
  void start(Random rng) {
    wave = 1;
    spawned = 0;
    pause = 0;
    kinds = kindsFor(1, rng);
  }

  bool spawnedAll(Difficulty d) => spawned >= size(wave, d);

  /// The wave is beaten: breath, then the next one.
  void cleared(Random rng) {
    wave++;
    spawned = 0;
    pause = pauseSeconds;
    kinds = kindsFor(wave, rng);
  }

  /// Wave 1 is one kind, wave 2 two, from wave 3 on all three.
  static List<DaemonKind> kindsFor(int wave, Random rng) {
    final all = [DaemonKind.lurker, DaemonKind.brute, DaemonKind.leech]..shuffle(rng);
    return all.take(min(wave, all.length)).toList();
  }
}
