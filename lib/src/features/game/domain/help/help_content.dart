import '../../../../core/i18n/app_strings.dart';
import '../actions/game_action.dart';
import '../actions/resource.dart';
import '../models/cell_object.dart';
import '../models/daemon_kind.dart';
import '../models/prayer_combat.dart';
import '../models/skills.dart';
import '../services/learning_service.dart';

/// One sentence in both languages. The help screen is the one place with
/// real sentences (playtest 2026-10-20: "wo ist 📢?") – the game itself
/// stays emoji-only.
class Tr {
  final String de;
  final String en;
  final String? es;
  final String? fr;
  final String? pt;
  const Tr(this.de, this.en, {this.es, this.fr, this.pt});

  /// In the current language; missing translations fall back to English.
  String get text => switch (AppStrings.currentLanguage) {
        'de' => de,
        'es' => es ?? en,
        'fr' => fr ?? en,
        'pt' => pt ?? en,
        _ => en,
      };
}

/// The explanations behind the emoji, for the ❓ help screen. Lists are
/// generated from the registries (BuildingActions, Lessons …) where possible
/// so the glossary cannot fall behind the game; a test checks every enum
/// value has its sentence.
abstract final class HelpContent {
  static const Map<Resource, Tr> resources = {
    Resource.faith: Tr('Glaube – deine Kraft für Gebet, Kampf und viele Aktionen. Lies in der Bibel 📖 und bete 🙏 im Pastorenhaus, um ihn aufzufüllen.', 'Faith – your strength for prayer, combat and many actions. Read the Bible 📖 and pray 🙏 at home to refill it.', es: 'Fe: tu fuerza para la oración, el combate y muchas acciones. Lee la Biblia 📖 y ora 🙏 en casa para recargarla.', fr: 'Foi : ta force pour la prière, le combat et beaucoup d’actions. Lis la Bible 📖 et prie 🙏 à la maison pour la recharger.', pt: 'Fé: sua força para a oração, o combate e muitas ações. Leia a Bíblia 📖 e ore 🙏 em casa para recarregá-la.'),
    Resource.health: Tr('Leben – sinkt bei Kämpfen und anstrengenden Diensten. Schlafen 😴 füllt es auf. Bei 0 wirst du ohnmächtig.', 'Health – drops in fights and draining services. Sleeping 😴 refills it. At 0 you faint.', es: 'Salud: baja en los combates y en servicios agotadores. Dormir 😴 la recupera. Si llega a 0, te desmayas.', fr: 'Santé : baisse dans les combats et les services épuisants. Dormir 😴 la recharge. À 0, tu t’évanouis.', pt: 'Saúde: cai nos combates e em serviços cansativos. Dormir 😴 a recupera. Em 0, você desmaia.'),
    Resource.hunger: Tr('Vorrat (Essen) – sinkt mit der Zeit. Essen 🍽️ im Pastorenhaus oder Einkaufen 🛒 füllt ihn auf.', 'Provisions (food) – drops over time. Eating 🍽️ at home or shopping 🛒 refills them.', es: 'Provisiones (comida): bajan con el tiempo. Comer 🍽️ en casa o comprar 🛒 las repone.', fr: 'Provisions (nourriture) : diminuent avec le temps. Manger 🍽️ à la maison ou faire les courses 🛒 les recharge.', pt: 'Provisões (comida): diminuem com o tempo. Comer 🍽️ em casa ou fazer compras 🛒 as repõe.'),
    Resource.materials: Tr('Material – für praktische Hilfe, Gottesdienste und Geschenke. Du findest 📦 auf der Straße, bekommst Spenden 🤲 oder arbeitest mit 🛠️.', 'Supplies – for practical help, services and gifts. Pick up 📦 in the street, ask for donations 🤲 or work a shift 🛠️.', es: 'Materiales: para ayuda práctica, cultos y regalos. Recoge 📦 en la calle, pide donativos 🤲 o trabaja un turno 🛠️.', fr: 'Matériel : pour l’aide pratique, les cultes et les cadeaux. Ramasse 📦 dans la rue, demande des dons 🤲 ou fais une équipe 🛠️.', pt: 'Materiais: para ajuda prática, cultos e presentes. Recolha 📦 na rua, peça doações 🤲 ou trabalhe um turno 🛠️.'),
    Resource.insight: Tr('Erkenntnis – bekommst du für besiegte Dämonen, Bibelkreise und Missionen. Damit verbesserst du im Pastorenhaus unter ⚔️ deine geistliche Kampfführung.', 'Insight – earned from defeated demons, Bible groups and missions. Spend it under ⚔️ at home to grow in spiritual warfare.', es: 'Sabiduría: la ganas venciendo demonios, en grupos bíblicos y con misiones. Gástala en ⚔️ en casa para mejorar tu guerra espiritual.', fr: 'Sagesse : gagnée en vainquant des démons, dans les groupes bibliques et par les missions. Dépense-la sous ⚔️ à la maison pour progresser dans le combat spirituel.', pt: 'Sabedoria: ganha ao vencer demônios, em grupos bíblicos e com missões. Gaste-a em ⚔️ em casa para melhorar sua batalha espiritual.'),
  };

  /// Symbols that appear all over the game.
  static const List<(String, Tr)> symbols = [
    (
      '🖐️',
      Tr('Handeln (Taste E): öffnet das Kreismenü mit allem in deiner Nähe – Menschen, Häuser, 👀 Umschauen.', 'Act (key E): opens the circle menu with everything nearby – people, buildings, 👀 look around.', es: 'Actuar (tecla E): abre el menú circular con todo lo cercano: personas, edificios, 👀 mirar alrededor.', fr: 'Agir (touche E) : ouvre le menu circulaire avec tout ce qui est proche – personnes, bâtiments, 👀 regarder autour.', pt: 'Agir (tecla E): abre o menu circular com tudo por perto – pessoas, edifícios, 👀 olhar ao redor.')
    ),
    (
      '🚪',
      Tr('Tür: Lauf einfach hinein, um ein Haus zu betreten oder anzuklopfen.', 'Door: just walk into it to enter a building or knock.', es: 'Puerta: camina hacia ella para entrar en un edificio o llamar.', fr: 'Porte : marche simplement dedans pour entrer dans un bâtiment ou frapper.', pt: 'Porta: basta andar até ela para entrar num edifício ou bater.')
    ),
    (
      '🙏 / 🏙️',
      Tr('Wechselt zwischen sichtbarer Stadt und unsichtbarer Welt (kostet 🙏).', 'Switches between the visible city and the invisible world (costs 🙏).', es: 'Cambia entre la ciudad visible y el mundo invisible (cuesta 🙏).', fr: 'Passe de la ville visible au monde invisible (coûte 🙏).', pt: 'Alterna entre a cidade visível e o mundo invisível (custa 🙏).')
    ),
    (
      '✝️',
      Tr('In der unsichtbaren Welt: gedrückt halten, um eine Gebetswelle aufzuladen. Bei Menschen: wie nah sie dem Glauben sind.', 'In the invisible world: hold to charge a prayer wave. On people: how close they are to faith.', es: 'En el mundo invisible: mantén pulsado para cargar una onda de oración. En las personas: lo cerca que están de la fe.', fr: 'Dans le monde invisible : maintiens pour charger une onde de prière. Sur les personnes : à quel point elles sont proches de la foi.', pt: 'No mundo invisível: segure para carregar uma onda de oração. Nas pessoas: o quanto estão perto da fé.')
    ),
    (
      '🏙️ / 🌐',
      Tr('Zwei dünne Linien unter ✝: oben dein Stadtteil, unten die ganze Stadt. In der Stadt (🏙️): oben blau der Weg bis zum Bollwerk 🏰, unten gold der Anteil der Christen. In der unsichtbaren Welt (🌐) wie das Land steht – Stadtteil: tiefrot = finster, grau = dazwischen, grün = freigebetet; ganze Stadt: violett = finster, grau, gold = freigebetet. ⚔️ = Bollwerk angreifbar, 🔥 = Stadtteil erweckt.', 'Two thin lines under ✝: top your neighbourhood, bottom the whole city. In the city (🏙️): top in blue the way to the stronghold 🏰, bottom in gold the share of Christians. In the invisible world (🌐) how the ground stands – neighbourhood: deep red = dark, grey = in between, green = prayed free; whole city: violet = dark, grey, gold = prayed free. ⚔️ = stronghold open, 🔥 = neighbourhood awakened.', es: 'Dos líneas finas bajo ✝: arriba tu barrio, abajo toda la ciudad. En la ciudad (🏙️): arriba en azul el camino hacia la fortaleza 🏰, abajo en dorado la proporción de cristianos. En el mundo invisible (🌐) cómo está el suelo: barrio: rojo oscuro = oscuro, gris = intermedio, verde = liberado por la oración; toda la ciudad: violeta = oscuro, gris, dorado = liberado. ⚔️ = fortaleza abierta, 🔥 = barrio despertado.', fr: 'Deux fines lignes sous ✝ : en haut ton quartier, en bas toute la ville. En ville (🏙️) : en haut en bleu le chemin vers la forteresse 🏰, en bas en or la part de chrétiens. Dans le monde invisible (🌐), l’état du sol : quartier : rouge foncé = sombre, gris = entre les deux, vert = libéré par la prière ; toute la ville : violet = sombre, gris, or = libéré. ⚔️ = forteresse ouverte, 🔥 = quartier réveillé.', pt: 'Duas linhas finas sob ✝: em cima seu bairro, embaixo a cidade inteira. Na cidade (🏙️): em cima, em azul, o caminho até a fortaleza 🏰; embaixo, em dourado, a parcela de cristãos. No mundo invisível (🌐), como está o chão: bairro: vermelho escuro = escuro, cinza = meio-termo, verde = liberto pela oração; cidade inteira: violeta = escuro, cinza, dourado = liberto. ⚔️ = fortaleza aberta, 🔥 = bairro despertado.'),
    ),
    (
      '📢🎺',
      Tr('Freiversammlung (nach 📢 Predigen, Kreismenü 🖐️ auf der Straße): ein großer Glaubensschritt – kostet 70 🙏, die Hälfte deines ❤️ und viel 🍞. Erreicht sehr viele Menschen – und kurz danach füllt Gott deinen Glauben ganz auf ✨🙏💯. Danach brauchst du erst wieder Kraft (❤️ über die Hälfte). Deine Jünger 🌱 in der Umgebung kommen dazu und beten eine Weile mit dir zusammen.', 'Open-air meeting (after 📢 preaching, circle menu 🖐️ in the street): a big step of faith – costs 70 🙏, half your ❤️ and much 🍞. Reaches very many people – and shortly after God fills your faith up completely ✨🙏💯. Then you need strength again first (❤️ above half). Your disciples 🌱 nearby join you and pray together with you for a while.', es: 'Reunión al aire libre (después de 📢 predicar, menú circular 🖐️ en la calle): un gran paso de fe; cuesta 70 🙏, la mitad de tu ❤️ y mucho 🍞. Llega a muchísima gente, y poco después Dios llena tu fe por completo ✨🙏💯. Luego necesitas recuperar fuerzas (❤️ por encima de la mitad). Tus discípulos 🌱 cercanos se unen y oran contigo un rato.', fr: 'Réunion en plein air (après 📢 prêcher, menu circulaire 🖐️ dans la rue) : un grand pas de foi – coûte 70 🙏, la moitié de ton ❤️ et beaucoup de 🍞. Elle touche énormément de gens – et peu après, Dieu remplit entièrement ta foi ✨🙏💯. Ensuite il te faut d’abord reprendre des forces (❤️ au-dessus de la moitié). Tes disciples 🌱 proches te rejoignent et prient avec toi un moment.', pt: 'Reunião ao ar livre (depois de 📢 pregar, menu circular 🖐️ na rua): um grande passo de fé – custa 70 🙏, metade do seu ❤️ e muito 🍞. Alcança muitíssimas pessoas – e pouco depois Deus enche sua fé completamente ✨🙏💯. Depois você precisa recuperar as forças (❤️ acima da metade). Seus discípulos 🌱 por perto se juntam e oram com você por um tempo.'),
    ),
    (
      '🌱 🔒⚔️',
      Tr('Jüngerschaft (Gespräch mit einem Christen, Tab 🌱): Dasselbe ⚔️-Menü wie im Pastorenhaus – nur für diesen Menschen. Du gibst weiter, was du selbst gelernt hast, mit 📖 und nie weiter als deine eigene Stufe (🔒⚔️ = erst selbst verbessern). In der unsichtbaren Welt betet er dann in deiner Nähe mit: alle paar Sekunden eine kleine Welle – immer in der Gebetsart, die du bei ihm am meisten ausgebaut hast. So legst du fest, wofür er da ist: einer für 🫸, einer für ⏳, viele für 🕊️ … Erkennbar am Ring in dieser Farbe. Eine Freiversammlung 📢🎺 ruft die Jünger in der Umgebung zusammen: Sie kommen zu dir und beten eine Weile mit jeder deiner Wellen mit. Je mehr Jünger in einem Viertel wohnen, desto stärker betet es mit (2 Tim 2,2).', 'Discipleship (talk with a Christian, tab 🌱): the same ⚔️ menu as in the pastor house – for this person. You pass on what you have learned yourself, with 📖 and never beyond your own level (🔒⚔️ = improve yourself first). In the invisible world they then pray along near you: a small wave every few seconds – always in the kind of prayer you built up most in them. That is how you decide what they are for: one for 🫸, one for ⏳, many for 🕊️ … You can tell them by the ring in that colour. An open-air meeting 📢🎺 calls the disciples around together: they come to you and for a while pray with each of your waves. The more disciples live in a quarter, the more it prays along (2 Tim 2:2).', es: 'Discipulado (conversación con un cristiano, pestaña 🌱): el mismo menú ⚔️ que en la casa pastoral, para esta persona. Transmites lo que tú mismo has aprendido, con 📖 y nunca más allá de tu propio nivel (🔒⚔️ = mejórate primero). En el mundo invisible ora contigo cerca de ti: una pequeña onda cada pocos segundos, siempre del tipo de oración que más desarrollaste en él. Así decides para qué está: uno para 🫸, uno para ⏳, muchos para 🕊️… Lo reconoces por el anillo de ese color. Una reunión al aire libre 📢🎺 reúne a los discípulos: vienen a ti y durante un rato oran con cada una de tus ondas. Cuantos más discípulos vivan en un barrio, más ora el barrio contigo (2 Ti 2:2).', fr: 'Discipulat (discussion avec un chrétien, onglet 🌱) : le même menu ⚔️ que dans la maison pastorale – pour cette personne. Tu transmets ce que tu as appris toi-même, avec 📖 et jamais au-delà de ton propre niveau (🔒⚔️ = améliore-toi d’abord). Dans le monde invisible, il prie alors avec toi près de toi : une petite onde toutes les quelques secondes – toujours dans le type de prière que tu as le plus développé chez lui. C’est ainsi que tu décides de son rôle : un pour 🫸, un pour ⏳, beaucoup pour 🕊️… Tu le reconnais à l’anneau de cette couleur. Une réunion en plein air 📢🎺 rassemble les disciples : ils viennent vers toi et prient un moment avec chacune de tes ondes. Plus il y a de disciples dans un quartier, plus il prie avec toi (2 Tm 2,2).', pt: 'Discipulado (conversa com um cristão, aba 🌱): o mesmo menu ⚔️ da casa pastoral – para esta pessoa. Você passa adiante o que você mesmo aprendeu, com 📖 e nunca além do seu próprio nível (🔒⚔️ = melhore-se primeiro). No mundo invisível ela ora com você quando está perto: uma pequena onda a cada poucos segundos – sempre no tipo de oração que você mais desenvolveu nela. Assim você decide para que ela serve: um para 🫸, um para ⏳, muitos para 🕊️… Você a reconhece pelo anel dessa cor. Uma reunião ao ar livre 📢🎺 reúne os discípulos: eles vêm até você e por um tempo oram com cada uma das suas ondas. Quanto mais discípulos morarem num bairro, mais ele ora junto (2 Tm 2:2).'),
    ),
    (
      '🌐 ↔️ 👥',
      Tr('Die unsichtbare Welt lebt – jeden Tag, in der ganzen Stadt, auch wenn du nicht dort bist: Helle und dunkle Felder breiten sich zu ihren Nachbarn aus, tiefe Dunkelheit sickert weiter. Christen und heilige Häuser machen ihre Umgebung heller, feindselige Menschen dunkler. Umgekehrt wirkt die Umgebung auf alle Menschen: Im Hellen werden sie offener (höchstens 🤔 suchend – zum Glauben finden sie nur im Gespräch mit dir), im Dunkeln verschlossener. Kommst du in eine Gegend zurück, hat sie sich in der Zwischenzeit verändert.', 'The invisible world lives – every day, in the whole city, even where you are not: light and dark cells spread to their neighbours, deep darkness seeps on. Christians and holy houses brighten their surroundings, hostile people darken them. In turn the surroundings act on everyone: in the light people grow more open (at most 🤔 seeking – they find faith only in a talk with you), in the dark more closed. When you come back to an area, it has changed in the meantime.', es: 'El mundo invisible vive: cada día, en toda la ciudad, también donde tú no estás. Las casillas claras y oscuras se extienden a sus vecinas; la oscuridad profunda se filtra. Los cristianos y las casas santas iluminan su entorno; las personas hostiles lo oscurecen. A su vez, el entorno actúa sobre todos: en la luz la gente se abre (como mucho 🤔 buscando; a la fe solo llegan conversando contigo), en la oscuridad se cierra. Cuando vuelves a una zona, ha cambiado mientras tanto.', fr: 'Le monde invisible vit – chaque jour, dans toute la ville, même là où tu n’es pas : les cases claires et sombres s’étendent à leurs voisines, l’obscurité profonde s’infiltre. Les chrétiens et les maisons saintes éclairent leur entourage, les personnes hostiles l’assombrissent. En retour, l’entourage agit sur chacun : dans la lumière, les gens s’ouvrent (au plus 🤔 en recherche – ils ne trouvent la foi qu’en discutant avec toi), dans l’obscurité ils se ferment. Quand tu reviens dans un endroit, il a changé entre-temps.', pt: 'O mundo invisível vive – todos os dias, na cidade inteira, também onde você não está: casas claras e escuras se espalham para as vizinhas, a escuridão profunda se infiltra. Cristãos e casas santas iluminam seus arredores, pessoas hostis os escurecem. Por sua vez, o ambiente age sobre todos: na luz as pessoas se abrem (no máximo 🤔 buscando – só encontram a fé conversando com você), no escuro se fecham. Quando você volta a uma área, ela mudou nesse meio-tempo.'),
    ),
    (
      '✝️💔',
      Tr('Angeschlagener Christ: Wer lange im Dunkeln wohnt, verliert Glauben – weniger, wenn er stabil ist (Seelsorge 👂, durchgearbeitete Lebensthemen 📜, Gemeinde ⛪, Jüngerschaft 🌱, andere Christen in der Nähe). Unter 30 ✝️ schützt und betet er nicht mehr. Er bleibt Christ – besuche ihn, sprich und bete mit ihm, dann ist er wieder stark.', 'Shaken Christian: whoever lives in the dark for long loses faith – less when they are stable (care 👂, life challenges worked through 📜, church ⛪, discipleship 🌱, other Christians nearby). Below 30 ✝️ they no longer protect or pray. They stay a Christian – visit them, talk and pray with them, and they are strong again.', es: 'Cristiano debilitado: quien vive mucho tiempo en la oscuridad pierde fe, menos si es estable (cuidado 👂, temas de vida superados 📜, iglesia ⛪, discipulado 🌱, otros cristianos cerca). Por debajo de 30 ✝️ ya no protege ni ora. Sigue siendo cristiano: visítalo, conversa y ora con él, y volverá a estar fuerte.', fr: 'Chrétien ébranlé : qui vit longtemps dans l’obscurité perd la foi – moins s’il est stable (accompagnement 👂, épreuves de vie surmontées 📜, Église ⛪, discipulat 🌱, d’autres chrétiens à proximité). En dessous de 30 ✝️, il ne protège plus et ne prie plus. Il reste chrétien – rends-lui visite, parle et prie avec lui, et il redevient fort.', pt: 'Cristão abalado: quem vive muito tempo no escuro perde fé – menos se for estável (cuidado 👂, temas de vida superados 📜, igreja ⛪, discipulado 🌱, outros cristãos por perto). Abaixo de 30 ✝️ deixa de proteger e de orar. Continua cristão – visite-o, converse e ore com ele, e ele volta a ficar forte.'),
    ),
    (
      '🏰 ⚔️ 🔥',
      Tr('Bollwerk: zu → angreifbar (⚔️) → besiegt, der Stadtteil ist erweckt (🔥). Erweckte Viertel öffnen neue Lektionen.', 'Stronghold: closed → attackable (⚔️) → defeated, the neighbourhood is awakened (🔥). Awakened quarters open new lessons.', es: 'Fortaleza: cerrada → atacable (⚔️) → vencida, el barrio ha despertado (🔥). Los barrios despertados abren nuevas lecciones.', fr: 'Forteresse : fermée → attaquable (⚔️) → vaincue, le quartier est réveillé (🔥). Les quartiers réveillés ouvrent de nouvelles leçons.', pt: 'Fortaleza: fechada → atacável (⚔️) → vencida, o bairro despertou (🔥). Bairros despertados abrem novas lições.')
    ),
    (
      '🎓',
      Tr('Lektion bei einem Mentor. Die gelbe Zeile oben links zeigt deinen Fortschritt – antippen öffnet diese Hilfe.', 'A mentor\'s lesson. The yellow line top-left shows your progress – tap it to open this help.', es: 'La lección de un mentor. La línea amarilla arriba a la izquierda muestra tu progreso; tócala para abrir esta ayuda.', fr: 'La leçon d’un mentor. La ligne jaune en haut à gauche montre ta progression – touche-la pour ouvrir cette aide.', pt: 'A lição de um mentor. A linha amarela em cima à esquerda mostra seu progresso – toque nela para abrir esta ajuda.')
    ),
    (
      '📍',
      Tr('Mission oder Lektion verfolgen: Die Minimap und der Pfeil zeigen dir den Weg.', 'Track a mission or lesson: the minimap and the arrow show you the way.', es: 'Seguir una misión o lección: el minimapa y la flecha te muestran el camino.', fr: 'Suivre une mission ou une leçon : la mini-carte et la flèche te montrent le chemin.', pt: 'Seguir uma missão ou lição: o minimapa e a seta mostram o caminho.')
    ),
    (
      '📋',
      Tr('Missionsbrett im Pastorenhaus: Missionen 📋 und der Lernweg 🎓.', 'Mission board in the pastor house: missions 📋 and the learning path 🎓.', es: 'Tablón de misiones en la casa pastoral: misiones 📋 y camino de aprendizaje 🎓.', fr: 'Tableau des missions dans la maison pastorale : missions 📋 et parcours d’apprentissage 🎓.', pt: 'Quadro de missões na casa pastoral: missões 📋 e caminho de aprendizado 🎓.')
    ),
    (
      '🔒3',
      Tr('Gesperrt: Du musst dieses Haus noch 3-mal besuchen bzw. dort handeln.', 'Locked: visit or act in this building 3 more times.', es: 'Bloqueado: visita o actúa en este edificio 3 veces más.', fr: 'Verrouillé : visite ce bâtiment ou agis-y encore 3 fois.', pt: 'Bloqueado: visite ou aja neste edifício mais 3 vezes.')
    ),
    (
      '🔒✝️ 🔒⚰️ 🔒🏫',
      Tr('Gesperrt, bis die Bedingung erfüllt ist: ein Christ wohnt hier, erst eine Beerdigung, erst mit der Leitung sprechen.', 'Locked until: a Christian lives here, a funeral was held, you talked to the director.', es: 'Bloqueado hasta que: viva aquí un cristiano, se haya celebrado un funeral, hayas hablado con la dirección.', fr: 'Verrouillé jusqu’à ce que : un chrétien habite ici, des obsèques aient eu lieu, tu aies parlé à la direction.', pt: 'Bloqueado até que: um cristão more aqui, um funeral tenha sido realizado, você tenha falado com a direção.')
    ),
    ('🚫🙏', Tr('Dafür fehlt dir gerade diese Ressource.', 'You lack this resource right now.', es: 'Ahora te falta este recurso.', fr: 'Il te manque cette ressource pour l’instant.', pt: 'Agora falta este recurso.')),
    (
      '✨',
      Tr('Ein verborgener Fund in einem Raum – einmal pro Haus: 📖 oder 📦.', 'A hidden find in a room – once per building: 📖 or 📦.', es: 'Un hallazgo escondido en una habitación, una vez por edificio: 📖 o 📦.', fr: 'Une trouvaille cachée dans une pièce – une fois par bâtiment : 📖 ou 📦.', pt: 'Um achado escondido num cômodo – uma vez por edifício: 📖 ou 📦.')
    ),
    (
      '⭐',
      Tr('Übung: Was du oft tust, wird stärker – jeder Stern ist eine Stufe.', 'Practice: what you do often grows stronger – each star is a level.', es: 'Práctica: lo que haces a menudo se fortalece; cada estrella es un nivel.', fr: 'Pratique : ce que tu fais souvent devient plus fort – chaque étoile est un niveau.', pt: 'Prática: o que você faz com frequência fica mais forte – cada estrela é um nível.')
    ),
    ('👥', Tr('Wirkt auf mehrere Menschen bzw. alle Bewohner.', 'Affects several people or all residents.', es: 'Afecta a varias personas o a todos los residentes.', fr: 'Touche plusieurs personnes ou tous les habitants.', pt: 'Afeta várias pessoas ou todos os moradores.')),
    ('🌍', Tr('Wirkt auf die unsichtbare Welt rundherum.', 'Affects the invisible world around.', es: 'Afecta al mundo invisible de alrededor.', fr: 'Agit sur le monde invisible alentour.', pt: 'Afeta o mundo invisível ao redor.')),
    ('⛪👥', Tr('Deine Gemeinde: bekehrte Menschen, die mitarbeiten.', 'Your church: converted people who help out.', es: 'Tu iglesia: personas convertidas que ayudan.', fr: 'Ton Église : des personnes converties qui aident.', pt: 'Sua igreja: pessoas convertidas que ajudam.')),
    ('📅 😴', Tr('Ein Tag endet, wenn du im Pastorenhaus schläfst.', 'A day ends when you sleep in the pastor house.', es: 'Un día termina cuando duermes en la casa pastoral.', fr: 'Une journée se termine quand tu dors dans la maison pastorale.', pt: 'Um dia termina quando você dorme na casa pastoral.')),
  ];

  /// Sentences under the emoji messages (toasts) when texts are on.
  static const Map<String, Tr> toasts = {
    'strongholdOpen': Tr('Genug Christen im Viertel – das Bollwerk 🏰 ist jetzt angreifbar!', 'Enough Christians in this quarter – the stronghold 🏰 can now be attacked!', es: 'Hay suficientes cristianos en el barrio: ¡ya se puede atacar la fortaleza 🏰!', fr: 'Assez de chrétiens dans le quartier : la forteresse 🏰 peut être attaquée !', pt: 'Cristãos suficientes no bairro – a fortaleza 🏰 já pode ser atacada!'),
    'awakened': Tr('Das Bollwerk ist gefallen – das Viertel ist erweckt!', 'The stronghold has fallen – the quarter is awakened!', es: '¡La fortaleza ha caído: el barrio ha despertado!', fr: 'La forteresse est tombée : le quartier est réveillé !', pt: 'A fortaleza caiu – o bairro despertou!'),
    'prayedFree': Tr("Halleluja! Dein Viertel ist in der unsichtbaren Welt zu {p} % freigebetet. {c} von {n} Menschen hier glauben schon an Jesus – Gott hat Großes getan!", "Hallelujah! Your quarter is {p} % prayed free in the invisible world. {c} of {n} people here already believe in Jesus – God has done great things!", es: "¡Aleluya! Tu barrio está liberado por la oración en un {p} % en el mundo invisible. {c} de {n} personas de aquí ya creen en Jesús: ¡Dios ha hecho grandes cosas!", fr: "Alléluia ! Ton quartier est libéré par la prière à {p} % dans le monde invisible. {c} personnes sur {n} ici croient déjà en Jésus – Dieu a fait de grandes choses !", pt: "Aleluia! Seu bairro está {p} % liberto pela oração no mundo invisível. {c} de {n} pessoas daqui já creem em Jesus – Deus fez grandes coisas!"),
    'allChristian': Tr("Jeder Mensch in diesem Viertel ist jetzt Christ! Wenn das in allen Vierteln der Stadt so ist, ist das große Ziel erreicht.", "Everyone in this quarter is now a Christian! When that is true in every quarter of the city, the great goal is reached.", es: "¡Ahora todas las personas de este barrio son cristianas! Cuando eso ocurra en todos los barrios de la ciudad, se habrá alcanzado la gran meta.", fr: "Tout le monde dans ce quartier est maintenant chrétien ! Quand ce sera le cas dans tous les quartiers de la ville, le grand objectif sera atteint.", pt: "Agora todas as pessoas deste bairro são cristãs! Quando isso acontecer em todos os bairros da cidade, o grande objetivo terá sido alcançado."),
    'openAirDenied': Tr('Für eine Freiversammlung fehlt dir noch etwas.', 'You still lack something for an open-air meeting.', es: 'Aún te falta algo para una reunión al aire libre.', fr: 'Il te manque encore quelque chose pour une réunion en plein air.', pt: 'Ainda falta algo para uma reunião ao ar livre.'),
    'openAir': Tr('Freiversammlung: Viele Menschen haben zugehört.', 'Open-air meeting: many people listened.', es: 'Reunión al aire libre: mucha gente escuchó.', fr: 'Réunion en plein air : beaucoup de gens ont écouté.', pt: 'Reunião ao ar livre: muita gente ouviu.'),
    'openAirGathered': Tr('Freiversammlung: Viele haben zugehört – deine Jünger kommen und beten mit dir.', 'Open-air meeting: many listened – your disciples come and pray with you.', es: 'Reunión al aire libre: muchos escucharon; tus discípulos vienen y oran contigo.', fr: 'Réunion en plein air : beaucoup ont écouté – tes disciples viennent prier avec toi.', pt: 'Reunião ao ar livre: muitos ouviram – seus discípulos vêm orar com você.'),
    'faithRefilled': Tr('Gott füllt deinen Glauben ganz auf.', 'God fills your faith up completely.', es: 'Dios llena tu fe por completo.', fr: 'Dieu remplit entièrement ta foi.', pt: 'Deus enche sua fé completamente.'),
    'released': Tr('Befreit! Dieser Mensch ist frei vom bösen Geist.', 'Set free! This person is free from the evil spirit.', es: '¡Liberado! Esta persona está libre del espíritu maligno.', fr: 'Libéré ! Cette personne est délivrée de l’esprit mauvais.', pt: 'Liberto! Esta pessoa está livre do espírito maligno.'),
    'prayDenied': Tr("Dein Glaube 🙏 reicht nicht mehr für eine Gebetswelle. Geh zurück in die Stadt, lies in der Bibel oder bete in der Kirche.", "Your faith 🙏 is not enough for a prayer wave. Go back to the city, read the Bible or pray in a church.", es: "Tu fe 🙏 ya no alcanza para una ola de oración. Vuelve a la ciudad, lee la Biblia o ora en una iglesia.", fr: "Ta foi 🙏 ne suffit plus pour une vague de prière. Retourne en ville, lis la Bible ou prie dans une église.", pt: "Sua fé 🙏 não basta para uma onda de oração. Volte à cidade, leia a Bíblia ou ore numa igreja."),
    'worldDenied': Tr('Zu wenig Glaube 🙏 für die unsichtbare Welt.', 'Not enough faith 🙏 for the invisible world.', es: 'No tienes suficiente fe 🙏 para el mundo invisible.', fr: 'Pas assez de foi 🙏 pour le monde invisible.', pt: 'Fé 🙏 insuficiente para o mundo invisível.'),
    'lessonStarted': Tr('Lektion begonnen – jetzt üben.', 'Lesson started – now practise.', es: 'Lección iniciada: ahora a practicar.', fr: 'Leçon commencée – à toi de pratiquer.', pt: 'Lição iniciada – agora pratique.'),
    'lessonStep': Tr('Ein Übungsschritt geschafft.', 'One practice step done.', es: 'Un paso de práctica hecho.', fr: 'Une étape d’exercice réussie.', pt: 'Um passo de prática concluído.'),
    'learned': Tr('Gelernt! Du hast eine neue Fähigkeit.', 'Learned! You have a new skill.', es: '¡Aprendido! Tienes una nueva habilidad.', fr: 'Appris ! Tu as une nouvelle capacité.', pt: 'Aprendido! Você tem uma nova habilidade.'),
    'ability': Tr('Neue Fähigkeit im Gebet freigeschaltet!', 'New prayer ability unlocked!', es: '¡Nueva capacidad de oración desbloqueada!', fr: 'Nouvelle capacité de prière débloquée !', pt: 'Nova habilidade de oração desbloqueada!'),
    'missionDone': Tr('Mission erfüllt!', 'Mission accomplished!', es: '¡Misión cumplida!', fr: 'Mission accomplie !', pt: 'Missão cumprida!'),
    'practiceUp': Tr('Übung macht stark: Diese Disziplin ist eine Stufe gewachsen.', 'Practice makes strong: this discipline grew a level.', es: 'La práctica fortalece: esta disciplina subió un nivel.', fr: 'La pratique rend fort : cette discipline a gagné un niveau.', pt: 'A prática fortalece: esta disciplina subiu um nível.'),
  };

  /// What an action does, told before it happens (playtest 2026-10-31:
  /// "wäre sinnvoller vor der Aktion – damit man weiß, ob man das machen
  /// möchte"). Shown in the explanation box at the bottom when texts are
  /// on, until the player mutes it for that action.
  static const Map<ActionId, Tr> explanations = {
    ActionId.talk: Tr(
      'Ihr redet miteinander. Wer sich kennt, vertraut sich – die Person wird offener für Gott, ihr ✝️-Balken steigt. Jeder weitere Besuch vertieft eure Beziehung.',
      'You talk together. People who know each other trust each other – the person grows more open to God and their ✝️ bar rises. Every further visit deepens your relationship.',
      es: 'Conversáis. Quien se conoce confía: la persona se abre a Dios y su barra ✝️ sube. Cada visita profundiza vuestra relación.',
      fr: 'Vous discutez. Quand on se connaît, on se fait confiance – la personne s’ouvre à Dieu et sa barre ✝️ monte. Chaque visite approfondit votre relation.',
      pt: 'Vocês conversam. Quem se conhece confia – a pessoa se abre para Deus e a barra ✝️ sobe. Cada visita aprofunda o relacionamento.',
    ),
    ActionId.counsel: Tr(
      'Du hörst zu und begleitest seelsorgerlich. Das kostet dich Kraft (❤️), bewegt aber viel: Der Glaube der Person wächst deutlich, eure Beziehung wird tiefer. Bei Besessenen ist es der erste Schritt zur Befreiung.',
      'You listen and give pastoral care. It costs you strength (❤️) but moves a lot: the person\'s faith grows clearly and your relationship deepens. With possessed people it is the first step towards freedom.',
      es: 'Escuchas y acompañas. Te cuesta fuerzas (❤️), pero mueve mucho: la fe de la persona crece claramente y vuestra relación se hace más profunda. Con los poseídos es el primer paso hacia la libertad.',
      fr: 'Tu écoutes et accompagnes. Cela te coûte des forces (❤️), mais fait beaucoup : la foi de la personne grandit nettement et votre relation s’approfondit. Avec les possédés, c’est le premier pas vers la délivrance.',
      pt: 'Você ouve e aconselha. Custa forças (❤️), mas move muito: a fé da pessoa cresce bastante e o relacionamento se aprofunda. Com pessoas possessas é o primeiro passo para a libertação.',
    ),
    ActionId.pray: Tr(
      'Du bietest an, mit der Person zu beten (−🙏). Nimmt sie an, wächst ihr Glaube – und die unsichtbare Welt um euch wird ein wenig heller.',
      'You offer to pray with the person (−🙏). If they accept, their faith grows – and the invisible world around you becomes a little brighter.',
      es: 'Ofreces orar con la persona (−🙏). Si acepta, su fe crece y el mundo invisible a vuestro alrededor se ilumina un poco.',
      fr: 'Tu proposes de prier avec la personne (−🙏). Si elle accepte, sa foi grandit – et le monde invisible autour de vous s’éclaire un peu.',
      pt: 'Você se oferece para orar com a pessoa (−🙏). Se ela aceitar, a fé dela cresce – e o mundo invisível ao redor fica um pouco mais iluminado.',
    ),
    ActionId.bible: Tr(
      'Ihr lest gemeinsam in der Bibel. Gottes Wort spricht die Person an – ihr Glaube wächst, und auch dein eigener Glaube wird gestärkt (+🙏).',
      'You read the Bible together. God\'s word speaks to the person – their faith grows, and your own faith is strengthened too (+🙏).',
      es: 'Leéis juntos la Biblia. La Palabra de Dios habla a la persona: su fe crece, y tu propia fe también se fortalece (+🙏).',
      fr: 'Vous lisez la Bible ensemble. La Parole de Dieu parle à la personne – sa foi grandit, et ta propre foi est fortifiée aussi (+🙏).',
      pt: 'Vocês leem a Bíblia juntos. A Palavra de Deus fala com a pessoa – a fé dela cresce, e a sua também é fortalecida (+🙏).',
    ),
    ActionId.help: Tr(
      'Du hilfst der Person mit etwas Konkretem (−📦). Praktische Liebe öffnet Herzen: Ihr Glaube wächst, und du wirst selbst ermutigt (+🙏).',
      'You help the person with something concrete (−📦). Practical love opens hearts: their faith grows, and you are encouraged too (+🙏).',
      es: 'Ayudas a la persona con algo concreto (−📦). El amor práctico abre corazones: su fe crece y tú también te animas (+🙏).',
      fr: 'Tu aides la personne concrètement (−📦). L’amour en actes ouvre les cœurs : sa foi grandit, et toi aussi tu es encouragé (+🙏).',
      pt: 'Você ajuda a pessoa com algo concreto (−📦). O amor prático abre corações: a fé dela cresce e você também é encorajado (+🙏).',
    ),
    ActionId.convert: Tr(
      'Du lädst die Person ein, Jesus nachzufolgen. Ist ihr ✝️-Balken hoch genug, sagt sie Ja: Sie wird Christ, gehört zu deiner Gemeinde und macht ab jetzt ihre Umgebung in der unsichtbaren Welt heller.',
      'You invite the person to follow Jesus. If their ✝️ bar is high enough, they say yes: they become a Christian, belong to your church and from now on brighten their surroundings in the invisible world.',
      es: 'Invitas a la persona a seguir a Jesús. Si su barra ✝️ está bastante alta, dice que sí: se hace cristiana, pertenece a tu iglesia y desde ahora ilumina su entorno en el mundo invisible.',
      fr: 'Tu invites la personne à suivre Jésus. Si sa barre ✝️ est assez haute, elle dit oui : elle devient chrétienne, fait partie de ton Église et éclaire désormais son entourage dans le monde invisible.',
      pt: 'Você convida a pessoa a seguir Jesus. Se a barra ✝️ estiver alta o suficiente, ela diz sim: torna-se cristã, faz parte da sua igreja e a partir de agora ilumina os arredores no mundo invisível.',
    ),
    ActionId.lifeTalk: Tr(
      'Ihr sprecht über ein Thema aus ihrem Leben. Schritt für Schritt wird eine alte Wunde verarbeitet – danach ist die Person freier, ihr Glaube wächst, und als Christ wird sie stabiler.',
      'You talk about something from their life. Step by step an old wound is worked through – afterwards the person is freer, their faith grows, and as a Christian they become more stable.',
      es: 'Habláis de algo de su vida. Paso a paso se sana una herida antigua: después la persona es más libre, su fe crece y, como cristiana, se vuelve más estable.',
      fr: 'Vous parlez d’un épisode de sa vie. Pas à pas, une ancienne blessure est surmontée – ensuite la personne est plus libre, sa foi grandit et, en tant que chrétienne, elle devient plus stable.',
      pt: 'Vocês conversam sobre algo da vida dela. Passo a passo uma ferida antiga é tratada – depois a pessoa fica mais livre, a fé cresce e, como cristã, fica mais estável.',
    ),
    ActionId.readBible: Tr(
      'Du liest in Ruhe in der Bibel. Das füllt deinen Glauben auf (🙏) – die Kraft für alles, was du tust: Gespräche, Gebet und den Kampf in der unsichtbaren Welt.',
      'You read the Bible in peace. It refills your faith (🙏) – the strength for everything you do: talks, prayer and the battle in the invisible world.',
      es: 'Lees la Biblia con calma. Eso llena tu fe (🙏): la fuerza para todo lo que haces, conversaciones, oración y la batalla en el mundo invisible.',
      fr: 'Tu lis la Bible au calme. Cela remplit ta foi (🙏) – la force pour tout ce que tu fais : discussions, prière et combat dans le monde invisible.',
      pt: 'Você lê a Bíblia com calma. Isso enche sua fé (🙏) – a força para tudo o que você faz: conversas, oração e a batalha no mundo invisível.',
    ),
    ActionId.eat: Tr(
      'Du isst. Dein Vorrat (🍞) ist danach wieder voll – ohne Essen werden Gebete teurer und du verlierst Kraft.',
      'You eat. Afterwards your provisions (🍞) are full again – without food prayers cost more and you lose strength.',
      es: 'Comes. Después tus provisiones (🍞) vuelven a estar llenas; sin comida las oraciones cuestan más y pierdes fuerzas.',
      fr: 'Tu manges. Ensuite tes provisions (🍞) sont de nouveau pleines – sans nourriture, les prières coûtent plus et tu perds des forces.',
      pt: 'Você come. Depois suas provisões (🍞) ficam cheias de novo – sem comida as orações custam mais e você perde forças.',
    ),
    ActionId.sleep: Tr(
      'Du schläfst. Deine Kraft (❤️) wird aufgefüllt und ein neuer Tag beginnt. Über Nacht lebt die Stadt weiter – in der unsichtbaren Welt verändert sich manches.',
      'You sleep. Your strength (❤️) is restored and a new day begins. During the night the city lives on – some things change in the invisible world.',
      es: 'Duermes. Tu fuerza (❤️) se recupera y empieza un nuevo día. Por la noche la ciudad sigue viviendo: en el mundo invisible cambian algunas cosas.',
      fr: 'Tu dors. Tes forces (❤️) reviennent et une nouvelle journée commence. Pendant la nuit, la ville continue de vivre – certaines choses changent dans le monde invisible.',
      pt: 'Você dorme. Sua força (❤️) é restaurada e começa um novo dia. Durante a noite a cidade continua vivendo – algumas coisas mudam no mundo invisível.',
    ),
    ActionId.homePray: Tr(
      'Du betest zu Hause. Das stärkt deinen Glauben (+🙏) – und es verändert etwas: In der unsichtbaren Welt wird die Umgebung deines Hauses weit hinaus heller. Dunkelheit weicht, Dämonen haben es dort schwerer, und die Menschen in der Nähe werden mit der Zeit offener für Gott.',
      'You pray at home. It strengthens your faith (+🙏) – and it changes something: in the invisible world the area around your home grows brighter far and wide. Darkness retreats, demons have a harder time there, and over time the people nearby grow more open to God.',
      es: 'Oras en casa. Eso fortalece tu fe (+🙏) y cambia algo: en el mundo invisible el entorno de tu casa se ilumina a lo lejos. La oscuridad retrocede, a los demonios les cuesta más estar allí y, con el tiempo, la gente cercana se abre a Dios.',
      fr: 'Tu pries à la maison. Cela fortifie ta foi (+🙏) – et cela change quelque chose : dans le monde invisible, les environs de ta maison s’éclairent loin à la ronde. L’obscurité recule, les démons ont plus de mal à y rester, et avec le temps les gens proches s’ouvrent à Dieu.',
      pt: 'Você ora em casa. Isso fortalece sua fé (+🙏) – e muda algo: no mundo invisível os arredores da sua casa ficam iluminados ao longe. A escuridão recua, os demônios têm mais dificuldade ali e, com o tempo, as pessoas por perto se abrem para Deus.',
    ),
    ActionId.missions: Tr(
      'Am Missionsbrett siehst du, wer gerade Hilfe braucht, und deinen Lernweg bei den Mentoren. Mit 📍 nimmst du eine Aufgabe an – Karte und Pfeil zeigen dir dann den Weg.',
      'On the mission board you see who needs help right now, and your learning path with the mentors. With 📍 you accept a task – the map and the arrow then show you the way.',
      es: 'En el tablón de misiones ves quién necesita ayuda ahora y tu camino de aprendizaje con los mentores. Con 📍 aceptas una tarea: el mapa y la flecha te muestran el camino.',
      fr: 'Au tableau des missions, tu vois qui a besoin d’aide en ce moment et ton parcours d’apprentissage auprès des mentors. Avec 📍, tu acceptes une tâche – la carte et la flèche te montrent le chemin.',
      pt: 'No quadro de missões você vê quem precisa de ajuda agora e seu caminho de aprendizado com os mentores. Com 📍 você aceita uma tarefa – o mapa e a seta mostram o caminho.',
    ),
    ActionId.practicalHelp: Tr(
      'Du packst im Haus praktisch mit an (−📦). Taten sprechen: Die Bewohner kommen dem Glauben näher, und für eine Weile wird es um das Haus in der unsichtbaren Welt heller.',
      'You lend a hand in the home (−📦). Deeds speak: the residents come closer to faith, and for a while it grows brighter around the house in the invisible world.',
      es: 'Echas una mano en la casa (−📦). Los hechos hablan: los vecinos se acercan a la fe y, por un tiempo, alrededor de la casa se ilumina el mundo invisible.',
      fr: 'Tu donnes un coup de main dans la maison (−📦). Les actes parlent : les habitants se rapprochent de la foi, et pour un temps les environs de la maison s’éclairent dans le monde invisible.',
      pt: 'Você dá uma ajuda prática na casa (−📦). Atitudes falam: os moradores se aproximam da fé e, por um tempo, os arredores da casa ficam mais iluminados no mundo invisível.',
    ),
    ActionId.housePray: Tr(
      'Du betest für das Haus und seine Bewohner (−🙏). Gebet wirkt im Verborgenen: Die Umgebung wird in der unsichtbaren Welt heller, und die Bewohner werden offener.',
      'You pray for the home and its residents (−🙏). Prayer works in secret: the surroundings grow brighter in the invisible world and the residents grow more open.',
      es: 'Oras por la casa y sus habitantes (−🙏). La oración actúa en lo secreto: el entorno se ilumina en el mundo invisible y los vecinos se abren.',
      fr: 'Tu pries pour la maison et ses habitants (−🙏). La prière agit dans le secret : les environs s’éclairent dans le monde invisible et les habitants s’ouvrent.',
      pt: 'Você ora pela casa e por seus moradores (−🙏). A oração age em secreto: os arredores ficam iluminados no mundo invisível e os moradores se abrem.',
    ),
    ActionId.houseVisit: Tr(
      'Du bist zum Kaffee eingeladen. Gemeinschaft tut gut: Du bekommst Kraft (❤️) und etwas zu essen (🍞), und die Beziehung zu den Bewohnern wächst.',
      'You are invited for coffee. Fellowship does you good: you get strength (❤️) and something to eat (🍞), and your relationship with the residents grows.',
      es: 'Te invitan a un café. La comunión hace bien: recibes fuerza (❤️) y algo de comer (🍞), y crece la relación con los vecinos.',
      fr: 'On t’invite à prendre un café. La communion fait du bien : tu reçois des forces (❤️) et à manger (🍞), et ta relation avec les habitants grandit.',
      pt: 'Você é convidado para um café. A comunhão faz bem: você ganha força (❤️) e algo para comer (🍞), e o relacionamento com os moradores cresce.',
    ),
    ActionId.discipleshipGroup: Tr(
      'Du leitest eine Jüngerschaftsgruppe (−🙏). Die Christen im Haus wachsen im Glauben, du gewinnst Weisheit (📖) – und die Umgebung wird in der unsichtbaren Welt dauerhaft heller.',
      'You lead a discipleship group (−🙏). The Christians in the home grow in faith, you gain insight (📖) – and the surroundings grow lastingly brighter in the invisible world.',
      es: 'Diriges un grupo de discipulado (−🙏). Los cristianos de la casa crecen en la fe, tú ganas sabiduría (📖) y el entorno se ilumina de forma duradera en el mundo invisible.',
      fr: 'Tu animes un groupe de disciples (−🙏). Les chrétiens de la maison grandissent dans la foi, tu gagnes de la sagesse (📖) – et les environs s’éclairent durablement dans le monde invisible.',
      pt: 'Você conduz um grupo de discipulado (−🙏). Os cristãos da casa crescem na fé, você ganha sabedoria (📖) – e os arredores ficam iluminados de forma duradoura no mundo invisível.',
    ),
    ActionId.fellowship: Tr(
      'Hier wohnen nur Christen. Du betest mit deinen Geschwistern und schöpfst neue Kraft (🙏) – wie zu Hause. „Wo zwei oder drei versammelt sind in meinem Namen, da bin ich mitten unter ihnen.“ So musst du zum Auftanken nicht jedes Mal nach Hause – einmal am Tag je Familie.',
      'Only Christians live here. You pray with your brothers and sisters and draw new strength (🙏) – as at home. “Where two or three gather in my name, there am I with them.” So you need not go home every time to refill – once a day per family.',
      es: 'Aquí solo viven cristianos. Oras con tus hermanos y recibes nuevas fuerzas (🙏), como en casa. «Donde están dos o tres congregados en mi nombre, allí estoy yo en medio de ellos.» Así no tienes que volver a casa cada vez para recargar: una vez al día por familia.',
      fr: 'Ici n’habitent que des chrétiens. Tu pries avec tes frères et sœurs et tu reprends des forces (🙏) – comme à la maison. « Là où deux ou trois sont assemblés en mon nom, je suis au milieu d’eux. » Ainsi, tu n’as pas besoin de rentrer à chaque fois pour te ressourcer – une fois par jour et par famille.',
      pt: 'Aqui só moram cristãos. Você ora com seus irmãos e recebe novas forças (🙏) – como em casa. “Onde estiverem dois ou três reunidos em meu nome, aí estou eu no meio deles.” Assim você não precisa voltar para casa toda vez para recarregar – uma vez por dia em cada família.',
    ),
    ActionId.blessHousehold: Tr(
      'Du segnest alle Haushalte im Wohnblock (−🙏). Viele Menschen werden auf einmal berührt, und um das Haus wird es für eine Weile heller.',
      'You bless every household in the block (−🙏). Many people are touched at once, and for a while it grows brighter around the building.',
      es: 'Bendices todos los hogares del bloque (−🙏). Muchas personas son tocadas a la vez y, por un tiempo, alrededor del edificio hay más luz.',
      fr: 'Tu bénis tous les foyers de l’immeuble (−🙏). Beaucoup de personnes sont touchées à la fois, et pour un temps les environs s’éclairent.',
      pt: 'Você abençoa todos os lares do prédio (−🙏). Muitas pessoas são tocadas de uma vez e, por um tempo, os arredores ficam mais iluminados.',
    ),
    ActionId.sundayService: Tr(
      'Du hältst einen Gottesdienst (−📦 −❤️). Die Gemeinde feiert Gott: Dein Glaube wird stark gefüllt (🙏), und das ganze Viertel wird in der unsichtbaren Welt für lange Zeit heller.',
      'You hold a service (−📦 −❤️). The church celebrates God: your faith is filled up strongly (🙏), and the whole quarter grows brighter in the invisible world for a long time.',
      es: 'Celebras un culto (−📦 −❤️). La iglesia celebra a Dios: tu fe se llena mucho (🙏) y todo el barrio se ilumina en el mundo invisible durante largo tiempo.',
      fr: 'Tu célèbres un culte (−📦 −❤️). L’Église célèbre Dieu : ta foi est largement remplie (🙏), et tout le quartier s’éclaire longtemps dans le monde invisible.',
      pt: 'Você realiza um culto (−📦 −❤️). A igreja celebra a Deus: sua fé fica bem cheia (🙏) e o bairro inteiro fica iluminado no mundo invisível por muito tempo.',
    ),
    ActionId.worship: Tr(
      'Du betest Gott an. Lobpreis füllt deinen Glauben (🙏) und macht die Umgebung der Kirche in der unsichtbaren Welt dauerhaft heller – ein Leuchtturm im Viertel.',
      'You worship God. Worship fills your faith (🙏) and makes the church\'s surroundings lastingly brighter in the invisible world – a lighthouse in the quarter.',
      es: 'Adoras a Dios. La alabanza llena tu fe (🙏) e ilumina de forma duradera el entorno de la iglesia en el mundo invisible: un faro en el barrio.',
      fr: 'Tu adores Dieu. La louange remplit ta foi (🙏) et éclaire durablement les environs de l’église dans le monde invisible – un phare dans le quartier.',
      pt: 'Você adora a Deus. O louvor enche sua fé (🙏) e ilumina de forma duradoura os arredores da igreja no mundo invisível – um farol no bairro.',
    ),
    ActionId.medicalHelp: Tr(
      'Du wirst versorgt (−📦). Kraft (❤️) und Vorrat (🍞) sind danach wieder voll – so kannst du weiter für die Menschen da sein.',
      'You are looked after (−📦). Afterwards strength (❤️) and provisions (🍞) are full again – so you can keep being there for people.',
      es: 'Te atienden (−📦). Después fuerza (❤️) y provisiones (🍞) están llenas: así puedes seguir estando para la gente.',
      fr: 'On prend soin de toi (−📦). Ensuite tes forces (❤️) et tes provisions (🍞) sont pleines – tu peux continuer à être là pour les gens.',
      pt: 'Você é atendido (−📦). Depois força (❤️) e provisões (🍞) ficam cheias – assim você pode continuar presente para as pessoas.',
    ),
    ActionId.counseling: Tr(
      'Du besuchst Kranke als Seelsorger. Zuhören tröstet: Patienten und Angehörige werden offener für den Glauben.',
      'You visit the sick as a pastor. Listening comforts: patients and relatives grow more open to faith.',
      es: 'Visitas a los enfermos como pastor. Escuchar consuela: pacientes y familiares se abren a la fe.',
      fr: 'Tu rends visite aux malades comme aumônier. Écouter console : patients et proches s’ouvrent à la foi.',
      pt: 'Você visita os doentes como capelão. Ouvir consola: pacientes e familiares se abrem à fé.',
    ),
    ActionId.chapelService: Tr(
      'Du hältst eine Andacht in der Kapelle (−🙏). Kranke und Angehörige schöpfen Hoffnung – viele kommen dem Glauben näher. Es zählt auch als Gottesdienst ⛪.',
      'You hold a chapel service (−🙏). The sick and their families find hope – many come closer to faith. It also counts as a service ⛪.',
      es: 'Celebras un culto en la capilla (−🙏). Enfermos y familiares encuentran esperanza; muchos se acercan a la fe. También cuenta como culto ⛪.',
      fr: 'Tu célèbres un culte à la chapelle (−🙏). Malades et proches retrouvent l’espérance – beaucoup se rapprochent de la foi. Cela compte aussi comme culte ⛪.',
      pt: 'Você realiza um culto na capela (−🙏). Doentes e familiares encontram esperança – muitos se aproximam da fé. Também conta como culto ⛪.',
    ),
    ActionId.letterToManagement: Tr(
      'Du schreibst der Leitung (−📦). Ein freundlicher Brief öffnet Türen – die Schule wird ein Stück offener für das, was dir wichtig ist.',
      'You write to the management (−📦). A friendly letter opens doors – the school becomes a little more open to what matters to you.',
      es: 'Escribes a la dirección (−📦). Una carta amable abre puertas: la escuela se abre un poco a lo que te importa.',
      fr: 'Tu écris à la direction (−📦). Une lettre aimable ouvre des portes – l’école devient un peu plus ouverte à ce qui te tient à cœur.',
      pt: 'Você escreve à direção (−📦). Uma carta gentil abre portas – a escola fica um pouco mais aberta ao que importa para você.',
    ),
    ActionId.talkDirector: Tr(
      'Du sprichst mit der Leitung. Vertrauen an der Spitze öffnet die ganze Schule – danach darfst du auch einen Wertevortrag 🎤 halten.',
      'You talk with the head. Trust at the top opens the whole school – afterwards you may also give a talk on values 🎤.',
      es: 'Hablas con la dirección. La confianza arriba abre toda la escuela: después también puedes dar una charla sobre valores 🎤.',
      fr: 'Tu parles avec la direction. La confiance au sommet ouvre toute l’école – ensuite tu peux aussi donner un exposé sur les valeurs 🎤.',
      pt: 'Você fala com a direção. A confiança no topo abre toda a escola – depois você também pode dar uma palestra sobre valores 🎤.',
    ),
    ActionId.valueLecture: Tr(
      'Du sprichst vor allen über Werte. Viele junge Menschen hören zu – der Glaube vieler wächst ein wenig.',
      'You speak to everyone about values. Many young people listen – many grow a little in faith.',
      es: 'Hablas a todos sobre valores. Muchos jóvenes escuchan y la fe de muchos crece un poco.',
      fr: 'Tu parles à tous des valeurs. Beaucoup de jeunes écoutent – la foi de beaucoup grandit un peu.',
      pt: 'Você fala para todos sobre valores. Muitos jovens ouvem – a fé de muitos cresce um pouco.',
    ),
    ActionId.prayerCircle: Tr(
      'Du leitest einen Gebetskreis (−🙏). Gemeinsames Gebet schenkt dir Weisheit (📖) und macht die Umgebung für einen Tag in der unsichtbaren Welt heller.',
      'You lead a prayer circle (−🙏). Praying together gives you insight (📖) and brightens the surroundings in the invisible world for a day.',
      es: 'Diriges un círculo de oración (−🙏). Orar juntos te da sabiduría (📖) e ilumina el entorno en el mundo invisible durante un día.',
      fr: 'Tu animes un cercle de prière (−🙏). Prier ensemble te donne de la sagesse (📖) et éclaire les environs dans le monde invisible pendant une journée.',
      pt: 'Você conduz um círculo de oração (−🙏). Orar juntos lhe dá sabedoria (📖) e ilumina os arredores no mundo invisível por um dia.',
    ),
    ActionId.funeral: Tr(
      'Du hältst eine Beerdigung. In der Trauer sprichst du von der Hoffnung auf die Auferstehung – die Trauernden sind berührt. Danach kannst du sie trösten.',
      'You hold a funeral. In grief you speak of the hope of the resurrection – the mourners are moved. Afterwards you can comfort them.',
      es: 'Celebras un funeral. En el duelo hablas de la esperanza de la resurrección y los que lloran se conmueven. Después puedes consolarlos.',
      fr: 'Tu célèbres des obsèques. Dans le deuil, tu parles de l’espérance de la résurrection – les personnes endeuillées sont touchées. Ensuite tu peux les consoler.',
      pt: 'Você realiza um funeral. No luto você fala da esperança da ressurreição – os enlutados ficam tocados. Depois você pode consolá-los.',
    ),
    ActionId.comfort: Tr(
      'Du tröstest Trauernde (−❤️ −🍞). Das kostet sehr viel Kraft – aber es berührt Menschen tief, ihr Glaube wächst stark.',
      'You comfort the mourners (−❤️ −🍞). It takes a lot of strength – but it touches people deeply and their faith grows strongly.',
      es: 'Consuelas a los que lloran (−❤️ −🍞). Cuesta muchísima fuerza, pero toca profundamente a las personas y su fe crece mucho.',
      fr: 'Tu consoles les personnes en deuil (−❤️ −🍞). Cela coûte énormément de forces – mais touche profondément et leur foi grandit beaucoup.',
      pt: 'Você consola os enlutados (−❤️ −🍞). Custa muita força – mas toca profundamente as pessoas e a fé delas cresce muito.',
    ),
    ActionId.blessPolice: Tr(
      'Du segnest die Polizei (−🙏). Wer für Sicherheit sorgt, wird gestärkt – und für eine Weile wird es um die Wache in der unsichtbaren Welt heller.',
      'You bless the police (−🙏). Those who keep people safe are strengthened – and for a while it grows brighter around the station in the invisible world.',
      es: 'Bendices a la policía (−🙏). Quienes cuidan la seguridad se fortalecen y, por un tiempo, alrededor de la comisaría se ilumina el mundo invisible.',
      fr: 'Tu bénis la police (−🙏). Ceux qui veillent sur la sécurité sont fortifiés – et pour un temps les environs du commissariat s’éclairent dans le monde invisible.',
      pt: 'Você abençoa a polícia (−🙏). Quem cuida da segurança é fortalecido – e por um tempo os arredores da delegacia ficam iluminados no mundo invisível.',
    ),
    ActionId.intercede: Tr(
      'Du tust Fürbitte für dieses Haus (−🙏). Heute öffnet sich die Tür leichter, und Gespräche hier bewirken mehr.',
      'You intercede for this home (−🙏). Today the door opens more easily and talks here achieve more.',
      es: 'Intercedes por esta casa (−🙏). Hoy la puerta se abre más fácilmente y las conversaciones aquí logran más.',
      fr: 'Tu intercèdes pour cette maison (−🙏). Aujourd’hui la porte s’ouvre plus facilement et les discussions ici portent davantage.',
      pt: 'Você intercede por esta casa (−🙏). Hoje a porta se abre mais fácil e as conversas aqui rendem mais.',
    ),
    ActionId.fast: Tr(
      'Du fastest (−🍞). Fasten richtet das Herz auf Gott aus: Bis du nach Hause kommst, kostet Gebet in der unsichtbaren Welt weniger Glauben.',
      'You fast (−🍞). Fasting turns the heart towards God: until you get home, prayer in the invisible world costs less faith.',
      es: 'Ayunas (−🍞). El ayuno dirige el corazón a Dios: hasta que vuelvas a casa, orar en el mundo invisible cuesta menos fe.',
      fr: 'Tu jeûnes (−🍞). Le jeûne tourne le cœur vers Dieu : jusqu’à ton retour à la maison, la prière dans le monde invisible coûte moins de foi.',
      pt: 'Você jejua (−🍞). O jejum volta o coração para Deus: até você voltar para casa, orar no mundo invisível custa menos fé.',
    ),
    ActionId.preach: Tr(
      'Du predigst. Alle Menschen in der Nähe hören zu – viele kommen dem Glauben näher, sehr Feindselige wenden sich ab.',
      'You preach. Everyone nearby listens – many come closer to faith, very hostile people turn away.',
      es: 'Predicas. Todos los de alrededor escuchan: muchos se acercan a la fe; los muy hostiles se apartan.',
      fr: 'Tu prêches. Tous ceux qui sont autour écoutent – beaucoup se rapprochent de la foi, les plus hostiles se détournent.',
      pt: 'Você prega. Todos ao redor ouvem – muitos se aproximam da fé, os muito hostis se afastam.',
    ),
    ActionId.mayorAudience: Tr(
      'Du hast einen Termin beim Bürgermeister. Ein gutes Wort an der Spitze öffnet Türen in der ganzen Stadt.',
      'You meet the mayor. A good word at the top opens doors in the whole city.',
      es: 'Tienes una cita con el alcalde. Una buena palabra en lo más alto abre puertas en toda la ciudad.',
      fr: 'Tu as rendez-vous avec le maire. Une bonne parole au sommet ouvre des portes dans toute la ville.',
      pt: 'Você tem uma audiência com o prefeito. Uma boa palavra no topo abre portas na cidade inteira.',
    ),
    ActionId.prayForPoliticians: Tr(
      'Du betest für die Regierenden (1 Tim 2,1–2). Das kostet viel (🙏 ❤️ 🍞), wirkt aber auf die ganze Stadt 🌍.',
      'You pray for those in authority (1 Tim 2:1–2). It costs a lot (🙏 ❤️ 🍞) but affects the whole city 🌍.',
      es: 'Oras por los gobernantes (1 Ti 2:1–2). Cuesta mucho (🙏 ❤️ 🍞), pero influye en toda la ciudad 🌍.',
      fr: 'Tu pries pour les dirigeants (1 Tm 2,1–2). Cela coûte beaucoup (🙏 ❤️ 🍞), mais agit sur toute la ville 🌍.',
      pt: 'Você ora pelos governantes (1 Tm 2:1–2). Custa muito (🙏 ❤️ 🍞), mas influencia a cidade inteira 🌍.',
    ),
    ActionId.travel: Tr(
      'Du fährst mit dem Zug (−📦) und bist schnell in einem anderen Teil der Stadt.',
      'You take the train (−📦) and are quickly in another part of the city.',
      es: 'Tomas el tren (−📦) y llegas rápido a otra parte de la ciudad.',
      fr: 'Tu prends le train (−📦) et tu arrives vite dans un autre quartier.',
      pt: 'Você pega o trem (−📦) e chega rápido a outra parte da cidade.',
    ),
    ActionId.majorEvent: Tr(
      'Du veranstaltest ein Großevent im Stadion (−🙏 −📦). Tausende hören die Botschaft – und du gewinnst Weisheit (📖).',
      'You hold a big event in the stadium (−🙏 −📦). Thousands hear the message – and you gain insight (📖).',
      es: 'Organizas un gran evento en el estadio (−🙏 −📦). Miles escuchan el mensaje y tú ganas sabiduría (📖).',
      fr: 'Tu organises un grand événement au stade (−🙏 −📦). Des milliers entendent le message – et tu gagnes de la sagesse (📖).',
      pt: 'Você promove um grande evento no estádio (−🙏 −📦). Milhares ouvem a mensagem – e você ganha sabedoria (📖).',
    ),
    ActionId.talkBoss: Tr(
      'Du sprichst mit der Chefin oder dem Chef. So öffnen sich Türen im ganzen Geschäft.',
      'You talk with the boss. That opens doors in the whole business.',
      es: 'Hablas con el jefe o la jefa. Así se abren puertas en todo el negocio.',
      fr: 'Tu parles avec le patron ou la patronne. Cela ouvre des portes dans toute l’entreprise.',
      pt: 'Você fala com o chefe ou a chefe. Assim se abrem portas em todo o negócio.',
    ),
    ActionId.shopping: Tr(
      'Du kaufst ein (−📦). Vorrat (🍞) und Kraft (❤️) werden aufgefüllt.',
      'You go shopping (−📦). Provisions (🍞) and strength (❤️) are refilled.',
      es: 'Compras (−📦). Provisiones (🍞) y fuerza (❤️) se reponen.',
      fr: 'Tu fais les courses (−📦). Provisions (🍞) et forces (❤️) sont rechargées.',
      pt: 'Você faz compras (−📦). Provisões (🍞) e força (❤️) são repostas.',
    ),
    ActionId.bless: Tr(
      'Du segnest das Geschäft (−🙏). Segen bringt Licht in den Arbeitsalltag – für eine Weile wird es hier in der unsichtbaren Welt heller.',
      'You bless the business (−🙏). Blessing brings light into everyday work – for a while it grows brighter here in the invisible world.',
      es: 'Bendices el negocio (−🙏). La bendición trae luz a la vida laboral: por un tiempo aquí se ilumina el mundo invisible.',
      fr: 'Tu bénis le commerce (−🙏). La bénédiction apporte de la lumière au quotidien du travail – pour un temps, tout s’éclaire ici dans le monde invisible.',
      pt: 'Você abençoa o negócio (−🙏). A bênção traz luz ao dia a dia do trabalho – por um tempo, aqui fica mais iluminado no mundo invisível.',
    ),
    ActionId.requestDonation: Tr(
      'Du bittest um Spenden (−❤️ −🍞). Vielleicht bekommst du Material (📦) für deine Arbeit.',
      'You ask for donations (−❤️ −🍞). Maybe you receive supplies (📦) for your work.',
      es: 'Pides donativos (−❤️ −🍞). Quizá recibas materiales (📦) para tu labor.',
      fr: 'Tu demandes des dons (−❤️ −🍞). Tu recevras peut-être du matériel (📦) pour ton travail.',
      pt: 'Você pede doações (−❤️ −🍞). Talvez receba materiais (📦) para seu trabalho.',
    ),
    ActionId.genericPray: Tr(
      'Du betest hier. Das stärkt deinen Glauben ein wenig, und die Menschen hier kommen dem Glauben etwas näher.',
      'You pray here. It strengthens your faith a little and the people here come a little closer to faith.',
      es: 'Oras aquí. Eso fortalece un poco tu fe y la gente de aquí se acerca un poco a la fe.',
      fr: 'Tu pries ici. Cela fortifie un peu ta foi, et les gens d’ici se rapprochent un peu de la foi.',
      pt: 'Você ora aqui. Isso fortalece um pouco sua fé e as pessoas daqui se aproximam um pouco da fé.',
    ),
    ActionId.witness: Tr(
      'Du erzählst von Jesus (−📦). Wer zuhört, kommt dem Glauben näher.',
      'You tell people about Jesus (−📦). Whoever listens comes closer to faith.',
      es: 'Hablas de Jesús (−📦). Quien escucha se acerca a la fe.',
      fr: 'Tu parles de Jésus (−📦). Ceux qui écoutent se rapprochent de la foi.',
      pt: 'Você fala de Jesus (−📦). Quem ouve se aproxima da fé.',
    ),
    ActionId.distribute: Tr(
      'Du verteilst etwas (−📦). Großzügigkeit öffnet Herzen für den Glauben.',
      'You hand things out (−📦). Generosity opens hearts to faith.',
      es: 'Repartes algo (−📦). La generosidad abre corazones a la fe.',
      fr: 'Tu distribues quelque chose (−📦). La générosité ouvre les cœurs à la foi.',
      pt: 'Você distribui algo (−📦). A generosidade abre corações para a fé.',
    ),
    ActionId.blessVehicles: Tr(
      'Du segnest Fahrzeuge und Mannschaft (−🙏). Die Menschen, die anderen helfen, werden gestärkt und offener für den Glauben.',
      'You bless the vehicles and the crew (−🙏). Those who help others are strengthened and more open to faith.',
      es: 'Bendices los vehículos y al equipo (−🙏). Quienes ayudan a otros se fortalecen y se abren a la fe.',
      fr: 'Tu bénis les véhicules et l’équipe (−🙏). Ceux qui aident les autres sont fortifiés et s’ouvrent à la foi.',
      pt: 'Você abençoa os veículos e a equipe (−🙏). Quem ajuda os outros é fortalecido e se abre à fé.',
    ),
    ActionId.chaplaincy: Tr(
      'Du begleitest nach einem schweren Einsatz seelsorgerlich (−❤️ −🍞). Das berührt die Mannschaft – und du gewinnst etwas Weisheit (📖).',
      'You give pastoral care after a hard call-out (−❤️ −🍞). It touches the crew – and you gain a little insight (📖).',
      es: 'Acompañas tras una intervención dura (−❤️ −🍞). Eso toca al equipo y tú ganas algo de sabiduría (📖).',
      fr: 'Tu accompagnes après une intervention difficile (−❤️ −🍞). Cela touche l’équipe – et tu gagnes un peu de sagesse (📖).',
      pt: 'Você aconselha depois de uma ocorrência difícil (−❤️ −🍞). Isso toca a equipe – e você ganha um pouco de sabedoria (📖).',
    ),
    ActionId.bringMeal: Tr(
      'Du bringst der Schicht ein Essen (−📦). Kleine Freundlichkeiten machen froh und öffnen Herzen.',
      'You bring the shift a meal (−📦). Small kindnesses bring joy and open hearts.',
      es: 'Llevas comida al turno (−📦). Los pequeños gestos alegran y abren corazones.',
      fr: 'Tu apportes un repas à l’équipe (−📦). Les petites attentions réjouissent et ouvrent les cœurs.',
      pt: 'Você leva uma refeição ao turno (−📦). Pequenas gentilezas alegram e abrem corações.',
    ),
    ActionId.sendCards: Tr(
      'Du verschickst Ermutigungskarten (−📦). Viele Menschen werden ermutigt und kommen dem Glauben näher.',
      'You send encouragement cards (−📦). Many people are encouraged and come closer to faith.',
      es: 'Envías tarjetas de ánimo (−📦). Mucha gente se anima y se acerca a la fe.',
      fr: 'Tu envoies des cartes d’encouragement (−📦). Beaucoup de gens sont encouragés et se rapprochent de la foi.',
      pt: 'Você envia cartões de encorajamento (−📦). Muitas pessoas são encorajadas e se aproximam da fé.',
    ),
    ActionId.study: Tr(
      'Du studierst in Ruhe (−🍞). Das vertieft deine Weisheit (📖).',
      'You study in peace (−🍞). It deepens your insight (📖).',
      es: 'Estudias con calma (−🍞). Eso profundiza tu sabiduría (📖).',
      fr: 'Tu étudies au calme (−🍞). Cela approfondit ta sagesse (📖).',
      pt: 'Você estuda com calma (−🍞). Isso aprofunda sua sabedoria (📖).',
    ),
    ActionId.bookCircle: Tr(
      'Du leitest einen Lesekreis (−📦). Die Besucher sprechen über Lebensfragen und kommen dem Glauben näher.',
      'You lead a reading circle (−📦). The visitors talk about life\'s questions and come closer to faith.',
      es: 'Diriges un círculo de lectura (−📦). Los visitantes hablan de las preguntas de la vida y se acercan a la fe.',
      fr: 'Tu animes un cercle de lecture (−📦). Les visiteurs parlent des questions de la vie et se rapprochent de la foi.',
      pt: 'Você conduz um círculo de leitura (−📦). Os visitantes falam sobre as questões da vida e se aproximam da fé.',
    ),
    ActionId.churchHistory: Tr(
      'Du siehst dir die Kirchengeschichte an (−🍞). Aus der Vergangenheit lernst du – ein wenig Weisheit (📖).',
      'You look at the church history (−🍞). You learn from the past – a little insight (📖).',
      es: 'Miras la historia de la Iglesia (−🍞). Aprendes del pasado: un poco de sabiduría (📖).',
      fr: 'Tu regardes l’histoire de l’Église (−🍞). Tu apprends du passé – un peu de sagesse (📖).',
      pt: 'Você observa a história da Igreja (−🍞). Aprende com o passado – um pouco de sabedoria (📖).',
    ),
    ActionId.workShift: Tr(
      'Du arbeitest eine Schicht mit (−❤️ −🍞). Dafür bekommst du Material (📦) – und lernst die Arbeiter besser kennen.',
      'You work a shift (−❤️ −🍞). In return you get supplies (📦) – and get to know the workers better.',
      es: 'Trabajas un turno (−❤️ −🍞). A cambio recibes materiales (📦) y conoces mejor a los trabajadores.',
      fr: 'Tu fais une équipe de travail (−❤️ −🍞). En échange tu reçois du matériel (📦) – et tu apprends à mieux connaître les ouvriers.',
      pt: 'Você trabalha um turno (−❤️ −🍞). Em troca recebe materiais (📦) – e conhece melhor os trabalhadores.',
    ),
    ActionId.prayWorkers: Tr(
      'Du betest für die Sicherheit der Arbeiter. Das stärkt deinen Glauben, und die Menschen hier kommen dem Glauben näher.',
      'You pray for the workers\' safety. It strengthens your faith and the people here come closer to faith.',
      es: 'Oras por la seguridad de los trabajadores. Eso fortalece tu fe y la gente de aquí se acerca a la fe.',
      fr: 'Tu pries pour la sécurité des ouvriers. Cela fortifie ta foi, et les gens d’ici se rapprochent de la foi.',
      pt: 'Você ora pela segurança dos trabalhadores. Isso fortalece sua fé e as pessoas daqui se aproximam da fé.',
    ),
  };

  /// Short labels for things that are no action (texts on).
  static const Map<String, Tr> labels = {
    'look': Tr('Umschauen', 'Look around', es: 'Mirar', fr: 'Regarder', pt: 'Olhar'),
    'openAir': Tr('Freiversammlung', 'Open-air meeting', es: 'Reunión al aire libre', fr: 'Réunion en plein air', pt: 'Reunião ao ar livre'),
    'churchOverview': Tr('Gemeinde', 'Church', es: 'Iglesia', fr: 'Église', pt: 'Igreja'),
    'upgrades': Tr('Ausrüstung', 'Equipment', es: 'Equipo', fr: 'Équipement', pt: 'Equipamento'),
    'doIt': Tr('Machen', 'Do it', es: 'Hacerlo', fr: 'Le faire', pt: 'Fazer'),
    'muteAndDo': Tr('Machen, nicht mehr erklären', 'Do it, don\'t explain again', es: 'Hacerlo y no volver a explicar', fr: 'Le faire, ne plus expliquer', pt: 'Fazer e não explicar mais'),
    'cancel': Tr('Abbrechen', 'Cancel', es: 'Cancelar', fr: 'Annuler', pt: 'Cancelar'),
  };

  /// Short names of the actions – captions under the buttons when texts
  /// are on (TextMode).
  static const Map<ActionId, Tr> actionNames = {
    ActionId.talk: Tr('Gespräch', 'Talk', es: 'Conversar', fr: 'Discuter', pt: 'Conversar'),
    ActionId.counsel: Tr('Seelsorge', 'Counsel', es: 'Acompañar', fr: 'Accompagner', pt: 'Aconselhar'),
    ActionId.pray: Tr('Beten', 'Pray', es: 'Orar', fr: 'Prier', pt: 'Orar'),
    ActionId.bible: Tr('Gemeinsam Bibel lesen', 'Read the Bible together', es: 'Leer la Biblia juntos', fr: 'Lire la Bible ensemble', pt: 'Ler a Bíblia juntos'),
    ActionId.help: Tr('Helfen', 'Help', es: 'Ayudar', fr: 'Aider', pt: 'Ajudar'),
    ActionId.convert: Tr('Zum Glauben einladen', 'Invite to faith', es: 'Invitar a la fe', fr: 'Inviter à la foi', pt: 'Convidar à fé'),
    ActionId.lifeTalk: Tr('Lebensgespräch', 'Life talk', es: 'Charla de vida', fr: 'Parler de sa vie', pt: 'Conversa de vida'),
    ActionId.readBible: Tr('Bibel lesen', 'Read the Bible', es: 'Leer la Biblia', fr: 'Lire la Bible', pt: 'Ler a Bíblia'),
    ActionId.eat: Tr('Essen', 'Eat', es: 'Comer', fr: 'Manger', pt: 'Comer'),
    ActionId.sleep: Tr('Schlafen', 'Sleep', es: 'Dormir', fr: 'Dormir', pt: 'Dormir'),
    ActionId.homePray: Tr('Gebet zu Hause', 'Pray at home', es: 'Orar en casa', fr: 'Prier à la maison', pt: 'Orar em casa'),
    ActionId.missions: Tr('Missionen', 'Missions', es: 'Misiones', fr: 'Missions', pt: 'Missões'),
    ActionId.practicalHelp: Tr('Praktisch helfen', 'Practical help', es: 'Ayuda práctica', fr: 'Aide pratique', pt: 'Ajuda prática'),
    ActionId.housePray: Tr('Für das Haus beten', 'Pray for the home', es: 'Orar por la casa', fr: 'Prier pour la maison', pt: 'Orar pela casa'),
    ActionId.houseVisit: Tr('Kaffeebesuch', 'Coffee visit', es: 'Visita con café', fr: 'Visite autour d’un café', pt: 'Visita com café'),
    ActionId.discipleshipGroup: Tr('Jüngerschaftsgruppe', 'Discipleship group', es: 'Grupo de discipulado', fr: 'Groupe de disciples', pt: 'Grupo de discipulado'),
    ActionId.fellowship: Tr('Gebet mit Geschwistern', 'Prayer with fellow believers', es: 'Oración con los hermanos', fr: 'Prière avec les frères et sœurs', pt: 'Oração com os irmãos'),
    ActionId.blessHousehold: Tr('Haushalte segnen', 'Bless households', es: 'Bendecir hogares', fr: 'Bénir les foyers', pt: 'Abençoar lares'),
    ActionId.sundayService: Tr('Gottesdienst', 'Sunday service', es: 'Culto dominical', fr: 'Culte du dimanche', pt: 'Culto de domingo'),
    ActionId.worship: Tr('Lobpreis', 'Worship', es: 'Alabanza', fr: 'Louange', pt: 'Louvor'),
    ActionId.medicalHelp: Tr('Medizinische Hilfe', 'Medical help', es: 'Ayuda médica', fr: 'Aide médicale', pt: 'Ajuda médica'),
    ActionId.counseling: Tr('Krankenseelsorge', 'Pastoral care', es: 'Cuidado pastoral', fr: 'Aumônerie', pt: 'Capelania'),
    ActionId.chapelService: Tr('Andacht in der Kapelle', 'Chapel service', es: 'Culto en la capilla', fr: 'Culte à la chapelle', pt: 'Culto na capela'),
    ActionId.letterToManagement: Tr('Brief an die Leitung', 'Letter to the management', es: 'Carta a la dirección', fr: 'Lettre à la direction', pt: 'Carta à direção'),
    ActionId.talkDirector: Tr('Gespräch mit der Leitung', 'Talk to the head', es: 'Hablar con la dirección', fr: 'Parler à la direction', pt: 'Falar com a direção'),
    ActionId.valueLecture: Tr('Wertevortrag', 'Talk on values', es: 'Charla sobre valores', fr: 'Exposé sur les valeurs', pt: 'Palestra sobre valores'),
    ActionId.prayerCircle: Tr('Gebetskreis', 'Prayer circle', es: 'Círculo de oración', fr: 'Cercle de prière', pt: 'Círculo de oração'),
    ActionId.funeral: Tr('Beerdigung', 'Funeral', es: 'Funeral', fr: 'Obsèques', pt: 'Funeral'),
    ActionId.comfort: Tr('Trösten', 'Comfort', es: 'Consolar', fr: 'Consoler', pt: 'Consolar'),
    ActionId.blessPolice: Tr('Polizei segnen', 'Bless the police', es: 'Bendecir a la policía', fr: 'Bénir la police', pt: 'Abençoar a polícia'),
    ActionId.intercede: Tr('Fürbitte', 'Intercede', es: 'Interceder', fr: 'Intercéder', pt: 'Interceder'),
    ActionId.fast: Tr('Fasten', 'Fast', es: 'Ayunar', fr: 'Jeûner', pt: 'Jejuar'),
    ActionId.preach: Tr('Predigen', 'Preach', es: 'Predicar', fr: 'Prêcher', pt: 'Pregar'),
    ActionId.mayorAudience: Tr('Termin beim Bürgermeister', 'Meet the mayor', es: 'Cita con el alcalde', fr: 'Rencontrer le maire', pt: 'Audiência com o prefeito'),
    ActionId.prayForPoliticians: Tr('Für die Regierenden beten', 'Pray for leaders', es: 'Orar por los gobernantes', fr: 'Prier pour les dirigeants', pt: 'Orar pelos governantes'),
    ActionId.travel: Tr('Zug fahren', 'Take the train', es: 'Tomar el tren', fr: 'Prendre le train', pt: 'Pegar o trem'),
    ActionId.majorEvent: Tr('Großveranstaltung', 'Big event', es: 'Gran evento', fr: 'Grand événement', pt: 'Grande evento'),
    ActionId.talkBoss: Tr('Gespräch mit dem Chef', 'Talk to the boss', es: 'Hablar con el jefe', fr: 'Parler au patron', pt: 'Falar com o chefe'),
    ActionId.shopping: Tr('Einkaufen', 'Shopping', es: 'Comprar', fr: 'Faire les courses', pt: 'Fazer compras'),
    ActionId.bless: Tr('Segnen', 'Bless', es: 'Bendecir', fr: 'Bénir', pt: 'Abençoar'),
    ActionId.requestDonation: Tr('Um Spenden bitten', 'Ask for donations', es: 'Pedir donativos', fr: 'Demander des dons', pt: 'Pedir doações'),
    ActionId.genericPray: Tr('Hier beten', 'Pray here', es: 'Orar aquí', fr: 'Prier ici', pt: 'Orar aqui'),
    ActionId.witness: Tr('Von Jesus erzählen', 'Tell about Jesus', es: 'Hablar de Jesús', fr: 'Parler de Jésus', pt: 'Falar de Jesus'),
    ActionId.distribute: Tr('Verteilen', 'Hand out', es: 'Repartir', fr: 'Distribuer', pt: 'Distribuir'),
    ActionId.blessVehicles: Tr('Fahrzeuge segnen', 'Bless the vehicles', es: 'Bendecir los vehículos', fr: 'Bénir les véhicules', pt: 'Abençoar os veículos'),
    ActionId.chaplaincy: Tr('Seelsorge im Dienst', 'Chaplaincy', es: 'Capellanía', fr: 'Aumônerie', pt: 'Capelania'),
    ActionId.bringMeal: Tr('Essen bringen', 'Bring a meal', es: 'Llevar comida', fr: 'Apporter un repas', pt: 'Levar uma refeição'),
    ActionId.sendCards: Tr('Karten schreiben', 'Send cards', es: 'Enviar tarjetas', fr: 'Envoyer des cartes', pt: 'Enviar cartões'),
    ActionId.study: Tr('Studieren', 'Study', es: 'Estudiar', fr: 'Étudier', pt: 'Estudar'),
    ActionId.bookCircle: Tr('Lesekreis', 'Reading circle', es: 'Círculo de lectura', fr: 'Cercle de lecture', pt: 'Círculo de leitura'),
    ActionId.churchHistory: Tr('Kirchengeschichte', 'Church history', es: 'Historia de la Iglesia', fr: 'Histoire de l’Église', pt: 'História da Igreja'),
    ActionId.workShift: Tr('Schicht mitarbeiten', 'Work a shift', es: 'Trabajar un turno', fr: 'Faire une équipe', pt: 'Trabalhar um turno'),
    ActionId.prayWorkers: Tr('Für Arbeiter beten', 'Pray for workers', es: 'Orar por los trabajadores', fr: 'Prier pour les ouvriers', pt: 'Orar pelos trabalhadores'),
  };

  static const Map<ActionId, Tr> actions = {
    // ── People ──
    ActionId.talk: Tr('Gespräch: Ihr lernt euch kennen, die Person wird offener.', 'Talk: you get to know each other, the person opens up.', es: 'Conversar: os conocéis y la persona se abre.', fr: 'Discuter : vous faites connaissance, la personne s’ouvre.', pt: 'Conversar: vocês se conhecem e a pessoa se abre.'),
    ActionId.counsel: Tr('Zuhören und Seelsorge – kostet ❤️, wirkt stark auf den Glauben.', 'Listen and counsel – costs ❤️, strongly moves their faith.', es: 'Escuchar y acompañar: cuesta ❤️, mueve mucho su fe.', fr: 'Écouter et accompagner – coûte ❤️, fait beaucoup avancer sa foi.', pt: 'Ouvir e aconselhar – custa ❤️, move muito a fé dela.'),
    ActionId.pray: Tr('Mit der Person beten.', 'Pray with the person.', es: 'Orar con la persona.', fr: 'Prier avec la personne.', pt: 'Orar com a pessoa.'),
    ActionId.bible: Tr('Gemeinsam in der Bibel lesen.', 'Read the Bible together.', es: 'Leer juntos la Biblia.', fr: 'Lire la Bible ensemble.', pt: 'Ler a Bíblia juntos.'),
    ActionId.help:
        Tr('Ein Geschenk 📦 – nur wenn die Person etwas braucht.', 'A gift 📦 – only when the person needs something.', es: 'Un regalo 📦, solo cuando la persona necesita algo.', fr: 'Un cadeau 📦 – seulement quand la personne a besoin de quelque chose.', pt: 'Um presente 📦 – só quando a pessoa precisa de algo.'),
    ActionId.convert: Tr('Einladen, Christ zu werden. Gelingt, wenn ihr ✝️-Balken hoch genug ist.', 'Invite them to follow Christ. Works when their ✝️ bar is high enough.', es: 'Invitarla a seguir a Cristo. Funciona cuando su barra ✝️ está bastante alta.', fr: 'L’inviter à suivre le Christ. Fonctionne quand sa barre ✝️ est assez haute.', pt: 'Convidá-la a seguir a Cristo. Funciona quando a barra ✝️ está alta o suficiente.'),
    ActionId.lifeTalk: Tr('Lebensgeschichte (nach 🫂 Seelsorge): Du erfährst ihre Geschichte und hilfst bei alten Wunden.', 'Life story (after 🫂 pastoral care): learn their story and help with old wounds.', es: 'Historia de vida (después de 🫂 cuidado pastoral): conoce su historia y ayuda con heridas antiguas.', fr: 'Histoire de vie (après 🫂 l’accompagnement pastoral) : découvre son histoire et aide à guérir d’anciennes blessures.', pt: 'História de vida (depois de 🫂 cuidado pastoral): conheça a história dela e ajude com feridas antigas.'),
    // ── Pastor house ──
    ActionId.readBible: Tr('Bibel lesen: füllt deinen Glauben auf.', 'Read the Bible: refills your faith.', es: 'Leer la Biblia: recarga tu fe.', fr: 'Lire la Bible : recharge ta foi.', pt: 'Ler a Bíblia: recarrega sua fé.'),
    ActionId.eat: Tr('Essen: füllt den Vorrat auf.', 'Eat: refills provisions.', es: 'Comer: repone provisiones.', fr: 'Manger : recharge les provisions.', pt: 'Comer: repõe as provisões.'),
    ActionId.sleep: Tr('Schlafen: füllt ❤️ auf und beendet den Tag.', 'Sleep: refills ❤️ and ends the day.', es: 'Dormir: recarga ❤️ y termina el día.', fr: 'Dormir : recharge ❤️ et termine la journée.', pt: 'Dormir: recarrega ❤️ e termina o dia.'),
    ActionId.homePray: Tr('Gebet zu Hause: Glaube und die Umgebung wird hell.', 'Prayer at home: faith, and the area around grows bright.', es: 'Oración en casa: fe, y el entorno se ilumina.', fr: 'Prière à la maison : de la foi, et les environs s’éclairent.', pt: 'Oração em casa: fé, e os arredores ficam iluminados.'),
    ActionId.missions: Tr('Missionsbrett: Missionen und Lernweg.', 'Mission board: missions and learning path.', es: 'Tablón de misiones: misiones y camino de aprendizaje.', fr: 'Tableau des missions : missions et parcours d’apprentissage.', pt: 'Quadro de missões: missões e caminho de aprendizado.'),
    // ── Homes ──
    ActionId.practicalHelp: Tr('Praktisch helfen (−📦): Die Bewohner kommen dem Glauben näher.', 'Practical help (−📦): the residents come closer to faith.', es: 'Ayuda práctica (−📦): los vecinos se acercan a la fe.', fr: 'Aide pratique (−📦) : les habitants se rapprochent de la foi.', pt: 'Ajuda prática (−📦): os moradores se aproximam da fé.'),
    ActionId.housePray: Tr('Für das Haus beten.', 'Pray for the home.', es: 'Orar por la casa.', fr: 'Prier pour la maison.', pt: 'Orar pela casa.'),
    ActionId.houseVisit: Tr('Kaffeebesuch – ab einigen Besuchen. Du wirst bewirtet: ❤️ und 🍞.', 'Coffee visit – after a few visits. You are looked after: ❤️ and 🍞.', es: 'Visita con café, tras algunas visitas. Te atienden: ❤️ y 🍞.', fr: 'Visite autour d’un café – après quelques visites. On prend soin de toi : ❤️ et 🍞.', pt: 'Visita com café – depois de algumas visitas. Cuidam de você: ❤️ e 🍞.'),
    ActionId.discipleshipGroup:
        Tr('Hauskreis – wenn hier ein Christ wohnt. Gibt 📖.', 'Home group – when a Christian lives here. Gives 📖.', es: 'Grupo en casa, cuando aquí vive un cristiano. Da 📖.', fr: 'Groupe de maison – quand un chrétien habite ici. Donne 📖.', pt: 'Grupo nos lares – quando um cristão mora aqui. Dá 📖.'),
    ActionId.fellowship: Tr('Gebet mit Geschwistern – wenn hier nur Christen wohnen. Gibt 🙏 wie zu Hause, einmal am Tag.', 'Prayer with fellow believers – when only Christians live here. Gives 🙏 as at home, once a day.', es: 'Oración con los hermanos, cuando aquí solo viven cristianos. Da 🙏 como en casa, una vez al día.', fr: 'Prière avec les frères et sœurs – quand seuls des chrétiens habitent ici. Donne 🙏 comme à la maison, une fois par jour.', pt: 'Oração com os irmãos – quando só moram cristãos aqui. Dá 🙏 como em casa, uma vez por dia.'),
    ActionId.blessHousehold: Tr('Alle Haushalte im Wohnblock segnen.', 'Bless every household in the block.', es: 'Bendecir todos los hogares del bloque.', fr: 'Bénir tous les foyers de l’immeuble.', pt: 'Abençoar todos os lares do prédio.'),
    // ── Church ──
    ActionId.sundayService: Tr('Gottesdienst halten (−📦 −❤️): viel 🙏, die Umgebung wird hell. Zählt für Lektionen mit ⛪.', 'Hold a service (−📦 −❤️): lots of 🙏, the area grows bright. Counts for ⛪ lessons.', es: 'Celebrar un culto (−📦 −❤️): mucho 🙏, el entorno se ilumina. Cuenta para las lecciones ⛪.', fr: 'Célébrer un culte (−📦 −❤️) : beaucoup de 🙏, les environs s’éclairent. Compte pour les leçons ⛪.', pt: 'Realizar um culto (−📦 −❤️): muito 🙏, os arredores se iluminam. Conta para as lições ⛪.'),
    ActionId.worship:
        Tr('Lobpreis: Glaube, dauerhaft helleres Viertel.', 'Worship: faith and a lastingly brighter area.', es: 'Alabanza: fe y un entorno iluminado de forma duradera.', fr: 'Louange : de la foi et des environs durablement éclairés.', pt: 'Louvor: fé e arredores iluminados de forma duradoura.'),
    // ── Hospital ──
    ActionId.medicalHelp: Tr('Medizinische Hilfe: ❤️ und 🍞 voll.', 'Medical help: ❤️ and 🍞 full.', es: 'Ayuda médica: ❤️ y 🍞 al máximo.', fr: 'Aide médicale : ❤️ et 🍞 au maximum.', pt: 'Ajuda médica: ❤️ e 🍞 cheios.'),
    ActionId.counseling: Tr('Seelsorge an Kranken.', 'Counselling the sick.', es: 'Acompañar a los enfermos.', fr: 'Accompagner les malades.', pt: 'Aconselhar os doentes.'),
    ActionId.chapelService:
        Tr('Andacht in der Kapelle. Zählt auch als Gottesdienst ⛪.', 'Chapel service. Also counts as a ⛪ service.', es: 'Culto en la capilla. También cuenta como culto ⛪.', fr: 'Culte à la chapelle. Compte aussi comme culte ⛪.', pt: 'Culto na capela. Também conta como culto ⛪.'),
    // ── School ──
    ActionId.letterToManagement: Tr('Brief an die Leitung.', 'Letter to the management.', es: 'Carta a la dirección.', fr: 'Lettre à la direction.', pt: 'Carta à direção.'),
    ActionId.talkDirector:
        Tr('Gespräch mit der Leitung – öffnet den Vortrag 🎤.', 'Talk to the director – unlocks the talk 🎤.', es: 'Hablar con la dirección: desbloquea la charla 🎤.', fr: 'Parler à la direction – débloque l’exposé 🎤.', pt: 'Falar com a direção – desbloqueia a palestra 🎤.'),
    ActionId.valueLecture: Tr('Wertevortrag vor allen.', 'A talk on values for everyone.', es: 'Una charla sobre valores para todos.', fr: 'Un exposé sur les valeurs pour tous.', pt: 'Uma palestra sobre valores para todos.'),
    ActionId.prayerCircle: Tr('Gebetskreis: gibt 📖.', 'Prayer circle: gives 📖.', es: 'Círculo de oración: da 📖.', fr: 'Cercle de prière : donne 📖.', pt: 'Círculo de oração: dá 📖.'),
    // ── Cemetery ──
    ActionId.funeral: Tr('Beerdigung halten.', 'Hold a funeral.', es: 'Oficiar un funeral.', fr: 'Célébrer des obsèques.', pt: 'Realizar um funeral.'),
    ActionId.comfort: Tr('Trauernde trösten (nach einer Beerdigung) – sehr anstrengend, sehr tief.', 'Comfort the mourners (after a funeral) – very draining, very deep.', es: 'Consolar a los que lloran (después de un funeral): muy agotador, muy profundo.', fr: 'Consoler les personnes en deuil (après des obsèques) – très éprouvant, très profond.', pt: 'Consolar os enlutados (depois de um funeral) – muito cansativo, muito profundo.'),
    // ── Civic ──
    ActionId.blessPolice: Tr('Die Polizei segnen.', 'Bless the police.', es: 'Bendecir a la policía.', fr: 'Bénir la police.', pt: 'Abençoar a polícia.'),
    ActionId.mayorAudience: Tr('Termin beim Bürgermeister.', 'Audience with the mayor.', es: 'Audiencia con el alcalde.', fr: 'Audience chez le maire.', pt: 'Audiência com o prefeito.'),
    ActionId.prayForPoliticians: Tr('Für die Regierenden beten – wirkt auf die ganze Stadt 🌍.', 'Pray for those in authority – affects the whole city 🌍.', es: 'Orar por los gobernantes: afecta a toda la ciudad 🌍.', fr: 'Prier pour les dirigeants – agit sur toute la ville 🌍.', pt: 'Orar pelos governantes – afeta a cidade inteira 🌍.'),
    ActionId.travel: Tr('Mit dem Zug in einen anderen Stadtteil fahren.', 'Take the train to another part of town.', es: 'Tomar el tren a otra parte de la ciudad.', fr: 'Prendre le train vers un autre quartier.', pt: 'Pegar o trem para outra parte da cidade.'),
    ActionId.majorEvent: Tr('Großveranstaltung im Stadion: 📖.', 'Big event in the stadium: 📖.', es: 'Gran evento en el estadio: 📖.', fr: 'Grand événement au stade : 📖.', pt: 'Grande evento no estádio: 📖.'),
    // ── Commercial ──
    ActionId.talkBoss: Tr('Gespräch mit der Chefin / dem Chef.', 'Talk to the boss.', es: 'Hablar con el jefe.', fr: 'Parler au patron.', pt: 'Falar com o chefe.'),
    ActionId.shopping: Tr('Einkaufen: 🍞 und ❤️.', 'Shopping: 🍞 and ❤️.', es: 'Comprar: 🍞 y ❤️.', fr: 'Faire les courses : 🍞 et ❤️.', pt: 'Fazer compras: 🍞 e ❤️.'),
    ActionId.bless: Tr('Das Geschäft segnen.', 'Bless the business.', es: 'Bendecir el negocio.', fr: 'Bénir le commerce.', pt: 'Abençoar o negócio.'),
    ActionId.requestDonation: Tr('Um Spenden bitten: vielleicht 📦.', 'Ask for donations: maybe 📦.', es: 'Pedir donativos: quizá 📦.', fr: 'Demander des dons : peut-être 📦.', pt: 'Pedir doações: talvez 📦.'),
    // ── Generic ──
    ActionId.genericPray: Tr('Hier beten.', 'Pray here.', es: 'Orar aquí.', fr: 'Prier ici.', pt: 'Orar aqui.'),
    ActionId.witness: Tr('Von Jesus erzählen.', 'Tell people about Jesus.', es: 'Hablar de Jesús a la gente.', fr: 'Parler de Jésus aux gens.', pt: 'Falar de Jesus às pessoas.'),
    ActionId.distribute: Tr('Etwas verteilen.', 'Hand things out.', es: 'Repartir cosas.', fr: 'Distribuer des choses.', pt: 'Distribuir coisas.'),
    ActionId.blessVehicles: Tr('Fahrzeuge und Mannschaft segnen.', 'Bless the vehicles and the crew.', es: 'Bendecir los vehículos y al equipo.', fr: 'Bénir les véhicules et l’équipe.', pt: 'Abençoar os veículos e a equipe.'),
    ActionId.chaplaincy:
        Tr('Notfallseelsorge nach einem schweren Einsatz.', 'Emergency chaplaincy after a hard call-out.', es: 'Capellanía de emergencia tras una intervención dura.', fr: 'Aumônerie d’urgence après une intervention difficile.', pt: 'Capelania de emergência depois de uma ocorrência difícil.'),
    ActionId.bringMeal: Tr('Der Schicht ein Essen bringen.', 'Bring a meal to the shift.', es: 'Llevar una comida al turno.', fr: 'Apporter un repas à l’équipe de service.', pt: 'Levar uma refeição ao turno.'),
    ActionId.sendCards: Tr('Ermutigungskarten verschicken.', 'Send encouragement cards.', es: 'Enviar tarjetas de ánimo.', fr: 'Envoyer des cartes d’encouragement.', pt: 'Enviar cartões de encorajamento.'),
    ActionId.study: Tr('In Ruhe studieren: 📖.', 'Quiet study: 📖.', es: 'Estudio tranquilo: 📖.', fr: 'Étude au calme : 📖.', pt: 'Estudo tranquilo: 📖.'),
    ActionId.bookCircle: Tr('Lesekreis mit den Besuchern.', 'Reading circle with the visitors.', es: 'Círculo de lectura con los visitantes.', fr: 'Cercle de lecture avec les visiteurs.', pt: 'Círculo de leitura com os visitantes.'),
    ActionId.churchHistory:
        Tr('Kirchengeschichte in der Ausstellung: etwas 📖.', 'Church history in the exhibition: a little 📖.', es: 'Historia de la Iglesia en la exposición: un poco de 📖.', fr: 'Histoire de l’Église dans l’exposition : un peu de 📖.', pt: 'História da Igreja na exposição: um pouco de 📖.'),
    ActionId.workShift: Tr('Eine Schicht mitarbeiten: 📦, kostet Kraft.', 'Work a shift: 📦, costs strength.', es: 'Trabajar un turno: 📦, cuesta fuerzas.', fr: 'Faire une équipe : 📦, coûte des forces.', pt: 'Trabalhar um turno: 📦, custa forças.'),
    ActionId.prayWorkers: Tr('Für die Sicherheit der Arbeiter beten.', 'Pray for the workers\' safety.', es: 'Orar por la seguridad de los trabajadores.', fr: 'Prier pour la sécurité des ouvriers.', pt: 'Orar pela segurança dos trabalhadores.'),
    // ── Learned ──
    ActionId.intercede: Tr('Fürbitte für ein Haus (gelernt 🙏): Heute öffnet sich die Tür leichter, Gespräche wirken mehr.', 'Intercede for a home (learned 🙏): today the door opens more easily and talks achieve more.', es: 'Interceder por una casa (aprendido 🙏): hoy la puerta se abre más fácilmente y las conversaciones logran más.', fr: 'Intercéder pour une maison (appris 🙏) : aujourd’hui la porte s’ouvre plus facilement et les discussions portent davantage.', pt: 'Interceder por uma casa (aprendido 🙏): hoje a porta se abre mais fácil e as conversas rendem mais.'),
    ActionId.fast: Tr('Fasten (gelernt 🍞): kostet 🍞, Gebete in der unsichtbaren Welt sind billiger, bis du heimkommst.', 'Fast (learned 🍞): costs 🍞, prayer in the invisible world is cheaper until you get home.', es: 'Ayunar (aprendido 🍞): cuesta 🍞; la oración en el mundo invisible es más barata hasta que vuelvas a casa.', fr: 'Jeûner (appris 🍞) : coûte 🍞, la prière dans le monde invisible coûte moins cher jusqu’à ton retour à la maison.', pt: 'Jejuar (aprendido 🍞): custa 🍞; a oração no mundo invisível fica mais barata até você voltar para casa.'),
    ActionId.preach: Tr('Predigen (gelernt 📢) in der Kirche: alle Menschen in der Nähe hören zu. Einmal pro Tag und Kirche.', 'Preach (learned 📢) in a church: everyone nearby listens. Once a day per church.', es: 'Predicar (aprendido 📢) en una iglesia: todos los de alrededor escuchan. Una vez al día por iglesia.', fr: 'Prêcher (appris 📢) dans une église : tout le monde autour écoute. Une fois par jour et par église.', pt: 'Pregar (aprendido 📢) numa igreja: todos ao redor ouvem. Uma vez por dia por igreja.'),
  };

  static const Map<PrayerMode, Tr> prayerModes = {
    PrayerMode.liberation: Tr('Befreiung: Hauptgebet, macht rote Felder grün und trifft Dämonen.', 'Liberation: the main prayer, turns red ground green and hits demons.', es: 'Liberación: la oración principal, vuelve verde el suelo rojo y golpea a los demonios.', fr: 'Libération : la prière principale, rend vert le sol rouge et frappe les démons.', pt: 'Libertação: a oração principal, deixa verde o chão vermelho e atinge os demônios.'),
    PrayerMode.rebuke:
        Tr('Zurückweisen: stößt Dämonen weg (stark gegen 🪨).', 'Rebuke: pushes demons away (strong against 🪨).', es: 'Reprender: aparta a los demonios (fuerte contra 🪨).', fr: 'Repousser : chasse les démons (fort contre 🪨).', pt: 'Repreender: empurra os demônios para longe (forte contra 🪨).'),
    PrayerMode.slow:
        Tr('Binden: verlangsamt Dämonen (stark gegen 🐍).', 'Bind: slows demons down (strong against 🐍).', es: 'Atar: frena a los demonios (fuerte contra 🐍).', fr: 'Lier : ralentit les démons (fort contre 🐍).', pt: 'Amarrar: desacelera os demônios (forte contra 🐍).'),
    PrayerMode.drain: Tr('Entwaffnen: nimmt Dämonen Kraft und gibt dir 🙏 (stark gegen 🦇).', 'Disarm: drains demons and gives you 🙏 (strong against 🦇).', es: 'Desarmar: agota a los demonios y te da 🙏 (fuerte contra 🦇).', fr: 'Désarmer : affaiblit les démons et te donne 🙏 (fort contre 🦇).', pt: 'Desarmar: esgota os demônios e lhe dá 🙏 (forte contra 🦇).'),
  };

  static const Map<DaemonKind, Tr> daemons = {
    DaemonKind.lurker: Tr('Lauerer: schnell, schwach, kommt in Gruppen.', 'Lurker: fast, weak, comes in groups.', es: 'Acechador: rápido, débil, viene en grupos.', fr: 'Rôdeur : rapide, faible, vient en groupe.', pt: 'Espreitador: rápido, fraco, vem em grupos.'),
    DaemonKind.brute: Tr('Koloss: langsam, sehr viel Kraft.', 'Brute: slow, lots of strength.', es: 'Bruto: lento, con mucha fuerza.', fr: 'Brute : lent, très fort.', pt: 'Brutamontes: lento, muita força.'),
    DaemonKind.leech: Tr('Sauger: zieht dir in der Nähe Glauben ab.', 'Leech: drains your faith while close.', es: 'Sanguijuela: te quita fe mientras está cerca.', fr: 'Sangsue : aspire ta foi quand elle est proche.', pt: 'Sanguessuga: suga sua fé enquanto está perto.'),
    DaemonKind.possessor: Tr('Besetzer: sitzt in einem Menschen. Erst besiegbar, wenn dieser Mensch in der Stadt Seelsorge bekommen hat.', 'Possessor: sits in a person. Only beatable once that person was cared for in the city.', es: 'Poseedor: habita en una persona. Solo se puede vencer cuando esa persona fue cuidada en la ciudad.', fr: 'Possesseur : habite une personne. On ne peut le vaincre qu’après avoir pris soin de cette personne en ville.', pt: 'Possessor: habita numa pessoa. Só pode ser vencido depois que essa pessoa for cuidada na cidade.'),
  };

  static const Map<Skill, Tr> skills = {
    Skill.pastoralCare:
        Tr('Seelsorge: schaltet die Lebensgeschichten 📜 frei.', 'Pastoral care: unlocks life stories 📜.', es: 'Cuidado pastoral: desbloquea las historias de vida 📜.', fr: 'Accompagnement pastoral : débloque les histoires de vie 📜.', pt: 'Cuidado pastoral: desbloqueia as histórias de vida 📜.'),
    Skill.spiritualWarfare:
        Tr('Geistlicher Kampf: schaltet 🫸 Zurückweisen frei.', 'Spiritual warfare: unlocks 🫸 rebuke.', es: 'Guerra espiritual: desbloquea 🫸 reprender.', fr: 'Combat spirituel : débloque 🫸 repousser.', pt: 'Batalha espiritual: desbloqueia 🫸 repreender.'),
    Skill.binding: Tr('Binden: schaltet ⏳ frei.', 'Binding: unlocks ⏳.', es: 'Atar: desbloquea ⏳.', fr: 'Lier : débloque ⏳.', pt: 'Amarrar: desbloqueia ⏳.'),
    Skill.disarming: Tr('Entwaffnen: schaltet 🪫 frei.', 'Disarming: unlocks 🪫.', es: 'Desarmar: desbloquea 🪫.', fr: 'Désarmer : débloque 🪫.', pt: 'Desarmar: desbloqueia 🪫.'),
    Skill.discernment:
        Tr('Unterscheidung der Geister: Du erkennst die Dämonenarten.', 'Discernment: you see the kinds of demons.', es: 'Discernimiento: ves los tipos de demonios.', fr: 'Discernement : tu vois les types de démons.', pt: 'Discernimento: você vê os tipos de demônios.'),
    Skill.intercession: Tr('Fürbitte: 🙏🏠 in Wohnhäusern.', 'Intercession: 🙏🏠 in homes.', es: 'Intercesión: 🙏🏠 en las casas.', fr: 'Intercession : 🙏🏠 dans les maisons.', pt: 'Intercessão: 🙏🏠 nas casas.'),
    Skill.fasting: Tr('Fasten: ➖🍞 im Pastorenhaus.', 'Fasting: ➖🍞 in the pastor house.', es: 'Ayuno: ➖🍞 en la casa pastoral.', fr: 'Jeûne : ➖🍞 dans la maison pastorale.', pt: 'Jejum: ➖🍞 na casa pastoral.'),
    Skill.preaching: Tr('Predigen: 📢 in Kirchen – und 📢🎺 Freiversammlung auf der Straße (Kreismenü 🖐️).', 'Preaching: 📢 in churches – and 📢🎺 open-air meetings in the street (circle menu 🖐️).', es: 'Predicación: 📢 en iglesias, y 📢🎺 reuniones al aire libre en la calle (menú circular 🖐️).', fr: 'Prédication : 📢 dans les églises – et 📢🎺 réunions en plein air dans la rue (menu circulaire 🖐️).', pt: 'Pregação: 📢 nas igrejas – e 📢🎺 reuniões ao ar livre na rua (menu circular 🖐️).'),
    Skill.liberationMastery1: Tr('🕊️ Befreiung: die nächste Stufengrenze.', '🕊️ liberation: the next level cap.', es: '🕊️ liberación: el siguiente límite de nivel.', fr: '🕊️ libération : la limite de niveau suivante.', pt: '🕊️ libertação: o próximo limite de nível.'),
    Skill.liberationMastery2: Tr('🕊️ Befreiung bis Stufe 10.', '🕊️ liberation up to level 10.', es: '🕊️ liberación hasta el nivel 10.', fr: '🕊️ libération jusqu’au niveau 10.', pt: '🕊️ libertação até o nível 10.'),
    Skill.liberationMastery3: Tr('🕊️ Befreiung bis Stufe 15.', '🕊️ liberation up to level 15.', es: '🕊️ liberación hasta el nivel 15.', fr: '🕊️ libération jusqu’au niveau 15.', pt: '🕊️ libertação até o nível 15.'),
    Skill.rebukeMastery1: Tr('🫸: die nächste Stufengrenze.', '🫸: the next level cap.', es: '🫸: el siguiente límite de nivel.', fr: '🫸 : la limite de niveau suivante.', pt: '🫸: o próximo limite de nível.'),
    Skill.rebukeMastery2: Tr('🫸 bis Stufe 10.', '🫸 up to level 10.', es: '🫸 hasta el nivel 10.', fr: '🫸 jusqu’au niveau 10.', pt: '🫸 até o nível 10.'),
    Skill.slowMastery1: Tr('⏳: die nächste Stufengrenze.', '⏳: the next level cap.', es: '⏳: el siguiente límite de nivel.', fr: '⏳ : la limite de niveau suivante.', pt: '⏳: o próximo limite de nível.'),
    Skill.slowMastery2: Tr('⏳ bis Stufe 10.', '⏳ up to level 10.', es: '⏳ hasta el nivel 10.', fr: '⏳ jusqu’au niveau 10.', pt: '⏳ até o nível 10.'),
    Skill.drainMastery1: Tr('🪫: die nächste Stufengrenze.', '🪫: the next level cap.', es: '🪫: el siguiente límite de nivel.', fr: '🪫 : la limite de niveau suivante.', pt: '🪫: o próximo limite de nível.'),
    Skill.drainMastery2: Tr('🪫 bis Stufe 10.', '🪫 up to level 10.', es: '🪫 hasta el nivel 10.', fr: '🪫 jusqu’au niveau 10.', pt: '🪫 até o nível 10.'),
  };

  /// How to do a lesson's practice task – the answer to "I have the task,
  /// how do I do it?".
  static const Map<LessonTask, Tr> taskHowTo = {
    LessonTask.counsel: Tr('Sprich mit Menschen 🖐️ und wähle 👂 Zuhören – oder 👂 im Krankenhaus 🏥.', 'Talk to people 🖐️ and choose 👂 listen – or 👂 in a hospital 🏥.', es: 'Habla con la gente 🖐️ y elige 👂 escuchar, o 👂 en un hospital 🏥.', fr: 'Parle aux gens 🖐️ et choisis 👂 écouter – ou 👂 dans un hôpital 🏥.', pt: 'Converse com as pessoas 🖐️ e escolha 👂 ouvir – ou 👂 num hospital 🏥.'),
    LessonTask.defeatDaemons: Tr('Wechsle mit 🙏 in die unsichtbare Welt und besiege Dämonen 👹 mit beliebigen Gebeten.', 'Switch to the invisible world with 🙏 and defeat demons 👹 with any prayer.', es: 'Pasa al mundo invisible con 🙏 y vence demonios 👹 con cualquier oración.', fr: 'Passe dans le monde invisible avec 🙏 et vaincs des démons 👹 avec n’importe quelle prière.', pt: 'Passe para o mundo invisível com 🙏 e vença demônios 👹 com qualquer oração.'),
    LessonTask.pray: Tr('Bete – bei Menschen 🙏, in Häusern 🙏 oder im Pastorenhaus. Jedes Gebet zählt.', 'Pray – with people 🙏, in buildings 🙏 or at home. Every prayer counts.', es: 'Ora: con personas 🙏, en edificios 🙏 o en casa. Cada oración cuenta.', fr: 'Prie – avec des personnes 🙏, dans des bâtiments 🙏 ou à la maison. Chaque prière compte.', pt: 'Ore – com pessoas 🙏, em edifícios 🙏 ou em casa. Cada oração conta.'),
    LessonTask.service: Tr('Geh in eine Kirche ⛪ und halte einen Gottesdienst ⛪ (kostet 📦 und ❤️). Eine Andacht ⛪ im Krankenhaus 🏥 zählt auch.', 'Go to a church ⛪ and hold a service ⛪ (costs 📦 and ❤️). A chapel service ⛪ in a hospital 🏥 counts too.', es: 'Ve a una iglesia ⛪ y celebra un culto ⛪ (cuesta 📦 y ❤️). Un culto en la capilla ⛪ de un hospital 🏥 también cuenta.', fr: 'Va dans une église ⛪ et célèbre un culte ⛪ (coûte 📦 et ❤️). Un culte à la chapelle ⛪ d’un hôpital 🏥 compte aussi.', pt: 'Vá a uma igreja ⛪ e realize um culto ⛪ (custa 📦 e ❤️). Um culto na capela ⛪ de um hospital 🏥 também conta.'),
    LessonTask.defeatLiberation: Tr('Besiege Dämonen, die du mit 🕊️ Befreiung getroffen hast – auch wenn ein anderes Gebet sie am Ende besiegt.', 'Defeat demons you hit with 🕊️ liberation – even if another prayer finishes them.', es: 'Vence demonios a los que hayas alcanzado con 🕊️ liberación, aunque otra oración los derrote al final.', fr: 'Vaincs des démons que tu as touchés avec 🕊️ libération, même si une autre prière les achève.', pt: 'Vença demônios que você atingiu com 🕊️ libertação, mesmo que outra oração os derrote no fim.'),
    LessonTask.defeatRebuke: Tr('Besiege Dämonen, die du mit 🫸 Zurückweisen getroffen hast. 🫸 macht wenig Schaden – kombiniere es: 🫸 treffen, dann mit 🕊️ besiegen, zählt auch.', 'Defeat demons you hit with 🫸 rebuke. 🫸 does little damage – combine it: hit with 🫸, finish with 🕊️, and it counts too.', es: 'Vence demonios a los que hayas alcanzado con 🫸 reprender. 🫸 hace poco daño: combínalo, alcanza con 🫸 y vence con 🕊️, también cuenta.', fr: 'Vaincs des démons que tu as touchés avec 🫸 repousser. 🫸 fait peu de dégâts : combine-le, touche avec 🫸 puis achève avec 🕊️, cela compte aussi.', pt: 'Vença demônios que você atingiu com 🫸 repreender. 🫸 causa pouco dano: combine, atinja com 🫸 e vença com 🕊️, também conta.'),
    LessonTask.defeatSlow: Tr('Besiege Dämonen, die du mit ⏳ Binden getroffen hast – egal, welches Gebet sie am Ende besiegt.', 'Defeat demons you hit with ⏳ binding – whichever prayer finishes them.', es: 'Vence demonios a los que hayas alcanzado con ⏳ atar, sin importar qué oración los derrote al final.', fr: 'Vaincs des démons que tu as touchés avec ⏳ lier, quelle que soit la prière qui les achève.', pt: 'Vença demônios que você atingiu com ⏳ amarrar, não importa qual oração os derrote no fim.'),
    LessonTask.defeatDrain: Tr('Besiege Dämonen, die du mit 🪫 Entwaffnen getroffen hast – egal, welches Gebet sie am Ende besiegt.', 'Defeat demons you hit with 🪫 disarming – whichever prayer finishes them.', es: 'Vence demonios a los que hayas alcanzado con 🪫 desarmar, sin importar qué oración los derrote al final.', fr: 'Vaincs des démons que tu as touchés avec 🪫 désarmer, quelle que soit la prière qui les achève.', pt: 'Vença demônios que você atingiu com 🪫 desarmar, não importa qual oração os derrote no fim.'),
  };

  static const Map<BuildingType, Tr> buildings = {
    BuildingType.house: Tr('Wohnhaus', 'House', es: 'Casa', fr: 'Maison', pt: 'Casa'),
    BuildingType.apartment: Tr('Wohnblock', 'Apartment block', es: 'Bloque de pisos', fr: 'Immeuble', pt: 'Prédio'),
    BuildingType.pastorHouse: Tr('Pastorenhaus / Korps 🛡️ (dein Zuhause)', 'Pastor house / corps 🛡️ (your home)', es: 'Casa pastoral / cuerpo 🛡️ (tu hogar)', fr: 'Maison pastorale / poste 🛡️ (ta maison)', pt: 'Casa pastoral / corpo 🛡️ (seu lar)'),
    BuildingType.shop: Tr('Laden', 'Shop', es: 'Tienda', fr: 'Boutique', pt: 'Loja'),
    BuildingType.supermarket: Tr('Supermarkt', 'Supermarket', es: 'Supermercado', fr: 'Supermarché', pt: 'Supermercado'),
    BuildingType.mall: Tr('Einkaufszentrum', 'Mall', es: 'Centro comercial', fr: 'Centre commercial', pt: 'Shopping'),
    BuildingType.office: Tr('Büro', 'Office', es: 'Oficina', fr: 'Bureau', pt: 'Escritório'),
    BuildingType.skyscraper: Tr('Hochhaus', 'Skyscraper', es: 'Rascacielos', fr: 'Gratte-ciel', pt: 'Arranha-céu'),
    BuildingType.factory: Tr('Fabrik', 'Factory', es: 'Fábrica', fr: 'Usine', pt: 'Fábrica'),
    BuildingType.warehouse: Tr('Lagerhalle', 'Warehouse', es: 'Almacén', fr: 'Entrepôt', pt: 'Armazém'),
    BuildingType.trainStation: Tr('Bahnhof', 'Train station', es: 'Estación de tren', fr: 'Gare', pt: 'Estação de trem'),
    BuildingType.policeStation: Tr('Polizei', 'Police station', es: 'Comisaría', fr: 'Commissariat', pt: 'Delegacia'),
    BuildingType.fireStation: Tr('Feuerwehr', 'Fire station', es: 'Bomberos', fr: 'Caserne de pompiers', pt: 'Corpo de bombeiros'),
    BuildingType.postOffice: Tr('Post', 'Post office', es: 'Correos', fr: 'Bureau de poste', pt: 'Correios'),
    BuildingType.hospital: Tr('Krankenhaus', 'Hospital', es: 'Hospital', fr: 'Hôpital', pt: 'Hospital'),
    BuildingType.school: Tr('Schule', 'School', es: 'Escuela', fr: 'École', pt: 'Escola'),
    BuildingType.university: Tr('Universität', 'University', es: 'Universidad', fr: 'Université', pt: 'Universidade'),
    BuildingType.church: Tr('Kirche', 'Church', es: 'Iglesia', fr: 'Église', pt: 'Igreja'),
    BuildingType.cathedral: Tr('Kathedrale', 'Cathedral', es: 'Catedral', fr: 'Cathédrale', pt: 'Catedral'),
    BuildingType.library: Tr('Bibliothek', 'Library', es: 'Biblioteca', fr: 'Bibliothèque', pt: 'Biblioteca'),
    BuildingType.museum: Tr('Museum', 'Museum', es: 'Museo', fr: 'Musée', pt: 'Museu'),
    BuildingType.stadium: Tr('Stadion', 'Stadium', es: 'Estadio', fr: 'Stade', pt: 'Estádio'),
    BuildingType.cityHall: Tr('Rathaus', 'City hall', es: 'Ayuntamiento', fr: 'Mairie', pt: 'Prefeitura'),
    BuildingType.cemetery: Tr('Friedhof', 'Cemetery', es: 'Cementerio', fr: 'Cimetière', pt: 'Cemitério'),
    BuildingType.powerPlant: Tr('Kraftwerk', 'Power plant', es: 'Central eléctrica', fr: 'Centrale électrique', pt: 'Usina elétrica'),
  };

  /// What comes after the tutorial – the walkthrough continues the tutorial
  /// steps with these.
  static const List<(String, Tr, Tr)> nextSteps = [
    (
      '🎓',
      Tr('Lerne bei Mentoren', 'Learn from mentors', es: 'Aprende de mentores', fr: 'Apprends auprès des mentors', pt: 'Aprenda com mentores'),
      Tr('Im Missionsbrett 📋 unter 🎓 siehst du alle Fähigkeiten und wo ihre Mentoren sind. Tippe 📍, geh hin und nimm die Lektion an 🎓✅. Dann übst du die Aufgabe – die gelbe Zeile oben links zeigt, wie weit du bist. Beim Mentor kannst du auch mit 📖 studieren 📖➡️: je 3 📖 ein Schritt, höchstens die Hälfte – den Rest übst du selbst.', 'The mission board 📋 lists every skill under 🎓 and where its mentors are. Tap 📍, go there and accept the lesson 🎓✅. Then practise the task – the yellow line top-left shows your progress. At the mentor you can also study with 📖 📖➡️: one step per 3 📖, at most half – the rest you practise yourself.', es: 'El tablón de misiones 📋 muestra bajo 🎓 todas las habilidades y dónde están sus mentores. Toca 📍, ve allí y acepta la lección 🎓✅. Luego practica la tarea: la línea amarilla arriba a la izquierda muestra tu progreso. Con el mentor también puedes estudiar con 📖 📖➡️: un paso por cada 3 📖, como mucho la mitad; el resto lo practicas tú.', fr: 'Le tableau des missions 📋 montre sous 🎓 toutes les capacités et où se trouvent leurs mentors. Touche 📍, vas-y et accepte la leçon 🎓✅. Puis pratique la tâche – la ligne jaune en haut à gauche montre ta progression. Chez le mentor, tu peux aussi étudier avec 📖 📖➡️ : une étape pour 3 📖, au plus la moitié – le reste, tu le pratiques toi-même.', pt: 'O quadro de missões 📋 mostra em 🎓 todas as habilidades e onde estão os mentores. Toque em 📍, vá até lá e aceite a lição 🎓✅. Depois pratique a tarefa – a linha amarela em cima à esquerda mostra seu progresso. Com o mentor você também pode estudar com 📖 📖➡️: um passo a cada 3 📖, no máximo a metade – o resto você pratica.')
    ),
    (
      '⚔️',
      Tr('Verbessere deine Gebete', 'Improve your prayers', es: 'Mejora tus oraciones', fr: 'Améliore tes prières', pt: 'Melhore suas orações'),
      Tr('Erkenntnis 📖 investierst du im Pastorenhaus 🏡 unter ⚔️. Jede Stufe kostet mehr als die davor. Ist eine Gebetsart an ihrer Grenze 🔒, hebt die nächste Meisterschaft ⭐ bei einem Mentor sie an – 3, 5, 10, 15, 20 … ohne Ende.', 'Spend insight 📖 under ⚔️ in the pastor house 🏡. Each level costs more than the one before. When a prayer is at its cap 🔒, the next mastery ⭐ with a mentor lifts it – 3, 5, 10, 15, 20 … without end.', es: 'Gasta la sabiduría 📖 en ⚔️ en la casa pastoral 🏡. Cada nivel cuesta más que el anterior. Cuando una oración llega a su límite 🔒, la siguiente maestría ⭐ con un mentor lo sube: 3, 5, 10, 15, 20… sin fin.', fr: 'Dépense ta sagesse 📖 sous ⚔️ dans la maison pastorale 🏡. Chaque niveau coûte plus que le précédent. Quand une prière atteint sa limite 🔒, la maîtrise suivante ⭐ auprès d’un mentor la relève – 3, 5, 10, 15, 20 … sans fin.', pt: 'Gaste a sabedoria 📖 em ⚔️ na casa pastoral 🏡. Cada nível custa mais que o anterior. Quando uma oração chega ao limite 🔒, a próxima maestria ⭐ com um mentor o eleva – 3, 5, 10, 15, 20 … sem fim.')
    ),
    (
      '🏘️🔥',
      Tr('Erwecke Stadtteile', 'Awaken neighbourhoods', es: 'Despierta barrios', fr: 'Réveille des quartiers', pt: 'Desperte bairros'),
      Tr('Werden in einem Stadtteil genug Menschen Christen, öffnet sich das Bollwerk 🏰. Besiege es in der unsichtbaren Welt – der Stadtteil ist erweckt 🔥 und neue Lektionen (z.B. 📢 Predigen) werden frei.', 'Once enough people in a quarter are Christians, its stronghold 🏰 opens. Defeat it in the invisible world – the quarter awakens 🔥 and new lessons (e.g. 📢 preaching) open.', es: 'Cuando en un barrio hay suficientes cristianos, se abre su fortaleza 🏰. Véncela en el mundo invisible: el barrio despierta 🔥 y se abren nuevas lecciones (p. ej. 📢 predicar).', fr: 'Quand assez de gens d’un quartier sont chrétiens, sa forteresse 🏰 s’ouvre. Vaincs-la dans le monde invisible – le quartier se réveille 🔥 et de nouvelles leçons s’ouvrent (p. ex. 📢 prêcher).', pt: 'Quando há cristãos suficientes num bairro, a fortaleza 🏰 se abre. Vença-a no mundo invisível – o bairro desperta 🔥 e novas lições se abrem (p. ex. 📢 pregar).')
    ),
    (
      '😴',
      Tr('Pass auf dich auf', 'Look after yourself', es: 'Cuida de ti', fr: 'Prends soin de toi', pt: 'Cuide de você'),
      Tr('Halte ❤️ und 🍞 im Blick. Schlafen 😴 im Pastorenhaus füllt ❤️ und beendet den Tag, Essen 🍽️ füllt 🍞. Der Pfeil oben links zeigt dir immer den Weg nach Hause 🏡.', 'Watch ❤️ and 🍞. Sleeping 😴 at home refills ❤️ and ends the day, eating 🍽️ refills 🍞. The arrow top-left always points home 🏡.', es: 'Vigila ❤️ y 🍞. Dormir 😴 en casa recarga ❤️ y termina el día; comer 🍽️ recarga 🍞. La flecha de arriba a la izquierda siempre señala a casa 🏡.', fr: 'Surveille ❤️ et 🍞. Dormir 😴 à la maison recharge ❤️ et termine la journée, manger 🍽️ recharge 🍞. La flèche en haut à gauche montre toujours la maison 🏡.', pt: 'Fique de olho em ❤️ e 🍞. Dormir 😴 em casa recarrega ❤️ e termina o dia; comer 🍽️ recarrega 🍞. A seta em cima à esquerda sempre aponta para casa 🏡.')
    ),
    (
      '⛪👥',
      Tr('Baue Gemeinde', 'Build a church', es: 'Edifica una iglesia', fr: 'Bâtis une Église', pt: 'Edifique uma igreja'),
      Tr('Bekehrte Menschen gehören zu deiner Gemeinde. Besuche sie, gründe Hauskreise 📖👥 und halte Gottesdienste ⛪ – so wächst der Glaube im ganzen Viertel. Mach sie zu Jüngern 🌱: Gib deine 📖 Weisheit weiter, dann beten sie in der unsichtbaren Welt mit.', 'Converted people belong to your church. Visit them, start home groups 📖👥 and hold services ⛪ – that is how faith grows in the whole quarter. Make them disciples 🌱: pass on your 📖 insight and they pray along in the invisible world.', es: 'Las personas convertidas forman parte de tu iglesia. Visítalas, empieza grupos en casa 📖👥 y celebra cultos ⛪: así crece la fe en todo el barrio. Hazlas discípulos 🌱: transmite tu sabiduría 📖 y orarán contigo en el mundo invisible.', fr: 'Les personnes converties font partie de ton Église. Rends-leur visite, lance des groupes de maison 📖👥 et célèbre des cultes ⛪ – c’est ainsi que la foi grandit dans tout le quartier. Fais-en des disciples 🌱 : transmets ta sagesse 📖 et elles prieront avec toi dans le monde invisible.', pt: 'As pessoas convertidas fazem parte da sua igreja. Visite-as, comece grupos nos lares 📖👥 e realize cultos ⛪ – é assim que a fé cresce no bairro inteiro. Faça delas discípulos 🌱: passe adiante sua sabedoria 📖 e elas orarão com você no mundo invisível.')
    ),
  ];

  static const sectionTitles = {
    'resources': Tr('Ressourcen', 'Resources', es: 'Recursos', fr: 'Ressources', pt: 'Recursos'),
    'symbols': Tr('Symbole', 'Symbols', es: 'Símbolos', fr: 'Symboles', pt: 'Símbolos'),
    'people': Tr('Menschen', 'People', es: 'Personas', fr: 'Personnes', pt: 'Pessoas'),
    'buildings': Tr('Gebäude', 'Buildings', es: 'Edificios', fr: 'Bâtiments', pt: 'Edifícios'),
    'spirit': Tr('Unsichtbare Welt', 'Invisible world', es: 'Mundo invisible', fr: 'Monde invisible', pt: 'Mundo invisível'),
    'lessons': Tr('Lektionen', 'Lessons', es: 'Lecciones', fr: 'Leçons', pt: 'Lições'),
    'tasks': Tr('Meine Aufgaben', 'My tasks', es: 'Mis tareas', fr: 'Mes tâches', pt: 'Minhas tarefas'),
    'steps': Tr('Erste Schritte', 'First steps', es: 'Primeros pasos', fr: 'Premiers pas', pt: 'Primeiros passos'),
    'glossary': Tr('Glossar', 'Glossary', es: 'Glosario', fr: 'Glossaire', pt: 'Glossário'),
    'keys': Tr('Tasten', 'Keys', es: 'Teclas', fr: 'Touches', pt: 'Teclas'),
    'search': Tr('Suchen (Emoji oder Wort)', 'Search (emoji or word)', es: 'Buscar (emoji o palabra)', fr: 'Rechercher (emoji ou mot)', pt: 'Buscar (emoji ou palavra)'),
    'noLesson':
        Tr('Gerade keine Lektion. Diese kannst du jetzt lernen:', 'No lesson right now. You can learn these now:', es: 'Ahora no hay lección. Ya puedes aprender estas:', fr: 'Pas de leçon en ce moment. Tu peux apprendre celles-ci :', pt: 'Nenhuma lição agora. Você já pode aprender estas:'),
    'mentors': Tr('Mentor in', 'Mentor at', es: 'Mentor en', fr: 'Mentor à', pt: 'Mentor em'),
    'where': Tr('Wo?', 'Where?', es: '¿Dónde?', fr: 'Où ?', pt: 'Onde?'),
    'requires': Tr('Braucht zuerst', 'Needs first', es: 'Necesita antes', fr: 'Nécessite d’abord', pt: 'Precisa antes'),
    'learned': Tr('Gelernt – und wo du es einsetzt', 'Learned – and where to use it', es: 'Aprendido, y dónde usarlo', fr: 'Appris – et où l’utiliser', pt: 'Aprendido – e onde usar'),
    'invisible': Tr('in der unsichtbaren Welt', 'in the invisible world', es: 'en el mundo invisible', fr: 'dans le monde invisible', pt: 'no mundo invisível'),
    'tutorial': Tr('Tutorial', 'Tutorial', es: 'Tutorial', fr: 'Tutoriel', pt: 'Tutorial'),
    'awakened': Tr('erweckte Stadtteile', 'awakened quarters', es: 'barrios despertados', fr: 'quartiers réveillés', pt: 'bairros despertados'),
  };

  static String title(String key) => sectionTitles[key]!.text;
}
