import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/i18n/app_strings.dart';
import '../data/menu_repository.dart';
import 'models/app_settings.dart';
import 'models/difficulty.dart';
import 'models/game_save.dart';

// Re-export for convenience (Directives must appear before any declarations)
export 'models/difficulty.dart';
export 'models/game_save.dart';
export 'models/app_settings.dart';

/// Business logic for the main menu: language, difficulty and save/load.
class MenuService {
  final MenuRepository _repository;
  final LanguageNotifier languageNotifier;
  final ValueNotifierDifficulty difficultyNotifier;

  final _log = Logger('MenuService');

  MenuService({
    required MenuRepository repository,
    required this.languageNotifier,
    required this.difficultyNotifier,
  }) : _repository = repository;

  // --------------- Initialization -------------------------------------------

  Future<void> init() async {
    final settings = await _repository.loadSettings();
    languageNotifier.setLanguage(settings.language);
    difficultyNotifier.value = settings.lastDifficulty;
    _log.info('MenuService init: lang=${settings.language}, '
        'difficulty=${settings.lastDifficulty}');
  }

  // --------------- Language -------------------------------------------------

  Future<void> setLanguage(String lang) async {
    languageNotifier.setLanguage(lang);
    await _persistSettings();
  }

  // --------------- Difficulty -----------------------------------------------

  Future<void> setDifficulty(Difficulty difficulty) async {
    difficultyNotifier.value = difficulty;
    await _persistSettings();
  }

  // --------------- Saves ----------------------------------------------------

  Future<List<GameSave>> loadSaves() => _repository.loadAllSaves();

  Future<void> createSave(String name, Difficulty difficulty) async {
    final save = GameSave(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      difficulty: difficulty,
    );
    await _repository.writeSave(save);
    _log.info('Created save: ${save.id}');
  }

  /// Persists a fully constructed [GameSave] directly.
  Future<void> writeSave(GameSave save) async {
    await _repository.writeSave(save);
    _log.info('Wrote save: ${save.id}');
  }

  Future<void> deleteSave(String id) => _repository.deleteSave(id);

  /// Renames the save identified by [id] to [newName].
  ///
  /// If the save no longer exists this is a no-op.
  Future<void> renameSave(String id, String newName) async {
    final saves = await _repository.loadAllSaves();
    final existing = saves.where((s) => s.id == id).firstOrNull;
    if (existing == null) {
      _log.warning('renameSave: save $id not found – skipping');
      return;
    }
    await _repository.writeSave(existing.copyWithName(newName));
    _log.info('Renamed save ${existing.id} to "$newName"');
  }

  /// Updates the [gameState] of an existing save identified by [id].
  ///
  /// If the save no longer exists (deleted in another session), this is a
  /// no-op so the game can still exit cleanly.
  Future<void> updateSaveState(String id, Map<String, dynamic> gameState) async {
    final saves = await _repository.loadAllSaves();
    final existing = saves.where((s) => s.id == id).firstOrNull;
    if (existing == null) {
      _log.warning('updateSaveState: save $id not found – skipping');
      return;
    }
    await _repository.writeSave(existing.copyWithState(gameState));
    _log.info('Updated save state for ${existing.id}');
  }

  // --------------- Internal -------------------------------------------------

  Future<void> _persistSettings() async {
    final settings = AppSettings(
      language: AppStrings.currentLanguage,
      lastDifficulty: difficultyNotifier.value,
    );
    await _repository.saveSettings(settings);
  }
}

/// Typed [ValueNotifier] for [Difficulty] to make injection explicit.
class ValueNotifierDifficulty extends ValueNotifier<Difficulty> {
  ValueNotifierDifficulty(super.value);
}
