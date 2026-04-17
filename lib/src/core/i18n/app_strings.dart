/// Simple i18n string lookup system without external packages.
///
/// Supports DE and EN. All UI text should be retrieved via [AppStrings.get].
class AppStrings {
  static final Map<String, Map<String, String>> _translations = {
    'de': {
      // Main Menu
      'menu.title': 'SpiritWorld City',
      'menu.newGame': 'Neues Spiel',
      'menu.loadGame': 'Spiel laden',
      'menu.settings': 'Einstellungen',
      'menu.quit': 'Beenden',
      'menu.subtitle': 'Psalm 27,4',

      // Difficulty
      'difficulty.title': 'Wähle deinen Weg',
      'difficulty.easy': 'Einfach',
      'difficulty.normal': 'Normal',
      'difficulty.hard': 'Schwer',
      'difficulty.easy.verse': '„Der HERR kämpft für euch."',
      'difficulty.normal.verse': '„Wandelt im Glauben."',
      'difficulty.hard.verse': '„Erduldet Mühsal als guter Streiter."',
      'difficulty.easy.desc': 'Widerstand -30%, Glauben-Regeneration +50%',
      'difficulty.normal.desc': 'Ausgewogenes Gameplay',
      'difficulty.hard.desc': 'Widerstand +30%, härterer Weg',
      'difficulty.start': 'Spiel starten',
      'difficulty.back': 'Zurück',

      // Load Game
      'loadGame.title': 'Spiel laden',
      'loadGame.empty': 'Keine gespeicherten Spiele',
      'loadGame.back': 'Zurück',
      'loadGame.delete': 'Löschen',
      'loadGame.load': 'Laden',
      'loadGame.lastPlayed': 'Zuletzt gespielt',

      // In-game
      'game.saveQuit': 'Speichern & Beenden',
      'game.saveName.prefix': 'Spiel',

      // Settings
      'settings.title': 'Einstellungen',
      'settings.placeholder': 'Einstellungen kommen in Phase 2',
      'settings.back': 'Zurück',

      // Common
      'common.language': 'Sprache',

      // NPC Dialog
      'dialog.talk': 'Sprich',
      'dialog.pray': 'Bete',
      'dialog.help': 'Diene',
      'dialog.convert': 'Bekehre',
      'dialog.farewell': '👋 Tschüss',
      'dialog.goodbye': '👋 Tschüss!',
      'dialog.conversation': 'Gespräch',
    },
    'en': {
      // Main Menu
      'menu.title': 'SpiritWorld City',
      'menu.newGame': 'New Game',
      'menu.loadGame': 'Load Game',
      'menu.settings': 'Settings',
      'menu.quit': 'Quit',
      'menu.subtitle': 'Psalm 27:4',

      // Difficulty
      'difficulty.title': 'Choose your path',
      'difficulty.easy': 'Easy',
      'difficulty.normal': 'Normal',
      'difficulty.hard': 'Hard',
      'difficulty.easy.verse': '"The Lord fights for you."',
      'difficulty.normal.verse': '"Walk in faith."',
      'difficulty.hard.verse': '"Endure hardship with faith."',
      'difficulty.easy.desc': 'Opposition -30%, Faith regen +50%',
      'difficulty.normal.desc': 'Balanced gameplay',
      'difficulty.hard.desc': 'Opposition +30%, harder path',
      'difficulty.start': 'Start Game',
      'difficulty.back': 'Back',

      // Load Game
      'loadGame.title': 'Load Game',
      'loadGame.empty': 'No saved games',
      'loadGame.back': 'Back',
      'loadGame.delete': 'Delete',
      'loadGame.load': 'Load',
      'loadGame.lastPlayed': 'Last played',

      // In-game
      'game.saveQuit': 'Save & Quit',
      'game.saveName.prefix': 'Game',

      // Settings
      'settings.title': 'Settings',
      'settings.placeholder': 'Settings coming in Phase 2',
      'settings.back': 'Back',

      // Common
      'common.language': 'Language',

      // NPC Dialog
      'dialog.talk': 'Talk',
      'dialog.pray': 'Pray',
      'dialog.help': 'Help',
      'dialog.convert': 'Convert',
      'dialog.farewell': '👋 Goodbye',
      'dialog.goodbye': '👋 Goodbye!',
      'dialog.conversation': 'Chat',
    },
  };

  static String _currentLanguage = 'de';

  static String get currentLanguage => _currentLanguage;

  static void setLanguage(String lang) {
    if (_translations.containsKey(lang)) {
      _currentLanguage = lang;
    }
  }

  /// Looks up a translation key in the current language.
  /// Falls back to the key itself if not found.
  static String get(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }
}
