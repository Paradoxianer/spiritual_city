import '../models/cell_object.dart';
import '../models/skills.dart';
import '../services/combat_abilities.dart';
import '../services/learning_service.dart';
import '../models/prayer_combat.dart';
import 'help_content.dart';

/// Lessons told in sentences by the narrator (playtest 2026-10-31: "the
/// important thing is explaining the missions that expand knowledge or
/// combat strength – what to do, where and how").
abstract final class LessonTexts {
  static const Tr _mastery = Tr(
    'Meisterschaft {stars} – damit kannst du deine Gebete im ⚔️-Schrank weiter ausbauen: {what}',
    'Mastery {stars} – with it you can build up your prayers further at the ⚔️ cabinet: {what}',
    es: 'Maestría {stars}: con ella puedes seguir mejorando tus oraciones en el armario ⚔️: {what}',
    fr: 'Maîtrise {stars} – elle te permet d’améliorer encore tes prières à l’armoire ⚔️ : {what}',
    pt: 'Maestria {stars} – com ela você pode melhorar ainda mais suas orações no armário ⚔️: {what}',
  );
  static const Tr _learned = Tr('Das hast du schon gelernt ✅.', 'You have learned this already ✅.',
      es: 'Esto ya lo has aprendido ✅.', fr: 'Tu l’as déjà appris ✅.', pt: 'Você já aprendeu isso ✅.');
  static const Tr _running = Tr(
    'Du übst gerade: {p} von {n} geschafft. So geht es: {how}',
    'You are practising: {p} of {n} done. This is how: {how}',
    es: 'Estás practicando: {p} de {n} hechos. Así se hace: {how}',
    fr: 'Tu t’exerces : {p} sur {n} réussis. Voici comment : {how}',
    pt: 'Você está praticando: {p} de {n} feitos. É assim: {how}',
  );
  static const Tr _where = Tr(
    'So lernst du es: Geh zu einem Mentor – {places}. Tippe 📍, dann zeigen dir Karte und Pfeil den Weg, und nimm dort die Lektion an (🎓✅).',
    'How to learn it: go to a mentor – {places}. Tap 📍 and the map and the arrow show you the way; accept the lesson there (🎓✅).',
    es: 'Así lo aprendes: ve a un mentor – {places}. Toca 📍 y el mapa y la flecha te mostrarán el camino; acepta allí la lección (🎓✅).',
    fr: 'Pour l’apprendre : va voir un mentor – {places}. Touche 📍, la carte et la flèche te montrent le chemin ; accepte la leçon sur place (🎓✅).',
    pt: 'Como aprender: vá até um mentor – {places}. Toque em 📍 e o mapa e a seta mostram o caminho; aceite a lição lá (🎓✅).',
  );
  static const Tr _practice = Tr(
    'Danach übst du {n}×: {how}',
    'Then you practise {n}×: {how}',
    es: 'Después practicas {n} veces: {how}',
    fr: 'Ensuite tu t’exerces {n} fois : {how}',
    pt: 'Depois você pratica {n} vezes: {how}',
  );
  static const Tr _study = Tr(
    'Beim Mentor kannst du auch mit 📖 studieren (📖➡️): je 3 📖 ein Schritt, höchstens die Hälfte.',
    'At the mentor you can also study with 📖 (📖➡️): one step per 3 📖, at most half.',
    es: 'Con el mentor también puedes estudiar con 📖 (📖➡️): un paso por cada 3 📖, como mucho la mitad.',
    fr: 'Chez le mentor, tu peux aussi étudier avec 📖 (📖➡️) : une étape pour 3 📖, au plus la moitié.',
    pt: 'Com o mentor você também pode estudar com 📖 (📖➡️): um passo a cada 3 📖, no máximo a metade.',
  );
  static const Tr _needs = Tr('Noch gesperrt – vorher brauchst du: {skills}.', 'Still locked – first you need: {skills}.',
      es: 'Aún bloqueado: antes necesitas {skills}.', fr: 'Encore verrouillé – il te faut d’abord : {skills}.',
      pt: 'Ainda bloqueado – antes você precisa de: {skills}.');
  static const Tr _awaken = Tr(
    'Außerdem müssen erst {n} Viertel erweckt sein 🏰🔥 (jetzt: {have}): Werden in einem Viertel genug Menschen Christen, besiege das Bollwerk in der unsichtbaren Welt.',
    'Also {n} quarters must be awakened first 🏰🔥 (now: {have}): once enough people in a quarter are Christians, defeat its stronghold in the invisible world.',
    es: 'Además deben estar despertados {n} barrios 🏰🔥 (ahora: {have}): cuando haya suficientes cristianos en un barrio, vence su fortaleza en el mundo invisible.',
    fr: 'Il faut aussi d’abord {n} quartiers réveillés 🏰🔥 (maintenant : {have}) : quand assez de gens d’un quartier sont chrétiens, vaincs sa forteresse dans le monde invisible.',
    pt: 'Além disso, primeiro {n} bairros precisam estar despertados 🏰🔥 (agora: {have}): quando houver cristãos suficientes num bairro, vença a fortaleza no mundo invisível.',
  );
  static const Tr _capReached = Tr(
    '{mode} ist auf der höchsten Stufe, die du gerade erreichen kannst ({level}/{cap}). Weiter geht es mit dem nächsten Mentor-Schritt:',
    '{mode} is at the highest level you can reach right now ({level}/{cap}). The next mentor step takes you further:',
    es: '{mode} está en el nivel más alto que puedes alcanzar ahora ({level}/{cap}). El siguiente paso con un mentor te lleva más lejos:',
    fr: '{mode} est au niveau le plus haut que tu peux atteindre pour l’instant ({level}/{cap}). L’étape suivante avec un mentor te mène plus loin :',
    pt: '{mode} está no nível mais alto que você pode alcançar agora ({level}/{cap}). O próximo passo com um mentor leva você mais longe:',
  );
  static const Tr _canBuild = Tr(
    '{mode}: Stufe {level} von {cap}. Mit 📖 Weisheit kaufst du hier Stufen – 🎯 weiter, ⚡ stärker, ⏱️ länger, 💨 schneller. Weisheit bekommst du von besiegten Dämonen, Missionen und Bibelkreisen.',
    '{mode}: level {level} of {cap}. With 📖 insight you buy levels here – 🎯 further, ⚡ stronger, ⏱️ longer, 💨 faster. You get insight from defeated demons, missions and Bible groups.',
    es: '{mode}: nivel {level} de {cap}. Con sabiduría 📖 compras niveles aquí: 🎯 más lejos, ⚡ más fuerte, ⏱️ más tiempo, 💨 más rápido. La sabiduría la ganas venciendo demonios, con misiones y grupos bíblicos.',
    fr: '{mode} : niveau {level} sur {cap}. Avec la sagesse 📖, tu achètes des niveaux ici – 🎯 plus loin, ⚡ plus fort, ⏱️ plus longtemps, 💨 plus vite. Tu gagnes de la sagesse en vainquant des démons, par les missions et les groupes bibliques.',
    pt: '{mode}: nível {level} de {cap}. Com sabedoria 📖 você compra níveis aqui – 🎯 mais longe, ⚡ mais forte, ⏱️ mais tempo, 💨 mais rápido. Você ganha sabedoria vencendo demônios, com missões e grupos bíblicos.',
  );

  /// Name of a skill: its help sentence up to the colon.
  static String skillName(Skill s) {
    final t = HelpContent.skills[s]?.text ?? s.emoji;
    final colon = t.indexOf(':');
    return '${s.emoji} ${colon > 0 ? t.substring(0, colon) : t.replaceAll('.', '')}';
  }

  static bool _isMastery(Skill s) =>
      PrayerMode.values.any((m) => CombatAbilities.mastery(m).contains(s));

  static String _places(Lesson l) => [
        for (final b in l.mentorAt)
          '${HelpContent.buildings[b]?.text.split(' (').first ?? b.name} ${_emoji(b)}'
      ].join(' / ');

  static String _emoji(BuildingType b) => switch (b) {
        BuildingType.church => '⛪',
        BuildingType.cathedral => '🕍',
        BuildingType.hospital => '🏥',
        BuildingType.school => '🏫',
        BuildingType.university => '🎓',
        BuildingType.library => '📚',
        _ => '',
      };

  /// What [l] teaches, where and how – for the player's current state.
  static String explain(Lesson l, {
    required LearnedSkills learned,
    required int awakenings,
    Skill? active,
    int progress = 0,
  }) {
    final how = HelpContent.taskHowTo[l.task]?.text ?? l.task.emoji;
    var what = HelpContent.skills[l.skill]?.text ?? l.unlocks;
    if (_isMastery(l.skill)) {
      final stars = '⭐' * (CombatAbilities.mastery(
              PrayerMode.values.firstWhere((m) => CombatAbilities.mastery(m).contains(l.skill)))
          .indexOf(l.skill) + 1);
      what = _mastery.text.replaceAll('{stars}', stars).replaceAll('{what}', what);
    }
    final parts = <String>[what];
    if (learned.has(l.skill)) {
      parts.add(_learned.text);
    } else if (active == l.skill) {
      parts.add(_running.text
          .replaceAll('{p}', '$progress')
          .replaceAll('{n}', '${l.count}')
          .replaceAll('{how}', how));
    } else {
      final missing = [for (final r in l.requires) if (!learned.has(r)) skillName(r)];
      if (missing.isNotEmpty) parts.add(_needs.text.replaceAll('{skills}', missing.join(', ')));
      if (awakenings < l.minAwakenings) {
        parts.add(_awaken.text.replaceAll('{n}', '${l.minAwakenings}').replaceAll('{have}', '$awakenings'));
      }
      parts.add(_where.text.replaceAll('{places}', _places(l)));
      parts.add(_practice.text.replaceAll('{n}', '${l.count}').replaceAll('{how}', how));
      if (l.count >= 2) parts.add(_study.text);
    }
    return parts.join(' ');
  }

  /// A prayer mode in the ⚔️ cabinet: what it is, its level, and how to
  /// go further.
  static String explainMode(PrayerMode mode, {
    required int level,
    required int cap,
    required String modeName,
    String? nextLesson,
  }) {
    final base = HelpContent.prayerModes[mode]?.text ?? '';
    if (level >= cap && nextLesson != null) {
      return '$base ${_capReached.text.replaceAll('{mode}', modeName).replaceAll('{level}', '$level').replaceAll('{cap}', '$cap')} $nextLesson';
    }
    return '$base ${_canBuild.text.replaceAll('{mode}', modeName).replaceAll('{level}', '$level').replaceAll('{cap}', '$cap')}';
  }
}
