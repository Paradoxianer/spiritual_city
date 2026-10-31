import 'package:flutter/foundation.dart';

import 'app_language.dart';

/// One thing the narrator explains.
class NarratorLine {
  final String key;
  final String emoji;
  final String title;
  final String text;
  const NarratorLine(this.key, this.emoji, this.title, this.text);
}

/// The narrator (playtests 2026-10-31): the only text in the game screen –
/// a speech bubble at the bottom that types out what something is or does
/// when the pastor comes near it or taps it. It fades out by itself after
/// a while and comes again next time – until the player swipes it down by
/// its handle; then that explanation never comes again. Off with the
/// "narrator" switch in the settings (TextMode).
abstract final class Narrator {
  /// Explanations the player closed (keys like 'action.talk'), saved in
  /// the app settings.
  static final Set<String> muted = {};

  static final ValueNotifier<NarratorLine?> current = ValueNotifier(null);

  /// Saves [muted] (set by the menu service).
  static void Function()? persist;

  /// Explains [key] with [text] – unless the narrator is off, [text] is
  /// missing, or the player closed this explanation before. A new line
  /// replaces the one shown.
  static void say(String key, String emoji, String title, String? text) {
    if (!TextMode.on || text == null || text.isEmpty || muted.contains(key)) return;
    if (current.value?.key == key) return;
    current.value = NarratorLine(key, emoji, title, text);
  }

  /// Read: fades out, but comes again next time.
  static void hide(String key) {
    if (current.value?.key == key) current.value = null;
  }

  /// Swiped down: this explanation does not come again.
  static void dismiss() {
    final line = current.value;
    if (line == null) return;
    current.value = null;
    muted.add(line.key);
    persist?.call();
  }

  /// Settings: all explanations come again.
  static void resetMuted() {
    muted.clear();
    persist?.call();
  }
}
