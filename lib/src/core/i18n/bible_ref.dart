import 'app_strings.dart';

/// Bible references are written the German way in the data ("Joh 8,36",
/// "1 Tim 2,1"); shown in the current language's abbreviations, with
/// "chapter:verse" where that is usual.
abstract final class BibleRef {
  static const Map<String, Map<String, String>> _books = {
    'en': {'Joh': 'John', 'Tim': 'Tim', 'Kor': 'Cor', 'Eph': 'Eph', 'Jak': 'Jas', 'Kol': 'Col', 'Lk': 'Luke', 'Mk': 'Mark', 'Mt': 'Matt', 'Röm': 'Rom', 'Apg': 'Acts', 'Ps': 'Ps'},
    'es': {'Joh': 'Jn', 'Tim': 'Ti', 'Kor': 'Co', 'Eph': 'Ef', 'Jak': 'Stg', 'Kol': 'Col', 'Lk': 'Lc', 'Mk': 'Mr', 'Mt': 'Mt', 'Röm': 'Ro', 'Apg': 'Hch', 'Ps': 'Sal'},
    'fr': {'Joh': 'Jn', 'Tim': 'Tm', 'Kor': 'Co', 'Eph': 'Ep', 'Jak': 'Jc', 'Kol': 'Col', 'Lk': 'Lc', 'Mk': 'Mc', 'Mt': 'Mt', 'Röm': 'Rm', 'Apg': 'Ac', 'Ps': 'Ps'},
    'pt': {'Joh': 'Jo', 'Tim': 'Tm', 'Kor': 'Co', 'Eph': 'Ef', 'Jak': 'Tg', 'Kol': 'Cl', 'Lk': 'Lc', 'Mk': 'Mc', 'Mt': 'Mt', 'Röm': 'Rm', 'Apg': 'At', 'Ps': 'Sl'},
  };

  /// [ref] ("Joh 8,36") in the current language.
  static String localized(String ref) => localizedFor(ref, AppStrings.currentLanguage);

  static String localizedFor(String ref, String lang) {
    final books = _books[lang];
    if (books == null) return ref; // German
    var out = ref;
    for (final e in books.entries) {
      out = out.replaceAllMapped(RegExp('(^|\\s)${e.key}(?=\\s)'), (m) => '${m[1]}${e.value}');
    }
    // French keeps "8,36"; the others write "8:36".
    return lang == 'fr' ? out : out.replaceAll(',', ':');
  }
}
