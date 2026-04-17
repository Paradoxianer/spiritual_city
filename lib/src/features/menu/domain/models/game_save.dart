import 'package:hive/hive.dart';
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

  GameSave({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.difficulty,
    DateTime? lastPlayed,
    this.gameState = const {},
  }) : lastPlayed = lastPlayed ?? createdAt;

  /// Returns a copy of this save with [gameState] and [lastPlayed] updated.
  GameSave copyWithState(Map<String, dynamic> newState) => GameSave(
        id: id,
        name: name,
        createdAt: createdAt,
        difficulty: difficulty,
        lastPlayed: DateTime.now(),
        gameState: newState,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'lastPlayed': lastPlayed.toIso8601String(),
        'difficulty': difficulty.index,
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
