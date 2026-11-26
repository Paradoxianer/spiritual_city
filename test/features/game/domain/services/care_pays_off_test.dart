import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/services/building_interaction_service.dart';
import 'package:spiritual_city/src/features/game/domain/services/christian_support.dart';
import 'package:spiritual_city/src/features/game/domain/services/npc_interaction_service.dart';

// Playtest 2026-11-13: prayer with Christians who were cared for (👂, 📜,
// church, discipleship) must give much more than with new ones, and their
// light must reach further.
void main() {
  const maxFaith = 260.0; // faith level 9

  test('fellowship with a firm household gives about five times as much', () {
    final fresh = BuildingInteractionService.fellowshipFaithFor(maxFaith, 0);
    final firm = BuildingInteractionService.fellowshipFaithFor(maxFaith, 0.9);
    expect(fresh, greaterThanOrEqualTo(BuildingInteractionService.fellowshipFaith));
    expect(firm / fresh, greaterThan(4.5));
  });

  test('prayer with a firm Christian gives several times as much', () {
    // Barely cared for (church + a few chats ≈ 0.2): little – with the 3
    // every prayer gives, about 7 at faith level 9.
    final fresh = NpcInteractionService.prayWithChristianFaith(maxFaith, 0.2);
    final firm = NpcInteractionService.prayWithChristianFaith(maxFaith, 0.9);
    expect(fresh + 3, lessThanOrEqualTo(8));
    expect(firm / fresh, greaterThan(6));
  });

  test('filling up faith takes three prayers or more, even with full practice – reading half', () {
    expect(BuildingInteractionService.homePrayFaith(maxFaith), 65);
    for (final max in [100.0, maxFaith, 600.0]) {
      // 📖 at home gives half (playtest 2026-11-26): with full practice
      // three quarters, never all of it at once.
      expect(BuildingInteractionService.homeBibleFaith(max) * 1.5, lessThan(max * 0.8));
      for (final gain in [
        BuildingInteractionService.homePrayFaith(max),
        BuildingInteractionService.worshipFaith(max),
        BuildingInteractionService.fellowshipFaithFor(max, 0.9),
      ]) {
        expect(gain * 1.5, lessThanOrEqualTo(max * 0.4), reason: 'max $max');
      }
    }
    expect(BuildingInteractionService.homePrayFaith(40), BuildingInteractionService.pastorHousePrayFaith);
  });

  test('firm Christians protect further', () {
    expect(ChristianSupport.radiusFor(0), 2);
    expect(ChristianSupport.radiusFor(0.45), 5);
    expect(ChristianSupport.radiusFor(0.9), 9);
  });
}
