import 'dart:convert';

import 'models/difficulty.dart';
import 'models/game_save.dart';

/// A save as a file and back (#192): until there is sync between devices,
/// a save can travel as `.json` from phone to web and back.
///
/// Pure rules – the screens only pick and share the file.
class SaveTransfer {
  /// Marks our files, so a foreign `.json` is refused.
  static const String format = 'spiritworld-city-save';

  /// The file layout (not the game state's `schemaVersion`, which the game
  /// migrates when it loads the save).
  static const int formatVersion = 1;

  /// File name for [save], e.g. `spiritworld-Mein_Spiel.json`.
  static String fileName(GameSave save) {
    final safe = save.name.replaceAll(RegExp(r'[^A-Za-z0-9äöüÄÖÜß_-]+'), '_');
    return 'spiritworld-${safe.isEmpty ? save.id : safe}.json';
  }

  /// The save as JSON text.
  static String export(GameSave save) => jsonEncode({
        'format': format,
        'formatVersion': formatVersion,
        'save': _jsonSafe(save.toMap()),
      });

  /// Reads a file written by [export] as a **new** save with [newId] – an
  /// import never overwrites an existing save.
  ///
  /// Throws [SaveImportException] for broken or foreign files and for saves
  /// of a newer game ([maxSchemaVersion]) than this one.
  static GameSave import(String text, {required String newId, required int maxSchemaVersion}) {
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException {
      throw const SaveImportException('not json');
    }
    if (root is! Map || root['format'] != format) {
      throw const SaveImportException('not a save');
    }
    final fv = root['formatVersion'];
    if (fv is! int || fv > formatVersion) {
      throw const SaveImportException('newer file');
    }
    final map = root['save'];
    if (map is! Map ||
        map['name'] is! String ||
        map['createdAt'] is! String ||
        map['difficulty'] is! int ||
        (map['difficulty'] as int) < 0 ||
        (map['difficulty'] as int) >= Difficulty.values.length ||
        (map['gameState'] != null && map['gameState'] is! Map) ||
        (map['seed'] != null && map['seed'] is! int)) {
      throw const SaveImportException('fields');
    }
    final state = map['gameState'] as Map?;
    final schema = state?['schemaVersion'];
    if (schema != null && (schema is! int || schema > maxSchemaVersion)) {
      throw const SaveImportException('newer game');
    }
    try {
      return GameSave.fromMap({...map, 'id': newId});
    } catch (_) {
      throw const SaveImportException('fields');
    }
  }

  /// Hive keeps maps with any keys and doubles like NaN; JSON does not.
  static Object? _jsonSafe(Object? v) {
    if (v is Map) return {for (final e in v.entries) e.key.toString(): _jsonSafe(e.value)};
    if (v is Iterable) return [for (final e in v) _jsonSafe(e)];
    if (v is double && !v.isFinite) return 0.0;
    return v;
  }
}

/// A file that is not (or not yet) a save this game can read.
class SaveImportException implements Exception {
  final String reason;
  const SaveImportException(this.reason);

  @override
  String toString() => 'SaveImportException($reason)';
}
