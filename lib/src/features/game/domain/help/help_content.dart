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
  const Tr(this.de, this.en);

  String get text => AppStrings.currentLanguage == 'en' ? en : de;
}

/// The explanations behind the emoji, for the ❓ help screen. Lists are
/// generated from the registries (BuildingActions, Lessons …) where possible
/// so the glossary cannot fall behind the game; a test checks every enum
/// value has its sentence.
abstract final class HelpContent {
  static const Map<Resource, Tr> resources = {
    Resource.faith: Tr(
      'Glaube – deine Kraft für Gebet, Kampf und viele Aktionen. Lies in der Bibel 📖 und bete 🙏 im Pastorenhaus, um ihn aufzufüllen.',
      'Faith – your strength for prayer, combat and many actions. Read the Bible 📖 and pray 🙏 at home to refill it.',
    ),
    Resource.health: Tr(
      'Leben – sinkt bei Kämpfen und anstrengenden Diensten. Schlafen 😴 füllt es auf. Bei 0 wirst du ohnmächtig.',
      'Health – drops in fights and draining services. Sleeping 😴 refills it. At 0 you faint.',
    ),
    Resource.hunger: Tr(
      'Vorrat (Essen) – sinkt mit der Zeit. Essen 🍽️ im Pastorenhaus oder Einkaufen 🛒 füllt ihn auf.',
      'Provisions (food) – drops over time. Eating 🍽️ at home or shopping 🛒 refills them.',
    ),
    Resource.materials: Tr(
      'Material – für praktische Hilfe, Gottesdienste und Geschenke. Du findest 📦 auf der Straße, bekommst Spenden 🤲 oder arbeitest mit 🛠️.',
      'Supplies – for practical help, services and gifts. Pick up 📦 in the street, ask for donations 🤲 or work a shift 🛠️.',
    ),
    Resource.insight: Tr(
      'Erkenntnis – bekommst du für besiegte Dämonen, Bibelkreise und Missionen. Damit verbesserst du im Pastorenhaus am ⚔️-Schrank deine Gebete.',
      'Insight – earned from defeated demons, Bible groups and missions. Spend it at the ⚔️ cabinet at home to improve your prayers.',
    ),
  };

  /// Symbols that appear all over the game.
  static const List<(String, Tr)> symbols = [
    (
      '🖐️',
      Tr('Handeln (Taste E): öffnet das Kreismenü mit allem in deiner Nähe – Menschen, Häuser, 👀 Umschauen.',
          'Act (key E): opens the circle menu with everything nearby – people, buildings, 👀 look around.')
    ),
    (
      '🚪',
      Tr('Tür: Lauf einfach hinein, um ein Haus zu betreten oder anzuklopfen.',
          'Door: just walk into it to enter a building or knock.')
    ),
    (
      '🙏 / 🏙️',
      Tr('Wechselt zwischen sichtbarer Stadt und unsichtbarer Welt (kostet 🙏).',
          'Switches between the visible city and the invisible world (costs 🙏).')
    ),
    (
      '✝️',
      Tr('In der unsichtbaren Welt: gedrückt halten, um eine Gebetswelle aufzuladen. Bei Menschen: wie nah sie dem Glauben sind.',
          'In the invisible world: hold to charge a prayer wave. On people: how close they are to faith.')
    ),
    (
      '🏘️',
      Tr('Balken deines Stadtteils: Werden genug Menschen Christen, öffnet sich das Bollwerk 🏰.',
          'Your neighbourhood bar: once enough people are Christians, the stronghold 🏰 opens.')
    ),
    (
      '🏰 ⚔️ 🔥',
      Tr('Bollwerk: zu → angreifbar (⚔️) → besiegt, der Stadtteil ist erweckt (🔥). Erweckte Viertel öffnen neue Lektionen.',
          'Stronghold: closed → attackable (⚔️) → defeated, the neighbourhood is awakened (🔥). Awakened quarters open new lessons.')
    ),
    (
      '🎓',
      Tr('Lektion bei einem Mentor. Die gelbe Zeile oben links zeigt deinen Fortschritt – antippen öffnet diese Hilfe.',
          'A mentor\'s lesson. The yellow line top-left shows your progress – tap it to open this help.')
    ),
    (
      '📍',
      Tr('Mission oder Lektion verfolgen: Die Minimap und der Pfeil zeigen dir den Weg.',
          'Track a mission or lesson: the minimap and the arrow show you the way.')
    ),
    (
      '📋',
      Tr('Missionsbrett im Pastorenhaus: Missionen 📋 und der Lernweg 🎓.',
          'Mission board in the pastor house: missions 📋 and the learning path 🎓.')
    ),
    (
      '🔒3',
      Tr('Gesperrt: Du musst dieses Haus noch 3-mal besuchen bzw. dort handeln.',
          'Locked: visit or act in this building 3 more times.')
    ),
    (
      '🔒✝️ 🔒⚰️ 🔒🏫',
      Tr('Gesperrt, bis die Bedingung erfüllt ist: ein Christ wohnt hier, erst eine Beerdigung, erst mit der Leitung sprechen.',
          'Locked until: a Christian lives here, a funeral was held, you talked to the director.')
    ),
    ('🚫🙏', Tr('Dafür fehlt dir gerade diese Ressource.', 'You lack this resource right now.')),
    (
      '✨',
      Tr('Ein verborgener Fund in einem Raum – einmal pro Haus: 📖 oder 📦.',
          'A hidden find in a room – once per building: 📖 or 📦.')
    ),
    (
      '⭐',
      Tr('Meisterschaft: hebt die Höchststufe eines Gebets (2 → 5 → 10, 🕊️ bis 15).',
          'Mastery: raises the level cap of a prayer (2 → 5 → 10, 🕊️ up to 15).')
    ),
    ('👥', Tr('Wirkt auf mehrere Menschen bzw. alle Bewohner.', 'Affects several people or all residents.')),
    ('🌍', Tr('Wirkt auf die unsichtbare Welt rundherum.', 'Affects the invisible world around.')),
    ('⛪👥', Tr('Deine Gemeinde: bekehrte Menschen, die mitarbeiten.', 'Your church: converted people who help out.')),
    ('📅 😴', Tr('Ein Tag endet, wenn du im Pastorenhaus schläfst.', 'A day ends when you sleep in the pastor house.')),
  ];

  static const Map<ActionId, Tr> actions = {
    // ── People ──
    ActionId.talk: Tr('Gespräch: Ihr lernt euch kennen, die Person wird offener.',
        'Talk: you get to know each other, the person opens up.'),
    ActionId.counsel: Tr('Zuhören und Seelsorge – kostet ❤️, wirkt stark auf den Glauben.',
        'Listen and counsel – costs ❤️, strongly moves their faith.'),
    ActionId.pray: Tr('Mit der Person beten.', 'Pray with the person.'),
    ActionId.bible: Tr('Aus der Bibel erzählen.', 'Share from the Bible.'),
    ActionId.help:
        Tr('Ein Geschenk 📦 – nur wenn die Person etwas braucht.', 'A gift 📦 – only when the person needs something.'),
    ActionId.convert: Tr('Einladen, Christ zu werden. Gelingt, wenn ihr ✝️-Balken hoch genug ist.',
        'Invite them to follow Christ. Works when their ✝️ bar is high enough.'),
    ActionId.lifeTalk: Tr(
        'Lebensgeschichte (nach 🫂 Seelsorge): Du erfährst ihre Geschichte und hilfst bei alten Wunden.',
        'Life story (after 🫂 pastoral care): learn their story and help with old wounds.'),
    // ── Pastor house ──
    ActionId.readBible: Tr('Bibel lesen: füllt deinen Glauben auf.', 'Read the Bible: refills your faith.'),
    ActionId.eat: Tr('Essen: füllt den Vorrat auf.', 'Eat: refills provisions.'),
    ActionId.sleep: Tr('Schlafen: füllt ❤️ auf und beendet den Tag.', 'Sleep: refills ❤️ and ends the day.'),
    ActionId.homePray: Tr('Gebet zu Hause: Glaube und die Umgebung wird hell.',
        'Prayer at home: faith, and the area around grows bright.'),
    ActionId.missions: Tr('Missionsbrett: Missionen und Lernweg.', 'Mission board: missions and learning path.'),
    // ── Homes ──
    ActionId.practicalHelp: Tr('Praktisch helfen (−📦): Die Bewohner kommen dem Glauben näher.',
        'Practical help (−📦): the residents come closer to faith.'),
    ActionId.housePray: Tr('Für das Haus beten.', 'Pray for the home.'),
    ActionId.houseVisit: Tr('Kaffeebesuch – ab einigen Besuchen. Du wirst bewirtet: ❤️ und 🍞.',
        'Coffee visit – after a few visits. You are looked after: ❤️ and 🍞.'),
    ActionId.discipleshipGroup:
        Tr('Hauskreis – wenn hier ein Christ wohnt. Gibt 📖.', 'Home group – when a Christian lives here. Gives 📖.'),
    ActionId.blessHousehold: Tr('Alle Haushalte im Wohnblock segnen.', 'Bless every household in the block.'),
    // ── Church ──
    ActionId.sundayService: Tr(
        'Gottesdienst halten (−📦 −❤️): viel 🙏, die Umgebung wird hell. Zählt für Lektionen mit ⛪.',
        'Hold a service (−📦 −❤️): lots of 🙏, the area grows bright. Counts for ⛪ lessons.'),
    ActionId.worship:
        Tr('Lobpreis: Glaube, dauerhaft helleres Viertel.', 'Worship: faith and a lastingly brighter area.'),
    // ── Hospital ──
    ActionId.medicalHelp: Tr('Medizinische Hilfe: ❤️ und 🍞 voll.', 'Medical help: ❤️ and 🍞 full.'),
    ActionId.counseling: Tr('Seelsorge an Kranken.', 'Counselling the sick.'),
    ActionId.chapelService:
        Tr('Andacht in der Kapelle. Zählt auch als Gottesdienst ⛪.', 'Chapel service. Also counts as a ⛪ service.'),
    // ── School ──
    ActionId.letterToManagement: Tr('Brief an die Leitung.', 'Letter to the management.'),
    ActionId.talkDirector:
        Tr('Gespräch mit der Leitung – öffnet den Vortrag 🎤.', 'Talk to the director – unlocks the talk 🎤.'),
    ActionId.valueLecture: Tr('Wertevortrag vor allen.', 'A talk on values for everyone.'),
    ActionId.prayerCircle: Tr('Gebetskreis: gibt 📖.', 'Prayer circle: gives 📖.'),
    // ── Cemetery ──
    ActionId.funeral: Tr('Beerdigung halten.', 'Hold a funeral.'),
    ActionId.comfort: Tr('Trauernde trösten (nach einer Beerdigung) – sehr anstrengend, sehr tief.',
        'Comfort the mourners (after a funeral) – very draining, very deep.'),
    // ── Civic ──
    ActionId.blessPolice: Tr('Die Polizei segnen.', 'Bless the police.'),
    ActionId.mayorAudience: Tr('Termin beim Bürgermeister.', 'Audience with the mayor.'),
    ActionId.prayForPoliticians: Tr('Für die Regierenden beten – wirkt auf die ganze Stadt 🌍.',
        'Pray for those in authority – affects the whole city 🌍.'),
    ActionId.travel: Tr('Mit dem Zug in einen anderen Stadtteil fahren.', 'Take the train to another part of town.'),
    ActionId.majorEvent: Tr('Großveranstaltung im Stadion: 📖.', 'Big event in the stadium: 📖.'),
    // ── Commercial ──
    ActionId.talkBoss: Tr('Gespräch mit der Chefin / dem Chef.', 'Talk to the boss.'),
    ActionId.shopping: Tr('Einkaufen: 🍞 und ❤️.', 'Shopping: 🍞 and ❤️.'),
    ActionId.bless: Tr('Das Geschäft segnen.', 'Bless the business.'),
    ActionId.requestDonation: Tr('Um Spenden bitten: vielleicht 📦.', 'Ask for donations: maybe 📦.'),
    // ── Generic ──
    ActionId.genericPray: Tr('Hier beten.', 'Pray here.'),
    ActionId.witness: Tr('Von Jesus erzählen.', 'Tell people about Jesus.'),
    ActionId.distribute: Tr('Etwas verteilen.', 'Hand things out.'),
    ActionId.blessVehicles: Tr('Fahrzeuge und Mannschaft segnen.', 'Bless the vehicles and the crew.'),
    ActionId.chaplaincy:
        Tr('Notfallseelsorge nach einem schweren Einsatz.', 'Emergency chaplaincy after a hard call-out.'),
    ActionId.bringMeal: Tr('Der Schicht ein Essen bringen.', 'Bring a meal to the shift.'),
    ActionId.sendCards: Tr('Ermutigungskarten verschicken.', 'Send encouragement cards.'),
    ActionId.study: Tr('In Ruhe studieren: 📖.', 'Quiet study: 📖.'),
    ActionId.bookCircle: Tr('Lesekreis mit den Besuchern.', 'Reading circle with the visitors.'),
    ActionId.churchHistory:
        Tr('Kirchengeschichte in der Ausstellung: etwas 📖.', 'Church history in the exhibition: a little 📖.'),
    ActionId.workShift: Tr('Eine Schicht mitarbeiten: 📦, kostet Kraft.', 'Work a shift: 📦, costs strength.'),
    ActionId.prayWorkers: Tr('Für die Sicherheit der Arbeiter beten.', 'Pray for the workers\' safety.'),
    // ── Learned ──
    ActionId.intercede: Tr(
        'Fürbitte für ein Haus (gelernt 🙏): Heute öffnet sich die Tür leichter, Gespräche wirken mehr.',
        'Intercede for a home (learned 🙏): today the door opens more easily and talks achieve more.'),
    ActionId.fast: Tr(
        'Fasten (gelernt 🍞): kostet 🍞, Gebete in der unsichtbaren Welt sind billiger, bis du heimkommst.',
        'Fast (learned 🍞): costs 🍞, prayer in the invisible world is cheaper until you get home.'),
    ActionId.preach: Tr(
        'Predigen (gelernt 📢) in der Kirche: alle Menschen in der Nähe hören zu. Einmal pro Tag und Kirche.',
        'Preach (learned 📢) in a church: everyone nearby listens. Once a day per church.'),
  };

  static const Map<PrayerMode, Tr> prayerModes = {
    PrayerMode.liberation: Tr('Befreiung: Hauptgebet, macht rote Felder grün und trifft Dämonen. Bis Stufe 15.',
        'Liberation: the main prayer, turns red ground green and hits demons. Up to level 15.'),
    PrayerMode.rebuke:
        Tr('Zurückweisen: stößt Dämonen weg (stark gegen 🪨).', 'Rebuke: pushes demons away (strong against 🪨).'),
    PrayerMode.slow:
        Tr('Binden: verlangsamt Dämonen (stark gegen 🐍).', 'Bind: slows demons down (strong against 🐍).'),
    PrayerMode.drain: Tr('Entwaffnen: nimmt Dämonen Kraft und gibt dir 🙏 (stark gegen 🦇).',
        'Disarm: drains demons and gives you 🙏 (strong against 🦇).'),
  };

  static const Map<DaemonKind, Tr> daemons = {
    DaemonKind.lurker: Tr('Lauerer: schnell, schwach, kommt in Gruppen.', 'Lurker: fast, weak, comes in groups.'),
    DaemonKind.brute: Tr('Koloss: langsam, sehr viel Kraft.', 'Brute: slow, lots of strength.'),
    DaemonKind.leech: Tr('Sauger: zieht dir in der Nähe Glauben ab.', 'Leech: drains your faith while close.'),
    DaemonKind.possessor: Tr(
        'Besetzer: sitzt in einem Menschen. Erst besiegbar, wenn dieser Mensch in der Stadt Seelsorge bekommen hat.',
        'Possessor: sits in a person. Only beatable once that person was cared for in the city.'),
  };

  static const Map<Skill, Tr> skills = {
    Skill.pastoralCare:
        Tr('Seelsorge: schaltet die Lebensgeschichten 📜 frei.', 'Pastoral care: unlocks life stories 📜.'),
    Skill.spiritualWarfare:
        Tr('Geistlicher Kampf: schaltet 🫸 Zurückweisen frei.', 'Spiritual warfare: unlocks 🫸 rebuke.'),
    Skill.binding: Tr('Binden: schaltet ⏳ frei.', 'Binding: unlocks ⏳.'),
    Skill.disarming: Tr('Entwaffnen: schaltet 🪫 frei.', 'Disarming: unlocks 🪫.'),
    Skill.discernment:
        Tr('Unterscheidung der Geister: Du erkennst die Dämonenarten.', 'Discernment: you see the kinds of demons.'),
    Skill.intercession: Tr('Fürbitte: 🙏🏠 in Wohnhäusern.', 'Intercession: 🙏🏠 in homes.'),
    Skill.fasting: Tr('Fasten: ➖🍞 im Pastorenhaus.', 'Fasting: ➖🍞 in the pastor house.'),
    Skill.preaching: Tr('Predigen: 📢 in Kirchen.', 'Preaching: 📢 in churches.'),
    Skill.liberationMastery1: Tr('🕊️ Befreiung bis Stufe 5.', '🕊️ liberation up to level 5.'),
    Skill.liberationMastery2: Tr('🕊️ Befreiung bis Stufe 10.', '🕊️ liberation up to level 10.'),
    Skill.liberationMastery3: Tr('🕊️ Befreiung bis Stufe 15.', '🕊️ liberation up to level 15.'),
    Skill.rebukeMastery1: Tr('🫸 bis Stufe 5.', '🫸 up to level 5.'),
    Skill.rebukeMastery2: Tr('🫸 bis Stufe 10.', '🫸 up to level 10.'),
    Skill.slowMastery1: Tr('⏳ bis Stufe 5.', '⏳ up to level 5.'),
    Skill.slowMastery2: Tr('⏳ bis Stufe 10.', '⏳ up to level 10.'),
    Skill.drainMastery1: Tr('🪫 bis Stufe 5.', '🪫 up to level 5.'),
    Skill.drainMastery2: Tr('🪫 bis Stufe 10.', '🪫 up to level 10.'),
  };

  /// How to do a lesson's practice task – the answer to "I have the task,
  /// how do I do it?".
  static const Map<LessonTask, Tr> taskHowTo = {
    LessonTask.counsel: Tr('Sprich mit Menschen 🖐️ und wähle 👂 Zuhören – oder 👂 im Krankenhaus 🏥.',
        'Talk to people 🖐️ and choose 👂 listen – or 👂 in a hospital 🏥.'),
    LessonTask.defeatDaemons: Tr(
        'Wechsle mit 🙏 in die unsichtbare Welt und besiege Dämonen 👹 mit beliebigen Gebeten.',
        'Switch to the invisible world with 🙏 and defeat demons 👹 with any prayer.'),
    LessonTask.pray: Tr('Bete – bei Menschen 🙏, in Häusern 🙏 oder im Pastorenhaus. Jedes Gebet zählt.',
        'Pray – with people 🙏, in buildings 🙏 or at home. Every prayer counts.'),
    LessonTask.service: Tr(
        'Geh in eine Kirche ⛪ und halte einen Gottesdienst ⛪ (kostet 📦 und ❤️). Eine Andacht ⛪ im Krankenhaus 🏥 zählt auch.',
        'Go to a church ⛪ and hold a service ⛪ (costs 📦 and ❤️). A chapel service ⛪ in a hospital 🏥 counts too.'),
    LessonTask.defeatLiberation: Tr(
        'Besiege Dämonen in der unsichtbaren Welt mit 🕊️ Befreiung (der letzte Treffer zählt).',
        'Defeat demons in the invisible world with 🕊️ liberation (the final hit counts).'),
    LessonTask.defeatRebuke: Tr('Besiege Dämonen mit 🫸 Zurückweisen.', 'Defeat demons with 🫸 rebuke.'),
    LessonTask.defeatSlow: Tr('Besiege Dämonen mit ⏳ Binden.', 'Defeat demons with ⏳ binding.'),
    LessonTask.defeatDrain: Tr('Besiege Dämonen mit 🪫 Entwaffnen.', 'Defeat demons with 🪫 disarming.'),
  };

  static const Map<BuildingType, Tr> buildings = {
    BuildingType.house: Tr('Wohnhaus', 'House'),
    BuildingType.apartment: Tr('Wohnblock', 'Apartment block'),
    BuildingType.pastorHouse: Tr('Pastorenhaus (dein Zuhause)', 'Pastor house (your home)'),
    BuildingType.shop: Tr('Laden', 'Shop'),
    BuildingType.supermarket: Tr('Supermarkt', 'Supermarket'),
    BuildingType.mall: Tr('Einkaufszentrum', 'Mall'),
    BuildingType.office: Tr('Büro', 'Office'),
    BuildingType.skyscraper: Tr('Hochhaus', 'Skyscraper'),
    BuildingType.factory: Tr('Fabrik', 'Factory'),
    BuildingType.warehouse: Tr('Lagerhalle', 'Warehouse'),
    BuildingType.trainStation: Tr('Bahnhof', 'Train station'),
    BuildingType.policeStation: Tr('Polizei', 'Police station'),
    BuildingType.fireStation: Tr('Feuerwehr', 'Fire station'),
    BuildingType.postOffice: Tr('Post', 'Post office'),
    BuildingType.hospital: Tr('Krankenhaus', 'Hospital'),
    BuildingType.school: Tr('Schule', 'School'),
    BuildingType.university: Tr('Universität', 'University'),
    BuildingType.church: Tr('Kirche', 'Church'),
    BuildingType.cathedral: Tr('Kathedrale', 'Cathedral'),
    BuildingType.library: Tr('Bibliothek', 'Library'),
    BuildingType.museum: Tr('Museum', 'Museum'),
    BuildingType.stadium: Tr('Stadion', 'Stadium'),
    BuildingType.cityHall: Tr('Rathaus', 'City hall'),
    BuildingType.cemetery: Tr('Friedhof', 'Cemetery'),
    BuildingType.powerPlant: Tr('Kraftwerk', 'Power plant'),
  };

  /// What comes after the tutorial – the walkthrough continues the tutorial
  /// steps with these.
  static const List<(String, Tr, Tr)> nextSteps = [
    (
      '🎓',
      Tr('Lerne bei Mentoren', 'Learn from mentors'),
      Tr('Im Missionsbrett 📋 unter 🎓 siehst du alle Fähigkeiten und wo ihre Mentoren sind. Tippe 📍, geh hin und nimm die Lektion an 🎓✅. Dann übst du die Aufgabe – die gelbe Zeile oben links zeigt, wie weit du bist.',
          'The mission board 📋 lists every skill under 🎓 and where its mentors are. Tap 📍, go there and accept the lesson 🎓✅. Then practise the task – the yellow line top-left shows your progress.')
    ),
    (
      '⚔️',
      Tr('Verbessere deine Gebete', 'Improve your prayers'),
      Tr('Erkenntnis 📖 investierst du im Pastorenhaus 🏡 am ⚔️-Schrank. Ab einer Stufe brauchst du eine Meisterschaft ⭐ von einem Mentor – das Menü zeigt dir, welche und wo (📍).',
          'Spend insight 📖 at the ⚔️ cabinet in the pastor house 🏡. Past a certain level you need a mastery ⭐ from a mentor – the menu shows which one and where (📍).')
    ),
    (
      '🏘️🔥',
      Tr('Erwecke Stadtteile', 'Awaken neighbourhoods'),
      Tr('Werden in einem Stadtteil genug Menschen Christen, öffnet sich das Bollwerk 🏰. Besiege es in der unsichtbaren Welt – der Stadtteil ist erweckt 🔥 und neue Lektionen (z.B. 📢 Predigen) werden frei.',
          'Once enough people in a quarter are Christians, its stronghold 🏰 opens. Defeat it in the invisible world – the quarter awakens 🔥 and new lessons (e.g. 📢 preaching) open.')
    ),
    (
      '😴',
      Tr('Pass auf dich auf', 'Look after yourself'),
      Tr('Halte ❤️ und 🍞 im Blick. Schlafen 😴 im Pastorenhaus füllt ❤️ und beendet den Tag, Essen 🍽️ füllt 🍞. Der Pfeil oben links zeigt dir immer den Weg nach Hause 🏡.',
          'Watch ❤️ and 🍞. Sleeping 😴 at home refills ❤️ and ends the day, eating 🍽️ refills 🍞. The arrow top-left always points home 🏡.')
    ),
    (
      '⛪👥',
      Tr('Baue Gemeinde', 'Build a church'),
      Tr('Bekehrte Menschen gehören zu deiner Gemeinde. Besuche sie, gründe Hauskreise 📖👥 und halte Gottesdienste ⛪ – so wächst der Glaube im ganzen Viertel.',
          'Converted people belong to your church. Visit them, start home groups 📖👥 and hold services ⛪ – that is how faith grows in the whole quarter.')
    ),
  ];

  static const sectionTitles = {
    'resources': Tr('Ressourcen', 'Resources'),
    'symbols': Tr('Symbole', 'Symbols'),
    'people': Tr('Menschen', 'People'),
    'buildings': Tr('Gebäude', 'Buildings'),
    'spirit': Tr('Unsichtbare Welt', 'Invisible world'),
    'lessons': Tr('Lektionen', 'Lessons'),
    'tasks': Tr('Meine Aufgaben', 'My tasks'),
    'steps': Tr('Erste Schritte', 'First steps'),
    'glossary': Tr('Glossar', 'Glossary'),
    'keys': Tr('Tasten', 'Keys'),
    'search': Tr('Suchen (Emoji oder Wort)', 'Search (emoji or word)'),
    'noLesson':
        Tr('Gerade keine Lektion. Diese kannst du jetzt lernen:', 'No lesson right now. You can learn these now:'),
    'mentors': Tr('Mentor in', 'Mentor at'),
    'where': Tr('Wo?', 'Where?'),
    'requires': Tr('Braucht zuerst', 'Needs first'),
    'learned': Tr('Gelernt – und wo du es einsetzt', 'Learned – and where to use it'),
    'invisible': Tr('in der unsichtbaren Welt', 'in the invisible world'),
    'tutorial': Tr('Tutorial', 'Tutorial'),
    'awakened': Tr('erweckte Stadtteile', 'awakened quarters'),
  };

  static String title(String key) => sectionTitles[key]!.text;
}
