import 'package:flutter/painting.dart';

/// Laid-out single-line texts (mostly emoji) for Flame `render` methods.
///
/// Laying out a [TextPainter] every frame – for every pickup, HUD button and
/// fortress label – cost a lot after a while (playtest 2026-11-12: the game
/// stuttered). The recently used ones are kept; the oldest are freed.
abstract final class TextCache {
  static const int _max = 400;
  static final Map<(String, TextStyle), TextPainter> _painters = {};

  static TextPainter get(String text, TextStyle style) {
    final key = (text, style);
    var tp = _painters.remove(key);
    if (tp == null) {
      tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      if (_painters.length >= _max) {
        final oldest = _painters.keys.first;
        _painters.remove(oldest)!.dispose();
      }
    }
    _painters[key] = tp; // most recent last
    return tp;
  }
}
