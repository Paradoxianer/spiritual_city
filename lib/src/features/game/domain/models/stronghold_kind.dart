import '../city_generation/district_selector.dart';
import 'quarter.dart';

/// How strong a neighbourhood's stronghold is (playtest 2026-10-31: some
/// should hardly fall to one pastor alone – "where two or three are
/// gathered", Mt 18:19–20; "a threefold cord is not quickly broken",
/// Eccl 4:12). Decided by the city itself – the same for every player.
enum StrongholdKind {
  /// 🏰 As before: one pastor manages.
  fort('🏰', 1.0, 1, 25, false, 3, 46),

  /// 🏰🏰 Bulwark: hard alone, comfortable with a disciple.
  bulwark('🏰🏰', 1.6, 2, 30, true, 4, 56),

  /// 🏯 Great fortress (city centre, city hall, slums): hardly possible
  /// alone – it keeps healing until several pray together.
  greatFortress('🏯', 3.0, 3, 45, true, 6, 70);

  final String emoji;

  /// Wall strength compared with a fort.
  final double energyFactor;

  /// Different people praying at it within [unityWindow] that stop its
  /// healing (the pastor counts as one).
  final int unityNeeded;

  /// Healing per second.
  final double regenPerSecond;

  /// Heals even while hit – unless enough pray together.
  final bool healsWhileHit;

  final int maxGuards;
  final double radius;

  const StrongholdKind(this.emoji, this.energyFactor, this.unityNeeded, this.regenPerSecond,
      this.healsWhileHit, this.maxGuards, this.radius);

  double get energy => Awakening.strongholdEnergy * energyFactor;

  /// Seconds within which hits count as praying together.
  static const double unityWindow = 3.0;

  /// Extra damage per further person praying together.
  static const double unityBonusPerPerson = 0.15;

  /// Damage factor for [together] people praying at it.
  static double unityFactor(int together) => 1 + unityBonusPerPerson * (together - 1).clamp(0, 10);

  /// The kind of [q]'s stronghold: the pastor's home quarter is always an
  /// easy start; the city centre, the city hall and the slums have great
  /// fortresses; commercial and industrial quarters bulwarks.
  static StrongholdKind of(
    Quarter q, {
    required DistrictType Function(int x, int y) district,
    required (int, int) homeCell,
    required (int, int) cityHallCell,
  }) {
    if (q == Quarter.ofCell(homeCell.$1, homeCell.$2)) return fort;
    if (q == Quarter.ofCell(cityHallCell.$1, cityHallCell.$2)) return greatFortress;
    final (cx, cy) = q.centerCell;
    return switch (district(cx, cy)) {
      DistrictType.downtown || DistrictType.slums => greatFortress,
      DistrictType.commercial || DistrictType.industrial => bulwark,
      _ => fort,
    };
  }
}
