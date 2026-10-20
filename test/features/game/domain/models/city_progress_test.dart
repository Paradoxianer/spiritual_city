import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/quarter.dart';

void main() {
  test('a cell counts as free above zero', () {
    final t = Liberation.ofStates([-0.5, 0.0, 0.01, 1.0]);
    expect(t, const Tally(2, 4));
    expect(t.percent, 50);
  });

  test('percent never shows 100 before everything is free', () {
    expect(const Tally(999, 1000).percent, 99);
    expect(const Tally(1000, 1000).percent, 100);
    expect(Tally.zero.percent, 0);
  });

  test('saved cells are summed per chunk, also at negative coordinates', () {
    final byChunk = Liberation.savedByChunk({
      '0,0': {'s': 0.5},
      '15,15': {'s': -0.2},
      '16,0': {'s': 0.1},
      '-1,-1': {'s': 0.3},
      'broken': {'s': 1.0},
    });
    expect(byChunk['0,0'], const Tally(1, 2));
    expect(byChunk['1,0'], const Tally(1, 1));
    expect(byChunk['-1,-1'], const Tally(1, 1));
    expect(byChunk.length, 3);
  });

  test('chunks belong to the quarter of 3×3 chunks around them', () {
    expect(Liberation.quarterOfChunk(2, 2), const Quarter(0, 0));
    expect(Liberation.quarterOfChunk(3, 0), const Quarter(1, 0));
    expect(Liberation.quarterOfChunk(-1, -3), const Quarter(-1, -1));
  });
}
