import '../models/cell_object.dart';
import 'help_content.dart';

/// What the narrator says when the pastor comes near something (or taps
/// an upgrade) – playtest 2026-10-31. Five languages.
abstract final class NearTexts {
  static const Map<BuildingType, Tr> buildings = {
    BuildingType.house: Tr(
      'Ein Wohnhaus. Hier wohnen Familien – du kannst praktisch helfen, für das Haus beten und Besuche machen. Wohnt hier ein Christ, kannst du einen Hauskreis gründen.',
      'A house. Families live here – you can help in practical ways, pray for the home and visit. If a Christian lives here, you can start a home group.',
      es: 'Una casa. Aquí viven familias: puedes ayudar de forma práctica, orar por la casa y hacer visitas. Si vive un cristiano, puedes empezar un grupo en casa.',
      fr: 'Une maison. Des familles y habitent – tu peux aider concrètement, prier pour la maison et faire des visites. Si un chrétien y habite, tu peux lancer un groupe de maison.',
      pt: 'Uma casa. Aqui moram famílias – você pode ajudar na prática, orar pela casa e fazer visitas. Se um cristão mora aqui, você pode começar um grupo nos lares.',
    ),
    BuildingType.apartment: Tr(
      'Ein Wohnblock mit vielen Haushalten. Ein Segen erreicht hier viele Menschen auf einmal.',
      'An apartment block with many households. A blessing here reaches many people at once.',
      es: 'Un bloque de pisos con muchos hogares. Una bendición aquí llega a muchas personas a la vez.',
      fr: 'Un immeuble avec de nombreux foyers. Une bénédiction ici touche beaucoup de gens à la fois.',
      pt: 'Um prédio com muitos lares. Uma bênção aqui alcança muitas pessoas de uma vez.',
    ),
    BuildingType.pastorHouse: Tr(
      'Dein Zuhause, das Korps. Hier liest du Bibel, betest, isst und schläfst – und findest das Missionsbrett und die Ausrüstung für deine Gebete.',
      'Your home, the corps. Here you read the Bible, pray, eat and sleep – and find the mission board and the equipment for your prayers.',
      es: 'Tu hogar, el cuerpo. Aquí lees la Biblia, oras, comes y duermes, y encuentras el tablón de misiones y el equipo para tus oraciones.',
      fr: 'Ta maison, le poste. Ici tu lis la Bible, pries, manges et dors – et tu trouves le tableau des missions et l’équipement pour tes prières.',
      pt: 'Seu lar, o corpo. Aqui você lê a Bíblia, ora, come e dorme – e encontra o quadro de missões e o equipamento para suas orações.',
    ),
    BuildingType.shop: Tr(
      'Ein Laden. Sprich mit den Inhabern, segne das Geschäft oder bitte um Spenden.',
      'A shop. Talk to the owners, bless the business or ask for donations.',
      es: 'Una tienda. Habla con los dueños, bendice el negocio o pide donativos.',
      fr: 'Une boutique. Parle aux propriétaires, bénis le commerce ou demande des dons.',
      pt: 'Uma loja. Fale com os donos, abençoe o negócio ou peça doações.',
    ),
    BuildingType.supermarket: Tr(
      'Ein Supermarkt. Hier kaufst du ein und füllst deinen Vorrat (🍞) auf.',
      'A supermarket. Here you shop and refill your provisions (🍞).',
      es: 'Un supermercado. Aquí compras y repones tus provisiones (🍞).',
      fr: 'Un supermarché. Ici tu fais les courses et refais tes provisions (🍞).',
      pt: 'Um supermercado. Aqui você faz compras e repõe suas provisões (🍞).',
    ),
    BuildingType.mall: Tr(
      'Ein Einkaufszentrum voller Menschen – ein guter Ort, um Gutes zu tun und ins Gespräch zu kommen.',
      'A mall full of people – a good place to do good and start conversations.',
      es: 'Un centro comercial lleno de gente: un buen lugar para hacer el bien y conversar.',
      fr: 'Un centre commercial plein de monde – un bon endroit pour faire le bien et engager la conversation.',
      pt: 'Um shopping cheio de gente – um bom lugar para fazer o bem e puxar conversa.',
    ),
    BuildingType.office: Tr(
      'Ein Bürogebäude. Hier arbeiten viele – ein Gespräch mit der Leitung öffnet Türen.',
      'An office building. Many work here – a talk with the management opens doors.',
      es: 'Un edificio de oficinas. Aquí trabajan muchos: hablar con la dirección abre puertas.',
      fr: 'Un immeuble de bureaux. Beaucoup y travaillent – parler à la direction ouvre des portes.',
      pt: 'Um prédio de escritórios. Muitos trabalham aqui – conversar com a direção abre portas.',
    ),
    BuildingType.skyscraper: Tr(
      'Ein Hochhaus – viele Menschen auf engem Raum, die oft einsam sind.',
      'A skyscraper – many people in a small space, often lonely.',
      es: 'Un rascacielos: mucha gente en poco espacio, a menudo sola.',
      fr: 'Un gratte-ciel – beaucoup de gens dans peu d’espace, souvent seuls.',
      pt: 'Um arranha-céu – muitas pessoas em pouco espaço, muitas vezes sozinhas.',
    ),
    BuildingType.factory: Tr(
      'Eine Fabrik. Arbeite eine Schicht mit (📦) oder bete für die Sicherheit der Arbeiter.',
      'A factory. Work a shift (📦) or pray for the workers\' safety.',
      es: 'Una fábrica. Trabaja un turno (📦) u ora por la seguridad de los trabajadores.',
      fr: 'Une usine. Fais une équipe (📦) ou prie pour la sécurité des ouvriers.',
      pt: 'Uma fábrica. Trabalhe um turno (📦) ou ore pela segurança dos trabalhadores.',
    ),
    BuildingType.warehouse: Tr(
      'Eine Lagerhalle. Hier gibt es Arbeit – und Material (📦) für deinen Dienst.',
      'A warehouse. There is work here – and supplies (📦) for your service.',
      es: 'Un almacén. Aquí hay trabajo, y materiales (📦) para tu servicio.',
      fr: 'Un entrepôt. Il y a du travail ici – et du matériel (📦) pour ton service.',
      pt: 'Um armazém. Aqui há trabalho – e materiais (📦) para o seu serviço.',
    ),
    BuildingType.trainStation: Tr(
      'Der Bahnhof. Mit dem Zug kommst du schnell in andere Teile der Stadt.',
      'The train station. By train you quickly reach other parts of the city.',
      es: 'La estación de tren. En tren llegas rápido a otras partes de la ciudad.',
      fr: 'La gare. En train, tu rejoins vite d’autres quartiers.',
      pt: 'A estação de trem. De trem você chega rápido a outras partes da cidade.',
    ),
    BuildingType.policeStation: Tr(
      'Die Polizei. Segne die, die für Sicherheit sorgen – das ganze Viertel profitiert.',
      'The police station. Bless those who keep people safe – the whole quarter benefits.',
      es: 'La comisaría. Bendice a quienes cuidan la seguridad: todo el barrio se beneficia.',
      fr: 'Le commissariat. Bénis ceux qui veillent sur la sécurité – tout le quartier en profite.',
      pt: 'A delegacia. Abençoe quem cuida da segurança – todo o bairro se beneficia.',
    ),
    BuildingType.fireStation: Tr(
      'Die Feuerwehr. Segne Fahrzeuge und Mannschaft und begleite sie nach schweren Einsätzen.',
      'The fire station. Bless the vehicles and the crew and support them after hard call-outs.',
      es: 'Los bomberos. Bendice los vehículos y al equipo, y acompáñalos tras intervenciones duras.',
      fr: 'La caserne de pompiers. Bénis les véhicules et l’équipe, et accompagne-les après des interventions difficiles.',
      pt: 'O corpo de bombeiros. Abençoe os veículos e a equipe e apoie-os depois de ocorrências difíceis.',
    ),
    BuildingType.postOffice: Tr(
      'Die Post. Verschicke Ermutigungskarten – sie erreichen viele Menschen.',
      'The post office. Send encouragement cards – they reach many people.',
      es: 'Correos. Envía tarjetas de ánimo: llegan a mucha gente.',
      fr: 'La poste. Envoie des cartes d’encouragement – elles touchent beaucoup de gens.',
      pt: 'Os correios. Envie cartões de encorajamento – eles alcançam muitas pessoas.',
    ),
    BuildingType.hospital: Tr(
      'Das Krankenhaus. Hier wirst du versorgt, besuchst Kranke als Seelsorger und hältst Andachten in der Kapelle.',
      'The hospital. Here you are looked after, visit the sick as a pastor and hold services in the chapel.',
      es: 'El hospital. Aquí te atienden, visitas a los enfermos como pastor y celebras cultos en la capilla.',
      fr: 'L’hôpital. Ici on prend soin de toi, tu rends visite aux malades comme aumônier et tu célèbres des cultes à la chapelle.',
      pt: 'O hospital. Aqui você é atendido, visita os doentes como capelão e realiza cultos na capela.',
    ),
    BuildingType.school: Tr(
      'Eine Schule. Schreib der Leitung, sprich mit ihr – dann darfst du über Werte sprechen und einen Gebetskreis leiten.',
      'A school. Write to the management, talk to them – then you may speak about values and lead a prayer circle.',
      es: 'Una escuela. Escribe a la dirección, habla con ella; después puedes hablar de valores y dirigir un círculo de oración.',
      fr: 'Une école. Écris à la direction, parle-lui – ensuite tu peux parler des valeurs et animer un cercle de prière.',
      pt: 'Uma escola. Escreva à direção, fale com ela – depois você pode falar sobre valores e conduzir um círculo de oração.',
    ),
    BuildingType.university: Tr(
      'Die Universität. Junge Menschen stellen hier Lebensfragen – Gespräch und Gebetskreis bringen viel.',
      'The university. Young people ask life\'s questions here – talks and a prayer circle achieve a lot.',
      es: 'La universidad. Aquí los jóvenes se hacen preguntas sobre la vida: conversar y orar juntos da mucho fruto.',
      fr: 'L’université. Des jeunes s’y posent les questions de la vie – discussions et cercle de prière portent beaucoup de fruit.',
      pt: 'A universidade. Jovens fazem perguntas sobre a vida aqui – conversas e um círculo de oração rendem muito.',
    ),
    BuildingType.church: Tr(
      'Eine Kirche. Halte Gottesdienste, bete an – das macht das Viertel in der unsichtbaren Welt heller. Hier warten oft Mentoren 🎓.',
      'A church. Hold services, worship – it brightens the quarter in the invisible world. Mentors 🎓 often wait here.',
      es: 'Una iglesia. Celebra cultos, adora: eso ilumina el barrio en el mundo invisible. Aquí suelen esperar mentores 🎓.',
      fr: 'Une église. Célèbre des cultes, adore – cela éclaire le quartier dans le monde invisible. Des mentors 🎓 y attendent souvent.',
      pt: 'Uma igreja. Realize cultos, adore – isso ilumina o bairro no mundo invisível. Muitas vezes há mentores 🎓 aqui.',
    ),
    BuildingType.cathedral: Tr(
      'Die Kathedrale. Ein großer Ort des Gebets – mit starken Gottesdiensten und erfahrenen Mentoren 🎓.',
      'The cathedral. A great place of prayer – with powerful services and experienced mentors 🎓.',
      es: 'La catedral. Un gran lugar de oración, con cultos poderosos y mentores experimentados 🎓.',
      fr: 'La cathédrale. Un grand lieu de prière – avec des cultes puissants et des mentors expérimentés 🎓.',
      pt: 'A catedral. Um grande lugar de oração – com cultos poderosos e mentores experientes 🎓.',
    ),
    BuildingType.library: Tr(
      'Die Bibliothek. Studiere in Ruhe und lade zum Lesekreis ein – das schenkt dir Weisheit (📖).',
      'The library. Study in peace and invite people to a reading circle – it gives you insight (📖).',
      es: 'La biblioteca. Estudia con calma e invita a un círculo de lectura: te da sabiduría (📖).',
      fr: 'La bibliothèque. Étudie au calme et invite à un cercle de lecture – cela te donne de la sagesse (📖).',
      pt: 'A biblioteca. Estude com calma e convide para um círculo de leitura – isso lhe dá sabedoria (📖).',
    ),
    BuildingType.museum: Tr(
      'Das Museum. In der Ausstellung zur Kirchengeschichte lernst du aus der Vergangenheit.',
      'The museum. In the church history exhibition you learn from the past.',
      es: 'El museo. En la exposición de historia de la Iglesia aprendes del pasado.',
      fr: 'Le musée. Dans l’exposition sur l’histoire de l’Église, tu apprends du passé.',
      pt: 'O museu. Na exposição de história da Igreja você aprende com o passado.',
    ),
    BuildingType.stadium: Tr(
      'Das Stadion. Hier kannst du ein Großevent veranstalten – tausende hören die Botschaft.',
      'The stadium. Here you can hold a big event – thousands hear the message.',
      es: 'El estadio. Aquí puedes organizar un gran evento: miles escuchan el mensaje.',
      fr: 'Le stade. Ici tu peux organiser un grand événement – des milliers entendent le message.',
      pt: 'O estádio. Aqui você pode promover um grande evento – milhares ouvem a mensagem.',
    ),
    BuildingType.cityHall: Tr(
      'Das Rathaus. Ein Termin beim Bürgermeister und das Gebet für die Regierenden wirken auf die ganze Stadt.',
      'City hall. A meeting with the mayor and prayer for those in authority affect the whole city.',
      es: 'El ayuntamiento. Una cita con el alcalde y la oración por los gobernantes influyen en toda la ciudad.',
      fr: 'La mairie. Un rendez-vous avec le maire et la prière pour les dirigeants agissent sur toute la ville.',
      pt: 'A prefeitura. Uma audiência com o prefeito e a oração pelos governantes influenciam a cidade inteira.',
    ),
    BuildingType.cemetery: Tr(
      'Der Friedhof. Halte Beerdigungen und tröste die Trauernden – mit der Hoffnung auf die Auferstehung.',
      'The cemetery. Hold funerals and comfort the mourners – with the hope of the resurrection.',
      es: 'El cementerio. Oficia funerales y consuela a los que lloran, con la esperanza de la resurrección.',
      fr: 'Le cimetière. Célèbre des obsèques et console les personnes en deuil – avec l’espérance de la résurrection.',
      pt: 'O cemitério. Realize funerais e console os enlutados – com a esperança da ressurreição.',
    ),
    BuildingType.powerPlant: Tr(
      'Das Kraftwerk. Hier arbeiten viele in Schichten – bete für ihre Sicherheit.',
      'The power plant. Many work shifts here – pray for their safety.',
      es: 'La central eléctrica. Aquí muchos trabajan por turnos: ora por su seguridad.',
      fr: 'La centrale électrique. Beaucoup y travaillent en équipes – prie pour leur sécurité.',
      pt: 'A usina elétrica. Muitos trabalham em turnos aqui – ore pela segurança deles.',
    ),
  };

  /// 'person', 'christian', 'shaken'.
  static const Map<String, Tr> people = {
    'person': Tr(
      'Ein Mensch aus der Stadt. Geh hin und sprich mit ihm: Gespräch, Gebet und Bibel machen ihn offener für Gott – der ✝️-Balken zeigt, wie nah er dem Glauben ist.',
      'A person from the city. Go and talk to them: talks, prayer and the Bible make them more open to God – the ✝️ bar shows how close they are to faith.',
      es: 'Una persona de la ciudad. Acércate y habla con ella: la conversación, la oración y la Biblia la abren a Dios; la barra ✝️ muestra lo cerca que está de la fe.',
      fr: 'Une personne de la ville. Va lui parler : discussion, prière et Bible l’ouvrent à Dieu – la barre ✝️ montre à quel point elle est proche de la foi.',
      pt: 'Uma pessoa da cidade. Vá conversar com ela: conversa, oração e Bíblia a abrem para Deus – a barra ✝️ mostra o quanto está perto da fé.',
    ),
    'christian': Tr(
      'Ein Christ aus deiner Gemeinde. Er macht seine Umgebung heller. Im Tab 🌱 kannst du ihn zum Jünger machen – dann betet er in der unsichtbaren Welt mit dir.',
      'A Christian from your church. They brighten their surroundings. In the 🌱 tab you can make them a disciple – then they pray with you in the invisible world.',
      es: 'Un cristiano de tu iglesia. Ilumina su entorno. En la pestaña 🌱 puedes hacerlo discípulo: entonces ora contigo en el mundo invisible.',
      fr: 'Un chrétien de ton Église. Il éclaire son entourage. Dans l’onglet 🌱, tu peux en faire un disciple – il prie alors avec toi dans le monde invisible.',
      pt: 'Um cristão da sua igreja. Ele ilumina os arredores. Na aba 🌱 você pode fazer dele um discípulo – então ele ora com você no mundo invisível.',
    ),
    'shaken': Tr(
      'Ein angeschlagener Christ ✝️💔. Er wohnt schon lange im Dunkeln und hat viel Glauben verloren. Besuche ihn, sprich und bete mit ihm – dann wird er wieder stark.',
      'A shaken Christian ✝️💔. They have lived in the dark for long and lost much faith. Visit them, talk and pray with them – and they become strong again.',
      es: 'Un cristiano debilitado ✝️💔. Vive desde hace tiempo en la oscuridad y ha perdido mucha fe. Visítalo, conversa y ora con él, y volverá a estar fuerte.',
      fr: 'Un chrétien ébranlé ✝️💔. Il vit depuis longtemps dans l’obscurité et a perdu beaucoup de foi. Rends-lui visite, parle et prie avec lui – et il redeviendra fort.',
      pt: 'Um cristão abalado ✝️💔. Mora há muito tempo no escuro e perdeu muita fé. Visite-o, converse e ore com ele – e ele volta a ficar forte.',
    ),
  };

  /// 📍 A place marked on the city map.
  static const Tr pin = Tr(
    'Dein Ziel 📍 ist markiert. Der Pfeil oben links und die kleine Karte zeigen dir den Weg. Tippe es auf der Karte noch einmal an, um es zu entfernen.',
    'Your destination 📍 is marked. The arrow at the top left and the small map show you the way. Tap it on the map again to remove it.',
    es: 'Tu destino 📍 está marcado. La flecha arriba a la izquierda y el minimapa te muestran el camino. Tócalo otra vez en el mapa para quitarlo.',
    fr: 'Ta destination 📍 est marquée. La flèche en haut à gauche et la petite carte te montrent le chemin. Touche-la encore sur la carte pour la retirer.',
    pt: 'Seu destino 📍 está marcado. A seta no canto superior esquerdo e o minimapa mostram o caminho. Toque nele de novo no mapa para removê-lo.',
  );

  /// Strong strongholds (StrongholdKind.name): too strong to win alone.
  static const Map<String, Tr> strongholds = {
    'bulwark': Tr(
      'Ein Bollwerk 🏰🏰. Allein heilt es fast so schnell, wie du es triffst. Wenn zwei zusammen beten 👥, hört die Heilung auf – ruf deine Jünger mit einer Freiversammlung 📢🎺. Vorher hilft 🪫 Entwaffnen: Es stoppt die Heilung eine Weile. ⏳ Binden halbiert sie und hält die Wächter auf.',
      'A bulwark 🏰🏰. Alone, it heals almost as fast as you hit it. When two pray together 👥, the healing stops – call your disciples with an open-air meeting 📢🎺. First, 🪫 Disarm helps: it stops the healing for a while. ⏳ Bind halves it and holds the guards back.',
      es: 'Un baluarte 🏰🏰. Solo, se cura casi tan rápido como lo golpeas. Cuando dos oran juntos 👥, la curación se detiene: llama a tus discípulos con una reunión al aire libre 📢🎺. Antes ayuda 🪫 Desarmar: detiene la curación un rato. ⏳ Atar la reduce a la mitad y frena a los guardianes.',
      fr: 'Un rempart 🏰🏰. Seul, il guérit presque aussi vite que tu le frappes. Quand deux prient ensemble 👥, la guérison s’arrête – appelle tes disciples avec une réunion en plein air 📢🎺. Avant, 🪫 Désarmer aide : cela arrête la guérison un moment. ⏳ Lier la divise par deux et retient les gardiens.',
      pt: 'Um baluarte 🏰🏰. Sozinho, ele se cura quase tão rápido quanto você o atinge. Quando dois oram juntos 👥, a cura para – chame seus discípulos com uma reunião ao ar livre 📢🎺. Antes ajuda 🪫 Desarmar: para a cura por um tempo. ⏳ Amarrar a reduz pela metade e segura os guardas.',
    ),
    'greatFortress': Tr(
      'Eine Großfestung 🏯 – zu stark für dich allein. Erst wenn drei zusammen beten 👥 3, hört sie auf zu heilen, und jeder Mitbeter macht die Welle stärker. Ruf deine Jünger mit einer Freiversammlung 📢🎺 zusammen. 🪫 Entwaffnen stoppt die Heilung eine Weile, ⏳ Binden halbiert sie – gut, wenn ein Jünger das betet.',
      'A great fortress 🏯 – too strong for you alone. Only when three pray together 👥 3 does it stop healing, and every one praying along makes the wave stronger. Gather your disciples with an open-air meeting 📢🎺. 🪫 Disarm stops the healing for a while, ⏳ Bind halves it – good when a disciple prays that.',
      es: 'Una gran fortaleza 🏯: demasiado fuerte para ti solo. Solo cuando tres oran juntos 👥 3 deja de curarse, y cada uno que ora contigo hace la onda más fuerte. Reúne a tus discípulos con una reunión al aire libre 📢🎺. 🪫 Desarmar detiene la curación un rato, ⏳ Atar la reduce a la mitad: bueno si un discípulo ora así.',
      fr: 'Une grande forteresse 🏯 – trop forte pour toi seul. Ce n’est que quand trois prient ensemble 👥 3 qu’elle cesse de guérir, et chaque personne qui prie avec toi rend l’onde plus forte. Rassemble tes disciples avec une réunion en plein air 📢🎺. 🪫 Désarmer arrête la guérison un moment, ⏳ Lier la divise par deux – utile quand un disciple prie ainsi.',
      pt: 'Uma grande fortaleza 🏯 – forte demais para você sozinho. Só quando três oram juntos 👥 3 ela para de se curar, e cada um que ora junto deixa a onda mais forte. Reúna seus discípulos com uma reunião ao ar livre 📢🎺. 🪫 Desarmar para a cura por um tempo, ⏳ Amarrar a reduz pela metade – bom quando um discípulo ora assim.',
    ),
  };

  /// ⚡ per prayer mode – what strength does for this mode.
  static const Map<String, Tr> strengthOf = {
    'liberation': Tr('Stärke: Deine Befreiungswelle trifft Dämonen härter und befreit den Boden schneller.', 'Strength: your liberation wave hits demons harder and frees the ground faster.', es: 'Fuerza: tu onda de liberación golpea más fuerte a los demonios y libera el suelo más rápido.', fr: 'Force : ton onde de libération frappe les démons plus fort et libère le sol plus vite.', pt: 'Força: sua onda de libertação atinge os demônios com mais força e liberta o chão mais rápido.'),
    'rebuke': Tr('Stärke: Zurückdrängen schiebt Dämonen weiter von dir weg und hält sie länger auf Abstand.', 'Strength: rebuke pushes demons further away from you and keeps them at a distance longer.', es: 'Fuerza: reprender empuja a los demonios más lejos de ti y los mantiene a distancia por más tiempo.', fr: 'Force : repousser éloigne davantage les démons de toi et les tient plus longtemps à distance.', pt: 'Força: repreender empurra os demônios para mais longe de você e os mantém afastados por mais tempo.'),
    'slow': Tr('Stärke: Binden bremst Dämonen stärker – sie kreisen und nähern sich viel langsamer.', 'Strength: binding slows demons more – they circle and approach much more slowly.', es: 'Fuerza: atar frena más a los demonios: giran y se acercan mucho más despacio.', fr: 'Force : lier freine davantage les démons – ils tournent et s’approchent bien plus lentement.', pt: 'Força: amarrar freia mais os demônios – eles giram e se aproximam bem mais devagar.'),
    'drain': Tr('Stärke: Entwaffnen zieht mehr Kraft ab – ein entwaffneter Dämon gibt dir mehr Glauben 🙏 zurück.', 'Strength: disarming draws off more power – a disarmed demon gives you more faith 🙏 back.', es: 'Fuerza: desarmar quita más poder: un demonio desarmado te devuelve más fe 🙏.', fr: 'Force : désarmer retire plus de puissance – un démon désarmé te rend plus de foi 🙏.', pt: 'Força: desarmar tira mais poder – um demônio desarmado devolve mais fé 🙏 para você.'),
  };

  /// ⚔️ upgrades: 'radius', 'strength', 'duration', 'speed', 'shield', 'helm'.
  static const Map<String, Tr> upgrades = {
    'radius': Tr('Radius: Deine Gebetswelle reicht weiter.', 'Radius: your prayer wave reaches further.', es: 'Radio: tu onda de oración llega más lejos.', fr: 'Rayon : ton onde de prière va plus loin.', pt: 'Raio: sua onda de oração alcança mais longe.'),
    'strength': Tr('Stärke: Deine Welle trifft Dämonen härter und befreit den Boden schneller.', 'Strength: your wave hits demons harder and frees the ground faster.', es: 'Fuerza: tu onda golpea más fuerte a los demonios y libera el suelo más rápido.', fr: 'Force : ton onde frappe les démons plus fort et libère le sol plus vite.', pt: 'Força: sua onda atinge os demônios com mais força e liberta o chão mais rápido.'),
    'duration': Tr('Dauer: Die Wirkung auf Dämonen hält länger an.', 'Duration: the effect on demons lasts longer.', es: 'Duración: el efecto sobre los demonios dura más.', fr: 'Durée : l’effet sur les démons dure plus longtemps.', pt: 'Duração: o efeito sobre os demônios dura mais.'),
    'speed': Tr('Tempo: Deine Welle breitet sich schneller aus.', 'Speed: your wave spreads faster.', es: 'Velocidad: tu onda se expande más rápido.', fr: 'Vitesse : ton onde se propage plus vite.', pt: 'Velocidade: sua onda se espalha mais rápido.'),
    'shield': Tr('Schild des Glaubens: Angriffe der Dämonen kosten dich weniger 🙏 (Eph 6,16).', 'Shield of faith: demon attacks cost you less 🙏 (Eph 6:16).', es: 'Escudo de la fe: los ataques de los demonios te cuestan menos 🙏 (Ef 6:16).', fr: 'Bouclier de la foi : les attaques des démons te coûtent moins de 🙏 (Ep 6,16).', pt: 'Escudo da fé: os ataques dos demônios custam menos 🙏 (Ef 6:16).'),
    'helm': Tr('Helm des Heils: Im Kampf verlierst du weniger Vorrat 🍞 (Eph 6,17).', 'Helmet of salvation: you lose fewer provisions 🍞 in battle (Eph 6:17).', es: 'Yelmo de la salvación: en la batalla pierdes menos provisiones 🍞 (Ef 6:17).', fr: 'Casque du salut : tu perds moins de provisions 🍞 au combat (Ep 6,17).', pt: 'Capacete da salvação: na batalha você perde menos provisões 🍞 (Ef 6:17).'),
  };
}
