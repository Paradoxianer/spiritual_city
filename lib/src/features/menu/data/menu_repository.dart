import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import '../domain/models/app_settings.dart';
import '../domain/models/game_save.dart';

/// Data layer: Hive-backed persistence for saves and settings.
class MenuRepository {
  static const _savesBoxName = 'gameSaves';
  static const _settingsBoxName = 'appSettings';
  static const _settingsKey = 'settings';

  final _log = Logger('MenuRepository');

  // --------------- Game Saves -----------------------------------------------

  Future<Box<GameSave>> _savesBox() async =>
      Hive.isBoxOpen(_savesBoxName)
          ? Hive.box<GameSave>(_savesBoxName)
          : await Hive.openBox<GameSave>(_savesBoxName);

  Future<List<GameSave>> loadAllSaves() async {
    final box = await _savesBox();
    final saves = box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _log.fine('Loaded ${saves.length} saves.');
    return saves;
  }

  Future<void> writeSave(GameSave save) async {
    final box = await _savesBox();
    await box.put(save.id, save);
    _log.info('Wrote save: ${save.id}');
  }

  Future<void> deleteSave(String id) async {
    final box = await _savesBox();
    await box.delete(id);
    _log.info('Deleted save: $id');
  }

  // --------------- App Settings ---------------------------------------------

  Future<Box<AppSettings>> _settingsBox() async =>
      Hive.isBoxOpen(_settingsBoxName)
          ? Hive.box<AppSettings>(_settingsBoxName)
          : await Hive.openBox<AppSettings>(_settingsBoxName);

  Future<AppSettings> loadSettings() async {
    final box = await _settingsBox();
    return box.get(_settingsKey) ?? AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    final box = await _settingsBox();
    await box.put(_settingsKey, settings);
    _log.fine('Settings saved: lang=${settings.language}');
  }
}
