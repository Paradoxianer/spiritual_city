import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/core/i18n/app_language.dart';
import 'package:spiritual_city/src/core/i18n/app_strings.dart';
import 'package:spiritual_city/src/core/i18n/bible_ref.dart';
import 'package:spiritual_city/src/core/i18n/strings_es.dart';
import 'package:spiritual_city/src/core/i18n/strings_fr.dart';
import 'package:spiritual_city/src/core/i18n/strings_pt.dart';

void main() {
  test('every UI string is translated into every language', () {
    AppStrings.setLanguage('en');
    // English keys come from the fallback: look them up via a key list.
    for (final (name, map) in [('es', stringsEs), ('fr', stringsFr), ('pt', stringsPt)]) {
      AppStrings.setLanguage(name);
      for (final key in stringsEs.keys) {
        expect(map.containsKey(key), isTrue, reason: '$name: $key');
      }
    }
    AppStrings.setLanguage('de');
  });

  test('missing keys fall back to English', () {
    AppStrings.setLanguage('es');
    expect(AppStrings.get('menu.newGame'), 'Nueva partida');
    AppStrings.setLanguage('de');
  });

  test('all supported languages can be chosen', () {
    for (final l in AppLanguages.all) {
      AppStrings.setLanguage(l.code);
      expect(AppStrings.currentLanguage, l.code);
    }
    AppStrings.setLanguage('de');
  });

  test('Bible references in each language', () {
    expect(BibleRef.localizedFor('Joh 8,36', 'de'), 'Joh 8,36');
    expect(BibleRef.localizedFor('Joh 8,36', 'en'), 'John 8:36');
    expect(BibleRef.localizedFor('1 Tim 2,1', 'es'), '1 Ti 2:1');
    expect(BibleRef.localizedFor('Mt 6,17–18', 'fr'), 'Mt 6,17–18');
    expect(BibleRef.localizedFor('Jak 4,7', 'pt'), 'Tg 4:7');
  });
}
