import '../../../menu/domain/models/difficulty.dart';
import '../models/npc_model.dart';
import '../services/faith_calculator_service.dart';
import 'game_action.dart';
import 'practice.dart';
import 'resource.dart';

/// All actions of the NPC dialog. Single source of truth for the buttons, the
/// keyboard slots, the affordability check and `NpcInteractionService`.
abstract final class NpcActions {
  static double _factor(Difficulty d) =>
      FaithCalculatorService.difficultyFactorFor(d);

  /// Base 8 ❤️, scaled inversely by difficulty: easy ≈ 5, normal 8, hard 16.
  static double counselHealthCost(Difficulty d) =>
      (8.0 / _factor(d)).round().clamp(1, 99).toDouble();

  /// Base 2 🙏, scaled inversely by difficulty: easy ≈ 1, normal 2, hard 4.
  static double prayFaithCost(Difficulty d) =>
      (2.0 / _factor(d)).round().clamp(1, 99).toDouble();

  static const double helpMaterialsCost = 8.0;

  /// Life talk mainly costs Faith (the central resource), only a little Health.
  static const double lifeTalkHealthCost = 2.0;
  static const double lifeTalkFaithCost = 5.0;

  /// Base reading time of 📖 in seconds (scaled by difficulty in the UI).
  static const int bibleSeconds = 5;

  static const GameAction<NPCModel> talk = GameAction(
    id: ActionId.talk,
    type: 'talk',
    emoji: '💬',
    effect: '✝️',
    discipline: Discipline.conversation,
  );

  static final GameAction<NPCModel> counsel = GameAction(
    id: ActionId.counsel,
    type: 'counsel',
    emoji: '👂',
    effect: '✝️',
    cost: (d) => ResourceCost({Resource.health: counselHealthCost(d)}),
    sessionPoints: 2,
    discipline: Discipline.counsel,
  );

  static final GameAction<NPCModel> pray = GameAction(
    id: ActionId.pray,
    type: 'pray',
    emoji: '🙏',
    effect: '✝️🌍',
    cost: (d) => ResourceCost({Resource.faith: prayFaithCost(d)}),
    discipline: Discipline.prayer,
  );

  static const GameAction<NPCModel> bible = GameAction(
    id: ActionId.bible,
    type: 'bible',
    emoji: '📖',
    effect: '🙏✝️',
    baseSeconds: bibleSeconds,
    discipline: Discipline.bible,
  );

  static final GameAction<NPCModel> help = GameAction(
    id: ActionId.help,
    type: 'help',
    emoji: '📦',
    effect: '✝️',
    cost: (_) => const ResourceCost({Resource.materials: helpMaterialsCost}),
    discipline: Discipline.service,
    visible: (npc) => npc.wantsGift,
  );

  static final GameAction<NPCModel> convert = GameAction(
    id: ActionId.convert,
    type: 'convert',
    emoji: '✝️🕊️',
    effect: '?',
    visible: (npc) => !npc.isChristian,
  );

  /// The life tab's only action (📜, docs/game_design/npc_backstory.md v5).
  static final GameAction<NPCModel> lifeTalk = GameAction(
    id: ActionId.lifeTalk,
    type: 'lifetalk',
    emoji: '🗣️',
    effect: '🌱',
    cost: (_) => const ResourceCost({
      Resource.faith: lifeTalkFaithCost,
      Resource.health: lifeTalkHealthCost,
    }),
    discipline: Discipline.counsel,
    lockedBy: (npc) => npc.backstory.currentChallenge == null ? '🌱✨' : null,
  );

  /// Chat-tab actions in fixed keyboard order: key 1 = [talk] … key 6 =
  /// [convert]. Hidden actions keep their slot so key numbers never shift.
  static final List<GameAction<NPCModel>> chat = [
    talk,
    counsel,
    pray,
    bible,
    help,
    convert,
  ];

  static final Map<String, GameAction<NPCModel>> _byType = {
    for (final a in [...chat, lifeTalk]) a.type: a,
  };

  static GameAction<NPCModel>? byType(String type) => _byType[type];
}
