import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/models/discipleship.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_model.dart';
import 'package:spiritual_city/src/features/game/domain/models/prayer_combat.dart';
import 'package:spiritual_city/src/features/game/domain/models/skills.dart';

NPCModel _npc({bool christian = true}) => NPCModel(
      id: 'n1',
      name: 'N',
      type: NPCType.values.first,
      homePosition: Vector2.zero(),
      isConverted: christian,
    );

void main() {
  test('only what the pastor can pray can be taught', () {
    expect(Discipleship.teachable(LearnedSkills()), [PrayerMode.liberation]);
    expect(Discipleship.teachable(LearnedSkills({Skill.spiritualWarfare})),
        [PrayerMode.liberation, PrayerMode.rebuke]);
  });

  test('never beyond the pastor\'s own level, paid like the pastor\'s upgrades', () {
    final pastor = CombatProfile();
    final learned = LearnedSkills();
    String? why(NPCModel n, PrayerMode m, CombatStat s, int insight) =>
        Discipleship.blocker(n, m, s, pastor: pastor, learned: learned, insight: insight);

    expect(why(_npc(christian: false), PrayerMode.liberation, CombatStat.radius, 99), '✝️🔒');
    final n = _npc();
    expect(why(n, PrayerMode.rebuke, CombatStat.radius, 99), '🎓', reason: '🫸 not learned');
    expect(why(n, PrayerMode.liberation, CombatStat.radius, 99), '🔒⚔️',
        reason: 'the pastor has no 🎯 yet');
    pastor.getFor(PrayerMode.liberation).radiusLevel = 2;
    expect(why(n, PrayerMode.liberation, CombatStat.radius, 0), '🚫📖');
    expect(why(n, PrayerMode.liberation, CombatStat.radius, upgradeInsightCost(0)), isNull);
    CombatStat.radius.raise(n.discipleProfile.getFor(PrayerMode.liberation));
    CombatStat.radius.raise(n.discipleProfile.getFor(PrayerMode.liberation));
    expect(n.isDisciple, isTrue);
    expect(why(n, PrayerMode.liberation, CombatStat.radius, 99), '🔒⚔️');
    expect(Discipleship.praying(n.discipleProfile), [PrayerMode.liberation]);
  });

  test('a disciple prays far weaker than the pastor', () {
    final s = CombatModifierSet(radiusLevel: 5, strengthLevel: 5, speedLevel: 5);
    // The pastor's wave: radius 140, strength 25 (full faith), × upgrades.
    expect(Discipleship.radius(s), lessThan(140 * s.radius));
    expect(Discipleship.strength(s), lessThan(25 * s.strength * 0.3));
  });

  test('a disciple prays the one mode the teacher built up most', () {
    final p = CombatProfile();
    expect(Discipleship.strongest(p), isNull);
    p.getFor(PrayerMode.liberation).radiusLevel = 1;
    p.getFor(PrayerMode.drain)
      ..strengthLevel = 1
      ..speedLevel = 1;
    expect(Discipleship.strongest(p), PrayerMode.drain);
    p.getFor(PrayerMode.liberation).strengthLevel = 1;
    expect(Discipleship.strongest(p), PrayerMode.liberation, reason: 'ties: the earlier mode');
  });
}
