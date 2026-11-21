import '../../../menu/domain/models/city_size.dart';

/// 🌉 Over the bridge into the next, bigger city once this one is won
/// (playtest 2026-11-21, core_loop_and_retention.md §3): the pastor comes
/// along – levels, skills, prayer upgrades, wisdom – the city stays behind.
abstract final class CityCrossing {
  /// The city after [size]; the big city is followed by another big city.
  static CitySize next(CitySize size) => switch (size) {
        CitySize.village => CitySize.smallTown,
        CitySize.smallTown => CitySize.town,
        CitySize.town || CitySize.metropolis => CitySize.metropolis,
      };

  /// What belongs to the city, not to the pastor: its neighbourhoods, the
  /// church and its people, the day count and the grace after an upgrade.
  static const Set<String> stays = {
    'awakened',
    'celebrated',
    'christianQuarters',
    'cityPrayedFree',
    'church',
    'day',
    'graceVisitsLeft',
  };

  /// The pastor's part of a saved `PlayerProgress` json.
  static Map<String, dynamic> carry(Map<String, dynamic> progress) => {
        for (final e in progress.entries)
          if (!stays.contains(e.key)) e.key: e.value,
      };

  /// The opening game state of the next city: only the pastor, at the new
  /// city's start, the tutorial behind them.
  static Map<String, dynamic> startState(Map<String, dynamic> progress,
          {required int schemaVersion, required int worldSeed}) =>
      {
        'schemaVersion': schemaVersion,
        'worldSeed': worldSeed,
        'tutorialCompleted': true,
        'progress': carry(progress),
      };
}
