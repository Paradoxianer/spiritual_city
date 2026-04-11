import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spiritual_city/src/app.dart';
import 'package:spiritual_city/src/core/di/service_locator.dart';
import 'package:spiritual_city/src/features/menu/domain/models/app_settings.dart';
import 'package:spiritual_city/src/features/menu/domain/models/game_save.dart';

void main() {
  setUpAll(() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GameSaveAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    await setupServiceLocator();
  });

  testWidgets('Smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SpiritWorldCityApp());
    expect(find.byType(SpiritWorldCityApp), findsOneWidget);
  });
}
