import '../models/city_chunk.dart';

/// A neighbourhood ("Viertel") – the stage goal of a session
/// (core_loop_and_retention.md §3, release_roadmap.md §3.3).
///
/// A square of [chunksPerSide]² chunks. Each has a 🏰 stronghold in the
/// invisible world that opens once enough people there have come to faith,
/// and falls through sustained prayer (2 Cor 10:4). Then the neighbourhood
/// is awakened.
class Quarter {
  static const int chunksPerSide = 3;
  static const int sizeCells = chunksPerSide * CityChunk.chunkSize;

  final int qx;
  final int qy;

  const Quarter(this.qx, this.qy);

  factory Quarter.ofCell(int cx, int cy) =>
      Quarter((cx / sizeCells).floor(), (cy / sizeCells).floor());

  String get key => '$qx,$qy';

  bool containsCell(int cx, int cy) => Quarter.ofCell(cx, cy) == this;

  /// Cell at the centre: where the stronghold stands.
  (int, int) get centerCell => (qx * sizeCells + sizeCells ~/ 2, qy * sizeCells + sizeCells ~/ 2);

  @override
  bool operator ==(Object other) => other is Quarter && other.qx == qx && other.qy == qy;

  @override
  int get hashCode => Object.hash(qx, qy);
}

/// Rules for awakening a neighbourhood.
abstract final class Awakening {
  /// Share of the neighbourhood's (known) people who must be Christians
  /// before its stronghold can be attacked. Startwert; the design doc's 50 %
  /// proved far too long for one session.
  static const double christianShare = 0.25;

  /// At least this many Christians, so tiny samples don't open it.
  static const int minChristians = 3;

  /// Stronghold energy and how fast it recovers when not under prayer.
  static const double strongholdEnergy = 2500.0;
  static const double strongholdRegenPerSecond = 25.0;

  /// Insight for an awakening – the biggest single reward in the game.
  static const double insightReward = 3.0;

  /// Extra daemon power per awakened neighbourhood (#178 scaling).
  static const int powerPerAwakening = 3;

  static bool strongholdOpen({required int christians, required int people}) =>
      christians >= minChristians && people > 0 && christians / people >= christianShare;

  /// Christians still needed to open the stronghold.
  static int christiansMissing({required int christians, required int people}) {
    final needed = (people * christianShare).ceil().clamp(minChristians, 1 << 30);
    return (needed - christians).clamp(0, needed);
  }
}

/// Status of the neighbourhood the pastor is in (for the HUD chip).
class QuarterStatus {
  final Quarter quarter;
  final int christians;
  final int people;
  final bool awakened;

  const QuarterStatus({
    required this.quarter,
    required this.christians,
    required this.people,
    required this.awakened,
  });

  bool get strongholdOpen =>
      Awakening.strongholdOpen(christians: christians, people: people);

  int get missing => Awakening.christiansMissing(christians: christians, people: people);

  /// 0..1 on the way to an attackable stronghold (HUD mini bar); 1 once
  /// open or awakened.
  double get progress {
    if (awakened || strongholdOpen) return 1.0;
    final needed = christians + missing;
    return needed == 0 ? 0.0 : (christians / needed).clamp(0.0, 1.0);
  }

  /// `🏘️ ✝️ 3/20 🏰🔒2` · `🏰⚔️` · `🔥✝️`
  String get label {
    if (awakened) return '🏘️ 🔥✝️';
    final fort = strongholdOpen ? '🏰⚔️' : '🏰🔒$missing';
    return '🏘️ ✝️ $christians/$people  $fort';
  }

  @override
  bool operator ==(Object other) =>
      other is QuarterStatus &&
      other.quarter == quarter &&
      other.christians == christians &&
      other.people == people &&
      other.awakened == awakened;

  @override
  int get hashCode => Object.hash(quarter, christians, people, awakened);
}
