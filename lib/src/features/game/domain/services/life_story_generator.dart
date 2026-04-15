import 'dart:math';

/// Generates a randomised life-story for an NPC as a list of emoji segments,
/// with a parallel list of single-emoji stage icons and integer tone values.
///
/// Every emoji in every stage pool is registered in [emojiValence] with a
/// fixed valence (+1 positive / 0 neutral / -1 negative).  When a segment of
/// three emoji is assembled its tone is determined by majority vote: a sum >= 2
/// is positive, <= -2 is negative, anything else is neutral.
class LifeStoryGenerator {
  final Random _random;

  LifeStoryGenerator(this._random);

  // ── Stage icons ───────────────────────────────────────────────────────────
  static const String _iconChildhood = '\u{1F476}'; // 👶
  static const String _iconSchool    = '\u{1F3EB}'; // 🏫
  static const String _iconFamily    = '\u{1F46A}'; // 👪
  static const String _iconEducation = '\u{1F393}'; // 🎓
  static const String _iconWork      = '\u{1F4BC}'; // 💼
  static const String _iconMarriage  = '\u{1F491}'; // 💑
  static const String _iconFaith     = '\u{26EA}';  // ⛪

  // ── Emoji valence map ─────────────────────────────────────────────────────
  /// Global valence of every emoji that can appear in a life-story segment.
  /// +1 = positive, 0 = neutral, -1 = negative.
  static const Map<String, int> emojiValence = {
    // ── Positive (+1) ────────────────────────────────────────────────────────
    '\u{1F3E1}': 1, // 🏡
    '\u{1F60A}': 1, // 😊
    '\u{1F308}': 1, // 🌈
    '\u{1F3A0}': 1, // 🎠
    '\u{1F9F8}': 1, // 🧸
    '\u{1F33B}': 1, // 🌻
    '\u{1F388}': 1, // 🎈
    '\u{1F36D}': 1, // 🍭
    '\u{1F938}': 1, // 🤸
    '\u{1F396}\uFE0F': 1, // 🎖️
    '\u{1F3C6}': 1, // 🏆
    '\u{1F31F}': 1, // 🌟
    '\u{1F947}': 1, // 🥇
    '\u{1F3AF}': 1, // 🎯
    '\u{1F64C}': 1, // 🙌
    '\u{1FAC2}': 1, // 🫂
    '\u{1F389}': 1, // 🎉
    '\u{1F917}': 1, // 🤗
    '\u{1F495}': 1, // 💕
    '\u{1F337}': 1, // 🌷
    '\u{1F382}': 1, // 🎂
    '\u{1F970}': 1, // 🥰
    '\u{1F4DC}': 1, // 📜
    '\u{1F3C5}': 1, // 🏅
    '\u{1F680}': 1, // 🚀
    '\u{1F4A1}': 1, // 💡
    '\u{1F4C8}': 1, // 📈
    '\u{1F91D}': 1, // 🤝
    '\u{1F4B5}': 1, // 💵
    '\u{1F48D}': 1, // 💍
    '\u{1F339}': 1, // 🌹
    '\u{1F38A}': 1, // 🎊
    '\u{1F942}': 1, // 🥂
    '\u{1F338}': 1, // 🌸
    '\u{1F90D}': 1, // 🤍
    '\u{1F64F}': 1, // 🙏
    '\u{1F304}': 1, // 🌄
    '\u{1F54A}\uFE0F': 1, // 🕊️
    '\u2705': 1,    // ✅  (replacing ✝️ to avoid stat-emoji conflict)
    '\u{1F492}': 1, // 💒
    '\u{1F305}': 1, // 🌅
    // ── Neutral (0) ──────────────────────────────────────────────────────────
    '\u{1F610}': 0, // 😐
    '\u{1F3E0}': 0, // 🏠
    '\u{1F9FA}': 0, // 🧺
    '\u{1F325}\uFE0F': 0, // 🌥️
    '\u{1F68C}': 0, // 🚌
    '\u{1F392}': 0, // 🎒
    '\u{1F9E9}': 0, // 🧩
    '\u{1F570}\uFE0F': 0, // 🕰️
    '\u{1F4DA}': 0, // 📚
    '\u{1F4DD}': 0, // 📝
    '\u270F\uFE0F': 0, // ✏️
    '\u{1F4D6}': 0, // 📖
    '\u{1F550}': 0, // 🕐
    '\u{1F611}': 0, // 😑
    '\u{1F4CB}': 0, // 📋
    '\u{1F58A}\uFE0F': 0, // 🖊️
    '\u{1F4AD}': 0, // 💭
    '\u{1F37D}\uFE0F': 0, // 🍽️
    '\u{1F6CB}\uFE0F': 0, // 🛋️
    '\u{1F4FA}': 0, // 📺
    '\u{1F636}': 0, // 😶
    '\u{1F4CA}': 0, // 📊
    '\u{1F3DB}\uFE0F': 0, // 🏛️
    '\u{1F393}': 0, // 🎓
    '\u{1F5A5}\uFE0F': 0, // 🖥️
    '\u23F1\uFE0F': 0,    // ⏱️
    '\u{1F3E2}': 0, // 🏢
    '\u{1F4C1}': 0, // 📁
    '\u{1F527}': 0, // 🔧
    '\u{1F914}': 0, // 🤔
    '\u{1F4C5}': 0, // 📅
    '\u{1F319}': 0, // 🌙
    '\u2753': 0,    // ❓
    '\u{1F56F}\uFE0F': 0, // 🕯️
    '\u{1F33F}': 0, // 🌿
    // ── Negative (-1) ────────────────────────────────────────────────────────
    '\u{1F622}': -1, // 😢
    '\u{1F327}\uFE0F': -1, // 🌧️
    '\u{1F630}': -1, // 😰
    '\u{1F494}': -1, // 💔
    '\u{1F628}': -1, // 😨
    '\u{1F311}': -1, // 🌑
    '\u{1F623}': -1, // 😣
    '\u{1F6AB}': -1, // 🚫
    '\u{1F614}': -1, // 😔
    '\u{1F61E}': -1, // 😞
    '\u{1F624}': -1, // 😤
    '\u274C': -1,    // ❌
    '\u{1F629}': -1, // 😩
    '\u{1F4C9}': -1, // 📉
    '\u{1F620}': -1, // 😠
    '\u{1F6AA}': -1, // 🚪
    '\u{1F4B8}': -1, // 💸
    '\u{1F525}': -1, // 🔥
    '\u26A1': -1,    // ⚡
    '\u{1F612}': -1, // 😒
    '\u{1F4A8}': -1, // 💨
  };

  // ── Combined stage pools ──────────────────────────────────────────────────
  // Emoji literal strings are used here for readability.
  // The actual valence is always looked up from [emojiValence].
  static const _childhoodPool = [
    '🏡', '😊', '🌈', '🎠', '🧸', '🌻', '🎈', '🍭', '🤸', // positive
    '😐', '🏠', '🧺', '🌥️', '🚌', '🎒', '🧩', '🕰️',        // neutral
    '😢', '🌧️', '😰', '💔', '😨', '🌑', '😣', '🚫',         // negative
  ];

  static const _schoolPool = [
    '🎖️', '🏆', '🌟', '🥇', '🎯', '🙌',                     // positive
    '📚', '📝', '✏️', '📖', '🕐', '😑', '📋', '🖊️',          // neutral
    '😔', '😞', '🚫', '😤', '❌', '😩', '📉', '😠',          // negative
  ];

  static const _familyPool = [
    '😊', '🫂', '🏡', '🎉', '🤗', '💕', '🌷', '🎂', '🥰',  // positive
    '😐', '💭', '🏠', '🍽️', '🛋️', '🕰️', '📺', '😶',        // neutral
    '💔', '😢', '😤', '🚪', '😔', '❌', '😠', '🌧️',         // negative
  ];

  static const _educationPool = [
    '📜', '🌟', '🥇', '🏅', '🚀', '💡', '🎯',               // positive
    '📖', '🕐', '📝', '🖊️', '📊', '📋', '😐', '🏛️', '🎓',  // neutral
    '😔', '❌', '😞', '📉', '🚫', '😩', '💸', '😤',         // negative
  ];

  static const _workPool = [
    '😊', '🏆', '🌟', '💵', '📈', '🎯', '🤝', '🏅', '🚀',  // positive
    '😐', '📋', '🖥️', '⏱️', '📊', '🏢', '📁', '🔧',         // neutral
    '😞', '🔥', '��', '😩', '📉', '😤', '❌', '⚡',          // negative
  ];

  static const _marriagePool = [
    '😊', '💍', '💕', '🌹', '🎊', '��', '🏡', '🌸', '🤍',  // positive
    '😐', '🏠', '🍽️', '🛋️', '💭', '🤔', '📅', '🌙',         // neutral
    '💔', '😢', '😤', '🚪', '😔', '❌', '🌧️', '😰',         // negative
  ];

  static const _faithPool = [
    '🙏', '🌄', '📖', '🕊️', '✅', '💒', '🌟', '🙌', '🌅',  // positive
    '🤔', '💭', '❓', '🕯️', '😐', '🌿',                       // neutral
    '😤', '🚫', '❌', '😒', '💨', '🌑', '😔', '⚡',          // negative
  ];

  // ── Segment assembly ──────────────────────────────────────────────────────

  /// Picks 3 unique emoji at random from [pool], concatenates them, and
  /// computes the segment's valence tone by majority vote via [emojiValence].
  ///
  /// Tone rules (sum of the three individual valences):
  /// * sum >= +2  ->  +1 (positive segment)
  /// * sum <= -2  ->  -1 (negative segment)
  /// * otherwise  ->   0 (neutral / mixed segment)
  ({String segment, int tone}) _buildSegment(List<String> pool) {
    final copy = List<String>.of(pool)..shuffle(_random);
    final picked = copy.take(3).toList();
    final sum = picked.fold(0, (acc, e) => acc + (emojiValence[e] ?? 0));
    return (
      segment: picked.join(),
      tone: sum >= 2 ? 1 : (sum <= -2 ? -1 : 0),
    );
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Builds the life-story for an NPC of the given [age].
  ///
  /// Returns a record with:
  /// - `segments` – the 3-emoji content for each stage
  /// - `icons`    – single stage-identifier emoji parallel to [segments]
  /// - `tones`    – valence tone (+1/0/-1) for each segment, parallel to [segments]
  ({List<String> segments, List<String> icons, List<int> tones}) build(int age) {
    final segments = <String>[];
    final icons    = <String>[];
    final tones    = <int>[];

    void add(List<String> pool, String icon) {
      final r = _buildSegment(pool);
      segments.add(r.segment);
      icons.add(icon);
      tones.add(r.tone);
    }

    add(_childhoodPool, _iconChildhood);
    if (age >= 14) add(_schoolPool, _iconSchool);
    if (age >= 18) add(_familyPool, _iconFamily);
    if (age >= 22) add(_educationPool, _iconEducation);
    if (age >= 25) add(_workPool, _iconWork);
    // ~60 % of adults have a marriage/love chapter
    if (age >= 20 && _random.nextDouble() < 0.6) add(_marriagePool, _iconMarriage);
    // Faith background for older NPCs
    if (age >= 30) add(_faithPool, _iconFaith);

    return (segments: segments, icons: icons, tones: tones);
  }
}
