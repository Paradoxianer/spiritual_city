import '../models/mission_model.dart';
import 'help_content.dart';

/// Missions told in sentences when texts are on (playtest 2026-10-31: "go
/// there, do this, and that is what it does"). The emoji row stays; this
/// is the explanation below it.
abstract final class MissionTexts {
  /// What to do ({n} times) and what it does, per kind of mission.
  static const Map<ActionType, Tr> task = {
    ActionType.residentialPracticalHelp: Tr(
      'Hilf dort {n}× praktisch (🛠️, kostet 📦). Das zeigt Gottes Liebe ganz konkret – die Bewohner werden offener für den Glauben.',
      'Help out there {n}× in practical ways (🛠️, costs 📦). It shows God\'s love in a concrete way – the residents grow more open to faith.',
      es: 'Ayuda allí {n} veces de forma práctica (🛠️, cuesta 📦). Muestra el amor de Dios de manera concreta: los vecinos se abren a la fe.',
      fr: 'Aide là-bas {n} fois concrètement (🛠️, coûte 📦). Cela montre l’amour de Dieu de façon concrète – les habitants s’ouvrent à la foi.',
      pt: 'Ajude ali {n} vezes de forma prática (🛠️, custa 📦). Isso mostra o amor de Deus de forma concreta – os moradores ficam mais abertos à fé.',
    ),
    ActionType.residentialPrayer: Tr(
      'Bete dort {n}× für das Haus (🙏). Gebet macht die Umgebung in der unsichtbaren Welt heller.',
      'Pray there {n}× for the home (🙏). Prayer makes the surroundings brighter in the invisible world.',
      es: 'Ora allí {n} veces por la casa (🙏). La oración ilumina el entorno en el mundo invisible.',
      fr: 'Prie là-bas {n} fois pour la maison (🙏). La prière éclaire les environs dans le monde invisible.',
      pt: 'Ore ali {n} vezes pela casa (🙏). A oração ilumina os arredores no mundo invisível.',
    ),
    ActionType.residentialHouseVisit: Tr(
      'Mach dort {n}× einen Kaffeebesuch (☕). Beziehung baut Vertrauen auf – und du wirst selbst gestärkt (❤️ 🍞).',
      'Pay {n} coffee visit(s) there (☕). Relationship builds trust – and you are strengthened too (❤️ 🍞).',
      es: 'Haz allí {n} visita(s) con café (☕). La relación crea confianza, y tú también te fortaleces (❤️ 🍞).',
      fr: 'Fais là-bas {n} visite(s) autour d’un café (☕). La relation crée la confiance – et toi aussi tu es fortifié (❤️ 🍞).',
      pt: 'Faça ali {n} visita(s) com café (☕). O relacionamento cria confiança – e você também é fortalecido (❤️ 🍞).',
    ),
    ActionType.residentialDiscipleshipGroup: Tr(
      'Leite dort {n}× eine Jüngerschaftsgruppe (📖). Die Bewohner wachsen im Glauben, das Haus wird dauerhaft heller.',
      'Lead a discipleship group there {n}× (📖). The residents grow in faith and the home becomes lastingly brighter.',
      es: 'Dirige allí {n} veces un grupo de discipulado (📖). Los vecinos crecen en la fe y la casa se ilumina de forma duradera.',
      fr: 'Anime là-bas {n} fois un groupe de disciples (📖). Les habitants grandissent dans la foi, la maison devient durablement plus lumineuse.',
      pt: 'Conduza ali {n} vezes um grupo de discipulado (📖). Os moradores crescem na fé e a casa fica iluminada de forma duradoura.',
    ),
    ActionType.residentialApartmentBless: Tr(
      'Segne dort {n}× alle Haushalte im Wohnblock (🏢). Viele Menschen werden auf einmal berührt.',
      'Bless all households in the block there {n}× (🏢). Many people are touched at once.',
      es: 'Bendice allí {n} veces todos los hogares del bloque (🏢). Muchas personas son tocadas a la vez.',
      fr: 'Bénis là-bas {n} fois tous les foyers de l’immeuble (🏢). Beaucoup de personnes sont touchées à la fois.',
      pt: 'Abençoe ali {n} vezes todos os lares do prédio (🏢). Muitas pessoas são tocadas de uma vez.',
    ),
    ActionType.commercialTalkToBoss: Tr(
      'Sprich dort {n}× mit der Chefin oder dem Chef (💼). So öffnen sich Türen im ganzen Geschäft.',
      'Talk to the boss there {n}× (💼). That opens doors in the whole business.',
      es: 'Habla allí {n} veces con el jefe o la jefa (💼). Así se abren puertas en todo el negocio.',
      fr: 'Parle là-bas {n} fois avec le patron ou la patronne (💼). Cela ouvre des portes dans toute l’entreprise.',
      pt: 'Fale ali {n} vezes com o chefe ou a chefe (💼). Assim se abrem portas em todo o negócio.',
    ),
    ActionType.commercialShopping: Tr(
      'Kauf dort {n}× ein (🛒). Du füllst deinen Vorrat auf und kommst mit den Leuten ins Gespräch.',
      'Shop there {n}× (🛒). You refill your provisions and get talking with people.',
      es: 'Compra allí {n} veces (🛒). Repones tus provisiones y conversas con la gente.',
      fr: 'Fais tes courses là-bas {n} fois (🛒). Tu refais tes provisions et tu parles avec les gens.',
      pt: 'Compre ali {n} vezes (🛒). Você repõe suas provisões e conversa com as pessoas.',
    ),
    ActionType.commercialBless: Tr(
      'Segne das Geschäft {n}× (🕊️). Segen bringt Licht in den Arbeitsalltag.',
      'Bless the business {n}× (🕊️). Blessing brings light into everyday work.',
      es: 'Bendice el negocio {n} veces (🕊️). La bendición trae luz a la vida laboral.',
      fr: 'Bénis le commerce {n} fois (🕊️). La bénédiction apporte de la lumière au quotidien du travail.',
      pt: 'Abençoe o negócio {n} vezes (🕊️). A bênção traz luz ao dia a dia do trabalho.',
    ),
    ActionType.commercialAskForDonation: Tr(
      'Bitte dort {n}× um Spenden (🤲). Vielleicht bekommst du 📦 für deine Arbeit.',
      'Ask for donations there {n}× (🤲). You may receive 📦 for your work.',
      es: 'Pide donativos allí {n} veces (🤲). Quizá recibas 📦 para tu labor.',
      fr: 'Demande des dons là-bas {n} fois (🤲). Tu recevras peut-être 📦 pour ton travail.',
      pt: 'Peça doações ali {n} vezes (🤲). Talvez você receba 📦 para seu trabalho.',
    ),
    ActionType.hospitalMedicalHelp: Tr(
      'Hilf dort {n}× bei der Versorgung (🏥). Kranke erfahren Fürsorge – und du wirst wieder gestärkt.',
      'Help with the care there {n}× (🏥). The sick experience care – and you are restored too.',
      es: 'Ayuda allí {n} veces en la atención (🏥). Los enfermos reciben cuidado, y tú también te recuperas.',
      fr: 'Aide aux soins là-bas {n} fois (🏥). Les malades sont entourés – et toi aussi tu reprends des forces.',
      pt: 'Ajude ali {n} vezes no cuidado (🏥). Os doentes recebem cuidado – e você também se recupera.',
    ),
    ActionType.hospitalPastoralCare: Tr(
      'Besuche dort {n}× Kranke als Seelsorger (👂). Zuhören tröstet und öffnet Herzen.',
      'Visit the sick there {n}× as a pastor (👂). Listening comforts and opens hearts.',
      es: 'Visita allí {n} veces a los enfermos como pastor (👂). Escuchar consuela y abre corazones.',
      fr: 'Rends visite là-bas {n} fois aux malades comme aumônier (👂). Écouter console et ouvre les cœurs.',
      pt: 'Visite ali {n} vezes os doentes como capelão (👂). Ouvir consola e abre corações.',
    ),
    ActionType.hospitalChurchService: Tr(
      'Halte dort {n}× eine Andacht in der Kapelle (⛪). Kranke und Angehörige finden Hoffnung.',
      'Hold a chapel service there {n}× (⛪). The sick and their families find hope.',
      es: 'Celebra allí {n} veces un culto en la capilla (⛪). Enfermos y familiares encuentran esperanza.',
      fr: 'Célèbre là-bas {n} fois un culte à la chapelle (⛪). Malades et proches trouvent l’espérance.',
      pt: 'Realize ali {n} vezes um culto na capela (⛪). Doentes e familiares encontram esperança.',
    ),
    ActionType.schoolLetterToManagement: Tr(
      'Schreib {n}× einen Brief an die Leitung (✉️). So bekommst du Gehör für Werte an der Schule.',
      'Write a letter to the management {n}× (✉️). That gets you a hearing for values at the school.',
      es: 'Escribe {n} veces una carta a la dirección (✉️). Así te escuchan sobre los valores en la escuela.',
      fr: 'Écris {n} fois une lettre à la direction (✉️). Ainsi tu es écouté sur les valeurs à l’école.',
      pt: 'Escreva {n} vezes uma carta à direção (✉️). Assim você é ouvido sobre valores na escola.',
    ),
    ActionType.schoolTalkToDirector: Tr(
      'Sprich {n}× mit der Schulleitung (🏫). Das Vertrauen der Leitung öffnet die ganze Schule.',
      'Talk to the head {n}× (🏫). The head\'s trust opens the whole school.',
      es: 'Habla {n} veces con la dirección (🏫). La confianza de la dirección abre toda la escuela.',
      fr: 'Parle {n} fois avec la direction (🏫). La confiance de la direction ouvre toute l’école.',
      pt: 'Fale {n} vezes com a direção (🏫). A confiança da direção abre toda a escola.',
    ),
    ActionType.schoolValuesTalk: Tr(
      'Halte dort {n}× einen Wertevortrag (🎤). Viele junge Menschen hören auf einmal zu.',
      'Give a talk on values there {n}× (🎤). Many young people listen at once.',
      es: 'Da allí {n} veces una charla sobre valores (🎤). Muchos jóvenes escuchan a la vez.',
      fr: 'Donne là-bas {n} fois un exposé sur les valeurs (🎤). Beaucoup de jeunes écoutent à la fois.',
      pt: 'Faça ali {n} vezes uma palestra sobre valores (🎤). Muitos jovens ouvem de uma vez.',
    ),
    ActionType.schoolPrayerCircle: Tr(
      'Leite dort {n}× einen Gebetskreis (⭕). Gemeinsames Gebet stärkt und schenkt dir 📖.',
      'Lead a prayer circle there {n}× (⭕). Praying together strengthens and gives you 📖.',
      es: 'Dirige allí {n} veces un círculo de oración (⭕). Orar juntos fortalece y te da 📖.',
      fr: 'Anime là-bas {n} fois un cercle de prière (⭕). Prier ensemble fortifie et te donne 📖.',
      pt: 'Conduza ali {n} vezes um círculo de oração (⭕). Orar juntos fortalece e lhe dá 📖.',
    ),
    ActionType.policeBless: Tr(
      'Segne {n}× die Polizei (👮). Wer für Sicherheit sorgt, wird gestärkt – das ganze Viertel profitiert.',
      'Bless the police {n}× (👮). Those who keep people safe are strengthened – the whole quarter benefits.',
      es: 'Bendice {n} veces a la policía (👮). Quienes cuidan la seguridad son fortalecidos y todo el barrio se beneficia.',
      fr: 'Bénis la police {n} fois (👮). Ceux qui veillent sur la sécurité sont fortifiés – tout le quartier en profite.',
      pt: 'Abençoe a polícia {n} vezes (👮). Quem cuida da segurança é fortalecido – todo o bairro se beneficia.',
    ),
    ActionType.cityHallAudience: Tr(
      'Geh {n}× zum Termin beim Bürgermeister (🏛️). Ein gutes Wort an der Spitze wirkt auf die ganze Stadt.',
      'Meet the mayor {n}× (🏛️). A good word at the top affects the whole city.',
      es: 'Ve {n} veces a la cita con el alcalde (🏛️). Una buena palabra en lo más alto influye en toda la ciudad.',
      fr: 'Va {n} fois au rendez-vous avec le maire (🏛️). Une bonne parole au sommet agit sur toute la ville.',
      pt: 'Vá {n} vezes à audiência com o prefeito (🏛️). Uma boa palavra no topo influencia a cidade inteira.',
    ),
    ActionType.cityHallPrayForPoliticians: Tr(
      'Bete {n}× für die Regierenden (🙏, 1 Tim 2,1–2). Das wirkt auf die ganze Stadt 🌍.',
      'Pray for those in authority {n}× (🙏, 1 Tim 2:1–2). It affects the whole city 🌍.',
      es: 'Ora {n} veces por los gobernantes (🙏, 1 Ti 2:1–2). Influye en toda la ciudad 🌍.',
      fr: 'Prie {n} fois pour les dirigeants (🙏, 1 Tm 2,1–2). Cela agit sur toute la ville 🌍.',
      pt: 'Ore {n} vezes pelos governantes (🙏, 1 Tm 2:1–2). Isso influencia a cidade inteira 🌍.',
    ),
    ActionType.churchService: Tr(
      'Halte dort {n}× einen Gottesdienst (⛪, kostet 📦 und ❤️). Die Gemeinde wächst, und das Viertel wird heller.',
      'Hold a service there {n}× (⛪, costs 📦 and ❤️). The church grows and the quarter grows brighter.',
      es: 'Celebra allí {n} veces un culto (⛪, cuesta 📦 y ❤️). La iglesia crece y el barrio se ilumina.',
      fr: 'Célèbre là-bas {n} fois un culte (⛪, coûte 📦 et ❤️). L’Église grandit et le quartier s’éclaire.',
      pt: 'Realize ali {n} vezes um culto (⛪, custa 📦 e ❤️). A igreja cresce e o bairro fica mais iluminado.',
    ),
    ActionType.churchWorshipPrayer: Tr(
      'Bete dort {n}× Gott an (🤲). Lobpreis füllt deinen Glauben und macht die Kirche zum Leuchtturm.',
      'Worship God there {n}× (🤲). Worship fills your faith and makes the church a lighthouse.',
      es: 'Adora a Dios allí {n} veces (🤲). La alabanza llena tu fe y convierte la iglesia en un faro.',
      fr: 'Adore Dieu là-bas {n} fois (🤲). La louange remplit ta foi et fait de l’église un phare.',
      pt: 'Adore a Deus ali {n} vezes (🤲). O louvor enche sua fé e faz da igreja um farol.',
    ),
    ActionType.cemeteryFuneral: Tr(
      'Halte dort {n}× eine Beerdigung (⚰️). In der Trauer bringst du Hoffnung auf die Auferstehung.',
      'Hold a funeral there {n}× (⚰️). In grief you bring the hope of the resurrection.',
      es: 'Oficia allí {n} veces un funeral (⚰️). En el duelo llevas la esperanza de la resurrección.',
      fr: 'Célèbre là-bas {n} fois des obsèques (⚰️). Dans le deuil, tu apportes l’espérance de la résurrection.',
      pt: 'Realize ali {n} vezes um funeral (⚰️). No luto, você leva a esperança da ressurreição.',
    ),
    ActionType.cemeteryComfort: Tr(
      'Tröste dort {n}× Trauernde (🫂). Sehr anstrengend – aber es berührt Menschen tief.',
      'Comfort the grieving there {n}× (🫂). Very demanding – but it touches people deeply.',
      es: 'Consuela allí {n} veces a los que lloran (🫂). Muy agotador, pero toca profundamente a las personas.',
      fr: 'Console là-bas {n} fois ceux qui sont en deuil (🫂). Très éprouvant – mais cela touche profondément.',
      pt: 'Console ali {n} vezes os enlutados (🫂). Muito cansativo – mas toca profundamente as pessoas.',
    ),
    ActionType.stadiumMajorEvent: Tr(
      'Veranstalte dort {n}× ein Großevent (🏟️). Tausende hören die Botschaft – und du gewinnst 📖.',
      'Hold a big event there {n}× (🏟️). Thousands hear the message – and you gain 📖.',
      es: 'Organiza allí {n} veces un gran evento (🏟️). Miles escuchan el mensaje y tú ganas 📖.',
      fr: 'Organise là-bas {n} fois un grand événement (🏟️). Des milliers entendent le message – et tu gagnes 📖.',
      pt: 'Promova ali {n} vezes um grande evento (🏟️). Milhares ouvem a mensagem – e você ganha 📖.',
    ),
    ActionType.libraryBibleStudy: Tr(
      'Studiere dort {n}× in Ruhe die Bibel (📚). Das vertieft deine Weisheit 📖.',
      'Study the Bible there in peace {n}× (📚). It deepens your insight 📖.',
      es: 'Estudia allí {n} veces la Biblia con calma (📚). Profundiza tu sabiduría 📖.',
      fr: 'Étudie là-bas {n} fois la Bible au calme (📚). Cela approfondit ta sagesse 📖.',
      pt: 'Estude ali {n} vezes a Bíblia com calma (📚). Isso aprofunda sua sabedoria 📖.',
    ),
    ActionType.npcConversation: Tr(
      'Führe {n}× ein Gespräch mit dieser Person (💬). Wer sich kennt, öffnet sich – ihr ✝️-Balken steigt.',
      'Have {n} conversation(s) with this person (💬). Knowing each other opens people up – their ✝️ bar rises.',
      es: 'Conversa {n} veces con esta persona (💬). Conocerse abre los corazones: su barra ✝️ sube.',
      fr: 'Discute {n} fois avec cette personne (💬). Se connaître ouvre les cœurs – sa barre ✝️ monte.',
      pt: 'Converse {n} vezes com esta pessoa (💬). Conhecer-se abre o coração – a barra ✝️ dela sobe.',
    ),
    ActionType.npcGospelShare: Tr(
      'Lade diese Person zum Glauben ein (✝️🕊️). Am besten, wenn ihr ✝️-Balken schon hoch ist – bereite es vorher mit Gespräch, Gebet und Bibel vor.',
      'Invite this person to faith (✝️🕊️). Best when their ✝️ bar is already high – prepare with talks, prayer and the Bible first.',
      es: 'Invita a esta persona a la fe (✝️🕊️). Mejor cuando su barra ✝️ ya está alta: prepáralo antes con conversación, oración y Biblia.',
      fr: 'Invite cette personne à la foi (✝️🕊️). Idéalement quand sa barre ✝️ est déjà haute – prépare d’abord par la discussion, la prière et la Bible.',
      pt: 'Convide esta pessoa à fé (✝️🕊️). Melhor quando a barra ✝️ já está alta – prepare antes com conversa, oração e Bíblia.',
    ),
  };

  static const Tr _goPerson = Tr('Geh zu {who} (zuletzt gesehen: {where}).', 'Go to {who} (last seen: {where}).', es: 'Ve a ver a {who} (visto por última vez: {where}).', fr: 'Va voir {who} (vu en dernier : {where}).', pt: 'Vá até {who} (visto por último em: {where}).');
  static const Tr _goPersonNoAddress = Tr('Geh zu {who}.', 'Go to {who}.', es: 'Ve a ver a {who}.', fr: 'Va voir {who}.', pt: 'Vá até {who}.');
  static const Tr _goPlace = Tr('Geh zu {where}.', 'Go to {where}.', es: 'Ve a {where}.', fr: 'Va à {where}.', pt: 'Vá até {where}.');
  static const Tr _follow = Tr('Tippe 📍 – dann zeigen dir Karte und Pfeil den Weg.', 'Tap 📍 – the map and the arrow will show you the way.', es: 'Toca 📍 y el mapa y la flecha te mostrarán el camino.', fr: 'Touche 📍 – la carte et la flèche te montreront le chemin.', pt: 'Toque em 📍 – o mapa e a seta mostram o caminho.');

  /// The whole explanation: where to go, what to do and why, and how to
  /// find the way. [who] is a person's first name (null for a building),
  /// [where] an address.
  static String explain({
    required ActionType type,
    required int count,
    String? who,
    String? where,
    bool tracked = false,
  }) {
    final go = who != null
        ? (where != null ? _goPerson : _goPersonNoAddress).text.replaceAll('{who}', who).replaceAll('{where}', where ?? '')
        : (where != null ? _goPlace.text.replaceAll('{where}', where) : null);
    final todo = task[type]?.text.replaceAll('{n}', '$count');
    return [
      if (go != null) go,
      if (todo != null) todo,
      if (!tracked) _follow.text,
    ].join(' ');
  }
}
