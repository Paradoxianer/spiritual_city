import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_cell.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_grid.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_model.dart';
import 'package:spiritual_city/src/features/game/domain/services/world_simulation.dart';

CityGrid _grid(double state) {
  final g = CityGrid();
  for (var y = 0; y < 16; y++) {
    for (var x = 0; x < 16; x++) {
      g.setCell(x, y, CityCell(x: x, y: y, spiritualState: state));
    }
  }
  return g;
}

NPCModel _npc(double faith, {bool christian = false}) => NPCModel(
      id: 'n${faith.round()}$christian',
      name: 'N',
      type: NPCType.values.first,
      homePosition: Vector2.zero(),
      faith: faith,
      isConverted: christian,
    );

void main() {
  group('the ground on people', () {
    double after(double faith, double env, {bool christian = false, double stability = 0}) =>
        WorldSimulation.faithAfterDay(
            faith: faith, isChristian: christian, environment: env, stability: stability);

    test('light surroundings open people – but only up to seeking 🤔', () {
      expect(after(0, 0.9), greaterThan(0));
      expect(after(39.5, 1.0), WorldSimulation.openingCap);
      expect(after(45, 1.0), 45, reason: 'more is a personal step');
      expect(after(60, 1.0, christian: true), greaterThan(60));
    });

    test('dark surroundings close people – not below possession', () {
      expect(after(0, -0.9), lessThan(0));
      expect(after(WorldSimulation.hardeningFloor + 0.5, -1.0), WorldSimulation.hardeningFloor);
    });

    test('neutral surroundings change nothing', () {
      expect(after(10, 0.2), 10);
      expect(after(70, -0.2, christian: true), 70);
    });

    test('Christians lose faith in the dark, less when stable, never below 0', () {
      final weak = after(60, -1.0, christian: true);
      final stable = after(60, -1.0, christian: true, stability: 0.8);
      expect(weak, lessThan(stable));
      expect(stable, lessThan(60));
      expect(after(1, -1.0, christian: true), 0);
    });

    test('stability grows with care, life talks, church and discipleship', () {
      final none = WorldSimulation.baseStability(
          resolvedChallenges: 0, interactions: 0, churchMember: false, discipleLevel: 0);
      final cared = WorldSimulation.baseStability(
          resolvedChallenges: 2, interactions: 10, churchMember: true, discipleLevel: 4);
      expect(none, 0);
      expect(cared, greaterThan(0.5));
      expect(WorldSimulation.stabilityWith(0.85, 10), 0.9, reason: 'never complete');
      expect(WorldSimulation.stabilityWith(0, 1, self: true), 0, reason: 'not counting oneself');
    });
  });

  group('people and houses on the ground', () {
    test('a Christian lightens the ground around them, a hostile person darkens it', () {
      final g = _grid(0);
      final c = _npc(80, christian: true);
      final h = _npc(-90);
      WorldSimulation.simulateDay(g,
          chunks: g.getLoadedChunks(), residents: [Resident(c, 4, 4), Resident(h, 12, 12)]);
      expect(g.getCell(4, 4)!.spiritualState, greaterThan(0.1));
      expect(g.getCell(5, 4)!.spiritualState, greaterThan(0));
      expect(g.getCell(12, 12)!.spiritualState, lessThan(-0.1));
    });

    test('a shaken Christian ✝️💔 no longer lightens', () {
      final g = _grid(0);
      final c = _npc(10, christian: true);
      expect(c.isShakenChristian, isTrue);
      WorldSimulation.simulateDay(g, chunks: g.getLoadedChunks(), residents: [Resident(c, 4, 4)]);
      expect(g.getCell(4, 4)!.spiritualState, lessThanOrEqualTo(0));
    });

    test('holy houses lighten their door, dark houses darken it', () {
      final g = _grid(0);
      WorldSimulation.simulateDay(g,
          chunks: g.getLoadedChunks(),
          residents: const [],
          anchors: const [HouseAnchor(100, 2, 2), HouseAnchor(-100, 10, 10)]);
      expect(g.getCell(2, 2)!.spiritualState, greaterThan(0));
      expect(g.getCell(10, 10)!.spiritualState, lessThan(0));
    });

    test('a dark district wears down the faith of its Christians over the days', () {
      final g = _grid(-0.9);
      final c = _npc(60, christian: true);
      for (var d = 0; d < 30; d++) {
        WorldSimulation.simulateDay(g, chunks: g.getLoadedChunks(), residents: [Resident(c, 8, 8)]);
      }
      expect(c.faith, lessThan(NPCModel.shakenBelow));
      expect(c.isConverted, isTrue, reason: 'shaken, never lost');
    });
  });
}
