import 'package:flutter/foundation.dart';
import 'app_strings.dart';

/// Notifies listeners when the app language changes.
///
/// Use [LanguageNotifier.setLanguage] to switch between 'de' and 'en'.
/// The selected language is reflected in [AppStrings] globally.
class LanguageNotifier extends ValueNotifier<String> {
  LanguageNotifier(super.initialLanguage);

  void setLanguage(String lang) {
    AppStrings.setLanguage(lang);
    value = lang;
  }
}
