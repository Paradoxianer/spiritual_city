import 'package:flutter/foundation.dart';

import 'app_language.dart';

/// An explanation waiting for the player's decision.
class PendingExplanation {
  final String key;
  final String emoji;
  final String title;
  final String text;
  final VoidCallback run;
  const PendingExplanation(this.key, this.emoji, this.title, this.text, this.run);
}

/// The explanation box (playtest 2026-10-31): with texts on, the first tap
/// on an action explains what it will do – the player then does it (▶),
/// does it and mutes the explanation for that action (🔕), or cancels.
abstract final class Explanations {
  /// Explanations the player has muted (keys like 'action.talk'), saved in
  /// the app settings.
  static final Set<String> muted = {};

  static final ValueNotifier<PendingExplanation?> pending = ValueNotifier(null);

  /// Saves [muted] (set by the menu service).
  static void Function()? persist;

  /// Runs [run] right away, or first explains it with [text].
  static void gate(String key, String emoji, String? title, String? text, VoidCallback run) {
    if (!TextMode.on || text == null || muted.contains(key)) {
      run();
      return;
    }
    pending.value = PendingExplanation(key, emoji, title ?? '', text, run);
  }

  /// ▶ do it (and with [mute] never explain this action again).
  static void confirm({bool mute = false}) {
    final p = pending.value;
    if (p == null) return;
    pending.value = null;
    if (mute) {
      muted.add(p.key);
      persist?.call();
    }
    p.run();
  }

  static void cancel() => pending.value = null;

  /// Settings: show all explanations again.
  static void resetMuted() {
    muted.clear();
    persist?.call();
  }
}
