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
    final fresh = NpcInteractionService.prayWithChristianFaith(maxFaith, 0);
    final firm = NpcInteractionService.prayWithChristianFaith(maxFaith, 0.9);
    expect(firm / fresh, greaterThan(6));
  });

  test('home prayer fills half the faith, never less than before', () {
    expect(BuildingInteractionService.homePrayFaith(maxFaith), 130);
    expect(BuildingInteractionService.homePrayFaith(40), BuildingInteractionService.pastorHousePrayFaith);
  });

  test('firm Christians protect further', () {
    expect(ChristianSupport.radiusFor(0), 2);
    expect(ChristianSupport.radiusFor(0.45), 3);
    expect(ChristianSupport.radiusFor(0.9), 5);
  });
}
