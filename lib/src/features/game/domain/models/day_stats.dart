/// Internal day counter (release_roadmap.md §3.3): sleeping in the pastor
/// house starts the next day. Not shown in the UI since the playtest of
/// 2026-10-18 (visible days and a day summary were too much) – it only paces
/// once-per-sleep actions. No real-time pressure.
class DayStats {
  /// Day number, starting at 1.
  int day = 1;

  int conversions = 0;
  int storiesHealed = 0;
  int daemonsDefeated = 0;
  int awakenings = 0;
  int missionsCompleted = 0;
  int lessonsLearned = 0;

  bool get isEmpty =>
      conversions + storiesHealed + daemonsDefeated + awakenings + missionsCompleted + lessonsLearned ==
      0;

  /// Starts the next day with empty counters.
  void nextDay() {
    day++;
    conversions = 0;
    storiesHealed = 0;
    daemonsDefeated = 0;
    awakenings = 0;
    missionsCompleted = 0;
    lessonsLearned = 0;
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'conv': conversions,
        'healed': storiesHealed,
        'daemons': daemonsDefeated,
        'awake': awakenings,
        'missions': missionsCompleted,
        'lessons': lessonsLearned,
      };

  void loadFromJson(Object? raw) {
    if (raw is! Map) return;
    int v(String k) => (raw[k] as num?)?.toInt() ?? 0;
    day = v('day').clamp(1, 1 << 30);
    conversions = v('conv');
    storiesHealed = v('healed');
    daemonsDefeated = v('daemons');
    awakenings = v('awake');
    missionsCompleted = v('missions');
    lessonsLearned = v('lessons');
  }
}
