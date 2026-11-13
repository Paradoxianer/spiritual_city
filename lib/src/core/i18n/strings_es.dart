/// Spanish UI strings (see AppStrings); missing keys fall back to English.
/// Bible verses: Reina-Valera 1909 (public domain).
const Map<String, String> stringsEs = {
  // Main Menu
  'menu.title': 'SpiritWorld City',
  'menu.newGame': 'Nueva partida',
  'menu.loadGame': 'Cargar partida',
  'menu.settings': 'Ajustes',
  'menu.quit': 'Salir',
  'menu.subtitle': 'Salmos 27:4',

  // Difficulty
  'difficulty.title': 'Elige tu camino',
  'difficulty.easy': 'Fácil',
  'difficulty.normal': 'Normal',
  'difficulty.hard': 'Difícil',
  'difficulty.easy.verse': '«Jehová peleará por vosotros.»',
  'difficulty.normal.verse': '«Por fe andamos.»',
  'difficulty.hard.verse': '«Sufre trabajos como fiel soldado.»',
  'difficulty.easy.desc': 'Oposición −30 %, fe se regenera +50 %',
  'difficulty.normal.desc': 'Juego equilibrado',
  'difficulty.hard.desc': 'Oposición +30 %, camino más duro',
  'difficulty.start': 'Empezar',
  'difficulty.back': 'Atrás',
  'difficulty.seed': 'Semilla',
  'difficulty.seed.hint': 'aleatoria',

  // Load Game
  'loadGame.title': 'Cargar partida',
  'loadGame.empty': 'No hay partidas guardadas',
  'loadGame.back': 'Atrás',
  'loadGame.delete': 'Borrar',
  'loadGame.load': 'Cargar',
  'loadGame.lastPlayed': 'Última vez',
  'loadGame.rename': 'Renombrar',
  'loadGame.rename.title': 'Renombrar partida',
  'loadGame.rename.hint': 'Nuevo nombre',
  'loadGame.rename.confirm': 'Renombrar',
  'loadGame.rename.cancel': 'Cancelar',
  'loadGame.export': 'Guardar / compartir como archivo',
  'loadGame.import': 'Cargar partida desde un archivo',
  'loadGame.imported': 'Partida importada',
  'loadGame.importFailed': 'Este archivo no es una partida (o es de una versión más nueva)',

  // In-game
  'game.saveQuit': 'Guardar y salir',
  'game.saveName.prefix': 'Partida',

  // Pause menu
  'game.pause.button': 'Pausa',
  'game.pause.title': 'Pausa',
  'game.pause.resume': 'Continuar',
  'game.pause.help': 'Ayuda',
  'share.title': 'Construyendo iglesia en SpiritWorld City – día {day}',
  'share.converted': 'personas encontraron a Jesús',
  'share.church': 'en mi iglesia',
  'share.awakened': 'barrios despertados',
  'share.prayedFree': 'barrios liberados por la oración',
  'share.play': 'Juega tú también:',
  'game.pause.save': 'Guardar',
  'game.pause.saved': 'Guardado ✓',
  'game.pause.quit': 'Guardar y salir',
  'game.pause.quitConfirm.title': '¿Guardar y salir?',
  'game.pause.quitConfirm.body': 'Tu progreso se guardará y volverás al menú principal.',
  'game.pause.quitConfirm.confirm': 'Salir',
  'game.pause.quitConfirm.cancel': 'Cancelar',

  // Settings
  'settings.title': 'Ajustes',
  'settings.back': 'Atrás',

  // Common
  'common.language': 'Idioma',

  // NPC Dialog
  'dialog.talk': 'Hablar',
  'dialog.pray': 'Orar',
  'dialog.help': 'Ayudar',
  'dialog.convert': 'Conversión',
  'dialog.farewell': '👋 Adiós',
  'dialog.goodbye': '👋 ¡Adiós!',
  'dialog.conversation': 'Charla',

  // Resources
  'resource.health': 'Salud',
  'upgrade.shield': 'Escudo',
  'upgrade.helm': 'Yelmo',
  'upgrade.radius': 'Radio',
  'upgrade.strength': 'Fuerza',
  'upgrade.duration': 'Duración',
  'upgrade.speed': 'Velocidad',
  'mode.liberation': 'Liberación',
  'mode.rebuke': 'Reprender',
  'mode.slow': 'Atar',
  'mode.drain': 'Desarmar',
  'resource.provision': 'Provisiones',
  'resource.faith': 'Fe',
  'resource.supplies': 'Materiales',

  // HUD
  'hud.christians': 'Cristianos',

  // Tutorial
  'tutorial.goHome.goal': 'Entra en tu casa pastoral 🏠',
  'tutorial.goHome.detail':
      'Tu hogar es el cuerpo (la iglesia local): la casa con el escudo rojo 🛡️ en el tejado. El anillo turquesa del minimapa, arriba a la derecha, te muestra el camino. Entra por la puerta 🚪, o toca el botón brillante 🖐️ delante de la casa (tecla E).',
  'tutorial.readBible.goal': 'Lee la Biblia 📖',
  'tutorial.readBible.detail':
      'La fe 🙏 es tu fuerza para todo lo que haces. Toca la estantería brillante 📖: el pastor va y lee. Eso llena tu fe.',
  'tutorial.talk.goal': 'Habla con una persona',
  'tutorial.talk.detail':
      'Sal por la puerta 🚪 hacia alguien (turquesa en el minimapa) y toca el botón brillante 🖐️ (tecla E). Al conversar 💬 os conocéis: cada visita lo abre más a Dios.',
  'tutorial.prayPerson.goal': 'Ora con una persona',
  'tutorial.prayPerson.detail':
      'En la conversación tienes 🙏 la oración. Cuando su barra de fe ✝️ esté bastante alta, puedes invitarla a hacerse cristiana.',
  'tutorial.enterSpirit.goal': 'Entra en el mundo invisible',
  'tutorial.enterSpirit.detail':
      'El botón brillante 🙏 abre el mundo invisible (cuesta 10 🙏). Allí ves dónde la ciudad está espiritualmente oscura (rojo) o iluminada (verde).',
  'tutorial.liberate.goal': 'Mantén ✝️ y ora',
  'tutorial.liberate.detail':
      'Mientras mantienes ✝️, salen de ti ondas de oración que vuelven verdes las casillas rojas. Cuesta fe: vigila tu 🙏.',
  'tutorial.defeatDaemon.goal': 'Vence a un demonio',
  'tutorial.defeatDaemon.detail':
      'Los demonios 👹 te atacan y oscurecen la ciudad. Alcánzalos con ondas de oración hasta que desaparezcan: te dan 📖 sabiduría para mejoras.',
  'tutorial.returnCity.goal': 'Vuelve a la ciudad',
  'tutorial.returnCity.detail':
      'Toca 🏙️ para volver. En la ciudad ayudas a la gente y recuperas fuerzas.',
  'tutorial.quarter.goal': 'Gana tu barrio',
  'tutorial.quarter.detail':
      'Bajo ✝️ ves dos líneas finas: la de arriba es tu barrio, la de abajo toda la ciudad. Cuando haya suficientes cristianos, puedes atacar la fortaleza 🏰 en el mundo invisible y despertar el barrio 🔥.',
  'tutorial.mission.goal': 'Acepta una misión',
  'tutorial.mission.detail':
      'El tablón de misiones 📋 está en la casa pastoral 🏠: brilla, tócalo. Luego toca 📍 junto a una misión, o bajo 🎓 junto a una habilidad: el mapa te mostrará el camino.',
  'tutorial.completed.goal': '¡Estás listo!',
  'tutorial.completed.detail':
      'Dios bendiga tu servicio en la ciudad. Los mentores 🎓 enseñan nuevas habilidades: echa un vistazo al tablón de misiones.',
  'tutorial.skip': 'Saltar tutorial',
  'tutorial.restart': 'Reiniciar tutorial',
  'tutorial.skipAsk': '¿Terminar el tutorial?',
  'loading.verse1': '«Jehová es mi pastor» – Salmos 23:1',
  'loading.verse2': '«Pedid, y se os dará» – Mateo 7:7',
  'loading.verse3': '«La verdad os libertará» – Juan 8:32',
  'loading.verse4': '«Todo lo puedo en Cristo» – Filipenses 4:13',
  'loading.verse5': '«Dios es amor» – 1 Juan 4:8',
  'keymap.title': 'Teclas',

  // Lessons – Reina-Valera 1909
  'lesson.pastoralCare.verse':
      'El cual nos consuela en todas nuestras tribulaciones, para que podamos también nosotros consolar a los que están en cualquiera angustia.',
  'lesson.spiritualWarfare.verse':
      'Porque no tenemos lucha contra sangre y carne; sino contra principados, contra potestades … contra malicias espirituales en los aires.',
  'lesson.discernment.verse':
      'Amados, no creáis a todo espíritu, sino probad los espíritus si son de Dios.',
  'lesson.intercession.verse':
      'Amonesto pues, ante todas cosas, que se hagan rogativas, oraciones, peticiones, hacimientos de gracias, por todos los hombres.',
  'lesson.fasting.verse':
      'Mas tú, cuando ayunas, unge tu cabeza y lava tu rostro; para no parecer a los hombres que ayunas.',
  'lesson.preaching.verse':
      '¿Cómo creerán a aquel de quien no han oído? ¿Y cómo oirán sin haber quien les predique?',
  'lesson.binding.verse':
      'De cierto os digo que todo lo que ligareis en la tierra, será ligado en el cielo.',
  'lesson.disarming.verse':
      'Y despojando los principados y las potestades, sacólos á la vergüenza en público, triunfando de ellos en sí mismo.',
  'lesson.mastery.liberation.verse':
      'Así que, si el Hijo os libertare, seréis verdaderamente libres.',
  'lesson.mastery.rebuke.verse':
      'Someteos pues a Dios; resistid al diablo, y de vosotros huirá.',
  'lesson.mastery.slow.verse':
      'Nadie puede saquear las alhajas del valiente entrando en su casa, si primero no atare al valiente.',
  'lesson.mastery.drain.verse':
      'He aquí os doy potestad de hollar sobre las serpientes y sobre los escorpiones, y sobre toda fuerza del enemigo.',
};
