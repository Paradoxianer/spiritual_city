import 'package:hive/hive.dart';
import 'city_size.dart';
import 'difficulty.dart';

/// Represents a saved game state stored in Hive.
///
/// TypeId: 1
class GameSave {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime lastPlayed;
  final Difficulty difficulty;
  final Map<String, dynamic> gameState;

  /// World-generation seed used for this save.  Stored so that loaded games
  /// always regenerate the exact same city layout.  Null only for saves
  /// created before seed support was added (they fall back to 42).
  final int? seed;

  /// Size of the city; null for saves from before sizes – the 🌆 big city.
  final CitySize? citySize;

  GameSave({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.difficulty,
    this.seed,
    this.citySize,
    DateTime? lastPlayed,
    this.gameState = const {},
  }) : lastPlayed = lastPlayed ?? createdAt;

  /// Returns a copy of this save with [gameState] and [lastPlayed] updated.
  GameSave copyWithState(Map<String, dynamic> newState) => GameSave(
        id: id,
        name: name,
        createdAt: createdAt,
        difficulty: difficulty,
        seed: seed,
        citySize: citySize,
        lastPlayed: DateTime.now(),
        gameState: newState,
      );

  /// Returns a copy of this save with [name] replaced.
  GameSave copyWithName(String newName) => GameSave(
        id: id,
        name: newName,
        createdAt: createdAt,
        difficulty: difficulty,
        seed: seed,
        citySize: citySize,
        lastPlayed: lastPlayed,
        gameState: gameState,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'lastPlayed': lastPlayed.toIso8601String(),
        'difficulty': difficulty.index,
        if (seed != null) 'seed': seed,
        if (citySize != null) 'citySize': citySize!.name,
        'gameState': gameState,
      };

  factory GameSave.fromMap(Map<dynamic, dynamic> map) => GameSave(
        id: map['id'] as String,
        name: map['name'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        lastPlayed: map['lastPlayed'] != null
            ? DateTime.parse(map['lastPlayed'] as String)
            : null,
        difficulty: Difficulty.values[map['difficulty'] as int],
        seed: map['seed'] as int?,
        citySize: CitySize.values.where((s) => s.name == map['citySize']).firstOrNull,
        gameState: (map['gameState'] as Map?)?.cast<String, dynamic>() ?? {},
      );
}

/// Manual Hive TypeAdapter for [GameSave] (typeId = 1).
class GameSaveAdapter extends TypeAdapter<GameSave> {
  @override
  final int typeId = 1;

  @override
  GameSave read(BinaryReader reader) {
    final map = reader.readMap();
    return GameSave.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, GameSave obj) {
    writer.writeMap(obj.toMap());
  }
}
