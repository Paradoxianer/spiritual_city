import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/actions/resource.dart';
import 'package:spiritual_city/src/features/game/domain/models/player_progress.dart';
import 'package:spiritual_city/src/features/game/domain/models/player_resources.dart';

void main() {
  group('PlayerResources', () {
    late PlayerProgress progress;
    late PlayerResources r;
    setUp(() {
      progress = PlayerProgress();
      r = PlayerResources(() => progress);
    });

    test('clamps to 0 and to the stage maximum', () {
      r.spendFaith(500);
      expect(r.faith, 0);
      r.gainHealth(500);
      expect(r.health, progress.maxHealth);
    });

    test('spendMaterials refuses without enough and spends nothing', () {
      expect(r.spendMaterials(r.materials + 1), isFalse);
      expect(r.materials, 40);
      expect(r.spendMaterials(10), isTrue);
      expect(r.materials, 30);
    });

    test('gains and spends feed the resource stages', () {
      r.gainFaith(20);
      r.spendFaith(30);
      expect(progress.faithStage.totalAccumulated, 50);
    });

    test('is a ResourceWallet', () {
      expect(r.amountOf(Resource.hunger), 80);
      progress.insight = 3;
      expect(r.amountOf(Resource.insight), 3);
    });
  });
}
