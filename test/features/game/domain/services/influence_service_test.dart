import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/building_model.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_cell.dart';
import 'package:spiritual_city/src/features/game/domain/models/city_grid.dart';
import 'package:spiritual_city/src/features/game/domain/services/influence_service.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Minimal [CityGrid] with a pre-populated 3×3 cell block centred at (0,0).
CityGrid _makeGrid() {
  final grid = CityGrid();
  for (int y = -2; y <= 2; y++) {
    for (int x = -2; x <= 2; x++) {
      grid.setCell(x, y, CityCell(x: x, y: y, spiritualState: 0.0));
    }
  }
  return grid;
}

void main() {
  group('InfluenceService', () {
    // ── applyAoE – permanent ────────────────────────────────────────────────

    group('permanent effect', () {
      test('immediately nudges the origin cell', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.5,
          radius: 1.0,
          durationType: InfluenceDurationType.permanent,
        );

        expect(grid.getCell(0, 0)!.spiritualState, greaterThan(0.0));
      });

      test('does not register a tracked effect', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.3,
          radius: 2.0,
          durationType: InfluenceDurationType.permanent,
        );

        expect(svc.activeEffectCount, 0);
      });

      test('effect persists after update ticks', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.4,
          radius: 1.0,
          durationType: InfluenceDurationType.permanent,
        );

        final stateBefore = grid.getCell(0, 0)!.spiritualState;

        // Large dt – permanent effects should not decay.
        svc.update(1000.0, grid);

        expect(grid.getCell(0, 0)!.spiritualState, closeTo(stateBefore, 0.001));
      });
    });

    // ── applyAoE – temporary ───────────────────────────────────────────────

    group('temporary effect', () {
      test('registers one tracked effect', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.1,
          radius: 1.0,
          durationType: InfluenceDurationType.temporary,
          durationSeconds: 5.0,
        );

        expect(svc.activeEffectCount, 1);
      });

      test('cell state is positive immediately after apply', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.2,
          radius: 1.0,
          durationType: InfluenceDurationType.temporary,
          durationSeconds: 2.0,
        );

        expect(grid.getCell(0, 0)!.spiritualState, greaterThan(0.0));
      });

      test('effect is reversed after duration expires', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.2,
          radius: 1.0,
          durationType: InfluenceDurationType.temporary,
          durationSeconds: 2.0,
        );

        // Advance past the full duration.
        svc.update(3.0, grid);

        // Cell should be back near 0 (small floating-point error acceptable).
        expect(grid.getCell(0, 0)!.spiritualState.abs(), lessThan(0.01));
      });

      test('tracked effect is removed after expiry', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.1,
          radius: 1.0,
          durationType: InfluenceDurationType.temporary,
          durationSeconds: 1.0,
        );

        svc.update(2.0, grid);

        expect(svc.activeEffectCount, 0);
      });

      test('cell state does NOT change before duration expires', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.3,
          radius: 1.0,
          durationType: InfluenceDurationType.temporary,
          durationSeconds: 10.0,
        );

        final stateAfterApply = grid.getCell(0, 0)!.spiritualState;

        // Advance half-way – should be unchanged for temporary effects.
        svc.update(5.0, grid);

        expect(
          grid.getCell(0, 0)!.spiritualState,
          closeTo(stateAfterApply, 0.001),
        );
      });
    });

    // ── applyAoE – decaying ────────────────────────────────────────────────

    group('decaying effect', () {
      test('registers one tracked effect', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.5,
          radius: 1.0,
          durationType: InfluenceDurationType.decaying,
          durationSeconds: 10.0,
        );

        expect(svc.activeEffectCount, 1);
      });

      test('cell state decreases over time for decaying effect', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.5,
          radius: 1.0,
          durationType: InfluenceDurationType.decaying,
          durationSeconds: 10.0,
        );

        final stateAfterApply = grid.getCell(0, 0)!.spiritualState;

        // Advance by half the duration.
        svc.update(5.0, grid);

        expect(
          grid.getCell(0, 0)!.spiritualState,
          lessThan(stateAfterApply),
        );
      });

      test('cell state is near zero after full duration', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.4,
          radius: 1.0,
          durationType: InfluenceDurationType.decaying,
          durationSeconds: 4.0,
        );

        // Tick with many small steps to simulate the game loop accurately.
        for (int i = 0; i < 100; i++) {
          svc.update(0.04, grid);
        }

        expect(
          grid.getCell(0, 0)!.spiritualState.abs(),
          lessThan(0.05),
        );
      });

      test('tracked effect is removed after decaying expires', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.2,
          radius: 1.0,
          durationType: InfluenceDurationType.decaying,
          durationSeconds: 2.0,
        );

        svc.update(3.0, grid);

        expect(svc.activeEffectCount, 0);
      });
    });

    // ── AoE radius + falloff ──────────────────────────────────────────────

    group('AoE radius and falloff', () {
      test('cells outside radius are not affected', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.5,
          radius: 1.0,
          durationType: InfluenceDurationType.permanent,
        );

        // Cell at distance ~2.83 (diagonal 2,2) should be unaffected.
        expect(grid.getCell(2, 2)!.spiritualState, 0.0);
      });

      test('origin cell receives strongest effect (falloff at 0)', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.5,
          radius: 2.0,
          durationType: InfluenceDurationType.permanent,
        );

        final originState   = grid.getCell(0, 0)!.spiritualState;
        final adjacentState = grid.getCell(1, 0)!.spiritualState;

        expect(originState, greaterThan(adjacentState));
      });
    });

    // ── buildingMultiplier ────────────────────────────────────────────────

    group('buildingMultiplier', () {
      test('2× multiplier doubles the origin-cell state change', () {
        final grid1 = _makeGrid();
        final grid2 = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid1,
          originX: 0, originY: 0,
          delta: 0.1, radius: 1.0,
          durationType: InfluenceDurationType.permanent,
          buildingMultiplier: 1.0,
        );
        svc.applyAoE(
          grid: grid2,
          originX: 0, originY: 0,
          delta: 0.1, radius: 1.0,
          durationType: InfluenceDurationType.permanent,
          buildingMultiplier: 2.0,
        );

        expect(
          grid2.getCell(0, 0)!.spiritualState,
          closeTo(grid1.getCell(0, 0)!.spiritualState * 2.0, 0.001),
        );
      });
    });

    // ── Cell-Glow trigger ─────────────────────────────────────────────────

    group('cell-glow trigger', () {
      test('applyAoE sets glowTimer on affected cells', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.3,
          radius: 1.0,
          durationType: InfluenceDurationType.permanent,
        );

        expect(grid.getCell(0, 0)!.glowTimer, greaterThan(0.0));
      });

      test('glow is green (positive glowStrength) for positive delta', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: 0.3,
          radius: 1.0,
          durationType: InfluenceDurationType.permanent,
        );

        expect(grid.getCell(0, 0)!.glowStrength, greaterThan(0.0));
      });

      test('glow is red (negative glowStrength) for negative delta', () {
        final grid = _makeGrid();
        final svc = InfluenceService();

        svc.applyAoE(
          grid: grid,
          originX: 0, originY: 0,
          delta: -0.3,
          radius: 1.0,
          durationType: InfluenceDurationType.permanent,
        );

        expect(grid.getCell(0, 0)!.glowStrength, lessThan(0.0));
      });
    });

    // ── BuildingInfluenceConstants ────────────────────────────────────────

    group('BuildingInfluenceConstants', () {
      test('multiplierSpiritual > multiplierLarge > multiplierMedium > multiplierSmall', () {
        expect(
          BuildingInfluenceConstants.multiplierSpiritual >
              BuildingInfluenceConstants.multiplierLarge,
          isTrue,
        );
        expect(
          BuildingInfluenceConstants.multiplierLarge >
              BuildingInfluenceConstants.multiplierMedium,
          isTrue,
        );
        expect(
          BuildingInfluenceConstants.multiplierMedium >
              BuildingInfluenceConstants.multiplierSmall,
          isTrue,
        );
      });

      test('multiplierSmall is 1.0 (baseline)', () {
        expect(BuildingInfluenceConstants.multiplierSmall, 1.0);
      });

      test('game-time helpers are consistent', () {
        expect(
          BuildingInfluenceConstants.gameDaySeconds,
          BuildingInfluenceConstants.gameHourSeconds * 24.0,
        );
        expect(
          BuildingInfluenceConstants.gameDaySeconds,
          BuildingInfluenceConstants.gameHalfDaySeconds * 2.0,
        );
      });
    });
  });
}
