import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/day_stats.dart';
import 'package:spiritual_city/src/features/game/domain/models/player_progress.dart';
import 'package:spiritual_city/src/features/game/domain/models/quarter.dart';

void main() {
  group('Quarter', () {
    test('cells map to neighbourhoods of 48×48, also for negative coordinates', () {
      expect(Quarter.ofCell(0, 0), const Quarter(0, 0));
      expect(Quarter.ofCell(47, 47), const Quarter(0, 0));
      expect(Quarter.ofCell(48, 0), const Quarter(1, 0));
      expect(Quarter.ofCell(-1, -1), const Quarter(-1, -1));
      expect(const Quarter(1, 2).centerCell, (72, 120));
    });

    test('the stronghold opens once enough people are Christians', () {
      expect(Awakening.strongholdOpen(christians: 2, people: 4), isFalse, reason: 'min 3');
      expect(Awakening.strongholdOpen(christians: 3, people: 40), isFalse);
      expect(Awakening.strongholdOpen(christians: 10, people: 40), isTrue);
      expect(Awakening.christiansMissing(christians: 4, people: 40), 6);
    });

    test('labels are emoji and numbers only', () {
      final s = QuarterStatus(quarter: const Quarter(0, 0), christians: 4, people: 40, awakened: false);
      expect(s.label, '🏘️ ✝️ 4/40  🏰🔒6');
      expect(RegExp(r'[A-Za-z]').hasMatch(s.label), isFalse);
    });

    test('awakened neighbourhoods are saved', () {
      final p = PlayerProgress()..awakenedQuarters.add('1,-2');
      final r = PlayerProgress()..loadFromJson(p.toJson());
      expect(r.awakenedQuarters, {'1,-2'});
    });
  });

  group('DayStats', () {
    test('next day clears the counters; every 7th day is Sunday', () {
      final d = DayStats()
        ..conversions = 2
        ..daemonsDefeated = 5;
      expect(d.rows, [('✝️', 2), ('👹', 5)]);
      for (var i = 0; i < 6; i++) {
        d.nextDay();
      }
      expect(d.day, 7);
      expect(d.isSunday, isTrue);
      expect(d.isEmpty, isTrue);
    });

    test('the day is saved with the progress', () {
      final p = PlayerProgress();
      p.dayStats
        ..day = 4
        ..storiesHealed = 1;
      final r = PlayerProgress()..loadFromJson(p.toJson());
      expect(r.dayStats.day, 4);
      expect(r.dayStats.storiesHealed, 1);
    });
  });
}
