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

  Future<void> deleteSave(String id) => _repository.deleteSave(id);

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
