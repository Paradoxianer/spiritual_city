import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_cell.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_grid.dart';
import 'package:spiritual_city/src/features/game/domain/services/world_simulation.dart';

// Playtest 2026-11-20: freed ground should hold like in the Game of Life –
// red eats in from outside by its depth, green holds itself together,
// nothing turns red everywhere at once.

/// 80×80 cells: a quarter (48×48) of [inside] in [outside].
CityGrid _quarter({required double inside, required double outside}) {
  final g = CityGrid();
  for (var y = 0; y < 80; y++) {
    for (var x = 0; x < 80; x++) {
      final q = x >= 16 && x < 64 && y >= 16 && y < 64;
      g.setCell(x, y, CityCell(x: x, y: y, spiritualState: q ? inside : outside));
    }
  }
  return g;
}

void _days(CityGrid g, int n) {
  for (var d = 0; d < n; d++) {
    WorldSimulation.simulateDay(g, chunks: g.getLoadedChunks(), residents: const []);
  }
}

int _green(CityGrid g) {
  var n = 0;
  for (var y = 16; y < 64; y++) {
    for (var x = 16; x < 64; x++) {
      if (g.getCell(x, y)!.spiritualState > WorldSimulation.greenAbove) n++;
    }
  }
  return n;
}

void main() {
  test('green among green stays green – for good', () {
    final g = _quarter(inside: 1, outside: 1);
    _days(g, 360);
    expect(_green(g), 48 * 48);
  });

  test('grey stays grey until red reaches it', () {
    final g = _quarter(inside: 0, outside: 0);
    _days(g, 120);
    expect(g.getCell(40, 40)!.spiritualState, 0);
  });

  test('a freed quarter in deep red holds 6 h from the edge in, its middle untouched', () {
    final g = _quarter(inside: 1, outside: -1);
    _days(g, 360); // 6 h, not a single Christian
    expect(_green(g), greaterThan(48 * 48 * 0.7));
    expect(g.getCell(40, 40)!.spiritualState, greaterThan(0.9));
    expect(g.getCell(16, 40)!.spiritualState, lessThan(-0.3), reason: 'the edge is eaten');
  });

  test('shallow red inside green heals, a deep speck only grows very slowly', () {
    final g = _quarter(inside: 1, outside: 1);
    g.getCell(30, 30)!.spiritualState = -0.4;
    g.getCell(50, 50)!.spiritualState = -1;
    _days(g, 360);
    expect(g.getCell(30, 30)!.spiritualState, greaterThan(WorldSimulation.greenAbove));
    expect(g.getCell(50, 50)!.spiritualState, -1, reason: 'only prayer frees deep red');
    expect(g.getCell(51, 50)!.spiritualState, greaterThan(WorldSimulation.greenAbove));
  });

  test('red presses by its depth', () {
    expect(WorldSimulation.press(-0.2), 0);
    expect(WorldSimulation.press(-0.4), lessThan(0.1));
    expect(WorldSimulation.press(-1), 1);
  });
}
