import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/menu/domain/models/city_size.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

import 'playthrough.dart';

/// The headless playthrough (playthrough.dart). The short run is part of
/// the normal tests; the long one is started on purpose:
///
///   SIM=1 flutter test test/simulation/playthrough_test.dart
///   SIM=1 SIM_QUARTERS=2 SIM_DAYS=730 SIM_DIFFICULTY=hard SIM_SEED=7 flutter test …
///
/// Variants: SIM_DIALOG=bible (📖 in every slot, the last 👂),
/// SIM_HOUSES=1 (houses act on the ground) / SIM_HOUSES=bless (and the
/// bot prays every Christian home fully holy), SIM_LIFE=1 (life talks
/// after each conversion), SIM_BUS=1 (🚌 for longer ways), SIM_CHURCH=1
/// (refill faith in the nearest church instead of at home), SIM_FELLOW=1
/// (🙏👥 refill in any fully Christian household), SIM_CITY=village
/// (a whole city of that size; won when everyone is a Christian).
///
/// It prints a line every few game days and writes the whole run to
/// build/sim/playthrough_<seed>_<quarters>_<difficulty>.csv.
void main() {
  test('short playthrough: the home quarter comes to faith and light', () {
    final result = Playthrough(const PlaythroughConfig(quarterRadius: 0, maxDays: 120)).run();
    final last = result.reports.last;
    expect(last.christianShare, greaterThan(0.5), reason: '$last');
    expect(result.fortAttempts, isNotEmpty, reason: 'the home fort should open');
  });

  final env = Platform.environment;
  test('holding test', () {
    for (final (name, houses, bless, life) in [
      ('ohne Häuser', false, false, false),
      ('Häuser wirken', true, false, false),
      ('Häuser gesegnet', true, true, false),
      ('Lebensgespräche', false, false, true),
      ('gesegnet + Leben', true, true, true),
    ]) {
      final sim = Playthrough(PlaythroughConfig(
          quarterRadius: 1, maxDays: 5000, holdDays: 600, houses: houses, blessHouses: bless, lifeTalks: life));
      sim.run();
      String at(int d) => d < sim.held.length ? '${(sim.held[d] * 100).round()} %' : '–';
      // ignore: avoid_print
      print('${name.padRight(18)} frei nach Ruhe: 0 T ${at(0)} · 30 T ${at(30)} · 60 T ${at(60)} · 120 T ${at(120)} · '
          '300 T ${at(300)} · 600 T ${at(599)} · 💔 am Ende ${sim.reports.last.shaken}');
    }
  }, skip: env['SIM_HOLD'] == null ? 'nur mit SIM_HOLD=1' : false, timeout: const Timeout(Duration(hours: 1)));
  test('long playthrough', () {
    final config = PlaythroughConfig(
      seed: int.tryParse(env['SIM_SEED'] ?? '') ?? 959865928,
      quarterRadius: int.tryParse(env['SIM_QUARTERS'] ?? '') ?? 1,
      maxDays: int.tryParse(env['SIM_DAYS'] ?? '') ?? 365,
      difficulty: Difficulty.values.firstWhere((d) => d.name == env['SIM_DIFFICULTY'],
          orElse: () => Difficulty.normal),
      dialog: env['SIM_DIALOG'] == 'bible' ? DialogStyle.bibleThenCounsel : DialogStyle.mixed,
      houses: env['SIM_HOUSES'] != null,
      blessHouses: env['SIM_HOUSES'] == 'bless',
      lifeTalks: env['SIM_LIFE'] != null,
      bus: env['SIM_BUS'] != null,
      churches: env['SIM_CHURCH'] != null,
      fellowship: env['SIM_FELLOW'] != null,
      citySize: CitySize.values.where((c) => c.name == env['SIM_CITY']).firstOrNull,
    );
    final watch = Stopwatch()..start();
    final sim = Playthrough(config);
    final result = sim.run();
    final every = (result.reports.length / 30).ceil().clamp(1, 1 << 20);
    for (var i = 0; i < result.reports.length; i += every) {
      // ignore: avoid_print
      print(result.reports[i]);
    }
    // ignore: avoid_print
    print(result.reports.last);
    final hours = {for (final e in result.timeSpent.entries) e.key: (e.value / 3600).toStringAsFixed(1)};
    // ignore: avoid_print
    print('${result.won ? '🎉 GEWONNEN' : '⏳ nicht gewonnen'} nach ${result.days} Tagen '
        '(${(result.days / 60).toStringAsFixed(1)} h Spielzeit) · Zeit in h: $hours · '
        'Festungen: ${result.fortAttempts} aufgegeben: ${result.fortsGivenUp} · '
        'höchstens 💔${sim.peakShaken} · gerechnet in ${watch.elapsed.inSeconds} s');
    // ignore: avoid_print
    sim.quarterSummary().forEach(print);
    final dir = Directory('build/sim')..createSync(recursive: true);
    File('${dir.path}/playthrough_${config.seed}_${config.quarterRadius}_${config.difficulty.name}.csv')
        .writeAsStringSync([DayReport.csvHeader, for (final r in result.reports) r.csv].join('\n'));
  }, skip: env['SIM'] == null ? 'nur mit SIM=1' : false, timeout: const Timeout(Duration(hours: 2)));
}
