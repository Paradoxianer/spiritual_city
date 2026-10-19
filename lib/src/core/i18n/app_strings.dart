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
      'upgrade.shield': 'Schild',
      'upgrade.helm': 'Helm',
      'upgrade.radius': 'Radius',
      'upgrade.strength': 'Stärke',
      'upgrade.duration': 'Dauer',
      'upgrade.speed': 'Tempo',
      'mode.liberation': 'Befreiung',
      'mode.rebuke': 'Zurechtweisen',
      'mode.slow': 'Binden',
      'mode.drain': 'Entwaffnen',
      'resource.provision': 'Versorgung',
      'resource.faith': 'Glaube',
      'resource.supplies': 'Vorräte',

      // HUD
      'hud.christians': 'Christen',

      // Tutorial
      'tutorial.goHome.goal': 'Geh in dein Pastorenhaus 🏠',
      'tutorial.goHome.detail': 'Dein Zuhause ist das Haus mit dem Kreuz ✝️ auf dem Dach. Der türkise Ring auf der Minimap oben rechts zeigt dir den Weg. Lauf einfach in die Tür 🚪 hinein – oder tippe vor dem Haus den leuchtenden 🖐️-Knopf (Taste E).',
      'tutorial.readBible.goal': 'Lies in der Bibel 📖',
      'tutorial.readBible.detail': 'Glaube 🙏 ist deine Kraft für alles, was du tust. Tippe das leuchtende Bücherregal 📖 an – der Pastor geht hin und liest. Das füllt deinen Glauben auf.',
      'tutorial.talk.goal': 'Sprich mit einem Menschen',
      'tutorial.talk.detail': 'Geh durch die Tür 🚪 nach draußen zu einer Person (türkis auf der Minimap) und tippe den leuchtenden 🖐️-Knopf (Taste E). Im Gespräch 💬 lernst du sie kennen – jede Begegnung macht sie offener für Gott.',
      'tutorial.prayPerson.goal': 'Bete mit einem Menschen',
      'tutorial.prayPerson.detail': 'Im Gespräch gibt es 🙏 Gebet. Ist ihr Glaubensbalken ✝️ hoch genug, kannst du sie einladen, Christ zu werden.',
      'tutorial.enterSpirit.goal': 'Wechsle in die unsichtbare Welt',
      'tutorial.enterSpirit.detail': 'Der leuchtende 🙏-Knopf öffnet die unsichtbare Welt (kostet 10 🙏). Dort siehst du, wo die Stadt geistlich finster (rot) oder hell (grün) ist.',
      'tutorial.liberate.goal': 'Halte ✝️ gedrückt und bete',
      'tutorial.liberate.detail': 'Solange du ✝️ hältst, gehen Gebetswellen von dir aus und machen rote Felder grün. Das kostet Glauben – achte auf 🙏.',
      'tutorial.defeatDaemon.goal': 'Besiege einen Dämon',
      'tutorial.defeatDaemon.detail': 'Dämonen 👹 greifen dich an und verdunkeln die Stadt. Triff sie mit Gebetswellen, bis sie vergehen – das gibt 📖 Erkenntnis für Verbesserungen.',
      'tutorial.returnCity.goal': 'Kehre in die Stadt zurück',
      'tutorial.returnCity.detail': 'Tippe 🏙️, um zurückzukehren. In der Stadt hilfst du Menschen und sammelst neue Kraft.',
      'tutorial.quarter.goal': 'Gewinne deinen Stadtteil',
      'tutorial.quarter.detail': 'Unter ✝️ siehst du den Stadtteil-Balken 🏘️. Werden genug Menschen Christen, kannst du das Bollwerk 🏰 in der unsichtbaren Welt angreifen und den Stadtteil erwecken 🔥.',
      'tutorial.mission.goal': 'Nimm eine Mission an',
      'tutorial.mission.detail': 'Im Pastorenhaus 🏠 hängt das Missionsbrett 📋 – es leuchtet, tippe es an. Tippe dann 📍 bei einer Mission oder unter 🎓 bei einer Fähigkeit – dann zeigt dir die Karte den Weg.',
      'tutorial.completed.goal': 'Du bist bereit!',
      'tutorial.completed.detail': 'Gott segne deinen Dienst in der Stadt. Neue Fähigkeiten lernst du bei Mentoren 🎓 – schau ins Missionsbrett.',
      'tutorial.skip': 'Tutorial überspringen',
      'tutorial.restart': 'Tutorial neu starten',
      'tutorial.skipAsk': 'Tutorial beenden?',
      'loading.verse1': '„Der HERR ist mein Hirte“ – Psalm 23,1',
      'loading.verse2': '„Bittet, so wird euch gegeben“ – Mt 7,7',
      'loading.verse3': '„Die Wahrheit wird euch frei machen“ – Joh 8,32',
      'loading.verse4': '„Ich vermag alles durch den, der mich mächtig macht, Christus“ – Phil 4,13',
      'loading.verse5': '„Gott ist die Liebe“ – 1 Joh 4,8',
      'keymap.title': 'Tastenbelegung',
      // ── Lern-Missionen (release_roadmap.md §3.9). Verse: Luther 1912 ──
      'lesson.pastoralCare.verse':
          'Der uns tröstet in aller unsrer Trübsal, daß wir auch trösten können, '
          'die da sind in allerlei Trübsal.',
      'lesson.spiritualWarfare.verse':
          'Denn wir haben nicht mit Fleisch und Blut zu kämpfen, sondern mit Fürsten '
          'und Gewaltigen … mit den bösen Geistern unter dem Himmel.',
      'lesson.discernment.verse':
          'Ihr Lieben, glaubet nicht einem jeglichen Geist, sondern prüfet die Geister, '
          'ob sie von Gott sind.',
      'lesson.intercession.verse':
          'So ermahne ich nun, daß man vor allen Dingen zuerst tue Bitte, Gebet, Fürbitte '
          'und Danksagung für alle Menschen.',
      'lesson.fasting.verse':
          'Wenn du aber fastest, so salbe dein Haupt und wasche dein Angesicht, '
          'auf daß du nicht scheinest vor den Leuten mit deinem Fasten.',
      'lesson.preaching.verse':
          'Wie sollen sie aber glauben, von dem sie nichts gehört haben? '
          'Wie sollen sie aber hören ohne Prediger?',
      'lesson.binding.verse':
          'Wahrlich ich sage euch: Was ihr auf Erden binden werdet, '
          'soll auch im Himmel gebunden sein.',
      'lesson.disarming.verse':
          'Und hat ausgezogen die Fürstentümer und die Gewaltigen und sie schaugetragen '
          'öffentlich und einen Triumph aus ihnen gemacht durch sich selbst.',
      'lesson.mastery.liberation.verse':
          'Wen nun der Sohn frei macht, den macht ihr recht frei.',
      'lesson.mastery.rebuke.verse':
          'So seid nun Gott untertänig. Widerstehet dem Teufel, so flieht er von euch.',
      'lesson.mastery.slow.verse':
          'Es kann niemand einem Starken in sein Haus fallen und seinen Hausrat rauben, '
          'es sei denn, daß er zuvor den Starken binde.',
      'lesson.mastery.drain.verse':
          'Sehet, ich habe euch Macht gegeben, zu treten auf Schlangen und Skorpione, '
          'und über alle Gewalt des Feindes.',

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
      'upgrade.shield': 'Shield',
      'upgrade.helm': 'Helmet',
      'upgrade.radius': 'Radius',
      'upgrade.strength': 'Strength',
      'upgrade.duration': 'Duration',
      'upgrade.speed': 'Speed',
      'mode.liberation': 'Liberation',
      'mode.rebuke': 'Rebuke',
      'mode.slow': 'Binding',
      'mode.drain': 'Disarming',
      'resource.provision': 'Provision',
      'resource.faith': 'Faith',
      'resource.supplies': 'Supplies',

      // HUD
      'hud.christians': 'Christians',

      // Tutorial
      'tutorial.goHome.goal': 'Go into your pastor house 🏠',
      'tutorial.goHome.detail': 'Your home is the house with the cross ✝️ on its roof. The cyan ring on the minimap top right shows you the way. Just walk into the door 🚪 – or tap the glowing 🖐️ button in front of the house (or press E).',
      'tutorial.readBible.goal': 'Read the Bible 📖',
      'tutorial.readBible.detail': 'Faith 🙏 is your strength for everything you do. Tap the glowing bookshelf 📖 – the pastor walks over and reads. It fills up your faith.',
      'tutorial.talk.goal': 'Talk to a person',
      'tutorial.talk.detail': 'Go out through the door 🚪 to someone (cyan on the minimap) and tap the glowing 🖐️ button (or press E). Talking 💬 lets you get to know them – every visit makes them more open to God.',
      'tutorial.prayPerson.goal': 'Pray with a person',
      'tutorial.prayPerson.detail': 'The conversation offers 🙏 prayer. Once their faith bar ✝️ is high enough, you can invite them to become a Christian.',
      'tutorial.enterSpirit.goal': 'Enter the invisible world',
      'tutorial.enterSpirit.detail': 'The glowing 🙏 button opens the invisible world (costs 10 🙏). There you see where the city is spiritually dark (red) or light (green).',
      'tutorial.liberate.goal': 'Hold ✝️ and pray',
      'tutorial.liberate.detail': 'While you hold ✝️, prayer waves go out from you and turn red cells green. It costs faith – watch your 🙏.',
      'tutorial.defeatDaemon.goal': 'Defeat a daemon',
      'tutorial.defeatDaemon.detail': 'Daemons 👹 attack you and darken the city. Hit them with prayer waves until they vanish – that gives 📖 insight for upgrades.',
      'tutorial.returnCity.goal': 'Return to the city',
      'tutorial.returnCity.detail': 'Tap 🏙️ to go back. In the city you help people and gather new strength.',
      'tutorial.quarter.goal': 'Win your neighbourhood',
      'tutorial.quarter.detail': 'Under ✝️ you see the neighbourhood bar 🏘️. Once enough people are Christians, you can attack the stronghold 🏰 in the invisible world and awaken the neighbourhood 🔥.',
      'tutorial.mission.goal': 'Accept a mission',
      'tutorial.mission.detail': 'The mission board 📋 hangs in the pastor house 🏠 – it glows, tap it. Then tap 📍 next to a mission, or under 🎓 next to a skill – the map then shows you the way.',
      'tutorial.completed.goal': 'You are ready!',
      'tutorial.completed.detail': 'God bless your service in the city. Mentors 🎓 teach new skills – have a look at the mission board.',
      'tutorial.skip': 'Skip tutorial',
      'tutorial.restart': 'Restart tutorial',
      'tutorial.skipAsk': 'End the tutorial?',
      'loading.verse1': '"The LORD is my shepherd" – Psalm 23:1',
      'loading.verse2': '"Ask, and it shall be given you" – Matthew 7:7',
      'loading.verse3': '"The truth shall make you free" – John 8:32',
      'loading.verse4': '"I can do all things through Christ" – Philippians 4:13',
      'loading.verse5': '"God is love" – 1 John 4:8',
      'keymap.title': 'Key bindings',
      // ── Learning missions (release_roadmap.md §3.9). Verses: KJV ──
      'lesson.pastoralCare.verse':
          'Who comforteth us in all our tribulation, that we may be able to comfort '
          'them which are in any trouble.',
      'lesson.spiritualWarfare.verse':
          'For we wrestle not against flesh and blood, but against principalities, '
          'against powers … against spiritual wickedness in high places.',
      'lesson.discernment.verse':
          'Beloved, believe not every spirit, but try the spirits whether they are of God.',
      'lesson.intercession.verse':
          'I exhort therefore, that, first of all, supplications, prayers, intercessions, '
          'and giving of thanks, be made for all men.',
      'lesson.fasting.verse':
          'But thou, when thou fastest, anoint thine head, and wash thy face; '
          'that thou appear not unto men to fast.',
      'lesson.preaching.verse':
          'How shall they believe in him of whom they have not heard? '
          'and how shall they hear without a preacher?',
      'lesson.binding.verse':
          'Verily I say unto you, Whatsoever ye shall bind on earth '
          'shall be bound in heaven.',
      'lesson.disarming.verse':
          'And having spoiled principalities and powers, he made a shew of them openly, '
          'triumphing over them in it.',
      'lesson.mastery.liberation.verse':
          'If the Son therefore shall make you free, ye shall be free indeed.',
      'lesson.mastery.rebuke.verse':
          'Submit yourselves therefore to God. Resist the devil, and he will flee from you.',
      'lesson.mastery.slow.verse':
          'No man can enter into a strong man\'s house, and spoil his goods, '
          'except he will first bind the strong man.',
      'lesson.mastery.drain.verse':
          'Behold, I give unto you power to tread on serpents and scorpions, '
          'and over all the power of the enemy.',

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
