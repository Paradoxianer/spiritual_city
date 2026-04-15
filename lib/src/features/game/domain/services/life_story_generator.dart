import 'dart:math';

/// Generates a randomised life-story for an NPC as a list of emoji segments,
/// with a parallel list of single-emoji stage icons and integer tone values.
///
/// Every emoji in every stage pool is registered in [emojiValence] with a
/// fixed valence (+1 positive / 0 neutral / -1 negative).  When a segment of
/// three emoji is assembled its tone is determined by majority vote: a sum >= 2
/// is positive, <= -2 is negative, anything else is neutral.  This replaces the
/// old "three separate pools per stage" approach with a single combined pool
/// and a shared valence map.
class LifeStoryGenerator {
  final Random _random;

  LifeStoryGenerator(this._random);

  // Stage icons
  static const String _iconChildhood = '👶';
  static const String _iconSchool    = '🏫';
  static const String _iconFamily    = '👪';
  static const String _iconEducation = '🎓';
  static const String _iconWork      = '💼';
  static const String _iconMarriage  = '💑';
  static const String _iconFaith     = '⛪';

  // ── Emoji valence map ─────────────────────────────────────────────────────
  /// Global valence of every emoji that can appear in a life-story segment.
  /// +1 = positive, 0 = neutral, -1 = negative.
  static const Map<String, int> emojiValence = {
    // Positive (+1)
    '🏡': 1, '��': 1, '🌈': 1, '🎠': 1, '🧸': 1, '🌻': 1, '🎈': 1, '🍭': 1, '🤸': 1,
    '🎖️': 1, '🏆': 1, '🌟': 1, '🥇': 1, '🎯': 1, '🙌': 1,
    '🫂': 1, '🎉': 1, '🤗': 1, '💕': 1, '🌷': 1, '🎂': 1, '🥰': 1,
    '📜': 1, '🏅': 1, '🚀': 1, '💡': 1, '📈': 1, '🤝': 1, '��': 1,
    '💍': 1, '🌹': 1, '🎊': 1, '🥂': 1, '🌸': 1, '🤍': 1,
    '🙏': 1, '🌄': 1, '🕊️': 1, '✝️': 1, '💒': 1, '🌅': 1,
    // Neutral (0)
    '😐': 0, '🏠': 0, '🧺': 0, '🌥️': 0, '🚌': 0, '🎒': 0, '🧩': 0, '🕰️': 0,
    '📚': 0, '📝': 0, '✏️': 0, '📖': 0, '🕐': 0, '😑': 0, '📋': 0, '🖊️': 0,
    '💭': 0, '🍽️': 0, '🛋️': 0, '📺': 0, '😶': 0,
    '📊': 0, '🏛️': 0, '🎓': 0,
    '🖥️': 0, '⏱️': 0, '🏢': 0, '📁': 0, '🔧': 0,
    '🤔': 0, '📅': 0, '🌙': 0,
    '❓': 0, '🕯️': 0, '🌿': 0,
    // Negative (-1)
    '😢': -1, '🌧️': -1, '😰': -1, '💔': -1, '😨': -1, '🌑': -1, '😣': -1, '🚫': -1,
    '😔': -1, '😞': -1, '😤': -1, '❌': -1, '😩': -1, '📉': -1, '😠': -1,
    '🚪': -1, '💸': -1, '🔥': -1, '⚡': -1, '😒': -1, '💨': -1,
  };

  // ── Combined stage pools ──────────────────────────────────────────────────
  // Each pool lists all emoji for that life stage in three thematic groups
  // (positive / neutral / negative).  The groups are informational only; the
  // actual valence of each emoji is determined by [emojiValence].
  static const _childhoodPool = [
    '🏡', '😊', '🌈', '🎠', '🧸', '🌻', '🎈', '🍭', '🤸', // positive
    '��', '🏠', '🧺', '🌥️', '🚌', '🎒', '🧩', '🕰️',        // neutral
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
    '😞', '🔥', '💸', '😩', '📉', '😤', '❌', '⚡',          // negative
  ];

  static const _marriagePool = [
    '😊', '💍', '💕', '🌹', '🎊', '🥂', '🏡', '🌸', '🤍',  // positive
    '😐', '🏠', '🍽️', '🛋️', '💭', '🤔', '📅', '🌙',         // neutral
    '💔', '😢', '😤', '🚪', '😔', '❌', '🌧️', '😰',         // negative
  ];

  static const _faithPool = [
    '🙏', '🌄', '📖', '🕊️', '✝️', '💒', '🌟', '🙌', '🌅',  // positive
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
