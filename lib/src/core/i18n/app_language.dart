import 'package:flutter/foundation.dart';
import 'app_strings.dart';

/// A language the game is translated into.
class AppLanguage {
  final String code;
  final String flag;
  final String name;
  const AppLanguage(this.code, this.flag, this.name);
}

/// The supported languages (playtest 2026-10-31: the most important ones;
/// more can be added by a strings map and the Tr fields). Missing
/// translations fall back to English.
abstract final class AppLanguages {
  static const List<AppLanguage> all = [
    AppLanguage('de', '🇩🇪', 'Deutsch'),
    AppLanguage('en', '🇬🇧', 'English'),
    AppLanguage('es', '🇪🇸', 'Español'),
    AppLanguage('fr', '🇫🇷', 'Français'),
    AppLanguage('pt', '🇧🇷', 'Português'),
  ];

  static bool isSupported(String code) => all.any((l) => l.code == code);

  /// The device's language if the game speaks it, else English.
  static String fromDevice() {
    try {
      final code = PlatformDispatcher.instance.locale.languageCode;
      return isSupported(code) ? code : 'en';
    } catch (_) {
      return 'en';
    }
  }
}

/// Notifies listeners when the app language changes.
///
/// Use [LanguageNotifier.setLanguage] to switch languages; the selected
/// language is reflected in [AppStrings] globally.
class LanguageNotifier extends ValueNotifier<String> {
  LanguageNotifier(super.initialLanguage);

  void setLanguage(String lang) {
    AppStrings.setLanguage(lang);
    value = AppStrings.currentLanguage;
  }
}

/// Texts besides the emoji (playtest 2026-10-31: emoji alone were hard to
/// follow): captions under buttons, explanations on long press, subtitles
/// under messages. On by default; the emoji-only game stays one switch
/// away (settings), e.g. for children who cannot read yet.
abstract final class TextMode {
  static final ValueNotifier<bool> enabled = ValueNotifier(true);
  static bool get on => enabled.value;
}
