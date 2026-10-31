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

  /// Sound effects on/off (pause menu 🔊/🔇).
  bool soundOn;

  /// Version of the first-start notice the player accepted (#153).
  int consentVersion;

  /// Texts besides the emoji (see TextMode).
  bool showTexts;

  /// Explanations the player muted (see Narrator).
  List<String> mutedExplanations;

  AppSettings({
    this.language = 'de',
    this.lastDifficulty = Difficulty.normal,
    this.tutorialCompleted = false,
    this.soundOn = true,
    this.consentVersion = 0,
    this.showTexts = true,
    this.mutedExplanations = const [],
  });

  Map<String, dynamic> toMap() => {
        'language': language,
        'lastDifficulty': lastDifficulty.index,
        'tutorialCompleted': tutorialCompleted,
        'soundOn': soundOn,
        'consentVersion': consentVersion,
        'showTexts': showTexts,
        'mutedExplanations': mutedExplanations,
      };

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) => AppSettings(
        language: map['language'] as String? ?? 'de',
        lastDifficulty:
            Difficulty.values[map['lastDifficulty'] as int? ?? 1],
        tutorialCompleted: map['tutorialCompleted'] as bool? ?? false,
        soundOn: map['soundOn'] as bool? ?? true,
        consentVersion: map['consentVersion'] as int? ?? 0,
        showTexts: map['showTexts'] as bool? ?? true,
        mutedExplanations: [for (final k in (map['mutedExplanations'] as List?) ?? const []) '$k'],
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
