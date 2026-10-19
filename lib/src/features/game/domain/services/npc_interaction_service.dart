import 'dart:math';

import '../actions/npc_actions.dart';
import '../actions/practice.dart';
import '../models/npc_model.dart';
import '../../../menu/domain/models/difficulty.dart';
import 'faith_calculator_service.dart';
import 'interaction_variance_service.dart';

/// What an NPC action did. Changes to the [NPCModel] itself are applied
/// directly by [NpcInteractionService]; everything outside the NPC (player
/// resources, cells, counters) is described here and applied by the caller.
class NpcInteractionResult {
  final String reaction;

  /// Net change of the player's resources (costs negative).
  final double playerFaithDelta;
  final double playerHealthDelta;
  final double playerMaterialsDelta;
  final double insightDelta;

  /// Nudge for the spiritual state of the NPC's own cell (accepted prayer).
  final double cellDelta;

  /// Conversion: strong light around the NPC (radius 5).
  final bool converted;

  /// A 💬 talk was held (counts towards conversation counters/missions).
  final bool conversationHeld;

  /// 📦 help was given (service mission counter).
  final bool serviceCompleted;

  /// The action really happened (its cost was paid) – used for practice.
  final bool performed;

  /// This action loosened a possession: the possessor can now be fought.
  final bool possessionWeakened;

  const NpcInteractionResult({
    required this.reaction,
    this.playerFaithDelta = 0,
    this.playerHealthDelta = 0,
    this.playerMaterialsDelta = 0,
    this.insightDelta = 0,
    this.cellDelta = 0,
    this.converted = false,
    this.conversationHeld = false,
    this.serviceCompleted = false,
    this.performed = true,
    this.possessionWeakened = false,
  });
}

/// The rules of the NPC dialog, independent of Flame
/// (docs/game_design/release_roadmap.md §2.1). Moved here unchanged from
/// `NPCComponent.handleInteraction`, plus the practice and relationship
/// bonuses of §3.4.
class NpcInteractionService {
  final Difficulty difficulty;
  final Random _random;
  final FaithCalculatorService _calc;

  NpcInteractionService({required Difficulty difficulty, Random? rng})
      : this._(difficulty, rng ?? Random());

  NpcInteractionService._(this.difficulty, this._random)
      : _calc = FaithCalculatorService(difficulty: difficulty, rng: _random);

  /// Insight for a successful conversion – a bigger, rarer milestone than a
  /// single worked-through backstory event.
  static const double conversionInsightReward = 0.5;

  /// Insight for fully working through one life challenge; extra when it also
  /// grew the "Als Christ" chapter, and when it was the last open one.
  static const double lifeTalkInsightOnCompletion = 0.2;
  static const double lifeTalkInsightOnChristGrowth = 0.3;
  static const double lifeTalkInsightOnFullyResolved = 0.5;

  /// NPC faith gained per severity point once a challenge is worked through.
  static const double lifeTalkFaithPerSeverity = 2.0;

  /// Runs action [type] on [npc].
  ///
  /// [spiritualState] is the NPC's cell (−1 … 1), [playerFaith] /
  /// [playerHealth] / [playerMaterials] the current amounts, and
  /// [practiceMultiplier] the pastor's practice bonus for this action.
  NpcInteractionResult perform(
    String type,
    NPCModel npc, {
    required double spiritualState,
    required double playerFaith,
    required double playerHealth,
    required double playerMaterials,
    double practiceMultiplier = 1.0,
  }) {
    npc.currentSessionInteractions++;

    final interactionScore = npc.faith + spiritualState * 50;

    // Liberated cells amplify gains, dark cells reduce them: 0.5× … 1.5×.
    final spiritualBonus = (1.0 + spiritualState * 0.5).clamp(0.5, 1.5);

    // Practice (pastor) × relationship (this person) – §3.4.
    final growth =
        practiceMultiplier * Relationship.multiplier(npc.sessionBonus);

    final resonance = (npc.faith / 20.0).clamp(-5.0, 5.0);
    var playerFaith0 = resonance;

    npc.lastNpcFaithDelta = 0.0;
    npc.lastPlayerFaithDelta = resonance;
    npc.lastMaterialsDelta = 0.0;
    npc.lastPlayerHealthDelta = 0.0;

    NpcInteractionResult refused(String reaction) {
      npc.currentSessionInteractions--;
      return NpcInteractionResult(
        reaction: reaction,
        playerFaithDelta: playerFaith0,
        performed: false,
      );
    }

    double gain(int base, String varianceKey) =>
        (base * spiritualBonus * InteractionVarianceService.multiplierFor(npc, varianceKey) * growth)
            .roundToDouble();

    switch (type) {
      case 'talk':
        final g = gain(_calc.calculateConversationGain(), 'talk');
        npc.applyInfluence(g);
        npc.recordAction('talk');
        npc.interactionCount++;
        npc.lastNpcFaithDelta = g;
        return NpcInteractionResult(
          reaction: _talkEmoji(npc),
          playerFaithDelta: playerFaith0,
          conversationHeld: true,
        );

      case 'counsel':
        final hpCost = NpcActions.counselHealthCost(difficulty);
        if (playerHealth <= hpCost) return refused('🚫❤️');
        npc.lastPlayerHealthDelta = -hpCost;
        final g = gain(_calc.calculateCounselingGain(), 'counsel');
        npc.applyInfluence(g);
        npc.recordAction('counsel');
        // Counts as 6 interactions so the session-dot bonus grows quickly.
        npc.interactionCount += 6;
        npc.currentSessionInteractions++; // 2 session points in total
        npc.lastNpcFaithDelta = g;
        if (npc.possessed && !npc.possessionWeakened) {
          npc.possessionWeakened = true;
          return NpcInteractionResult(
            reaction: '👂👁️💔',
            playerFaithDelta: playerFaith0,
            playerHealthDelta: -hpCost,
            possessionWeakened: true,
          );
        }
        return NpcInteractionResult(
          reaction: ['👂💬', '👂🙏', '👂😊', '👂💛'][_random.nextInt(4)],
          playerFaithDelta: playerFaith0,
          playerHealthDelta: -hpCost,
        );

      case 'lifetalk':
        final challenge = npc.backstory.currentChallenge;
        if (challenge == null) return refused('🌱😊');
        if (playerHealth <= NpcActions.lifeTalkHealthCost) return refused('🚫❤️');
        if (playerFaith < NpcActions.lifeTalkFaithCost) return refused('🚫🙏');
        playerFaith0 -= NpcActions.lifeTalkFaithCost;
        npc.lastPlayerHealthDelta = -NpcActions.lifeTalkHealthCost;
        npc.lastPlayerFaithDelta = playerFaith0;
        npc.recordAction('lifetalk');
        npc.interactionCount++;

        var result = npc.workOnCurrentChallenge();
        // Deep trust: one talk goes two steps.
        if (!result.completed &&
            Relationship.level(npc.sessionBonus) >= Relationship.deepTrustLevel) {
          result = npc.workOnCurrentChallenge();
        }
        if (!result.completed) {
          return NpcInteractionResult(
            reaction: '${challenge.event.glyph}💭',
            playerFaithDelta: playerFaith0,
            playerHealthDelta: -NpcActions.lifeTalkHealthCost,
          );
        }
        final g = (challenge.event.severity.abs() *
                lifeTalkFaithPerSeverity *
                spiritualBonus *
                growth)
            .roundToDouble();
        npc.applyInfluence(g);
        npc.lastNpcFaithDelta = g;
        return NpcInteractionResult(
          reaction: '${challenge.event.glyph}🌱',
          playerFaithDelta: playerFaith0,
          playerHealthDelta: -NpcActions.lifeTalkHealthCost,
          insightDelta: lifeTalkInsightOnCompletion +
              (result.christGrowth ? lifeTalkInsightOnChristGrowth : 0.0) +
              (npc.backstory.fullyResolved ? lifeTalkInsightOnFullyResolved : 0.0),
        );

      case 'pray':
        npc.interactionCount++;
        final faithCost = NpcActions.prayFaithCost(difficulty);
        if (playerFaith < faithCost) return refused('🚫🙏');
        playerFaith0 -= faithCost;
        final varianceMult = InteractionVarianceService.multiplierFor(npc, 'pray');
        npc.recordAction('pray');
        final prayerGain =
            _calc.calculatePrayerGain() * spiritualBonus * varianceMult * growth;
        // 20 % base acceptance, scaling with the NPC's own faith, plus up to
        // +25 % for the relationship invested so far.
        final interactionBonus = (npc.interactionCount * 0.015).clamp(0.0, 0.25);
        final acceptanceChance =
            (npc.faith / 100.0 * 0.6 + 0.2 + interactionBonus).clamp(0.0, 1.0);
        if (_random.nextDouble() < acceptanceChance) {
          final interactionMultiplier =
              (1.0 + npc.interactionCount / 20.0).clamp(1.0, 2.0);
          final boosted = (prayerGain * interactionMultiplier).roundToDouble();
          npc.applyInfluence(boosted);
          npc.lastNpcFaithDelta = boosted;
          playerFaith0 += 3.0;
          npc.lastPlayerFaithDelta = playerFaith0;
          final weakens = npc.possessed && !npc.possessionWeakened;
          if (weakens) npc.possessionWeakened = true;
          return NpcInteractionResult(
            reaction: weakens
                ? '🙏👁️💔'
                : ['❤️🕊️', '🙏💛', '❤️🙌', '🙏❤️'][_random.nextInt(4)],
            playerFaithDelta: playerFaith0,
            cellDelta: _calc.calculatePrayerCellDelta(),
            possessionWeakened: weakens,
          );
        }
        // A life shaped by processed hardship reacts steadier to rejection.
        final penalty = -8.0 * (1.0 - npc.backstory.resilienceDamping);
        npc.applyInfluence(penalty);
        npc.lastNpcFaithDelta = penalty;
        npc.lastPlayerFaithDelta = playerFaith0;
        return NpcInteractionResult(
          reaction: interactionScore < -20 ? '💀😬' : '😠💭',
          playerFaithDelta: playerFaith0,
        );

      case 'bible':
        final g = gain(_calc.calculateBibleGain(), 'bible');
        npc.applyInfluence(g);
        npc.recordAction('bible');
        npc.interactionCount++;
        npc.lastNpcFaithDelta = g;
        playerFaith0 += 2.0;
        npc.lastPlayerFaithDelta = playerFaith0;
        return NpcInteractionResult(
          reaction: ['📖✝️', '📖😊', '📖🙏', '📖💛'][_random.nextInt(4)],
          playerFaithDelta: playerFaith0,
        );

      case 'help':
        if (playerMaterials < NpcActions.helpMaterialsCost) return refused('🚫📦');
        final g = gain(_calc.calculateGiftGain(), 'help');
        npc.interactionCount++;
        npc.hadGiftThisSession = true;
        npc.wantsGift = false;
        npc.applyInfluence(g);
        npc.recordAction('help');
        npc.lastNpcFaithDelta = g;
        playerFaith0 += 5.0;
        npc.lastPlayerFaithDelta = playerFaith0;
        npc.lastMaterialsDelta = -NpcActions.helpMaterialsCost;
        return NpcInteractionResult(
          reaction: ['📦🙏', '😊📦', '🙏😊'][_random.nextInt(3)],
          playerFaithDelta: playerFaith0,
          playerMaterialsDelta: -NpcActions.helpMaterialsCost,
          serviceCompleted: true,
        );

      case 'convert':
        if (npc.isChristian) {
          return NpcInteractionResult(reaction: '✝️🙏', playerFaithDelta: playerFaith0);
        }
        // Succeeds once faith + spiritualState×50 > 50: a liberated cell
        // makes conversion easier.
        if (interactionScore > 50) {
          npc.isConverted = true;
          npc.unlockChristPhaseIfConverted();
          npc.applyInfluence(100);
          npc.lastNpcFaithDelta = 100.0;
          playerFaith0 += 25.0;
          npc.lastPlayerFaithDelta = playerFaith0;
          return NpcInteractionResult(
            reaction: '✝️🕊️',
            playerFaithDelta: playerFaith0,
            insightDelta: conversionInsightReward,
            converted: true,
          );
        }
        // People are annoyed by conversion attempts.
        final penalty = interactionScore < 0 ? -20.0 : -12.0;
        npc.applyInfluence(penalty);
        npc.lastNpcFaithDelta = penalty;
        return NpcInteractionResult(
          reaction: interactionScore < 0 ? '🚫😤' : '🙅💭',
          playerFaithDelta: playerFaith0,
        );
    }

    return NpcInteractionResult(reaction: '❓💭', playerFaithDelta: playerFaith0);
  }

  String _talkEmoji(NPCModel npc) {
    final options = npc.faith > 50
        ? ['😊✝️', '🙌💬', '😄🕊️']
        : npc.faith > 20
            ? ['😊💬', '🙌😊', '💬😄']
            : npc.faith > 0
                ? ['🤔💬', '💭😊', '👀💬']
                : npc.faith > -30
                    ? ['😐💬', '💭🤔', '😒💬']
                    : ['😠💬', '😤🙅', '😡💭'];
    return options[_random.nextInt(options.length)];
  }
}
