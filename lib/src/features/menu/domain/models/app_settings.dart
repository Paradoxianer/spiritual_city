import 'package:hive/hive.dart';
import 'difficulty.dart';

/// Persisted application settings stored in Hive.
///
/// TypeId: 2
class AppSettings {
  String language;
  Difficulty lastDifficulty;

  /// Whether the player has ever completed (or skipped) the tutorial.
  /// Stored globally so new saves don't re-show the tutorial.
  bool tutorialCompleted;

  AppSettings({
    this.language = 'de',
    this.lastDifficulty = Difficulty.normal,
    this.tutorialCompleted = false,
  });

  Map<String, dynamic> toMap() => {
        'language': language,
        'lastDifficulty': lastDifficulty.index,
        'tutorialCompleted': tutorialCompleted,
      };

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) => AppSettings(
        language: map['language'] as String? ?? 'de',
        lastDifficulty:
            Difficulty.values[map['lastDifficulty'] as int? ?? 1],
        tutorialCompleted: map['tutorialCompleted'] as bool? ?? false,
      );
}

/// Manual Hive TypeAdapter for [AppSettings] (typeId = 2).
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final map = reader.readMap();
    return AppSettings.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer.writeMap(obj.toMap());
  }
}
