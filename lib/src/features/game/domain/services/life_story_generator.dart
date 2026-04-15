import 'dart:math';

/// Generates a randomised life-story for an NPC as a list of emoji segments,
/// with a parallel list of single-emoji stage icons (pure emoji, no text).
///
/// Each stage has three tone pools (positive / neutral / negative), each
/// containing 8 or more emoji.  A segment is assembled by picking 2 emoji at
/// random from the chosen tone's pool, so the number of unique combinations
/// per stage is far greater than the old 3-variant approach.
class LifeStoryGenerator {
  final Random _random;

  LifeStoryGenerator(this._random);

  // ── Stage icon (shown as the header of each tile in the sidebar) ──────────
  static const String _iconChildhood  = '👶';
  static const String _iconSchool     = '🏫';
  static const String _iconFamily     = '👪';
  static const String _iconEducation  = '🎓';
  static const String _iconWork       = '💼';
  static const String _iconMarriage   = '💑';
  static const String _iconFaith      = '⛪';

  // ── Emoji pools ───────────────────────────────────────────────────────────
  // Childhood
  static const _childhoodPos = ['🏡', '😊', '🌈', '🎠', '🧸', '🌻', '🎈', '🍭', '🤸'];
  static const _childhoodNeu = ['😐', '🏠', '📦', '🌥️', '🚌', '🎒', '🧩', '🕰️'];
  static const _childhoodNeg = ['😢', '🌧️', '😰', '💔', '😨', '🌑', '😣', '🚫'];

  // School
  static const _schoolPos = ['📚', '⭐', '🏆', '✏️', '📝', '🌟', '🥇', '🎯', '🙌'];
  static const _schoolNeu = ['📚', '📝', '✏️', '📖', '🕐', '😑', '📋', '🖊️'];
  static const _schoolNeg = ['😔', '😞', '🚫', '😤', '❌', '😩', '📉', '😠'];

  // Family
  static const _familyPos = ['😊', '❤️', '🏡', '🎉', '🤗', '💕', '🌷', '🎂', '🥰'];
  static const _familyNeu = ['😐', '💭', '🏠', '🍽️', '🛋️', '🕰️', '📺', '😶'];
  static const _familyNeg = ['💔', '😢', '😤', '🚪', '😔', '❌', '😠', '🌧️'];

  // Education / University
  static const _educationPos = ['✨', '📜', '🌟', '🥇', '📖', '🎯', '🏅', '🚀', '💡'];
  static const _educationNeu = ['📖', '🕐', '📝', '🖊️', '📊', '📋', '😐', '🏛️'];
  static const _educationNeg = ['😔', '❌', '😞', '📉', '🚫', '😩', '💸', '😤'];

  // Work / Career
  static const _workPos = ['😊', '🏆', '🌟', '💰', '📈', '🎯', '🤝', '⭐', '🚀'];
  static const _workNeu = ['😐', '📋', '🖥️', '⏱️', '📊', '🏢', '📁', '🔧'];
  static const _workNeg = ['😞', '🔥', '💸', '😩', '📉', '😤', '❌', '⚡'];

  // Marriage / Love
  static const _marriagePos = ['😊', '💍', '💕', '🌹', '🎊', '🥂', '🏡', '🌸', '🤍'];
  static const _marriageNeu = ['😐', '🏠', '🍽️', '🛋️', '💭', '🤔', '📅', '🌙'];
  static const _marriageNeg = ['💔', '😢', '😤', '🚪', '😔', '❌', '🌧️', '😰'];

  // Faith
  static const _faithPos = ['🙏', '✨', '📖', '🕊️', '✝️', '💒', '🌟', '🙌', '🌅'];
  static const _faithNeu = ['🤔', '💭', '❓', '🕯️', '📖', '😐', '🌅', '🌿'];
  static const _faithNeg = ['😤', '🚫', '❌', '😒', '💨', '🌑', '😔', '⚡'];

  // ── Segment assembly ──────────────────────────────────────────────────────

  /// Picks 2 unique emoji at random from [pool] and concatenates them.
  String _buildSegment(List<String> pool) {
    final copy = List<String>.of(pool)..shuffle(_random);
    return copy.take(2).join();
  }

  /// Chooses a tone (35 % positive / 30 % neutral / 35 % negative) and
  /// assembles a segment from the matching pool.
  String _pickSegment(
    List<String> pos,
    List<String> neu,
    List<String> neg,
  ) {
    final roll = _random.nextDouble();
    if (roll < 0.35) return _buildSegment(pos);
    if (roll < 0.65) return _buildSegment(neu);
    return _buildSegment(neg);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Builds the life-story for an NPC of the given [age].
  ///
  /// Returns a record with:
  /// - `segments`: the emoji content for each stage (2 emoji each)
  /// - `icons`: the single stage-identifier emoji parallel to [segments]
  ({List<String> segments, List<String> icons}) build(int age) {
    final segments = <String>[];
    final icons    = <String>[];

    void add(String segment, String icon) {
      segments.add(segment);
      icons.add(icon);
    }

    // Everyone has a childhood
    add(_pickSegment(_childhoodPos, _childhoodNeu, _childhoodNeg), _iconChildhood);

    if (age >= 14) {
      add(_pickSegment(_schoolPos, _schoolNeu, _schoolNeg), _iconSchool);
    }
    if (age >= 18) {
      add(_pickSegment(_familyPos, _familyNeu, _familyNeg), _iconFamily);
    }
    if (age >= 22) {
      add(_pickSegment(_educationPos, _educationNeu, _educationNeg), _iconEducation);
    }
    if (age >= 25) {
      add(_pickSegment(_workPos, _workNeu, _workNeg), _iconWork);
    }
    // ~60 % of adults have a marriage/love chapter
    if (age >= 20 && _random.nextDouble() < 0.6) {
      add(_pickSegment(_marriagePos, _marriageNeu, _marriageNeg), _iconMarriage);
    }
    // Faith background for older NPCs
    if (age >= 30) {
      add(_pickSegment(_faithPos, _faithNeu, _faithNeg), _iconFaith);
    }

    return (segments: segments, icons: icons);
  }
}
