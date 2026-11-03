import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

import 'playthrough.dart';

/// The headless playthrough (playthrough.dart). The short run is part of
/// the normal tests; the long one is started on purpose:
///
///   SIM=1 flutter test test/simulation/playthrough_test.dart
///   SIM=1 SIM_QUARTERS=2 SIM_DAYS=730 SIM_DIFFICULTY=hard SIM_SEED=7 flutter test …
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
  test('long playthrough', () {
    final config = PlaythroughConfig(
      seed: int.tryParse(env['SIM_SEED'] ?? '') ?? 959865928,
      quarterRadius: int.tryParse(env['SIM_QUARTERS'] ?? '') ?? 1,
      maxDays: int.tryParse(env['SIM_DAYS'] ?? '') ?? 365,
      difficulty: Difficulty.values.firstWhere((d) => d.name == env['SIM_DIFFICULTY'],
          orElse: () => Difficulty.normal),
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
        'gerechnet in ${watch.elapsed.inSeconds} s');
    // ignore: avoid_print
    sim.quarterSummary().forEach(print);
    final dir = Directory('build/sim')..createSync(recursive: true);
    File('${dir.path}/playthrough_${config.seed}_${config.quarterRadius}_${config.difficulty.name}.csv')
        .writeAsStringSync([DayReport.csvHeader, for (final r in result.reports) r.csv].join('\n'));
  }, skip: env['SIM'] == null ? 'nur mit SIM=1' : false, timeout: const Timeout(Duration(hours: 2)));
}
