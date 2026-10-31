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

  test('only Christians, one gift, one step per day, paid with 📖', () {
    expect(discipleBlocker(_npc(christian: false), PrayerMode.liberation, 99, 1), '✝️🔒');
    final n = _npc();
    expect(discipleBlocker(n, PrayerMode.liberation, 4, 1), '🚫📖');
    expect(discipleBlocker(n, PrayerMode.liberation, 5, 1), isNull);
    n
      ..discipleGift = PrayerMode.liberation
      ..discipleLevel = 1
      ..discipleTaughtDay = 1;
    expect(n.isDisciple, isTrue);
    expect(discipleBlocker(n, PrayerMode.liberation, 99, 1), '📅');
    expect(discipleBlocker(n, PrayerMode.rebuke, 99, 2), '✅', reason: 'one gift per person');
    expect(discipleBlocker(n, PrayerMode.liberation, 9, 2), '🚫📖', reason: 'next day');
    expect(discipleBlocker(n, PrayerMode.liberation, 10, 2), isNull);
    n.discipleLevel = Discipleship.maxLevel;
    expect(discipleBlocker(n, PrayerMode.liberation, 99, 3), '✅');
  });

  test('deeper gifts pray more often, wider and stronger – but far below the pastor', () {
    for (var l = 1; l < Discipleship.maxLevel; l++) {
      expect(Discipleship.interval(l + 1), lessThan(Discipleship.interval(l)));
      expect(Discipleship.radius(l + 1), greaterThan(Discipleship.radius(l)));
      expect(Discipleship.strength(l + 1), greaterThan(Discipleship.strength(l)));
    }
    expect(Discipleship.strength(Discipleship.maxLevel), lessThan(25 * 0.4));
    expect(Discipleship.radius(Discipleship.maxLevel), lessThan(140));
  });
}
