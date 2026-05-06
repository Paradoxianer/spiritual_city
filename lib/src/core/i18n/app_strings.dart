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
      'difficulty.seed': 'Seed',
      'difficulty.seed.hint': 'random',

      // Load Game
      'loadGame.title': 'Spiel laden',
      'loadGame.empty': 'Keine gespeicherten Spiele',
      'loadGame.back': 'Zurück',
      'loadGame.delete': 'Löschen',
      'loadGame.load': 'Laden',
      'loadGame.lastPlayed': 'Zuletzt gespielt',
      'loadGame.rename': 'Umbenennen',
      'loadGame.rename.title': 'Spiel umbenennen',
      'loadGame.rename.hint': 'Neuer Name',
      'loadGame.rename.confirm': 'Umbenennen',
      'loadGame.rename.cancel': 'Abbrechen',

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
      'dialog.help': 'Helfen',
      'dialog.convert': 'Bekehrung',
      'dialog.farewell': '👋 Tschüss',
      'dialog.goodbye': '👋 Tschüss!',
      'dialog.conversation': 'Gespräch',

      // Resources
      'resource.health': 'Gesundheit',
      'resource.provision': 'Versorgung',
      'resource.faith': 'Glaube',
      'resource.supplies': 'Vorräte',

      // HUD
      'hud.christians': 'Christen',

      // Tutorial
      'tutorial.welcome.title': 'Willkommen!',
      'tutorial.welcome.message': 'Willkommen in der Stadt!\n'
          'Du bist ein Christ mit einer Mission.\n'
          'Gott hat dich gesandt, um Licht in diese Stadt zu bringen. 🌟',
      'tutorial.movement.title': 'Bewegung',
      'tutorial.movement.message': 'Tippe auf die Stadt um dich zu bewegen!\n'
          '(Auf dem PC: Pfeiltasten oder WASD)',
      'tutorial.npcTalk.title': 'Menschen ansprechen',
      'tutorial.npcTalk.message': 'Sprich mit jemandem in der Stadt!\n'
          'Gehe nah an eine Person heran und öffne das Aktions-Menü.',
      'tutorial.radialMenu.title': 'Aktions-Menü',
      'tutorial.radialMenu.message':
          'Öffne das Aktions-Menü (🖐️-Button rechts unten)\n'
          'und wähle eine Aktion aus!\n'
          '(PC: Taste E)',
      'tutorial.spiritWorld.title': 'Geistliche Welt',
      'tutorial.spiritWorld.message': 'Wechsle in die geistliche Welt!\n'
          'Tippe auf den 🙏-Button unten rechts.\n'
          '(PC: Taste Q)',
      'tutorial.prayer.title': 'Gebet & Kampf',
      'tutorial.prayer.message':
          'Bete für diesen Bereich – vertreibe die Dunkelheit!\n'
          'Halte den ✝️-Button gedrückt und lass ihn dann los.',
      'tutorial.returnToCity.title': 'Zurück in die Stadt',
      'tutorial.returnToCity.message':
          'Gut gemacht! Kehre zurück in die Stadt.\n'
          'Tippe auf den 🏙️-Button unten rechts.',
      'tutorial.hudExplain.title': 'Deine Status-Anzeige',
      'tutorial.hudExplain.message':
          '❤️ Gesundheit  •  🍞 Hunger  •  🙏 Glaube\n'
          '📦 Materialien  •  📖 Erkenntnis  •  ✝ Bekehrungen\n\n'
          'Halte deine Ressourcen im Blick –\n'
          'sie sind wichtig für deine Mission!',
      'tutorial.firstMission.title': 'Erste Mission',
      'tutorial.firstMission.message': 'Du hast deine erste Mission!\n'
          'Besuche ein Gebäude in der Nähe\n'
          'und führe eine Aktion durch.',
      'tutorial.completed.title': 'Tutorial abgeschlossen!',
      'tutorial.completed.message': 'Du bist bereit!\n'
          'Gott sei mit dir. ✝\n\n'
          'Die Stadt braucht dich –\n'
          'geh und bringe Licht!',
      'tutorial.next': 'Weiter →',
      'tutorial.start': 'Los geht\'s! 🚀',
      'tutorial.skip': 'Tutorial überspringen',
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
      'difficulty.seed': 'Seed',
      'difficulty.seed.hint': 'random',

      // Load Game
      'loadGame.title': 'Load Game',
      'loadGame.empty': 'No saved games',
      'loadGame.back': 'Back',
      'loadGame.delete': 'Delete',
      'loadGame.load': 'Load',
      'loadGame.lastPlayed': 'Last played',
      'loadGame.rename': 'Rename',
      'loadGame.rename.title': 'Rename Save',
      'loadGame.rename.hint': 'New name',
      'loadGame.rename.confirm': 'Rename',
      'loadGame.rename.cancel': 'Cancel',

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
      'dialog.convert': 'Conversion',
      'dialog.farewell': '👋 Goodbye',
      'dialog.goodbye': '👋 Goodbye!',
      'dialog.conversation': 'Chat',

      // Resources
      'resource.health': 'Health',
      'resource.provision': 'Provision',
      'resource.faith': 'Faith',
      'resource.supplies': 'Supplies',

      // HUD
      'hud.christians': 'Christians',

      // Tutorial
      'tutorial.welcome.title': 'Welcome!',
      'tutorial.welcome.message': 'Welcome to the city!\n'
          'You are a Christian on a mission.\n'
          'God has sent you to bring light to this city. 🌟',
      'tutorial.movement.title': 'Movement',
      'tutorial.movement.message': 'Tap on the city to move around!\n'
          '(On PC: arrow keys or WASD)',
      'tutorial.npcTalk.title': 'Talk to People',
      'tutorial.npcTalk.message': 'Talk to someone in the city!\n'
          'Get close to a person and open the action menu.',
      'tutorial.radialMenu.title': 'Action Menu',
      'tutorial.radialMenu.message':
          'Open the action menu (🖐️ button bottom right)\n'
          'and choose an action!\n'
          '(PC: key E)',
      'tutorial.spiritWorld.title': 'Spiritual World',
      'tutorial.spiritWorld.message': 'Switch to the spiritual world!\n'
          'Tap the 🙏 button at the bottom right.\n'
          '(PC: key Q)',
      'tutorial.prayer.title': 'Prayer & Combat',
      'tutorial.prayer.message':
          'Pray for this area – drive out the darkness!\n'
          'Hold the ✝️ button and then release it.',
      'tutorial.returnToCity.title': 'Back to the City',
      'tutorial.returnToCity.message': 'Well done! Return to the city.\n'
          'Tap the 🏙️ button at the bottom right.',
      'tutorial.hudExplain.title': 'Your Status Display',
      'tutorial.hudExplain.message':
          '❤️ Health  •  🍞 Hunger  •  🙏 Faith\n'
          '📦 Supplies  •  📖 Insight  •  ✝ Conversions\n\n'
          'Keep track of your resources –\n'
          'they are vital for your mission!',
      'tutorial.firstMission.title': 'First Mission',
      'tutorial.firstMission.message': 'You have your first mission!\n'
          'Visit a nearby building\n'
          'and perform an action.',
      'tutorial.completed.title': 'Tutorial Complete!',
      'tutorial.completed.message': 'You are ready!\n'
          'God be with you. ✝\n\n'
          'The city needs you –\n'
          'go and bring light!',
      'tutorial.next': 'Next →',
      'tutorial.start': 'Let\'s go! 🚀',
      'tutorial.skip': 'Skip Tutorial',
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
