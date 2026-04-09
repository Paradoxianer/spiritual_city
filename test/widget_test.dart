import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/app.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SpiritWorldCityApp());
    expect(find.byType(SpiritWorldCityApp), findsOneWidget);
  });
}
