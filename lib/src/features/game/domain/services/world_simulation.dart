import 'dart:math' as math;
import 'dart:typed_data';

import '../models/cell_object.dart';
import '../models/city_cell.dart';
import '../models/city_chunk.dart';
import '../models/city_grid.dart';
import '../models/npc_model.dart';
import 'christian_support.dart';

/// A person in the world simulation: who, and on which cell they are.
class Resident {
  final NPCModel npc;
  final int x;
  final int y;

  /// Stability from care, life talks, church and discipleship (0–1),
  /// without the Christians around – the simulation adds those.
  final double baseStability;

  const Resident(this.npc, this.x, this.y, {this.baseStability = 0});
}

/// A house in the world simulation: its holiness acts on the cells
/// around it ([radius], BuildingModel.influenceRadius), strongest at the
/// house – a holy household holds its street (playtest 2026-11-03: on the
/// door cell alone it changed nothing).
class HouseAnchor {
  final double holiness;
  final int x;
  final int y;
  final int radius;
  const HouseAnchor(this.holiness, this.x, this.y, {this.radius = 3});
}

/// Difficulty and modifier knobs of the simulation.
class WorldTuning {
  /// Strength of people's influence on the ground (easy 1.5 … hard 0.5).
  final double personFactor;

  /// 🌱 Wachstum modifier: how fast green heals the shallow red it encloses.
  final double spreadMultiplier;

  /// Bewahrung modifier: share of the red pressure held off.
  final double decayReduction;

  const WorldTuning({
    this.personFactor = 1.0,
    this.spreadMultiplier = 1.0,
    this.decayReduction = 0.0,
  });
}

/// One day of the invisible world (#194, docs/game_design/npc_influence.md):
/// the ground among itself ("Game of Life"), people and houses on the
/// ground, and the ground on people – everywhere, not only near the
/// pastor. Pure rules on the city grid, independent of any player, so the
/// same day can later run on a server for a shared city.
abstract final class WorldSimulation {
  // ── Ground among itself (playtest 2026-11-20: like the Game of Life) ──
  //
  // Each cell looks at its 8 neighbours. Red presses by its depth – deep
  // red fronts eat in, a shallow red speck hardly does. Green neighbours
  // hold it off and heal shallow red they enclose, but green never spreads
  // on its own (that is prayer, Christians and holy houses). No drift of
  // its own: grey stays grey and green stays green until red reaches it.

  /// A neighbour counts as green above this.
  static const double greenAbove = 0.3;

  /// A neighbour presses from here down (0 at −0.2 … 1 at −1, squared).
  static const double pressFrom = -0.2;

  /// Loss per day per unit of red pressure.
  static const double redPressure = 0.008;

  /// Share of the pressure each green neighbour holds off.
  static const double greenShield = 0.075;

  /// Healing per day per green neighbour, from [healNeighbours] on.
  static const double greenHealing = 0.0004;
  static const int healNeighbours = 5;

  /// Shallow red heals fully down to [healableTo]; from [deepRed] down only
  /// prayer frees it.
  static const double healableTo = -0.3;
  static const double deepRed = -0.7;

  /// Decay towards neutral for weakly held cells (|state| < 0.08).
  static const double decayRate = 0.98;

  /// Church cells: constant light per day.
  static const double churchBonus = 0.02;

  /// How hard a neighbour in [state] presses (0 … 1).
  static double press(double state) {
    final d = ((pressFrom - state) / (1 + pressFrom)).clamp(0.0, 1.0);
    return d * d;
  }

  /// Share of the green healing a cell in [state] takes (1 … 0 for deep red).
  static double healable(double state) =>
      ((state - deepRed) / (healableTo - deepRed)).clamp(0.0, 1.0);

  /// One day's change of a cell in [state] among its neighbours: red
  /// [pressure] (sum of [press]), [green] neighbours, [christians] in reach.
  static double groundDelta(double state,
      {required double pressure, required int green, int christians = 0, WorldTuning t = const WorldTuning()}) {
    var delta = -redPressure *
        pressure *
        (1 - greenShield * green) *
        (1 - t.decayReduction) *
        ChristianSupport.fallbackFactor(christians);
    if (green >= healNeighbours && state < 1) {
      delta += greenHealing * green * healable(state) * t.spreadMultiplier;
    }
    if (state.abs() < 0.08) delta += -state * (1 - decayRate);
    return delta;
  }

  // ── People and houses on the ground ─────────────────────────────────────

  /// A Christian's light per faith point on their own / neighbouring cells.
  /// (Their protecting reach is [ChristianSupport.radius]; a lone Christian
  /// in deep darkness must still be worn down – they need the others.)
  static const double christianCentre = 0.003;
  static const double christianAdjacent = 0.001;

  /// Disciples shine brighter (#193).
  static const double discipleFactor = 1.5;

  /// Sympathetic people (faith > 50) light their cell a little.
  static const double sympathetic = 0.02;

  /// Hostile people (faith < −50) darken their cell per faith point.
  static const double hostilePerFaith = 0.002;

  /// The undecided (faith −50 … 0) darken it much less.
  static const double undecidedPerFaith = 0.0002;

  /// A house's holiness (−100 … 100) at its centre, per 100 points; it
  /// fades to nothing at the edge of its radius.
  static const double housePer100 = 0.03;

  /// A holy house (holiness > 0, e.g. converted residents) shines this much
  /// stronger and one cell further than a dark one darkens.
  static const double holyHouseFactor = 2.0;
  static const int holyHouseExtraRadius = 1;

  // ── The ground on people ────────────────────────────────────────────────

  /// Surroundings brighter / darker than this move people's faith.
  static const double environmentThreshold = 0.3;

  /// Faith change per day at fully light / dark surroundings.
  static const double openingPerDay = 2.0;
  static const double hardeningPerDay = 2.0;
  static const double christianLossPerDay = 3.0;

  /// Light surroundings make people at most "seeking" – the step of faith
  /// stays a personal one, in a talk with the pastor.
  static const double openingCap = 40.0;

  /// Darkness pushes at most to just above possession (that stays its own
  /// mechanic).
  static const double hardeningFloor = NPCModel.possessionFaithThreshold + 1;

  /// Simulates one day for the cells of [chunks] and the given people and
  /// houses (only those on these chunks matter for a catch-up) at once.
  static void simulateDay(
    CityGrid grid, {
    required Iterable<CityChunk> chunks,
    required List<Resident> residents,
    List<HouseAnchor> anchors = const [],
    WorldTuning tuning = const WorldTuning(),
  }) {
    final day = WorldDay(grid, chunks: chunks, residents: residents, anchors: anchors, tuning: tuning);
    while (!day.step(1 << 30)) {}
  }

  // ── Rules (public for tests and the help) ───────────────────────────────

  /// Mean state of the 3×3 cells around ([x], [y]).
  static double surroundings(CityGrid grid, int x, int y) {
    var sum = 0.0;
    var n = 0;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final c = grid.getCell(x + dx, y + dy);
        if (c == null) continue;
        sum += c.spiritualState;
        n++;
      }
    }
    return n == 0 ? 0 : sum / n;
  }

  /// A person's faith after one day in [environment] (−1 … 1).
  static double faithAfterDay({
    required double faith,
    required bool isChristian,
    required double environment,
    required double stability,
  }) {
    final light = environment - environmentThreshold;
    final dark = -environment - environmentThreshold;
    const strength = 1 / (1 - environmentThreshold); // 0 … 1 above the threshold
    if (light > 0) {
      final gain = openingPerDay * light * strength;
      if (isChristian) return math.min(100, faith + gain);
      if (faith >= openingCap) return faith;
      return math.min(openingCap, faith + gain);
    }
    if (dark > 0) {
      if (isChristian) {
        // Never below zero: a Christian can be shaken, not lost.
        final loss = christianLossPerDay * dark * strength * (1 - stability.clamp(0.0, 1.0));
        return math.max(0, faith - loss);
      }
      if (faith <= hardeningFloor) return faith;
      return math.max(hardeningFloor, faith - hardeningPerDay * dark * strength);
    }
    return faith;
  }

  /// Stability of a person from [base] plus the Christians around them
  /// (never complete: 0.9 at most).
  static double stabilityWith(double base, int christiansAround, {bool self = false}) {
    final others = math.max(0, christiansAround - (self ? 1 : 0));
    return (base + math.min(0.2, 0.05 * others)).clamp(0.0, 0.9);
  }

  /// Base stability from care (👂 visits), worked-through life challenges
  /// (📜), church membership (⛪) and discipleship (🌱).
  static double baseStability({
    required int resolvedChallenges,
    required int interactions,
    required bool churchMember,
    required int discipleLevel,
  }) =>
      (math.min(0.45, 0.15 * resolvedChallenges) +
              math.min(0.15, 0.01 * interactions) +
              (churchMember ? 0.1 : 0) +
              math.min(0.3, 0.03 * discipleLevel))
          .clamp(0.0, 0.9);

  // ── Internals ───────────────────────────────────────────────────────────

  static void _houses(CityGrid grid, List<HouseAnchor> anchors) {
    for (final a in anchors) {
      final holy = a.holiness > 0;
      final centre = a.holiness / 100 * housePer100 * (holy ? holyHouseFactor : 1);
      if (centre == 0) continue;
      final r = a.radius + (holy ? holyHouseExtraRadius : 0);
      for (var dy = -r; dy <= r; dy++) {
        for (var dx = -r; dx <= r; dx++) {
          final d = math.sqrt((dx * dx + dy * dy).toDouble());
          if (d > r) continue;
          final cell = grid.getCell(a.x + dx, a.y + dy);
          if (cell != null) _add(cell, centre * (1 - d / (r + 1)));
        }
      }
    }
  }

  static void _groundOnPerson(CityGrid grid, Resident r, Map<int, int> christiansNear) {
    final stability =
        stabilityWith(r.baseStability, christiansNear[_key(r.x, r.y)] ?? 0, self: r.npc.isChristian);
    r.npc.faith = faithAfterDay(
      faith: r.npc.faith,
      isChristian: r.npc.isChristian,
      environment: surroundings(grid, r.x, r.y),
      stability: stability,
    );
  }

  static const List<(int, int)> _dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
  static const List<(int, int)> _around = [
    (-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1),
  ];

  static int _key(int x, int y) => ((x + 0x100000) << 21) | (y + 0x100000);

  static void _add(CityCell cell, double d) =>
      cell.spiritualState = (cell.spiritualState + d).clamp(-1.0, 1.0);

  /// Christians (not shaken ones) in reach of each cell (#180).
  static Map<int, int> _christiansNear(List<Resident> residents) {
    final near = <int, int>{};
    for (final p in residents) {
      if (!p.npc.isChristian || p.npc.isShakenChristian) continue;
      final r = ChristianSupport.radiusFor(p.baseStability);
      for (var dy = -r; dy <= r; dy++) {
        for (var dx = -r; dx <= r; dx++) {
          final k = _key(p.x + dx, p.y + dy);
          near[k] = (near[k] ?? 0) + 1;
        }
      }
    }
    return near;
  }

  /// The ground among itself – deltas first, so the order does not matter.
  /// Per chunk into a flat list (no hashing of cells – the hot loop).
  static void _groundDay(
      CityGrid grid, Iterable<CityChunk> chunks, Map<int, int> christiansNear, WorldTuning t) {
    const size = CityChunk.chunkSize;
    final list = chunks.toList();
    final deltas = [for (final _ in list) Float64List(size * size)];
    for (var k = 0; k < list.length; k++) {
      final chunk = list[k];
      final out = deltas[k];
      for (var ly = 0; ly < size; ly++) {
        for (var lx = 0; lx < size; lx++) {
          final cell = chunk.at(lx, ly);
          if (cell == null) continue;
          final st = cell.spiritualState;
          var pressure = 0.0;
          var green = 0;
          for (final (dx, dy) in _around) {
            final nx = lx + dx, ny = ly + dy;
            final n = (nx >= 0 && nx < size && ny >= 0 && ny < size)
                ? chunk.at(nx, ny)
                : grid.getCell(cell.x + dx, cell.y + dy);
            if (n == null) continue;
            pressure += press(n.spiritualState);
            if (n.spiritualState > greenAbove) green++;
          }
          var delta = groundDelta(st,
              pressure: pressure, green: green, christians: christiansNear[_key(cell.x, cell.y)] ?? 0, t: t);
          final data = cell.data;
          if (data is BuildingData &&
              (data.type == BuildingType.church || data.type == BuildingType.cathedral)) {
            delta += churchBonus;
          }
          out[ly * size + lx] = delta;
        }
      }
    }
    for (var k = 0; k < list.length; k++) {
      final chunk = list[k];
      final out = deltas[k];
      for (var i = 0; i < size * size; i++) {
        final cell = chunk.at(i % size, i ~/ size);
        if (cell == null) continue;
        final d = out[i];
        if (d != 0) _add(cell, d);
      }
    }
  }

  /// One person's light or darkness on the cells around them.
  static void _personOnGround(CityGrid grid, Resident r, WorldTuning t) {
    final npc = r.npc;
    final cell = grid.getCell(r.x, r.y);
    if (cell == null) return;
    if (npc.isChristian) {
      if (npc.isShakenChristian) return; // ✝️💔 needs care first
      // Firm Christians (care, church, discipleship) shine brighter.
      final f = npc.faith * t.personFactor * (npc.isDisciple ? discipleFactor : 1.0) *
          (1 + r.baseStability.clamp(0.0, 1.0));
      _add(cell, f * christianCentre);
      for (final (dx, dy) in _dirs) {
        final n = grid.getCell(r.x + dx, r.y + dy);
        if (n != null) _add(n, f * christianAdjacent);
      }
    } else if (npc.faith > 50) {
      _add(cell, sympathetic * t.personFactor);
    } else if (npc.faith < 0) {
      // Hostile people darken where they stand, the undecided a little
      // (grey is drawn slowly into red) – less the greener it is around
      // them; there their faith opens too, so it gives with time.
      final perFaith = npc.faith < -50 ? hostilePerFaith : undecidedPerFaith;
      final light = surroundings(grid, r.x, r.y).clamp(0.0, 1.0);
      _add(cell, npc.faith * perFaith * t.personFactor * (1 - light));
    }
  }
}

/// One day of [WorldSimulation] that can be spread over several frames
/// ([step] a little at a time) – a whole explored city at once made the
/// game stutter once a minute (playtest 2026-10-31). First the ground
/// chunk by chunk, then people and houses on the ground, then the ground
/// on people – each in slices.
class WorldDay {
  final CityGrid grid;
  final List<CityChunk> _chunks;
  final List<Resident> residents;
  final List<HouseAnchor> anchors;
  final WorldTuning tuning;
  late final Map<int, int> _christiansNear = WorldSimulation._christiansNear(residents);

  /// People handled per step for each chunk the step may do.
  static const int peoplePerChunk = 20;

  int _phase = 0;
  int _next = 0;

  WorldDay(
    this.grid, {
    required Iterable<CityChunk> chunks,
    required this.residents,
    this.anchors = const [],
    this.tuning = const WorldTuning(),
  }) : _chunks = chunks.toList();

  bool get isDone => _phase > 2;

  /// Does up to [maxChunks] chunks of ground (or the same work in people)
  /// more. Returns true when the day is complete.
  bool step(int maxChunks) {
    switch (_phase) {
      case 0: // the ground among itself
        final end = math.min(_chunks.length, _next + maxChunks);
        WorldSimulation._groundDay(grid, _chunks.sublist(_next, end), _christiansNear, tuning);
        _next = end;
      case 1: // people and houses on the ground
        final end = math.min(residents.length, _next + maxChunks * peoplePerChunk);
        for (var i = _next; i < end; i++) {
          WorldSimulation._personOnGround(grid, residents[i], tuning);
        }
        _next = end;
        if (_next >= residents.length) WorldSimulation._houses(grid, anchors);
      case 2: // the ground on people
        final end = math.min(residents.length, _next + maxChunks * peoplePerChunk);
        for (var i = _next; i < end; i++) {
          WorldSimulation._groundOnPerson(grid, residents[i], _christiansNear);
        }
        _next = end;
    }
    final total = _phase == 0 ? _chunks.length : residents.length;
    if (_phase <= 2 && _next >= total) {
      _phase++;
      _next = 0;
    }
    return isDone;
  }
}
