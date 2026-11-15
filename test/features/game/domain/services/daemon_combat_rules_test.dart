import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/daemon_kind.dart';
import 'package:spiritual_city/src/features/game/domain/models/player_progress.dart';
import 'package:spiritual_city/src/features/game/domain/models/prayer_combat.dart';
import 'package:spiritual_city/src/features/game/domain/services/christian_support.dart';
import 'package:spiritual_city/src/features/game/domain/services/daemon_combat_rules.dart';

DaemonHit _hit(DaemonKind k, PrayerMode m, {Set<PrayerMode> active = const {}}) =>
    DaemonCombatRules.hit(
      kind: k,
      mode: m,
      damage: 100,
      duration: 2,
      active: active,
      initialEnergy: -300,
    );

void main() {
  group('Daemon kinds (#178)', () {
    test('every ordinary kind has a different weakness', () {
      final w = {DaemonKind.lurker, DaemonKind.brute, DaemonKind.leech}.map((k) => k.weakness);
      expect(w.toSet().length, 3);
    });

    test('weakness: slow lasts longer on a lurker, rebuke pushes a brute further, '
        'drain hurts a leech more', () {
      expect(_hit(DaemonKind.lurker, PrayerMode.slow).effectDuration,
          greaterThan(_hit(DaemonKind.brute, PrayerMode.slow).effectDuration));
      expect(_hit(DaemonKind.brute, PrayerMode.rebuke).knockbackFactor,
          greaterThan(_hit(DaemonKind.lurker, PrayerMode.rebuke).knockbackFactor));
      expect(_hit(DaemonKind.leech, PrayerMode.drain).damage,
          greaterThan(_hit(DaemonKind.brute, PrayerMode.drain).damage));
      expect(_hit(DaemonKind.leech, PrayerMode.drain).weaknessHit, isTrue);
    });

    test('combo: the Slow → Drain → Rebuke chain does clearly more than the '
        'same three modes without combo', () {
      const k = DaemonKind.brute;
      final slow = _hit(k, PrayerMode.slow);
      final drain = _hit(k, PrayerMode.drain, active: {PrayerMode.slow});
      final rebuke = _hit(k, PrayerMode.rebuke, active: {PrayerMode.slow, PrayerMode.drain});
      final plain = _hit(k, PrayerMode.slow).damage +
          _hit(k, PrayerMode.drain).damage +
          _hit(k, PrayerMode.rebuke).damage;

      expect(drain.effectDuration, greaterThan(_hit(k, PrayerMode.drain).effectDuration));
      expect(rebuke.knockbackFactor, greaterThan(_hit(k, PrayerMode.rebuke).knockbackFactor));
      expect(rebuke.chainCompleted, isTrue);
      expect(slow.damage + drain.damage + rebuke.damage, greaterThan(2 * plain));
    });

    test('other orders are weaker (no chain)', () {
      final r = _hit(DaemonKind.brute, PrayerMode.rebuke, active: {PrayerMode.slow});
      expect(r.chainCompleted, isFalse);
    });

    test('tier is visible in size and grows energy', () {
      expect(DaemonCombatRules.tierSize(1), 1.0);
      expect(DaemonCombatRules.tierSize(3), 1.5);
      expect(DaemonCombatRules.tierEnergy(2), greaterThan(1.0));
      expect(DaemonCombatRules.tierFor(0), 1);
      expect(DaemonCombatRules.tierFor(DaemonCombatRules.tier2Power), 2);
      expect(DaemonCombatRules.tierFor(DaemonCombatRules.tier3Power), 3);
    });

    test('grace period: after an upgrade the old power holds for 3 visits', () {
      final p = PlayerProgress();
      expect(p.onSpiritWorldEntered(), 0);
      p.combatProfile.getFor(PrayerMode.liberation).strengthLevel = 10;
      p.onUpgradeBought();
      expect(p.onSpiritWorldEntered(), 0);
      expect(p.onSpiritWorldEntered(), 0);
      expect(p.onSpiritWorldEntered(), 0);
      expect(p.onSpiritWorldEntered(), 10);
      final restored = PlayerProgress()..loadFromJson(p.toJson());
      expect(restored.daemonPower, 10);
    });
  });

  group('ChristianSupport (#180)', () {
    test('Christians slow the fallback with diminishing returns', () {
      expect(ChristianSupport.fallbackFactor(0), 1.0);
      final one = ChristianSupport.fallbackFactor(1);
      final two = ChristianSupport.fallbackFactor(2);
      expect(one, lessThan(1.0));
      expect(two, lessThan(one));
      expect(1.0 - one, greaterThan(one - two)); // second helps less
      expect(ChristianSupport.fallbackFactor(100), ChristianSupport.minFallbackFactor);
    });
  });
}
