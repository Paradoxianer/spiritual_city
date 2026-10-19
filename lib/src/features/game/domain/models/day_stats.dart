/// The day as the session unit (release_roadmap.md §3.3, decision 2026-10-17):
/// sleeping in the pastor house ends the day and shows what happened.
/// No real-time pressure – a day lasts as long as the player wants.
class DayStats {
  /// Day number, starting at 1. Every 7th day is Sunday.
  int day = 1;

  int conversions = 0;
  int storiesHealed = 0;
  int daemonsDefeated = 0;
  int awakenings = 0;
  int missionsCompleted = 0;
  int lessonsLearned = 0;

  bool get isSunday => day % 7 == 0;

  /// Faith factor of a Sunday service on Sundays ("Sonntag = Gottesdienst-Tag").
  static const double sundayServiceBonus = 1.5;

  bool get isEmpty =>
      conversions + storiesHealed + daemonsDefeated + awakenings + missionsCompleted + lessonsLearned ==
      0;

  /// Emoji rows for the day summary: (emoji, count), only non-zero ones.
  List<(String, int)> get rows => [
        if (conversions > 0) ('✝️', conversions),
        if (storiesHealed > 0) ('🌱', storiesHealed),
        if (daemonsDefeated > 0) ('👹', daemonsDefeated),
        if (awakenings > 0) ('🔥🏘️', awakenings),
        if (missionsCompleted > 0) ('📋', missionsCompleted),
        if (lessonsLearned > 0) ('🎓', lessonsLearned),
      ];

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
