import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/menu/presentation/load_game_screen.dart';

void main() {
  test('save summary shows the stored levels and resources', () {
    expect(
      saveSummary({
        'faith': 230.4,
        'materials': 77,
        'progress': {
          'insight': 81,
          'npcsConverted': 12,
          'day': {'day': 9},
          'stages': {'faith': {'stage': 3}, 'materials': {'stage': 2}},
        },
      }),
      '🙏230 Lv3 · 📦77 Lv2 · 📖81 · ✝️12 · 📅9',
    );
    expect(saveSummary({}), '🙏0 Lv1 · 📦0 Lv1 · 📖0 · ✝️0');
  });
}
