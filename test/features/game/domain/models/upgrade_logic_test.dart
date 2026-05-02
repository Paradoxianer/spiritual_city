import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/player_progress.dart';
import 'package:spiritual_city/src/features/game/domain/models/prayer_combat.dart';

void main() {
  // ── upgradeInsightCost ────────────────────────────────────────────────────

  group('upgradeInsightCost', () {
    test('level 0 → cost is 1 (Einstiegs-Upgrade)', () {
      expect(upgradeInsightCost(0), 1);
    });

    test('level 1 → cost is 1', () {
      expect(upgradeInsightCost(1), 1);
    });

    test('level 2 → cost is 2', () {
      expect(upgradeInsightCost(2), 2);
    });

    test('level 3 → cost is 3', () {
      expect(upgradeInsightCost(3), 3);
    });

    test('level 4 → cost is 5', () {
      expect(upgradeInsightCost(4), 5);
    });

    test('level 6 → cost is 11', () {
      expect(upgradeInsightCost(6), 11);
    });

    test('cost is always at least 1', () {
      for (int level = 0; level <= 10; level++) {
        expect(upgradeInsightCost(level), greaterThanOrEqualTo(1),
            reason: 'level $level must have cost ≥ 1');
      }
    });

    test('costs are monotonically non-decreasing', () {
      int prev = upgradeInsightCost(0);
      for (int level = 1; level <= 10; level++) {
        final cost = upgradeInsightCost(level);
        expect(cost, greaterThanOrEqualTo(prev),
            reason: 'cost at level $level must be ≥ cost at level ${level - 1}');
        prev = cost;
      }
    });
  });

  // ── CombatModifierSet ─────────────────────────────────────────────────────

  group('CombatModifierSet', () {
    test('default levels are 0 and multipliers are 1.0', () {
      final set = CombatModifierSet();
      expect(set.radiusLevel, 0);
      expect(set.strengthLevel, 0);
      expect(set.durationLevel, 0);
      expect(set.speedLevel, 0);
      expect(set.radius, 1.0);
      expect(set.strength, 1.0);
      expect(set.duration, 1.0);
      expect(set.speed, 1.0);
    });

    test('multiplier increases by kCombatUpgradeStep per level', () {
      final set = CombatModifierSet(radiusLevel: 3);
      expect(set.radius, closeTo(1.0 + 3 * kCombatUpgradeStep, 0.0001));
    });

    test('level 10 gives 2.0 radius multiplier', () {
      final set = CombatModifierSet(radiusLevel: 10);
      expect(set.radius, closeTo(2.0, 0.0001));
    });

    test('toJson round-trips via fromJson', () {
      final original = CombatModifierSet(
        radiusLevel: 2,
        strengthLevel: 4,
        durationLevel: 1,
        speedLevel: 3,
      );
      final json = original.toJson();
      final restored = CombatModifierSet.fromJson(json);

      expect(restored.radiusLevel, 2);
      expect(restored.strengthLevel, 4);
      expect(restored.durationLevel, 1);
      expect(restored.speedLevel, 3);
    });

    test('fromJson defaults to 0 for missing keys', () {
      final set = CombatModifierSet.fromJson({});
      expect(set.radiusLevel, 0);
      expect(set.strengthLevel, 0);
      expect(set.durationLevel, 0);
      expect(set.speedLevel, 0);
    });
  });

  // ── CombatProfile (defense) ───────────────────────────────────────────────

  group('CombatProfile defense', () {
    test('default shieldLevel and helmLevel are 0 with no reduction', () {
      final profile = CombatProfile();
      expect(profile.shieldLevel, 0);
      expect(profile.helmLevel, 0);
      expect(profile.shieldDamageReduction, 0.0);
      expect(profile.helmHungerReduction, 0.0);
    });

    test('shieldDamageReduction is kShieldDamageReductionPerLevel per level', () {
      final profile = CombatProfile(shieldLevel: 3);
      expect(profile.shieldDamageReduction,
          closeTo(3 * kShieldDamageReductionPerLevel, 0.0001));
    });

    test('helmHungerReduction is kHelmHungerReductionPerLevel per level', () {
      final profile = CombatProfile(helmLevel: 5);
      expect(profile.helmHungerReduction,
          closeTo(5 * kHelmHungerReductionPerLevel, 0.0001));
    });

    test('shieldDamageReduction is capped at 0.8', () {
      final profile = CombatProfile(shieldLevel: 100);
      expect(profile.shieldDamageReduction, 0.8);
    });

    test('helmHungerReduction is capped at 0.8', () {
      final profile = CombatProfile(helmLevel: 100);
      expect(profile.helmHungerReduction, 0.8);
    });

    test('toJson / fromJson round-trips shield and helm levels', () {
      final original = CombatProfile(shieldLevel: 3, helmLevel: 2);
      final json = original.toJson();
      final restored = CombatProfile.fromJson(json);
      expect(restored.shieldLevel, 3);
      expect(restored.helmLevel, 2);
    });

    test('fromJson defaults shield/helm to 0 when keys are absent', () {
      final profile = CombatProfile.fromJson({});
      expect(profile.shieldLevel, 0);
      expect(profile.helmLevel, 0);
    });
  });

  // ── PlayerProgress.spendInsight ───────────────────────────────────────────

  group('PlayerProgress.spendInsight', () {
    late PlayerProgress progress;

    setUp(() {
      progress = PlayerProgress();
      progress.addInsight(5.0); // gives insight = 5
    });

    test('spending affordable amount succeeds and deducts insight', () {
      final ok = progress.spendInsight(3);
      expect(ok, isTrue);
      expect(progress.insight, 2);
    });

    test('spending exact balance succeeds', () {
      final ok = progress.spendInsight(5);
      expect(ok, isTrue);
      expect(progress.insight, 0);
    });

    test('spending more than available returns false and does not change insight', () {
      final ok = progress.spendInsight(10);
      expect(ok, isFalse);
      expect(progress.insight, 5);
    });

    test('spending zero always succeeds', () {
      final ok = progress.spendInsight(0);
      expect(ok, isTrue);
      expect(progress.insight, 5);
    });
  });

  // ── PlayerProgress save / load (CombatProfile levels) ─────────────────────

  group('PlayerProgress save/load CombatProfile', () {
    test('combat profile levels survive a toJson → loadFromJson round-trip', () {
      final progress = PlayerProgress();
      progress.addInsight(10.0);

      // Simulate upgrading a modifier
      final libStats = progress.combatProfile.getFor(PrayerMode.liberation);
      libStats.radiusLevel = 3;
      libStats.strengthLevel = 2;
      progress.combatProfile.shieldLevel = 2;
      progress.combatProfile.helmLevel = 1;

      // Serialise then restore
      final json = progress.toJson();
      final restored = PlayerProgress();
      restored.loadFromJson(json);

      final restoredLib = restored.combatProfile.getFor(PrayerMode.liberation);
      expect(restoredLib.radiusLevel, 3);
      expect(restoredLib.strengthLevel, 2);
      expect(restoredLib.durationLevel, 0);
      expect(restored.combatProfile.shieldLevel, 2);
      expect(restored.combatProfile.helmLevel, 1);
      expect(restored.insight, 10);
    });

    test('loading old save (no level keys) defaults all levels to 0', () {
      final progress = PlayerProgress();
      // Old save format had float values, not levels
      progress.loadFromJson({
        'insight': 3,
        'combatProfile': {
          'liberation': {'radius': 1.2, 'strength': 1.0, 'duration': 1.0, 'speed': 1.0},
        },
      });
      // Should not crash; levels default to 0
      final lib = progress.combatProfile.getFor(PrayerMode.liberation);
      expect(lib.radiusLevel, 0);
      expect(lib.strengthLevel, 0);
      expect(progress.insight, 3);
    });
  });
}
