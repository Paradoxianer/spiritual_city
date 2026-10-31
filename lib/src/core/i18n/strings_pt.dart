/// Portuguese (Brazil) UI strings (see AppStrings); missing keys fall back
/// to English. Bible verses: Almeida Revista e Corrigida (public domain).
const Map<String, String> stringsPt = {
  // Main Menu
  'menu.title': 'SpiritWorld City',
  'menu.newGame': 'Novo jogo',
  'menu.loadGame': 'Carregar jogo',
  'menu.settings': 'Configurações',
  'menu.quit': 'Sair',
  'menu.subtitle': 'Salmos 27:4',

  // Difficulty
  'difficulty.title': 'Escolha seu caminho',
  'difficulty.easy': 'Fácil',
  'difficulty.normal': 'Normal',
  'difficulty.hard': 'Difícil',
  'difficulty.easy.verse': '“O Senhor pelejará por vós.”',
  'difficulty.normal.verse': '“Andamos por fé.”',
  'difficulty.hard.verse': '“Sofre as aflições como bom soldado.”',
  'difficulty.easy.desc': 'Oposição −30%, fé se regenera +50%',
  'difficulty.normal.desc': 'Jogo equilibrado',
  'difficulty.hard.desc': 'Oposição +30%, caminho mais duro',
  'difficulty.start': 'Começar',
  'difficulty.back': 'Voltar',
  'difficulty.seed': 'Semente',
  'difficulty.seed.hint': 'aleatória',

  // Load Game
  'loadGame.title': 'Carregar jogo',
  'loadGame.empty': 'Nenhum jogo salvo',
  'loadGame.back': 'Voltar',
  'loadGame.delete': 'Apagar',
  'loadGame.load': 'Carregar',
  'loadGame.lastPlayed': 'Última vez',
  'loadGame.rename': 'Renomear',
  'loadGame.rename.title': 'Renomear jogo',
  'loadGame.rename.hint': 'Novo nome',
  'loadGame.rename.confirm': 'Renomear',
  'loadGame.rename.cancel': 'Cancelar',

  // In-game
  'game.saveQuit': 'Salvar e sair',
  'game.saveName.prefix': 'Jogo',

  // Pause menu
  'game.pause.button': 'Pausa',
  'game.pause.title': 'Pausa',
  'game.pause.resume': 'Continuar',
  'game.pause.help': 'Ajuda',
  'game.pause.save': 'Salvar',
  'game.pause.saved': 'Salvo ✓',
  'game.pause.quit': 'Salvar e sair',
  'game.pause.quitConfirm.title': 'Salvar e sair?',
  'game.pause.quitConfirm.body': 'Seu progresso será salvo e você voltará ao menu principal.',
  'game.pause.quitConfirm.confirm': 'Sair',
  'game.pause.quitConfirm.cancel': 'Cancelar',

  // Settings
  'settings.title': 'Configurações',
  'settings.back': 'Voltar',

  // Common
  'common.language': 'Idioma',

  // NPC Dialog
  'dialog.talk': 'Conversar',
  'dialog.pray': 'Orar',
  'dialog.help': 'Ajudar',
  'dialog.convert': 'Conversão',
  'dialog.farewell': '👋 Tchau',
  'dialog.goodbye': '👋 Tchau!',
  'dialog.conversation': 'Conversa',

  // Resources
  'resource.health': 'Saúde',
  'upgrade.shield': 'Escudo',
  'upgrade.helm': 'Capacete',
  'upgrade.radius': 'Raio',
  'upgrade.strength': 'Força',
  'upgrade.duration': 'Duração',
  'upgrade.speed': 'Velocidade',
  'mode.liberation': 'Libertação',
  'mode.rebuke': 'Repreender',
  'mode.slow': 'Amarrar',
  'mode.drain': 'Desarmar',
  'resource.provision': 'Provisões',
  'resource.faith': 'Fé',
  'resource.supplies': 'Materiais',

  // HUD
  'hud.christians': 'Cristãos',

  // Tutorial
  'tutorial.goHome.goal': 'Entre na sua casa pastoral 🏠',
  'tutorial.goHome.detail':
      'Seu lar é o corpo (a igreja local): a casa com o escudo vermelho 🛡️ no telhado. O anel turquesa no minimapa, em cima à direita, mostra o caminho. É só entrar pela porta 🚪 – ou tocar no botão brilhante 🖐️ em frente à casa (tecla E).',
  'tutorial.readBible.goal': 'Leia a Bíblia 📖',
  'tutorial.readBible.detail':
      'A fé 🙏 é sua força para tudo o que você faz. Toque na estante brilhante 📖 – o pastor vai até lá e lê. Isso enche sua fé.',
  'tutorial.talk.goal': 'Converse com uma pessoa',
  'tutorial.talk.detail':
      'Saia pela porta 🚪 até alguém (turquesa no minimapa) e toque no botão brilhante 🖐️ (tecla E). Conversando 💬 vocês se conhecem – cada visita a deixa mais aberta para Deus.',
  'tutorial.prayPerson.goal': 'Ore com uma pessoa',
  'tutorial.prayPerson.detail':
      'Na conversa há 🙏 a oração. Quando a barra de fé ✝️ estiver alta o suficiente, você pode convidá-la a se tornar cristã.',
  'tutorial.enterSpirit.goal': 'Entre no mundo invisível',
  'tutorial.enterSpirit.detail':
      'O botão brilhante 🙏 abre o mundo invisível (custa 10 🙏). Lá você vê onde a cidade está espiritualmente escura (vermelho) ou iluminada (verde).',
  'tutorial.liberate.goal': 'Segure ✝️ e ore',
  'tutorial.liberate.detail':
      'Enquanto você segura ✝️, ondas de oração saem de você e deixam verdes as casas vermelhas. Custa fé – fique de olho no seu 🙏.',
  'tutorial.defeatDaemon.goal': 'Vença um demônio',
  'tutorial.defeatDaemon.detail':
      'Os demônios 👹 atacam você e escurecem a cidade. Atinja-os com ondas de oração até sumirem – isso dá sabedoria 📖 para melhorias.',
  'tutorial.returnCity.goal': 'Volte para a cidade',
  'tutorial.returnCity.detail':
      'Toque em 🏙️ para voltar. Na cidade você ajuda as pessoas e recupera as forças.',
  'tutorial.quarter.goal': 'Ganhe seu bairro',
  'tutorial.quarter.detail':
      'Sob ✝️ você vê duas linhas finas: a de cima é seu bairro, a de baixo a cidade inteira. Quando houver cristãos suficientes, você pode atacar a fortaleza 🏰 no mundo invisível e despertar o bairro 🔥.',
  'tutorial.mission.goal': 'Aceite uma missão',
  'tutorial.mission.detail':
      'O quadro de missões 📋 fica na casa pastoral 🏠 – ele brilha, toque nele. Depois toque em 📍 ao lado de uma missão, ou em 🎓 ao lado de uma habilidade – o mapa mostra o caminho.',
  'tutorial.completed.goal': 'Você está pronto!',
  'tutorial.completed.detail':
      'Deus abençoe seu serviço na cidade. Os mentores 🎓 ensinam novas habilidades – dê uma olhada no quadro de missões.',
  'tutorial.skip': 'Pular tutorial',
  'tutorial.restart': 'Reiniciar tutorial',
  'tutorial.skipAsk': 'Encerrar o tutorial?',
  'loading.verse1': '“O Senhor é o meu pastor” – Salmos 23:1',
  'loading.verse2': '“Pedi, e dar-se-vos-á” – Mateus 7:7',
  'loading.verse3': '“A verdade vos libertará” – João 8:32',
  'loading.verse4': '“Posso todas as coisas naquele que me fortalece” – Filipenses 4:13',
  'loading.verse5': '“Deus é amor” – 1 João 4:8',
  'keymap.title': 'Teclas',

  // Lessons – Almeida Revista e Corrigida
  'lesson.pastoralCare.verse':
      'Que nos consola em toda a nossa tribulação, para que também possamos consolar os que estiverem em alguma tribulação.',
  'lesson.spiritualWarfare.verse':
      'Porque não temos que lutar contra carne e sangue, mas, sim, contra os principados, contra as potestades … contra as hostes espirituais da maldade, nos lugares celestiais.',
  'lesson.discernment.verse':
      'Amados, não creiais em todo espírito, mas provai se os espíritos são de Deus.',
  'lesson.intercession.verse':
      'Admoesto-te, pois, antes de tudo, que se façam deprecações, orações, intercessões e ações de graças por todos os homens.',
  'lesson.fasting.verse':
      'Porém tu, quando jejuares, unge a tua cabeça e lava o teu rosto, para não pareceres aos homens que jejuas.',
  'lesson.preaching.verse':
      'Como, pois, invocarão aquele em quem não creram? E como crerão naquele de quem não ouviram? E como ouvirão, se não há quem pregue?',
  'lesson.binding.verse':
      'Em verdade vos digo que tudo o que ligardes na terra será ligado no céu.',
  'lesson.disarming.verse':
      'E, despojando os principados e potestades, os expôs publicamente e deles triunfou em si mesmo.',
  'lesson.mastery.liberation.verse':
      'Se, pois, o Filho vos libertar, verdadeiramente sereis livres.',
  'lesson.mastery.rebuke.verse':
      'Sujeitai-vos, pois, a Deus; resisti ao diabo, e ele fugirá de vós.',
  'lesson.mastery.slow.verse':
      'Ninguém pode roubar os bens do valente, entrando-lhe em casa, se primeiro não manietar o valente.',
  'lesson.mastery.drain.verse':
      'Eis que vos dou poder para pisar serpentes, e escorpiões, e toda a força do Inimigo.',
};
