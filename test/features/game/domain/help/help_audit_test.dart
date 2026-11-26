import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_city/src/features/game/domain/actions/building_actions.dart';
import 'package:spiritual_city/src/features/game/domain/actions/game_action.dart';
import 'package:spiritual_city/src/features/game/domain/actions/npc_actions.dart';
import 'package:spiritual_city/src/features/game/domain/actions/resource.dart';
import 'package:spiritual_city/src/features/game/domain/help/help_content.dart';
import 'package:spiritual_city/src/features/game/domain/models/building_model.dart';
import 'package:spiritual_city/src/features/game/domain/models/cell_object.dart';
import 'package:spiritual_city/src/features/game/domain/models/npc_model.dart';
import 'package:spiritual_city/src/features/menu/domain/models/difficulty.dart';

/// A pastor at the very start: nothing, no church.
class _Nothing implements ResourceWallet, PastorProgress {
  @override
  double amountOf(Resource r) => 0;
  @override
  int get congregation => 0;
}

/// Playtest 2026-11-26 („überprüfen, ob alle Emojis und Spielkonzepte auch in
/// der Hilfe erklärt werden“): every emoji an action shows – its effect and
/// every lock it can show – must appear in the ❓ help, so a new one cannot
/// slip in unexplained.
void main() {
  final help = StringBuffer();
  for (final (k, t) in HelpContent.symbols) {
    help
      ..write(k)
      ..write(' ')
      ..write(t.de);
  }
  for (final t in [...HelpContent.resources.values, ...HelpContent.actions.values, ...HelpContent.explanations.values]) {
    help.write(t.de);
  }
  // The help lists every action with its emoji and sentence (generated
  // from the registries) – the action emojis are explained there.
  for (final t in BuildingType.values) {
    for (final a in BuildingActions.forType(t)) {
      help.write(a.emoji);
    }
  }
  for (final a in [...NpcActions.chat, NpcActions.lifeTalk]) {
    help.write(a.emoji);
  }
  final text = help.toString();

  // Digits, signs and fractions are no symbols to explain.
  final plain = RegExp(r'^[\s\d+\-−%?!½¼¾/.,:→]+$');
  // Variation selectors / joiners alone.
  bool isEmoji(String g) => !plain.hasMatch(g) && g.runes.any((r) => r > 0x2000);

  Iterable<String> symbolsOf(String s) => s.characters.where(isEmoji).map((g) => g.replaceAll('️', ''));

  bool explained(String g) => text.replaceAll('️', '').contains(g);

  NPCModel npc() => NPCModel(id: 'n', name: 'N', type: NPCType.citizen, homePosition: Vector2.zero());

  test('every emoji in an action effect is explained in the help', () {
    final missing = <String>{};
    final actions = <GameAction>[
      for (final t in BuildingType.values) ...BuildingActions.forType(t),
      ...NpcActions.chat,
      NpcActions.lifeTalk,
    ];
    for (final a in actions) {
      for (final g in symbolsOf(a.effect)) {
        if (!explained(g)) missing.add('$g (${a.type})');
      }
    }
    expect(missing, isEmpty, reason: missing.join('  '));
  });

  test('every lock a building action can show is explained in the help', () {
    final missing = <String>{};
    for (final t in BuildingType.values) {
      final b = BuildingModel(buildingId: 'b', type: t, residents: [npc()]);
      for (final a in BuildingActions.forType(t)) {
        final av = a.availability(b, _Nothing(), Difficulty.normal);
        if (av is! Locked) continue;
        // The help shows the lock as it looks, e.g. `🔒⛪👥 12/20`.
        final head = av.emoji.split(' ').first;
        final shown = HelpContent.symbols.any((s) => s.$1.split(' ').any((k) => k == head));
        if (!shown) missing.add('${av.emoji} (${a.type})');
      }
    }
    expect(missing, isEmpty);
  });
}
