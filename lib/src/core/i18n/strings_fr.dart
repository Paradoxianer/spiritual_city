/// French UI strings (see AppStrings); missing keys fall back to English.
/// Bible verses: Louis Segond 1910 (public domain).
const Map<String, String> stringsFr = {
  // Main Menu
  'menu.title': 'SpiritWorld City',
  'menu.newGame': 'Nouvelle partie',
  'menu.loadGame': 'Charger une partie',
  'menu.settings': 'Paramètres',
  'menu.quit': 'Quitter',
  'menu.subtitle': 'Psaume 27,4',

  // Difficulty
  'difficulty.title': 'Choisis ton chemin',
  'difficulty.easy': 'Facile',
  'difficulty.normal': 'Normal',
  'difficulty.hard': 'Difficile',
  'difficulty.easy.verse': '« L’Éternel combattra pour vous. »',
  'difficulty.normal.verse': '« Nous marchons par la foi. »',
  'difficulty.hard.verse': '« Souffre avec moi, comme un bon soldat. »',
  'difficulty.easy.desc': 'Opposition −30 %, foi régénérée +50 %',
  'difficulty.normal.desc': 'Jeu équilibré',
  'difficulty.hard.desc': 'Opposition +30 %, chemin plus dur',
  'difficulty.start': 'Commencer',
  'difficulty.back': 'Retour',
  'difficulty.seed': 'Graine',
  'difficulty.seed.hint': 'aléatoire',

  // Load Game
  'loadGame.title': 'Charger une partie',
  'loadGame.empty': 'Aucune partie sauvegardée',
  'loadGame.back': 'Retour',
  'loadGame.delete': 'Supprimer',
  'loadGame.load': 'Charger',
  'loadGame.lastPlayed': 'Dernière partie',
  'loadGame.rename': 'Renommer',
  'loadGame.rename.title': 'Renommer la partie',
  'loadGame.rename.hint': 'Nouveau nom',
  'loadGame.rename.confirm': 'Renommer',
  'loadGame.rename.cancel': 'Annuler',

  // In-game
  'game.saveQuit': 'Sauvegarder et quitter',
  'game.saveName.prefix': 'Partie',

  // Pause menu
  'game.pause.button': 'Pause',
  'game.pause.title': 'Pause',
  'game.pause.resume': 'Reprendre',
  'game.pause.help': 'Aide',
  'game.pause.save': 'Sauvegarder',
  'game.pause.saved': 'Sauvegardé ✓',
  'game.pause.quit': 'Sauvegarder et quitter',
  'game.pause.quitConfirm.title': 'Sauvegarder et quitter ?',
  'game.pause.quitConfirm.body': 'Ta progression sera sauvegardée et tu reviendras au menu principal.',
  'game.pause.quitConfirm.confirm': 'Quitter',
  'game.pause.quitConfirm.cancel': 'Annuler',

  // Settings
  'settings.title': 'Paramètres',
  'settings.back': 'Retour',

  // Common
  'common.language': 'Langue',

  // NPC Dialog
  'dialog.talk': 'Parler',
  'dialog.pray': 'Prier',
  'dialog.help': 'Aider',
  'dialog.convert': 'Conversion',
  'dialog.farewell': '👋 Au revoir',
  'dialog.goodbye': '👋 Au revoir !',
  'dialog.conversation': 'Discussion',

  // Resources
  'resource.health': 'Santé',
  'upgrade.shield': 'Bouclier',
  'upgrade.helm': 'Casque',
  'upgrade.radius': 'Rayon',
  'upgrade.strength': 'Force',
  'upgrade.duration': 'Durée',
  'upgrade.speed': 'Vitesse',
  'mode.liberation': 'Libération',
  'mode.rebuke': 'Repousser',
  'mode.slow': 'Lier',
  'mode.drain': 'Désarmer',
  'resource.provision': 'Provisions',
  'resource.faith': 'Foi',
  'resource.supplies': 'Matériel',

  // HUD
  'hud.christians': 'Chrétiens',

  // Tutorial
  'tutorial.goHome.goal': 'Entre dans ta maison pastorale 🏠',
  'tutorial.goHome.detail':
      'Ta maison, c’est le poste : la maison avec le bouclier rouge 🛡️ sur le toit. L’anneau turquoise sur la mini-carte, en haut à droite, te montre le chemin. Entre simplement par la porte 🚪 – ou touche le bouton lumineux 🖐️ devant la maison (touche E).',
  'tutorial.readBible.goal': 'Lis la Bible 📖',
  'tutorial.readBible.detail':
      'La foi 🙏 est ta force pour tout ce que tu fais. Touche l’étagère lumineuse 📖 – le pasteur s’y rend et lit. Cela remplit ta foi.',
  'tutorial.talk.goal': 'Parle à quelqu’un',
  'tutorial.talk.detail':
      'Sors par la porte 🚪 vers quelqu’un (turquoise sur la mini-carte) et touche le bouton lumineux 🖐️ (touche E). En discutant 💬, vous faites connaissance – chaque visite ouvre davantage cette personne à Dieu.',
  'tutorial.prayPerson.goal': 'Prie avec quelqu’un',
  'tutorial.prayPerson.detail':
      'La discussion propose 🙏 la prière. Quand sa barre de foi ✝️ est assez haute, tu peux l’inviter à devenir chrétien.',
  'tutorial.enterSpirit.goal': 'Entre dans le monde invisible',
  'tutorial.enterSpirit.detail':
      'Le bouton lumineux 🙏 ouvre le monde invisible (coûte 10 🙏). Tu y vois où la ville est spirituellement sombre (rouge) ou lumineuse (verte).',
  'tutorial.liberate.goal': 'Maintiens ✝️ et prie',
  'tutorial.liberate.detail':
      'Tant que tu maintiens ✝️, des ondes de prière partent de toi et rendent vertes les cases rouges. Cela coûte de la foi – surveille ton 🙏.',
  'tutorial.defeatDaemon.goal': 'Vaincs un démon',
  'tutorial.defeatDaemon.detail':
      'Les démons 👹 t’attaquent et assombrissent la ville. Touche-les avec des ondes de prière jusqu’à ce qu’ils disparaissent – cela donne de la sagesse 📖 pour des améliorations.',
  'tutorial.returnCity.goal': 'Retourne en ville',
  'tutorial.returnCity.detail':
      'Touche 🏙️ pour revenir. En ville, tu aides les gens et reprends des forces.',
  'tutorial.quarter.goal': 'Gagne ton quartier',
  'tutorial.quarter.detail':
      'Sous ✝️, tu vois deux fines lignes : celle du haut est ton quartier, celle du bas toute la ville. Quand assez de gens sont chrétiens, tu peux attaquer la forteresse 🏰 dans le monde invisible et réveiller le quartier 🔥.',
  'tutorial.mission.goal': 'Accepte une mission',
  'tutorial.mission.detail':
      'Le tableau des missions 📋 est dans la maison pastorale 🏠 – il brille, touche-le. Puis touche 📍 à côté d’une mission, ou sous 🎓 à côté d’une capacité – la carte te montre alors le chemin.',
  'tutorial.completed.goal': 'Tu es prêt !',
  'tutorial.completed.detail':
      'Que Dieu bénisse ton service dans la ville. Les mentors 🎓 enseignent de nouvelles capacités – jette un œil au tableau des missions.',
  'tutorial.skip': 'Passer le tutoriel',
  'tutorial.restart': 'Recommencer le tutoriel',
  'tutorial.skipAsk': 'Terminer le tutoriel ?',
  'loading.verse1': '« L’Éternel est mon berger » – Psaume 23,1',
  'loading.verse2': '« Demandez, et l’on vous donnera » – Matthieu 7,7',
  'loading.verse3': '« La vérité vous affranchira » – Jean 8,32',
  'loading.verse4': '« Je puis tout par celui qui me fortifie » – Philippiens 4,13',
  'loading.verse5': '« Dieu est amour » – 1 Jean 4,8',
  'lesson.study': 'Étudier',
  'keymap.title': 'Touches',

  // Lessons – Louis Segond 1910
  'lesson.pastoralCare.verse':
      'Qui nous console dans toutes nos afflictions, afin que, par la consolation dont nous sommes l’objet de la part de Dieu, nous puissions consoler ceux qui se trouvent dans quelque affliction !',
  'lesson.spiritualWarfare.verse':
      'Car nous n’avons pas à lutter contre la chair et le sang, mais contre les dominations, contre les autorités … contre les esprits méchants dans les lieux célestes.',
  'lesson.discernment.verse':
      'Bien-aimés, n’ajoutez pas foi à tout esprit ; mais éprouvez les esprits, pour savoir s’ils sont de Dieu.',
  'lesson.intercession.verse':
      'J’exhorte donc, avant toutes choses, à faire des prières, des supplications, des requêtes, des actions de grâces, pour tous les hommes.',
  'lesson.fasting.verse':
      'Mais quand tu jeûnes, parfume ta tête et lave ton visage, afin de ne pas montrer aux hommes que tu jeûnes.',
  'lesson.preaching.verse':
      'Comment croiront-ils en celui dont ils n’ont pas entendu parler ? Et comment en entendront-ils parler, s’il n’y a personne qui prêche ?',
  'lesson.binding.verse':
      'Je vous le dis en vérité, tout ce que vous lierez sur la terre sera lié dans le ciel.',
  'lesson.disarming.verse':
      'Il a dépouillé les dominations et les autorités, et les a livrées publiquement en spectacle, en triomphant d’elles par la croix.',
  'lesson.mastery.liberation.verse':
      'Si donc le Fils vous affranchit, vous serez réellement libres.',
  'lesson.mastery.rebuke.verse':
      'Soumettez-vous donc à Dieu ; résistez au diable, et il fuira loin de vous.',
  'lesson.mastery.slow.verse':
      'Personne ne peut entrer dans la maison d’un homme fort et piller ses biens, sans avoir auparavant lié cet homme fort.',
  'lesson.mastery.drain.verse':
      'Voici, je vous ai donné le pouvoir de marcher sur les serpents et les scorpions, et sur toute la puissance de l’ennemi.',
};
