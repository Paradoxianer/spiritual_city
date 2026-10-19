import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/church.dart';
import 'package:spiritual_city/src/features/game/domain/models/daemon_kind.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_model.dart';
import 'package:spiritual_city/src/features/game/domain/models/player_progress.dart';
import 'package:spiritual_city/src/features/game/domain/models/prayer_combat.dart';
import 'package:spiritual_city/src/features/game/domain/models/skills.dart';
import 'package:spiritual_city/src/features/game/domain/services/combat_abilities.dart';
import 'package:spiritual_city/src/features/game/domain/services/daemon_combat_rules.dart';
import 'package:spiritual_city/src/features/game/domain/services/learning_service.dart';
import 'package:spiritual_city/src/features/game/domain/services/mission_service.dart';

NPCModel _npc(String id) =>
    NPCModel(id: id, name: 'Anna $id', type: NPCType.citizen, homePosition: Vector2.zero());

void main() {
  group('Church (#181)', () {
    test('roles yield flat with diminishing returns', () {
      final c = Church();
      for (var i = 0; i < 4; i++) {
        c.members['i$i'] = ChurchMember(npcId: 'i$i', name: 'n', role: ChurchRole.intercessor);
      }
      final four = c.dailyYield().faith;
      expect(four, greaterThan(Church.faithPerIntercessor * 2));
      expect(four, lessThan(Church.faithPerIntercessor * 4));
      expect(c.dailyYield().insight, 0);
    });

    test('a member who worked through a wound becomes a 🩹 healer for others', () {
      NPCModel healed() {
        for (var i = 0; i < 500; i++) {
          final n = _npc('h$i');
          final ch = n.backstory.currentChallenge;
          if (ch == null) continue;
          while (n.backstory.currentChallenge == ch) {
            n.workOnCurrentChallenge();
          }
          return n;
        }
        fail('no challenge');
      }

      final c = Church();
      final h = healed();
      final m = c.join(h);
      expect(m.role, ChurchRole.woundedHealer);
      final eventId = h.backstory.resolvedChallenges.first.event.id;
      expect(c.healerFor(eventId, 1), same(m));
      expect(c.healerFor(eventId, 1, exceptNpcId: h.id), isNull);
      m.lastHelpDay = 1;
      expect(c.healerFor(eventId, 1), isNull, reason: 'one help per day');
      expect(c.healerFor(eventId, 2), same(m));
    });

    test('the church is saved with the progress', () {
      final p = PlayerProgress();
      p.church.members['x'] = ChurchMember(
          npcId: 'x', name: 'Max', role: ChurchRole.helper, healedGlyphs: {'e1': '💔'}, healedEventIds: {'e1'});
      final r = PlayerProgress()..loadFromJson(p.toJson());
      final m = r.church.members['x']!;
      expect(m.role, ChurchRole.helper);
      expect(m.healedEventIds, {'e1'});
      expect(m.healedGlyphs['e1'], '💔');
    });
  });

  group('Combat abilities (#179)', () {
    test('mode level unlocks abilities at 3 and 6', () {
      final s = CombatModifierSet();
      expect(CombatAbilities.tier(s), 0);
      s.strengthLevel = 2;
      s.radiusLevel = 1;
      expect(CombatAbilities.tier(s), 1);
      s.speedLevel = 3;
      expect(CombatAbilities.tier(s), 2);
    });

    test('abilities change the combat rules', () {
      DaemonHit hit(PrayerMode m, int tier, {Set<PrayerMode> active = const {}}) => DaemonCombatRules.hit(
            kind: DaemonKind.leech,
            mode: m,
            damage: 100,
            duration: 2,
            active: active,
            initialEnergy: -300,
            abilityTier: {m: tier, PrayerMode.slow: tier},
          );
      expect(hit(PrayerMode.slow, 1).effectDuration, greaterThan(hit(PrayerMode.slow, 0).effectDuration));
      expect(hit(PrayerMode.rebuke, 1).knockbackFactor, greaterThan(hit(PrayerMode.rebuke, 0).knockbackFactor));
      expect(hit(PrayerMode.rebuke, 2).damage, greaterThan(hit(PrayerMode.rebuke, 1).damage));
      expect(hit(PrayerMode.liberation, 2, active: {PrayerMode.slow}).damage,
          greaterThan(hit(PrayerMode.liberation, 0, active: {PrayerMode.slow}).damage));
    });
  });

  group('Preaching & missions (#172/#173)', () {
    test('preaching is only taught after the first awakening', () {
      final warrior = LearnedSkills({Skill.spiritualWarfare});
      expect(Lessons.offeredAt(BuildingType.church, warrior).map((l) => l.skill),
          isNot(contains(Skill.preaching)));
      expect(Lessons.offeredAt(BuildingType.church, warrior, awakenings: 1).map((l) => l.skill),
          contains(Skill.preaching));
    });

    test('mission rewards grow with the stage', () {
      final m = MissionService(onMissionCompleted: (_) {});
      expect(m.rewardScale, 1.0);
      m.stage = 2;
      expect(m.rewardScale, 2.0);
    });
  });
}
