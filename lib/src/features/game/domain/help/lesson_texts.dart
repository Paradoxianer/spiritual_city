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
    'Meisterschaft {stars} – damit verbesserst du deine geistliche Kampfführung: {what}',
    'Mastery {stars} – with it you grow in spiritual warfare: {what}',
    es: 'Maestría {stars}: con ella mejoras tu guerra espiritual: {what}',
    fr: 'Maîtrise {stars} – elle te fait progresser dans le combat spirituel : {what}',
    pt: 'Maestria {stars} – com ela você melhora sua batalha espiritual: {what}',
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
    'Lerne es bei einem Mentor: {places} – 📍 zeigt dir den Weg.',
    'Learn it from a mentor: {places} – 📍 shows you the way.',
    es: 'Apréndelo con un mentor: {places}; 📍 te muestra el camino.',
    fr: 'Apprends-le auprès d’un mentor : {places} – 📍 te montre le chemin.',
    pt: 'Aprenda com um mentor: {places} – 📍 mostra o caminho.',
  );
  static const Tr _practice = Tr(
    'Dann {n}×: {how}',
    'Then {n}×: {how}',
    es: 'Luego {n} veces: {how}',
    fr: 'Puis {n} fois : {how}',
    pt: 'Depois {n} vezes: {how}',
  );
  static const Tr _study = Tr(
    'Mit 📖 {cost} überspringst du bis zu {half} davon.',
    'With 📖 {cost} you can skip up to {half} of them.',
    es: 'Con 📖 {cost} te saltas hasta {half}.',
    fr: 'Avec 📖 {cost}, tu peux en sauter jusqu’à {half}.',
    pt: 'Com 📖 {cost} você pula até {half}.',
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
    '{mode} {level}/{cap} 🔒 – weiter geht es mit dem Mentor:',
    '{mode} {level}/{cap} 🔒 – a mentor takes you further:',
    es: '{mode} {level}/{cap} 🔒: un mentor te lleva más lejos:',
    fr: '{mode} {level}/{cap} 🔒 – un mentor t’emmène plus loin :',
    pt: '{mode} {level}/{cap} 🔒 – um mentor leva você adiante:',
  );
  static const Tr _canBuild = Tr(
    '{mode}: Stufe {level}/{cap}. Mit Erkenntnis 📖 kaufst du 🎯 Reichweite, ⚡ Stärke, ⏱️ Dauer und 💨 Tempo. Über {cap} hinaus hilft die nächste Meisterschaft ⭐ bei einem Mentor.',
    '{mode}: level {level}/{cap}. With insight 📖 you buy 🎯 range, ⚡ strength, ⏱️ duration and 💨 speed. Beyond {cap}, the next mastery ⭐ with a mentor helps.',
    es: '{mode}: nivel {level}/{cap}. Con sabiduría 📖 compras 🎯 alcance, ⚡ fuerza, ⏱️ duración y 💨 rapidez. Más allá de {cap} te ayuda la siguiente maestría ⭐ con un mentor.',
    fr: '{mode} : niveau {level}/{cap}. Avec la sagesse 📖, tu achètes 🎯 portée, ⚡ force, ⏱️ durée et 💨 vitesse. Au-delà de {cap}, la maîtrise suivante ⭐ auprès d’un mentor t’aide.',
    pt: '{mode}: nível {level}/{cap}. Com sabedoria 📖 você compra 🎯 alcance, ⚡ força, ⏱️ duração e 💨 velocidade. Além de {cap}, a próxima maestria ⭐ com um mentor ajuda.',
  );

  /// Name of a skill: its help sentence up to the colon.
  static String skillName(Skill s) {
    final t = HelpContent.skills[s]?.text ?? s.emoji;
    final colon = t.indexOf(':');
    return '${s.emoji} ${colon > 0 ? t.substring(0, colon) : t.replaceAll('.', '')}';
  }


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
    final mode = l.repeatable ? CombatAbilities.masteryMode(l.skill) : null;
    if (mode != null) {
      final stage = CombatAbilities.masteryStage(mode, learned);
      what = _mastery.text
          .replaceAll('{stars}', '⭐' * (stage + 1))
          .replaceAll('{what}', '$what 🔓 ${CombatAbilities.capFor(stage)} ➡️ ${CombatAbilities.capFor(stage + 1)}');
    }
    final parts = <String>[what];
    if (l.learnedIn(learned)) {
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
      if (l.count >= 2) {
        parts.add(_study.text
            .replaceAll('{cost}', '${LessonState.studyInsightCost}')
            .replaceAll('{half}', '${l.count ~/ 2}')
            .replaceAll('{n}', '${l.count}'));
      }
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
    String fill(Tr t) =>
        t.text.replaceAll('{mode}', modeName).replaceAll('{level}', '$level').replaceAll('{cap}', '$cap');
    if (level >= cap && nextLesson != null) return '${fill(_capReached)} $nextLesson';
    return '$base ${fill(_canBuild)}';
  }
}
