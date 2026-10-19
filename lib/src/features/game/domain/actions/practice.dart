/// Spiritual disciplines the pastor gets better at by doing them
/// ("Übung", docs/game_design/release_roadmap.md §3.4).
enum Discipline {
  prayer('🙏'),
  bible('📖'),
  conversation('💬'),
  counsel('👂'),
  service('🤝'),
  worship('🤲');

  final String emoji;
  const Discipline(this.emoji);
}

/// Counts how often each [Discipline] was practised and turns that into a
/// permanent effectiveness bonus: +10 % per level, at most +50 %.
///
/// Diminishing returns *within* a session (#171) stay untouched – practice
/// makes an action stronger overall, variety inside a conversation still pays.
class Practice {
  /// Uses needed for level 1…5.
  static const List<int> thresholds = [10, 30, 80, 200, 400];
  static const double bonusPerLevel = 0.10;

  final Map<Discipline, int> _counts = {};

  int count(Discipline d) => _counts[d] ?? 0;

  int level(Discipline d) {
    final c = count(d);
    var lvl = 0;
    for (final t in thresholds) {
      if (c < t) break;
      lvl++;
    }
    return lvl;
  }

  int get maxLevel => thresholds.length;

  /// Gain multiplier for [d] (1.0 … 1.5); 1.0 for actions without a discipline.
  double multiplier(Discipline? d) =>
      d == null ? 1.0 : 1.0 + level(d) * bonusPerLevel;

  /// Records one use; returns `true` when this use reached a new level.
  bool record(Discipline d) {
    final before = level(d);
    _counts[d] = count(d) + 1;
    return level(d) > before;
  }

  Map<String, int> toJson() => {
        for (final e in _counts.entries) e.key.name: e.value,
      };

  void loadFromJson(Map<String, dynamic> json) {
    _counts.clear();
    for (final d in Discipline.values) {
      final v = json[d.name];
      if (v is num) _counts[d] = v.toInt();
    }
  }
}

/// Relationship ("Beziehung", §3.4): the better the pastor knows a person,
/// the more every action with them achieves.
///
/// The level is the entity's existing session bonus (the same thresholds that
/// already grant extra session points), capped at [maxLevel].
abstract final class Relationship {
  static const int maxLevel = 5;
  static const double bonusPerLevel = 0.10;

  static int level(int sessionBonus) => sessionBonus.clamp(0, maxLevel);

  static double multiplier(int sessionBonus) =>
      1.0 + level(sessionBonus) * bonusPerLevel;

  /// From this level on a life-talk step counts double – trust makes it
  /// easier to talk about the hard things.
  static const int deepTrustLevel = 3;
}
