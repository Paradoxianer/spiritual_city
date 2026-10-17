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

      // Pause menu (Issue #162 / #174)
      'game.pause.button': 'Pause',
      'game.pause.title': 'Pause',
      'game.pause.resume': 'Fortsetzen',
      'game.pause.help': 'Tastenbelegung',
      'game.pause.save': 'Speichern',
      'game.pause.saved': 'Gespeichert ✓',
      'game.pause.quit': 'Speichern & Beenden',
      'game.pause.quitConfirm.title': 'Speichern & Beenden?',
      'game.pause.quitConfirm.body':
          'Dein Fortschritt wird gespeichert und du kehrst ins Hauptmenü zurück.',
      'game.pause.quitConfirm.confirm': 'Beenden',
      'game.pause.quitConfirm.cancel': 'Abbrechen',

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
      'tutorial.movement.message': 'Nutze den Joystick links unten,\n'
          'um dich in der Stadt zu bewegen!\n'
          '(Auf dem PC: Pfeiltasten oder WASD)',
      'tutorial.movement.trigger': '👟 Bewege dich, um fortzufahren.',
      'tutorial.spiritWorld.title': 'Unsichtbare Welt',
      'tutorial.spiritWorld.message':
          'Wechsle jetzt in die geistliche Welt!\n'
          'Tippe auf den 🙏-Button unten rechts.\n'
          '(PC: Taste Q)\n\n'
          'Dort kannst du verborgene Kräfte sehen\n'
          'und aktiv eingreifen.',
      'tutorial.spiritWorld.trigger':
          '🙏 Betritt die geistliche Welt, um fortzufahren.',
      'tutorial.prayer.title': 'Beten & Befreien',
      'tutorial.prayer.message':
          'Halte den ✝️-Button gedrückt, bis sich\n'
          'die Bereiche unter dir grün färben –\n'
          'so befreist du sie von der Dunkelheit!\n'
          '(PC: Leertaste gedrückt halten)\n\n'
          'Es gibt verschiedene Modi:\n'
          'Befreiung, Zurückdrängen u.v.m.',
      'tutorial.prayer.trigger': '⚡ Bete einmal, um fortzufahren.',
      'tutorial.returnToCity.title': 'Zurück in die Stadt',
      'tutorial.returnToCity.message':
          'Gut gemacht! Kehre zurück in die Stadt.\n'
          'Tippe auf den 🏙️-Button unten rechts.\n'
          '(PC: Taste Q)',
      'tutorial.returnToCity.trigger':
          '🏙️ Kehre in die Stadt zurück, um fortzufahren.',
      'tutorial.radialMenu.title': 'Aktions-Menü',
      'tutorial.radialMenu.message':
          'Gehe auf eine Person in der Stadt zu.\n'
          'Drücke dann den 🖐️-Button rechts unten\n'
          '(PC: Taste E), um das Aktions-Menü zu öffnen.\n\n'
          'Wähle eine Aktion aus der Liste aus.',
      'tutorial.radialMenu.trigger': '🖐️ Wähle eine Aktion aus, um fortzufahren.',
      'tutorial.npcTalk.title': 'Mit Personen interagieren',
      'tutorial.npcTalk.message':
          'Du bist jetzt im Gespräch!\n'
          'Aktionen haben Auswirkungen in der realen Welt –\n'
          'manchmal auch in der unsichtbaren.\n'
          'Die unsichtbare Welt beeinflusst\n'
          'den Erfolg deiner Aktionen.\n\n'
          'Interagiere mit der Person und drücke\n'
          'dann unten „Weiter".',
      'tutorial.hudExplain.title': 'Deine Ressourcen',
      'tutorial.hudExplain.message':
          '❤️ Gesundheit – sinkt bei Hunger oder Gefahren\n'
          '🍞 Hunger – sinkt mit der Zeit; iss, um ihn zu füllen\n'
          '🙏 Glaube – für geistliche Aktionen & Gebet nötig\n'
          '📦 Materialien – für praktische Hilfe benötigt\n'
          '📖 Erkenntnis – durch Jüngerschaft & Studium\n'
          '✝ Bekehrungen – Menschen, die den Glauben gefunden haben\n\n'
          'Tipp: Homebase aufsuchen, um Hunger & Gesundheit aufzufüllen!',
      'tutorial.homebase.title': 'Deine Homebase',
      'tutorial.homebase.message':
          '🏠 Nutze den Kompass ▲ (oben links),\n'
          'um das Pastorenhaus zu finden.\n\n'
          'Drücke E (oder 🖐️) → wähle\n'
          '\'Pastorenhaus\' → fülle deine Ressourcen auf!',
      'tutorial.homebase.trigger': '🏠 Betritt das Pastorenhaus, um fortzufahren.',
      'tutorial.firstMission.title': 'Erste Mission',
      'tutorial.firstMission.message': 'Du hast deine erste Mission!\n'
          'Besuche ein Gebäude in der Nähe\n'
          'und führe eine Aktion durch.',
      'tutorial.firstMission.trigger': '🏛️ Betritt ein Gebäude, um fortzufahren.',
      'tutorial.completed.title': 'Tutorial abgeschlossen!',
      'tutorial.completed.message': 'Du bist bereit!\n'
          'Gott sei mit dir. ✝\n\n'
          'Die Stadt braucht dich –\n'
          'geh und bringe Licht!',
      'tutorial.next': 'Weiter →',
      'tutorial.start': 'Los geht\'s! 🚀',
      'tutorial.skip': 'Tutorial überspringen',

      // NPC life story (📜 tab) – one sentence per LifeEvent id
      'life.birth': 'Geboren.',
      'life.today': 'Heute.',
      'life.hidden': 'Noch nicht erzählt …',
      'life.resolved': 'Verarbeitet:',
      'life.converted': 'Kam zum Glauben.',
      'life.best_friends_childhood': 'Fand einen besten Freund in der Nachbarschaft.',
      'life.playground_fun': 'Verbrachte unbeschwerte Nachmittage auf dem Spielplatz.',
      'life.sports_club': 'Trat einem Sportverein bei.',
      'life.minor_sibling_rivalry': 'Stritt sich oft mit den Geschwistern.',
      'life.first_crush': 'War zum ersten Mal verknallt.',
      'life.circle_of_friends': 'Hatte eine feste Clique.',
      'life.small_argument_with_friends': 'Zerstritt sich eine Zeit lang mit Freunden.',
      'life.steady_friendships_now': 'Hat verlässliche Freundschaften.',
      'life.occasional_loneliness': 'Fühlte sich oft einsam.',
      'life.neglect': 'Wurde zu Hause vernachlässigt.',
      'life.parents_separation': 'Erlebte die Trennung der Eltern.',
      'life.failed_relationship': 'Eine Beziehung zerbrach.',
      'life.sheltered_childhood': 'Wuchs behütet und geliebt auf.',
      'life.first_love': 'Erlebte die erste große Liebe.',
      'life.happy_relationship': 'Fand eine glückliche Partnerschaft.',
      'life.lost_pet': 'Verlor ein geliebtes Haustier.',
      'life.moved_away_lost_friends': 'Zog um und verlor dabei Freunde.',
      'life.family_illness': 'Jemand in der Familie wurde schwer krank.',
      'life.loss_of_parent': 'Verlor einen Elternteil.',
      'life.violent_loss': 'Verlor einen Menschen durch Gewalt.',
      'life.normal_childhood_illness': 'Hatte die üblichen Kinderkrankheiten.',
      'life.active_and_fit': 'War aktiv und sportlich.',
      'life.robust_health': 'Blieb meistens gesund.',
      'life.minor_health_worries': 'Hatte gesundheitliche Sorgen.',
      'life.alcohol_abuse': 'Geriet in die Alkoholsucht.',
      'life.drugs': 'Geriet an Drogen.',
      'life.imprisonment': 'Wurde straffällig und kam ins Gefängnis.',
      'life.pocket_money': 'Sparte das erste Taschengeld.',
      'life.finished_school_ok': 'Schaffte den Schulabschluss.',
      'life.enjoyed_school_days': 'Ging gern zur Schule.',
      'life.normal_job': 'Fand eine feste Arbeit.',
      'life.had_to_budget': 'Musste mit wenig Geld auskommen.',
      'life.unemployment': 'Wurde arbeitslos.',
      'life.debt': 'Geriet in Schulden.',
      'life.career_success': 'Hatte beruflich Erfolg.',
      'life.inheritance': 'Erbte etwas.',
      'life.sunday_school': 'Ging in den Kindergottesdienst.',
      'life.said_grace_at_home': 'Zu Hause wurde vor dem Essen gebetet.',
      'life.questioned_faith_as_teen': 'Stellte den Glauben infrage.',
      'life.church_disappointment': 'Wurde von einer Gemeinde enttäuscht.',
      'life.unanswered_prayer': 'Ein Gebet blieb unerhört.',
      'life.conversion_experience': 'Erlebte Gott ganz persönlich.',
      'life.answered_prayer': 'Erlebte eine Gebetserhörung.',
      'life.first_bible_study': 'Besuchte den ersten Bibelkreis.',
      'life.new_church_friends': 'Fand Freunde in der Gemeinde.',
      'life.baptism': 'Ließ sich taufen.',
      'life.shared_faith_with_someone': 'Erzählte jemandem vom Glauben.',
      'life.grown_through_setback': 'Wuchs in einer Krise im Glauben.',
      'life.doubted_if_it_was_real': 'Zweifelte, ob alles echt ist.',
      'life.small_group_conflict': 'Hatte Streit im Hauskreis.',
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

      // Pause menu (Issue #162 / #174)
      'game.pause.button': 'Pause',
      'game.pause.title': 'Paused',
      'game.pause.resume': 'Resume',
      'game.pause.help': 'Controls',
      'game.pause.save': 'Save',
      'game.pause.saved': 'Saved ✓',
      'game.pause.quit': 'Save & Quit',
      'game.pause.quitConfirm.title': 'Save & Quit?',
      'game.pause.quitConfirm.body':
          'Your progress will be saved and you\'ll return to the main menu.',
      'game.pause.quitConfirm.confirm': 'Quit',
      'game.pause.quitConfirm.cancel': 'Cancel',

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
      'tutorial.movement.message': 'Use the joystick at the bottom left\n'
          'to move around the city!\n'
          '(On PC: arrow keys or WASD)',
      'tutorial.movement.trigger': '👟 Move to continue.',
      'tutorial.spiritWorld.title': 'Invisible World',
      'tutorial.spiritWorld.message':
          'Switch to the spiritual world now!\n'
          'Tap the 🙏 button at the bottom right.\n'
          '(PC: key Q)\n\n'
          'There you can see hidden forces\n'
          'and actively intervene.',
      'tutorial.spiritWorld.trigger': '🙏 Enter the spiritual world to continue.',
      'tutorial.prayer.title': 'Prayer & Liberation',
      'tutorial.prayer.message':
          'Hold the ✝️ button until the areas\n'
          'beneath you turn green –\n'
          'that\'s how you liberate them!\n'
          '(PC: hold Space bar)\n\n'
          'There are different modes:\n'
          'Liberation, Pushback, and more.',
      'tutorial.prayer.trigger': '⚡ Perform a prayer to continue.',
      'tutorial.returnToCity.title': 'Back to the City',
      'tutorial.returnToCity.message':
          'Well done! Return to the city.\n'
          'Tap the 🏙️ button at the bottom right.\n'
          '(PC: key Q)',
      'tutorial.returnToCity.trigger': '🏙️ Return to the city to continue.',
      'tutorial.radialMenu.title': 'Action Menu',
      'tutorial.radialMenu.message':
          'Walk up to a person in the city.\n'
          'Then press the 🖐️ button (bottom right)\n'
          '(PC: key E) to open the action menu.\n\n'
          'Select an action from the list.',
      'tutorial.radialMenu.trigger': '🖐️ Choose an action to continue.',
      'tutorial.npcTalk.title': 'Interact with People',
      'tutorial.npcTalk.message':
          'You are now in a conversation!\n'
          'Actions have effects in the real world –\n'
          'and sometimes in the invisible world too.\n'
          'The invisible world influences\n'
          'the success of your actions.\n\n'
          'Interact with the person and then\n'
          'press "Next" below.',
      'tutorial.hudExplain.title': 'Your Resources',
      'tutorial.hudExplain.message':
          '❤️ Health – drops from hunger or danger\n'
          '🍞 Hunger – decreases over time; eat to refill\n'
          '🙏 Faith – needed for spiritual actions & prayer\n'
          '📦 Supplies – required for practical help\n'
          '📖 Insight – gained through discipleship & study\n'
          '✝ Conversions – people who have found faith\n\n'
          'Tip: Visit your homebase to refill hunger & health!',
      'tutorial.homebase.title': 'Your Homebase',
      'tutorial.homebase.message':
          '🏠 Use the compass ▲ (top left)\n'
          'to find the pastor\'s house.\n\n'
          'Press E (or 🖐️) → select\n'
          '"Pastor\'s House" → refill your resources!',
      'tutorial.homebase.trigger': '🏠 Enter the pastor\'s house to continue.',
      'tutorial.firstMission.title': 'First Mission',
      'tutorial.firstMission.message': 'You have your first mission!\n'
          'Visit a nearby building\n'
          'and perform an action.',
      'tutorial.firstMission.trigger': '🏛️ Enter a building to continue.',
      'tutorial.completed.title': 'Tutorial Complete!',
      'tutorial.completed.message': 'You are ready!\n'
          'God be with you. ✝\n\n'
          'The city needs you –\n'
          'go and bring light!',
      'tutorial.next': 'Next →',
      'tutorial.start': 'Let\'s go! 🚀',
      'tutorial.skip': 'Skip Tutorial',

      // NPC life story (📜 tab) – one sentence per LifeEvent id
      'life.birth': 'Born.',
      'life.today': 'Today.',
      'life.hidden': 'Not told yet …',
      'life.resolved': 'Worked through:',
      'life.converted': 'Came to faith.',
      'life.best_friends_childhood': 'Found a best friend in the neighbourhood.',
      'life.playground_fun': 'Spent carefree afternoons at the playground.',
      'life.sports_club': 'Joined a sports club.',
      'life.minor_sibling_rivalry': 'Often fought with siblings.',
      'life.first_crush': 'Had a first crush.',
      'life.circle_of_friends': 'Had a close circle of friends.',
      'life.small_argument_with_friends': 'Fell out with friends for a while.',
      'life.steady_friendships_now': 'Has reliable friendships.',
      'life.occasional_loneliness': 'Often felt lonely.',
      'life.neglect': 'Was neglected at home.',
      'life.parents_separation': 'Went through the parents’ separation.',
      'life.failed_relationship': 'A relationship fell apart.',
      'life.sheltered_childhood': 'Grew up sheltered and loved.',
      'life.first_love': 'Experienced first love.',
      'life.happy_relationship': 'Found a happy relationship.',
      'life.lost_pet': 'Lost a beloved pet.',
      'life.moved_away_lost_friends': 'Moved away and lost friends.',
      'life.family_illness': 'A family member fell seriously ill.',
      'life.loss_of_parent': 'Lost a parent.',
      'life.violent_loss': 'Lost someone to violence.',
      'life.normal_childhood_illness': 'Had the usual childhood illnesses.',
      'life.active_and_fit': 'Was active and fit.',
      'life.robust_health': 'Stayed mostly healthy.',
      'life.minor_health_worries': 'Had health worries.',
      'life.alcohol_abuse': 'Fell into alcohol addiction.',
      'life.drugs': 'Got into drugs.',
      'life.imprisonment': 'Committed a crime and went to prison.',
      'life.pocket_money': 'Saved up the first pocket money.',
      'life.finished_school_ok': 'Finished school.',
      'life.enjoyed_school_days': 'Enjoyed going to school.',
      'life.normal_job': 'Found a steady job.',
      'life.had_to_budget': 'Had to get by on little money.',
      'life.unemployment': 'Became unemployed.',
      'life.debt': 'Fell into debt.',
      'life.career_success': 'Had success at work.',
      'life.inheritance': 'Received an inheritance.',
      'life.sunday_school': 'Went to Sunday school.',
      'life.said_grace_at_home': 'The family said grace at home.',
      'life.questioned_faith_as_teen': 'Questioned faith.',
      'life.church_disappointment': 'Was let down by a church.',
      'life.unanswered_prayer': 'A prayer went unanswered.',
      'life.conversion_experience': 'Had a personal encounter with God.',
      'life.answered_prayer': 'Saw a prayer answered.',
      'life.first_bible_study': 'Joined a first Bible study.',
      'life.new_church_friends': 'Found friends at church.',
      'life.baptism': 'Was baptised.',
      'life.shared_faith_with_someone': 'Shared their faith with someone.',
      'life.grown_through_setback': 'Grew in faith through a setback.',
      'life.doubted_if_it_was_real': 'Doubted whether it was all real.',
      'life.small_group_conflict': 'Had a conflict in the small group.',
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
