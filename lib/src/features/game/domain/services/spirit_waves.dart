import 'dart:math';

import '../../../menu/domain/models/difficulty.dart';
import '../models/daemon_kind.dart';

/// The waves of one visit to the invisible world – second attempt
/// (playtest 2026-11-15, docs/game_design/daemons_and_combat.md "Notizen
/// für einen zweiten Anlauf"). Readable like the missions:
///
/// - a wave is a fixed set of daemons, all there at once – nothing spawns
///   while it runs, so `🌊2 👹 3/5` always tells what is left;
/// - the next wave is known ahead ([next]) and shown as a preview;
/// - beaten, a green wave rolls from the pastor ([breakthroughCells]),
///   then a real pause ([pauseSeconds]) before the next wave;
/// - the first waves are very easy, later ones harder – and the
///   breakthrough grows with them, without a cap.
///
/// Leaving keeps what was won; the next visit starts at 🌊1.
class SpiritWaves {
  /// The wave running (or, during the pause, coming) now.
  int wave = 1;

  /// The daemons of [wave].
  List<DaemonKind> current = const [];

  /// The daemons of the wave after – the preview.
  List<DaemonKind> next = const [];

  /// Breath left before [wave] comes (0 = it runs).
  double pause = 0;

  static const double pauseSeconds = 6;

  /// The order in which the kinds join: the slow 🪨 first (easy to hit),
  /// then the quick 🐍, from wave 3 the 🦇 that drains faith.
  static const List<DaemonKind> joining = [DaemonKind.brute, DaemonKind.lurker, DaemonKind.leech];

  /// Daemons in [wave]: 2 / 3 / 4 to start, one more each wave.
  static int size(int wave, Difficulty d) =>
      switch (d) {
        Difficulty.easy => 2,
        Difficulty.normal => 3,
        Difficulty.hard => 4,
      } +
      (wave - 1);

  /// Energy factor of the daemons in [wave]: 40 % in the first (very easy),
  /// full strength from wave 5, then on growing.
  static double energy(int wave) => 0.4 + 0.15 * (wave - 1);

  /// Radius (cells) of the breakthrough after [wave] – no cap: whoever
  /// holds out long is rewarded, never punished.
  static int breakthroughCells(int wave) => 6 * wave;

  /// How much it greens the ground.
  static double breakthroughStrength(int wave) => 50.0 + 10 * wave;

  /// Wisdom 📖 for beating [wave] – more for every wave held, no cap
  /// (playtest 2026-11-18): 0.25 for 🌊1, 2.25 for 🌊9.
  static double insight(int wave) => 0.25 * wave;

  /// Faith people in the breakthrough gain – more open for the gospel.
  static double openness(int wave) => 2.0 * wave;

  /// The daemons of [wave]: one kind in wave 1, two in wave 2, from wave 3
  /// all three – each kind at least once, the rest at random.
  static List<DaemonKind> plan(int wave, Difficulty d, Random rng) {
    final kinds = joining.take(min(wave, joining.length)).toList();
    final n = size(wave, d);
    return [
      for (var i = 0; i < n; i++) i < kinds.length ? kinds[i] : kinds[rng.nextInt(kinds.length)],
    ]..sort((a, b) => a.index.compareTo(b.index));
  }

  /// On entering: 🌊1 runs at once.
  void start(Difficulty d, Random rng) {
    wave = 1;
    pause = 0;
    current = plan(1, d, rng);
    next = plan(2, d, rng);
  }

  /// [wave] is beaten: the pause, then the previewed one.
  void cleared(Difficulty d, Random rng) {
    wave++;
    pause = pauseSeconds;
    current = next;
    next = plan(wave + 1, d, rng);
  }
}

/// What the HUD shows: `🌊2 👹 3/5`, the next wave, the pause.
class WaveStatus {
  final int wave;
  final int left;
  final int total;
  final List<DaemonKind> next;

  /// Seconds until [wave] comes (0 = it runs).
  final int pause;

  const WaveStatus(this.wave, this.left, this.total, this.next, this.pause);

  @override
  bool operator ==(Object other) =>
      other is WaveStatus &&
      other.wave == wave &&
      other.left == left &&
      other.total == total &&
      other.pause == pause;

  @override
  int get hashCode => Object.hash(wave, left, total, pause);
}
