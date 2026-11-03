import 'dart:math' as math;

import 'package:spiritual_city/src/core/utils/game_time.dart';
import 'package:spiritual_city/src/core/utils/seed_manager.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/city_generator.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/district_selector.dart';
import 'package:spiritual_city/src/features/game/domain/city_generation/special_building_registry.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_chunk.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_grid.dart';
import 'package:spiritual_city/src/features/game/domain/models/modifier_manager.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_model.dart';
import 'package:spiritual_city/src/features/game/domain/models/quarter.dart';
import 'package:spiritual_city/src/features/game/domain/models/stronghold_kind.dart';
import 'package:spiritual_city/src/features/game/domain/npc_registry.dart';
import 'package:spiritual_city/src/features/game/domain/services/npc_interaction_service.dart';
import 'package:spiritual_city/src/features/game/domain/services/world_simulation.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

/// A headless playthrough (playtest 2026-11-03): a bot pastor converts the
/// people and prays the invisible world free, quarter by quarter, while
/// the world keeps living – to see whether the darkness can be beaten at
/// all when the pastor has to cross the city again and again.
///
/// Real rules where they are pure Dart: city generation, people
/// ([NPCRegistry]), the dialog ([NpcInteractionService]), the daily world
/// ([WorldSimulation]), strongholds ([StrongholdKind], [Awakening]).
/// Rebuilt from the game's numbers where they live in Flame components:
/// walking (100 px/s along streets), prayer waves (every 1.8 s, 5 🙏,
/// strength 25 × faith × hold bonus, radius 140 px), the stronghold fight,
/// reading the Bible at home (5 s, +40 🙏).
///
/// Not modelled (yet): daemons, disciples and open-air meetings, life
/// talks, missions, hunger and health, houses' holiness, people walking
/// around (they stay at home). Time is simulated, not waited for: a
/// game year runs in seconds.
class PlaythroughConfig {
  final int seed;

  /// Quarters around the home quarter: 0 = only the home quarter,
  /// 1 = 3 × 3 quarters …
  final int quarterRadius;
  final Difficulty difficulty;
  final int maxDays;

  /// Seconds of the game's UI the bot pays per dialog tap, per closing
  /// a dialog (farewell + fade), and to enter the invisible world.
  final double tapSeconds;
  final double closeSeconds;

  /// Whether the bot spends insight on Liberation radius and strength.
  final bool buysUpgrades;

  const PlaythroughConfig({
    this.seed = 959865928,
    this.quarterRadius = 1,
    this.difficulty = Difficulty.normal,
    this.maxDays = 365,
    this.tapSeconds = 2.0,
    this.closeSeconds = 4.0,
    this.buysUpgrades = true,
  });
}

/// One row of the report (one game day).
class DayReport {
  final int day;
  final int christians;
  final int people;
  final int shaken;
  final int freeCells;
  final int darkCells;
  final int cells;
  final int awakened;
  final int quarters;
  final String doing;

  const DayReport(this.day, this.christians, this.people, this.shaken, this.freeCells, this.darkCells,
      this.cells, this.awakened, this.quarters, this.doing);

  double get christianShare => people == 0 ? 0 : christians / people;
  double get freeShare => cells == 0 ? 0 : freeCells / cells;
  double get darkShare => cells == 0 ? 0 : darkCells / cells;

  static const csvHeader = 'day,christians,people,shaken,free_cells,dark_cells,cells,awakened,quarters,doing';
  String get csv => '$day,$christians,$people,$shaken,$freeCells,$darkCells,$cells,$awakened,$quarters,$doing';

  @override
  String toString() => 'Tag ${day.toString().padLeft(4)}  '
      '✝️ ${(christianShare * 100).toStringAsFixed(1).padLeft(5)} % ($christians/$people, 💔$shaken)  '
      '🌐 frei ${(freeShare * 100).toStringAsFixed(1).padLeft(5)} %  dunkel ${(darkShare * 100).toStringAsFixed(1).padLeft(5)} %  '
      '🔥 $awakened/$quarters  · $doing';
}

/// What came out.
class PlaythroughResult {
  final bool won;
  final int days;
  final List<DayReport> reports;

  /// Stronghold attempts per quarter key, and those given up (too strong).
  final Map<String, int> fortAttempts;
  final Set<String> fortsGivenUp;

  /// Game-seconds per activity (walking, talking, home, praying, fort).
  final Map<String, double> timeSpent;

  const PlaythroughResult(this.won, this.days, this.reports, this.fortAttempts, this.fortsGivenUp, this.timeSpent);
}

class _Stop implements Exception {}

class Playthrough {
  final PlaythroughConfig config;
  final CityGrid grid = CityGrid();
  late final CityGenerator _generator = CityGenerator(SeedManager(config.seed));
  late final DistrictSelector _districts = DistrictSelector(seed: config.seed);
  late final NpcInteractionService _dialog =
      NpcInteractionService(difficulty: config.difficulty, rng: math.Random(config.seed));

  final List<NPCModel> people = [];
  final Map<String, (int, int)> _homeCell = {};

  /// Where each person is now: they wander along the streets as in the
  /// game (NPCComponent: one cell per ~1.5 s, roads preferred).
  final Map<String, (int, int)> _pos = {};
  late final math.Random _walkRng = math.Random(config.seed + 1);
  static const int stepsPerDay = 40;
  final Set<String> _members = {};
  final List<Quarter> quarters = [];
  final List<CityChunk> _chunks = [];
  final Set<String> awakened = {};
  final Map<String, int> fortAttempts = {};
  final Set<String> fortsGivenUp = {};
  final Map<String, double> timeSpent = {};
  final List<DayReport> reports = [];

  // ── The pastor ──────────────────────────────────────────────────────────
  static const double cellPx = 32;
  static const double walkCellsPerSecond = 100 / cellPx;
  static const double waveInterval = 1.8;
  static const double waveCost = 5;
  static const double enterSpiritCost = 10;
  static const double bibleAtHomeSeconds = 5;
  static const double bibleAtHomeFaith = 40;
  static const double maxFaith = 100;

  late final (int, int) _home = SpecialBuildingRegistry.pastorHouseCell;
  late (int, int) _at = (_home.$1, _home.$2 + 2); // the boulevard in front
  double faith = maxFaith;
  double health = 100;
  static const double sleepSeconds = 8;
  static const double sleepHealth = 50;
  double insight = 0;
  int radiusLevel = 0;
  int strengthLevel = 0;

  // ── Time ───────────────────────────────────────────────────────────────
  double clock = 0;
  int day = 0;
  String _doing = 'start';

  Playthrough(this.config);

  // ════════════════════════════════════════════════════════════════════════
  // Setup
  // ════════════════════════════════════════════════════════════════════════

  void _build() {
    final home = Quarter.ofCell(_home.$1, _home.$2);
    final r = config.quarterRadius;
    for (var qy = home.qy - r; qy <= home.qy + r; qy++) {
      for (var qx = home.qx - r; qx <= home.qx + r; qx++) {
        quarters.add(Quarter(qx, qy));
      }
    }
    // Nearest quarters first – the order the bot works them in.
    quarters.sort((a, b) => _qDist(a, home).compareTo(_qDist(b, home)));
    final registry = NPCRegistry(seed: config.seed);
    for (final q in quarters) {
      for (var cy = q.qy * Quarter.chunksPerSide; cy < (q.qy + 1) * Quarter.chunksPerSide; cy++) {
        for (var cx = q.qx * Quarter.chunksPerSide; cx < (q.qx + 1) * Quarter.chunksPerSide; cx++) {
          final chunk = grid.getOrCreateChunk(cx, cy);
          _generator.generateChunk(chunk);
          _chunks.add(chunk);
          for (final npc in registry.getNPCsInChunk(cx, cy, chunk: chunk)) {
            people.add(npc);
            _homeCell[npc.id] =
                ((npc.homePosition.x / cellPx).floor(), (npc.homePosition.y / cellPx).floor());
            _pos[npc.id] = _homeCell[npc.id]!;
            if (npc.isChristian) _members.add(npc.id);
          }
        }
      }
    }
  }

  static int _qDist(Quarter a, Quarter b) => (a.qx - b.qx).abs() + (a.qy - b.qy).abs();

  // ════════════════════════════════════════════════════════════════════════
  // Time and the living world
  // ════════════════════════════════════════════════════════════════════════

  /// Lets [seconds] of game time pass for [activity]; the world lives on.
  void _spend(double seconds, String activity) {
    timeSpent[activity] = (timeSpent[activity] ?? 0) + seconds;
    clock += seconds;
    while (clock >= (day + 1) * GameTime.gameDaySeconds) {
      day++;
      _worldDay();
      if (day >= config.maxDays || _won()) throw _Stop();
    }
  }

  void _wander() {
    const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
    for (final p in people) {
      var (x, y) = _pos[p.id]!;
      for (var s = 0; s < stepsPerDay; s++) {
        final order = [...dirs]..shuffle(_walkRng);
        order.sort((a, b) => _road(x + b.$1, y + b.$2).compareTo(_road(x + a.$1, y + a.$2)));
        for (final (dx, dy) in order) {
          if (grid.getCell(x + dx, y + dy) != null && grid.isWalkable(x + dx, y + dy)) {
            x += dx;
            y += dy;
            break;
          }
        }
      }
      _pos[p.id] = (x, y);
    }
  }

  int _road(int x, int y) => grid.getCell(x, y)?.data is RoadData ? 1 : 0;

  void _worldDay() {
    _wander();
    final residents = [
      for (final p in people)
        Resident(p, _pos[p.id]!.$1, _pos[p.id]!.$2,
            baseStability: WorldSimulation.baseStability(
              resolvedChallenges: 0,
              interactions: p.interactionCount,
              churchMember: _members.contains(p.id),
              discipleLevel: 0,
            )),
    ];
    WorldSimulation.simulateDay(grid,
        chunks: _chunks,
        residents: residents,
        tuning: WorldTuning(personFactor: switch (config.difficulty) {
          Difficulty.easy => 1.5,
          Difficulty.normal => 1.0,
          Difficulty.hard => 0.5,
        }));
    _report();
  }

  void _report() {
    var free = 0, dark = 0, cells = 0;
    for (final c in _chunks) {
      for (final cell in c.cells.values) {
        cells++;
        if (Liberation.isFree(cell.spiritualState)) {
          free++;
        } else if (Liberation.isDark(cell.spiritualState)) {
          dark++;
        }
      }
    }
    reports.add(DayReport(day, people.where((p) => p.isChristian).length, people.length,
        people.where((p) => p.isShakenChristian).length, free, dark, cells, awakened.length, quarters.length, _doing));
  }

  /// One line per quarter: kind, Christians, free / dark ground.
  List<String> quarterSummary() => [
        for (final q in quarters)
          () {
            final inQ = _peopleIn(q);
            final states = [
              for (var y = q.qy * Quarter.sizeCells; y < (q.qy + 1) * Quarter.sizeCells; y++)
                for (var x = q.qx * Quarter.sizeCells; x < (q.qx + 1) * Quarter.sizeCells; x++)
                  if (grid.getCell(x, y) case final c?) c.spiritualState,
            ];
            final t = Liberation.ofStates(states);
            final kind = StrongholdKind.of(q,
                district: _districts.getDistrictType,
                homeCell: SpecialBuildingRegistry.pastorHouseCell,
                cityHallCell: SpecialBuildingRegistry.cityHallCell);
            final c = inQ.where((p) => p.isChristian).length;
            return 'Viertel ${q.key.padRight(5)} ${kind.emoji.padRight(4)} ${awakened.contains(q.key) ? '🔥' : '  '} '
                '✝️ $c/${inQ.length}  🌐 frei ${(t.share * 100).round()} %  dunkel ${(t.darkShare * 100).round()} %';
          }(),
      ];

  bool _won() =>
      people.every((p) => p.isChristian) &&
      _chunks.every((c) => c.cells.values.every((cell) => Liberation.isFree(cell.spiritualState)));

  // ════════════════════════════════════════════════════════════════════════
  // The pastor's moves
  // ════════════════════════════════════════════════════════════════════════

  /// Along the street grid: Manhattan distance.
  void _walkTo((int, int) to) {
    final d = (to.$1 - _at.$1).abs() + (to.$2 - _at.$2).abs();
    if (d > 0) _spend(d / walkCellsPerSecond, 'gehen');
    _at = to;
  }

  /// Home, read the Bible until faith is full, back to where the bot was.
  void _refill() {
    final back = _at;
    final before = _doing;
    _doing = 'zuhause';
    _walkTo(_home);
    while (faith < maxFaith) {
      _spend(bibleAtHomeSeconds, 'zuhause');
      faith = math.min(maxFaith, faith + bibleAtHomeFaith);
    }
    while (health < 100) {
      _spend(sleepSeconds, 'zuhause');
      health = math.min(100, health + sleepHealth);
    }
    _buyUpgrades();
    _walkTo(back);
    _doing = before;
  }

  void _buyUpgrades() {
    if (!config.buysUpgrades) return;
    while (true) {
      final strength = strengthLevel <= radiusLevel;
      final level = strength ? strengthLevel : radiusLevel;
      final cost = math.max(1, math.pow(1.5, level).floor());
      if (insight < cost) return;
      insight -= cost;
      if (strength) {
        strengthLevel++;
      } else {
        radiusLevel++;
      }
    }
  }

  double _stateAt((int, int) c) => grid.getCell(c.$1, c.$2)?.spiritualState ?? 0;

  void _brighten((int, int) c, int radius, double amount) {
    for (var dy = -radius; dy <= radius; dy++) {
      for (var dx = -radius; dx <= radius; dx++) {
        final d2 = dx * dx + dy * dy;
        if (d2 > radius * radius) continue;
        final cell = grid.getCell(c.$1 + dx, c.$2 + dy);
        if (cell == null) continue;
        cell.spiritualState = (cell.spiritualState + amount * (1 - d2 / (radius * radius))).clamp(-1.0, 1.0);
      }
    }
  }

  // ── People ────────────────────────────────────────────────────────────

  /// Visits [npc] session after session until they are a Christian (or a
  /// shaken Christian is strong again) – at most [maxSessions] visits.
  void _care(NPCModel npc, {int maxSessions = 40}) {
    final home = _pos[npc.id]!;
    _walkTo(home);
    for (var s = 0; s < maxSessions; s++) {
      if (npc.isChristian && !npc.isShakenChristian) return;
      npc.resetSession();
      while (!npc.isReadyToLeave) {
        if (faith < 10 || health < 20) {
          _refill();
          break;
        }
        final state = _stateAt(home);
        final r = _dialog.perform(_choose(npc, state), npc,
            spiritualState: state, playerFaith: faith, playerHealth: health, playerMaterials: 0);
        final type = _lastType;
        faith = (faith + r.playerFaithDelta).clamp(0.0, maxFaith);
        health = (health + r.playerHealthDelta).clamp(0.0, 100.0);
        insight += r.insightDelta;
        if (r.cellDelta != 0) {
          final cell = grid.getCell(home.$1, home.$2);
          if (cell != null) cell.spiritualState = (cell.spiritualState + r.cellDelta).clamp(-1.0, 1.0);
        }
        _spend(type == 'bible' ? 5 : config.tapSeconds, 'gespräche');
        if (r.converted) {
          _members.add(npc.id);
          _brighten(home, 5, 0.35);
          _spend(config.closeSeconds, 'gespräche');
          return;
        }
        if (!r.performed) break;
      }
      _spend(config.closeSeconds, 'gespräche');
    }
  }

  String _lastType = '';

  /// What a sensible player taps: convert once it would succeed; 📖 first
  /// (strongest, refills a little); 🙏 only when it is likely accepted (a
  /// refusal costs the person 8); 👂 while health lasts; else 💬.
  String _choose(NPCModel npc, double state) {
    String pick() {
      if (!npc.isChristian && npc.faith + state * 50 > 50) return 'convert';
      if (npc.sessionCountFor('bible') == 0) return 'bible';
      final accept = npc.faith / 100 * 0.6 + 0.2 + (npc.interactionCount * 0.015).clamp(0.0, 0.25);
      if (npc.sessionCountFor('pray') == 0 && accept >= 0.55) return 'pray';
      if (npc.sessionCountFor('counsel') == 0 && health > 30) return 'counsel';
      return 'talk';
    }

    return _lastType = pick();
  }

  /// People in [q] now (they wander – as the game counts them).
  List<NPCModel> _peopleIn(Quarter q) =>
      [for (final p in people) if (q.containsCell(_pos[p.id]!.$1, _pos[p.id]!.$2)) p];

  /// One round through [q]: everyone not (firmly) a Christian is visited
  /// once – always the nearest next – until [upToShare] are Christians.
  void _convertQuarter(Quarter q, {double upToShare = 1.0}) {
    _doing = 'bekehren ${q.key}';
    final visited = <String>{};
    while (true) {
      final inQ = _peopleIn(q);
      if (inQ.isEmpty) return;
      if (inQ.where((p) => p.isChristian).length / inQ.length >= upToShare &&
          inQ.every((p) => !p.isShakenChristian)) {
        return;
      }
      final open = [
        for (final p in inQ)
          if ((!p.isChristian || p.isShakenChristian) && !visited.contains(p.id)) p
      ];
      if (open.isEmpty) return;
      open.sort((a, b) => _dist(_pos[a.id]!).compareTo(_dist(_pos[b.id]!)));
      visited.add(open.first.id);
      _care(open.first);
    }
  }

  int _dist((int, int) c) => (c.$1 - _at.$1).abs() + (c.$2 - _at.$2).abs();

  // ── The invisible world ───────────────────────────────────────────────

  double get _waveRadiusCells => (1 + radiusLevel * 0.08) * 140 / cellPx;

  double _waveStrength(double hold) =>
      (1 + strengthLevel * 0.08) * 25 * (faith / 100).clamp(0.1, 2.0) * ModifierManager.holdBonus(hold);

  /// One Liberation wave from where the pastor stands.
  void _wave(double hold) {
    final strength = _waveStrength(hold);
    final r = _waveRadiusCells;
    final ri = r.ceil();
    for (var dy = -ri; dy <= ri; dy++) {
      for (var dx = -ri; dx <= ri; dx++) {
        final d = math.sqrt((dx * dx + dy * dy).toDouble());
        if (d > r) continue;
        final cell = grid.getCell(_at.$1 + dx, _at.$2 + dy);
        if (cell == null) continue;
        cell.spiritualState = (cell.spiritualState + strength / 100 * (1 - d / r)).clamp(-1.0, 1.0);
      }
    }
    faith -= waveCost;
    _spend(waveInterval, 'beten');
  }

  /// Prays the quarter's cells free: always to the nearest cell that is
  /// not free yet, holding the prayer there until it is.
  void _liberateQuarter(Quarter q, {int maxRounds = 4000}) {
    _doing = 'befreien ${q.key}';
    faith -= enterSpiritCost;
    for (var round = 0; round < maxRounds; round++) {
      final target = _nearestUnfree(q);
      if (target == null) return;
      _walkTo(target);
      var hold = 0.0;
      while (_stateAt(target) <= 0.05) {
        if (faith < waveCost + 5) {
          _refill();
          faith -= enterSpiritCost;
          hold = 0;
        }
        _wave(hold);
        hold += waveInterval;
      }
    }
  }

  (int, int)? _nearestUnfree(Quarter q) {
    (int, int)? best;
    var bestD = 1 << 30;
    final x0 = q.qx * Quarter.sizeCells, y0 = q.qy * Quarter.sizeCells;
    for (var y = y0; y < y0 + Quarter.sizeCells; y++) {
      for (var x = x0; x < x0 + Quarter.sizeCells; x++) {
        final cell = grid.getCell(x, y);
        if (cell == null || Liberation.isFree(cell.spiritualState)) continue;
        final d = _dist((x, y));
        if (d < bestD) {
          bestD = d;
          best = (x, y);
        }
      }
    }
    return best;
  }

  // ── The stronghold ────────────────────────────────────────────────────

  /// Fights [q]'s stronghold alone with Liberation; gives up after
  /// [maxAttempts] full faith bars (it healed back each time).
  void _fight(Quarter q, {int maxAttempts = 6}) {
    final kind = StrongholdKind.of(q,
        district: _districts.getDistrictType,
        homeCell: SpecialBuildingRegistry.pastorHouseCell,
        cityHallCell: SpecialBuildingRegistry.cityHallCell);
    _doing = 'festung ${q.key} ${kind.emoji}';
    final centre = q.centerCell;
    var energy = kind.energy;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      fortAttempts[q.key] = attempt;
      // Away (refilling) the stronghold heals back – the whole way home and back.
      final away = clock;
      if (faith < maxFaith) _refill();
      energy = math.min(kind.energy, energy + kind.regenPerSecond * (clock - away));
      _walkTo(centre);
      faith -= enterSpiritCost;
      var hold = 0.0;
      while (faith >= waveCost) {
        // Standing next to it: the wave passes it at about its radius.
        final falloff = 1 - (kind.radius / (_waveRadiusCells * cellPx)).clamp(0.0, 1.0);
        final hit = _waveStrength(hold) * 5 * falloff;
        faith -= waveCost;
        _spend(waveInterval, 'festung');
        hold += waveInterval;
        energy -= hit;
        // Alone it keeps healing if it heals while hit (bulwark, great fortress).
        if (kind.healsWhileHit) energy = math.min(kind.energy, energy + kind.regenPerSecond * waveInterval);
        if (energy <= 0) {
          awakened.add(q.key);
          insight += Awakening.insightReward;
          _brighten(centre, 22, 0.6);
          return;
        }
      }
    }
    fortsGivenUp.add(q.key);
  }

  bool _fortOpen(Quarter q) {
    final inQ = _peopleIn(q);
    return Awakening.strongholdOpen(christians: inQ.where((p) => p.isChristian).length, people: inQ.length);
  }

  // ════════════════════════════════════════════════════════════════════════
  // The whole game
  // ════════════════════════════════════════════════════════════════════════

  PlaythroughResult run() {
    _build();
    _report();
    try {
      // Pass after pass over all quarters (nearest first) until everything
      // is light – an earlier quarter may have fallen back meanwhile.
      while (true) {
        for (final q in quarters) {
          // Light ground first: there people open up faster and convert
          // sooner (faith + ground × 50 > 50).
          _liberateQuarter(q);
          _convertQuarter(q, upToShare: Awakening.christianShare);
          if (!awakened.contains(q.key) && !fortsGivenUp.contains(q.key) && _fortOpen(q)) _fight(q);
          _convertQuarter(q);
        }
        if (_won()) break;
        // Nothing left to do on this pass (all gave up?) – let a day pass.
        _doing = 'warten';
        _spend(GameTime.gameDaySeconds, 'warten');
      }
    } on _Stop {
      // max days or won
    }
    _doing = _won() ? 'gewonnen' : 'ende';
    _report();
    return PlaythroughResult(_won(), day, reports, fortAttempts, fortsGivenUp, timeSpent);
  }
}
