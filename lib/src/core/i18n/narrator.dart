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
/// when the pastor comes near it or taps it, and fades out after a while.
/// ✕ closes just this bubble (e.g. to chat on quickly); swiping it down
/// turns the narrator off for good – a small handle stays, and swiping it
/// up (or tapping it) turns the narrator on again. The same switch as
/// "narrator" in the settings ([TextMode]).
abstract final class Narrator {
  static final ValueNotifier<NarratorLine?> current = ValueNotifier(null);

  /// Saves the on/off state (set by the menu service).
  static void Function()? persist;

  /// Explains [key] with [text] while the narrator is on. A new line
  /// replaces the one shown. [passing] lines (the pastor just walked past
  /// something) never interrupt a bubble and come at most every
  /// [passingGap] – walking along a street must not restart the
  /// typewriter again and again (playtest 2026-10-31).
  static void say(String key, String emoji, String title, String? text,
      {bool force = false, bool passing = false}) {
    if (!TextMode.on || text == null || text.isEmpty) return;
    if (current.value?.key == key && current.value?.text == text) return;
    if (passing) {
      if (current.value != null) return;
      final now = DateTime.now();
      if (now.difference(_lastPassing) < passingGap) return;
      _lastPassing = now;
    }
    current.value = NarratorLine(key, emoji, title, text);
  }

  static const Duration passingGap = Duration(seconds: 8);
  static DateTime _lastPassing = DateTime.fromMillisecondsSinceEpoch(0);

  /// Read: fades out.
  static void hide(String key) {
    if (current.value?.key == key) current.value = null;
  }

  /// ✕: close this bubble – the narrator stays on.
  static void close() => current.value = null;

  /// Swiped down: the narrator is off (a handle stays to bring it back).
  static void turnOff() {
    current.value = null;
    TextMode.enabled.value = false;
    persist?.call();
  }

  /// Handle swiped up / tapped: the narrator is on again.
  static void turnOn() {
    TextMode.enabled.value = true;
    persist?.call();
  }
}
