// NPC life-history simulation ("Lebensphasen").
//
// Design: `docs/game_design/npc_backstory.md` (v3). Every NPC's backstory is
// generated once, deterministically from its id, and never persisted – like
// [NpcNeed] (Issue #171), it is simply recomputed identically every time, so
// no save-schema change is needed.
//
// Core idea: three life phases are resolved *in order* (childhood → youth →
// now). A running `vulnerability` value carries forward between phases, so
// an unprocessed hardship early in life measurably skews later phases toward
// further hardship and away from positive outcomes – a real (if small)
// causal cascade, not independent per-phase dice rolls.

import 'dart:math';
import '../../../../core/utils/stable_hash.dart';

/// The three life phases every NPC's backstory is generated across, in
/// chronological (and generation) order.
enum LifePhase { childhood, youth, now }

/// Broad theme of a life event.  Only [faith] and [money] currently have a
/// concrete gameplay effect (they map onto the same two resources the pastor
/// himself has); the rest exist purely for narrative variety – see
/// `npc_backstory.md` §5 for why NPCs don't mirror all four pastor resources.
enum LifeCategory { faith, money, relationship, loss, health }

/// A single possible life event in the fixed backstory catalog.
///
/// Data only – no authored prose, in keeping with the game's emoji-first
/// presentation style (see `npc_backstory.md` §6/§3). [glyph] is shown
/// together with a short, generic phase/category caption once revealed.
class LifeEvent {
  final String id;
  final LifeCategory category;

  /// -10..+10. Negative = harmful, positive = beneficial. Drives both the
  /// magnitude of the faith/money effect and of the vulnerability/resilience
  /// shift this event causes.
  final int severity;

  final String glyph;

  /// Phases in which this event can occur.
  final Set<LifePhase> phases;

  /// How strongly rising `vulnerability` shifts this event's likelihood.
  ///
  /// Used only to weight *which* event is picked within its own valence pool
  /// (negative events compete only with other negative events for a slot,
  /// same for positive) – see [NpcBackstoryService.generate].
  /// - `0.0` ("nein"): unaffected.
  /// - `0.5` ("leicht") / `1.0` ("ja"): a negative event becomes more likely
  ///   as vulnerability rises.
  /// - `-1.0` ("invers"): a positive event becomes *less* likely as
  ///   vulnerability rises (successful relationships/career harder to reach
  ///   when already burdened).
  final double vulnerabilityFactor;

  const LifeEvent({
    required this.id,
    required this.category,
    required this.severity,
    required this.glyph,
    required this.phases,
    this.vulnerabilityFactor = 0.0,
  });

  bool get isNegative => severity < 0;
}

/// One event that actually occurred in a specific NPC's generated backstory.
class OccurredEvent {
  final LifeEvent event;
  final LifePhase phase;

  /// Whether this (negative) event was worked through. `null` for positive
  /// events, which never need a coping roll.
  final bool? processed;

  const OccurredEvent({
    required this.event,
    required this.phase,
    this.processed,
  });

  /// Short caption shown once revealed, e.g. "Kindheit · Beziehung".
  String get caption => '${_phaseLabel(phase)} · ${_categoryLabel(event.category)}';

  /// Emoji shown once revealed: the event's own glyph, plus a coping glyph
  /// (🌱 processed / 🌫️ unprocessed) for negative events.
  String get displayGlyph {
    if (!event.isNegative) return event.glyph;
    return '${event.glyph}${processed == true ? '🌱' : '🌫️'}';
  }

  static String _phaseLabel(LifePhase phase) => switch (phase) {
        LifePhase.childhood => 'Kindheit',
        LifePhase.youth => 'Jugend',
        LifePhase.now => 'Jetzt',
      };

  static String _categoryLabel(LifeCategory category) => switch (category) {
        LifeCategory.faith => 'Glaube',
        LifeCategory.money => 'Geld',
        LifeCategory.relationship => 'Beziehung',
        LifeCategory.loss => 'Verlust',
        LifeCategory.health => 'Gesundheit',
      };
}

/// The generated result: every event that occurred, plus the two running
/// totals the cascade left behind.
class NpcBackstory {
  final List<OccurredEvent> events;

  /// Accumulated mostly from *unprocessed* negative events. Skews later
  /// event selection toward more hardship, dampened positive outcomes, and
  /// (via [NpcBackstoryService.resilienceDamping] – actually via the
  /// separate [resilience] value) makes the NPC generally more reactive.
  final double vulnerability;

  /// Accumulated from *processed* negative events ("post-traumatic growth").
  /// Dampens negative interaction outcomes generally – see
  /// [resilienceDamping].
  final double resilience;

  const NpcBackstory({
    required this.events,
    required this.vulnerability,
    required this.resilience,
  });

  /// Sum of this NPC's faith-category event severities, scaled – applied as
  /// a one-time offset to the NPC's spawn faith by [NPCRegistry].
  double get faithOffset => _sumSeverity(LifeCategory.faith) * 1.5;

  /// Sum of this NPC's money-category event severities, scaled – a
  /// "generosity" modifier that nudges the *existing* donation-chance rolls
  /// in `BuildingInteractionService`. Deliberately **not** a persistent
  /// materials balance – see `npc_backstory.md` §5.
  double get wealthModifier => _sumSeverity(LifeCategory.money) * 0.02;

  double _sumSeverity(LifeCategory category) => events
      .where((o) => o.event.category == category)
      .fold(0.0, (sum, o) => sum + o.event.severity);

  /// Fraction (0.0–0.5) by which negative interaction penalties should be
  /// softened. Capped so resilience never makes an NPC fully immune.
  double get resilienceDamping => (resilience / 20.0).clamp(0.0, 0.5);
}

/// Fixed catalog of possible life events (`npc_backstory.md` §3). Data only,
/// deliberately small and reviewable – no authored prose, see the class docs
/// on [LifeEvent].
const List<LifeEvent> kLifeEventCatalog = [
  // ── Beziehung ──────────────────────────────────────────────────────────
  LifeEvent(
    id: 'neglect',
    category: LifeCategory.relationship,
    severity: -4,
    glyph: '😠',
    phases: {LifePhase.childhood},
  ),
  LifeEvent(
    id: 'parents_separation',
    category: LifeCategory.relationship,
    severity: -5,
    glyph: '💔',
    phases: {LifePhase.childhood, LifePhase.youth},
  ),
  LifeEvent(
    id: 'failed_relationship',
    category: LifeCategory.relationship,
    severity: -5,
    glyph: '💔',
    phases: {LifePhase.youth, LifePhase.now},
    vulnerabilityFactor: 0.5,
  ),
  LifeEvent(
    id: 'sheltered_childhood',
    category: LifeCategory.relationship,
    severity: 4,
    glyph: '🤱',
    phases: {LifePhase.childhood},
    vulnerabilityFactor: -1.0,
  ),
  LifeEvent(
    id: 'first_love',
    category: LifeCategory.relationship,
    severity: 4,
    glyph: '💞',
    phases: {LifePhase.youth},
    vulnerabilityFactor: -1.0,
  ),
  LifeEvent(
    id: 'happy_relationship',
    category: LifeCategory.relationship,
    severity: 6,
    glyph: '💑',
    phases: {LifePhase.now},
    vulnerabilityFactor: -1.0,
  ),

  // ── Verlust ────────────────────────────────────────────────────────────
  LifeEvent(
    id: 'loss_of_parent',
    category: LifeCategory.loss,
    severity: -7,
    glyph: '⚰️',
    phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now},
  ),
  LifeEvent(
    id: 'violent_loss',
    category: LifeCategory.loss,
    severity: -8,
    glyph: '🕯️',
    phases: {LifePhase.youth, LifePhase.now},
  ),
  LifeEvent(
    id: 'family_illness',
    category: LifeCategory.loss,
    severity: -5,
    glyph: '🏥',
    phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now},
  ),

  // ── Gesundheit (inkl. Sucht/Straffälligkeit) ──────────────────────────
  LifeEvent(
    id: 'minor_health_worries',
    category: LifeCategory.health,
    severity: -2,
    glyph: '🤒',
    phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now},
  ),
  LifeEvent(
    id: 'alcohol_abuse',
    category: LifeCategory.health,
    severity: -6,
    glyph: '🍺',
    phases: {LifePhase.youth, LifePhase.now},
    vulnerabilityFactor: 1.0,
  ),
  LifeEvent(
    id: 'drugs',
    category: LifeCategory.health,
    severity: -8,
    glyph: '💉',
    phases: {LifePhase.youth, LifePhase.now},
    vulnerabilityFactor: 1.0,
  ),
  LifeEvent(
    id: 'imprisonment',
    category: LifeCategory.health,
    severity: -7,
    glyph: '👊',
    phases: {LifePhase.youth, LifePhase.now},
    vulnerabilityFactor: 1.0,
  ),
  LifeEvent(
    id: 'robust_health',
    category: LifeCategory.health,
    severity: 2,
    glyph: '💪',
    phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now},
    vulnerabilityFactor: -1.0,
  ),

  // ── Geld / Beruf ───────────────────────────────────────────────────────
  LifeEvent(
    id: 'unemployment',
    category: LifeCategory.money,
    severity: -4,
    glyph: '📉',
    phases: {LifePhase.youth, LifePhase.now},
    vulnerabilityFactor: 0.5,
  ),
  LifeEvent(
    id: 'debt',
    category: LifeCategory.money,
    severity: -5,
    glyph: '💸',
    phases: {LifePhase.now},
    vulnerabilityFactor: 0.5,
  ),
  LifeEvent(
    id: 'career_success',
    category: LifeCategory.money,
    severity: 5,
    glyph: '💼✨',
    phases: {LifePhase.youth, LifePhase.now},
    vulnerabilityFactor: -1.0,
  ),
  LifeEvent(
    id: 'inheritance',
    category: LifeCategory.money,
    severity: 4,
    glyph: '💰',
    phases: {LifePhase.now},
  ),

  // ── Glaube ─────────────────────────────────────────────────────────────
  LifeEvent(
    id: 'church_disappointment',
    category: LifeCategory.faith,
    severity: -5,
    glyph: '✝️💔',
    phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now},
  ),
  LifeEvent(
    id: 'unanswered_prayer',
    category: LifeCategory.faith,
    severity: -4,
    glyph: '🙏💔',
    phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now},
  ),
  LifeEvent(
    id: 'conversion_experience',
    category: LifeCategory.faith,
    severity: 6,
    glyph: '✝️✨',
    phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now},
  ),
  LifeEvent(
    id: 'answered_prayer',
    category: LifeCategory.faith,
    severity: 5,
    glyph: '🙏✨',
    phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now},
  ),
];

/// Generates a deterministic [NpcBackstory] from an NPC id.
///
/// All balance numbers are illustrative starting values (Issue #83:
/// centralise once a `GameBalance` file exists), kept together here so they
/// are easy to find and tune as one block.
abstract final class NpcBackstoryService {
  /// Chance that *something* from a given category happens in a given phase
  /// at all (before deciding positive/negative).
  static const double categoryEventChance = 0.38;

  /// Base chance (before vulnerability) that an occurring event is negative.
  static const double baseNegativeChance = 0.5;

  /// How much each point of `vulnerability` shifts that chance.
  static const double vulnerabilityToNegativeChance = 0.05;

  /// Base chance a negative event gets processed, by how recent the phase is
  /// – more time to work through childhood than something that just
  /// happened "now".
  static double baseProcessedChance(LifePhase phase) => switch (phase) {
        LifePhase.childhood => 0.65,
        LifePhase.youth => 0.45,
        LifePhase.now => 0.25,
      };

  /// How much already-high vulnerability makes it *harder* to process new
  /// hardship well (a small downward-spiral term).
  static const double vulnerabilityToProcessedPenalty = 0.03;

  static const double processedVulnerabilityGain = 0.15;
  static const double processedResilienceGain = 0.3;
  static const double unprocessedVulnerabilityGain = 0.6;
  static const double positiveVulnerabilityReduction = 0.1;

  /// Generates the backstory for the NPC with the given [npcId].
  ///
  /// Uses a [Random] seeded purely from a hash of [npcId] – deterministic
  /// forever for the same id, and does not touch any shared/chunk RNG
  /// sequence (see `stableStringHash` doc comment), so calling this has no
  /// effect on world generation determinism.
  static NpcBackstory generate(String npcId) {
    final rng = Random(stableStringHash('$npcId#backstory'));
    double vulnerability = 0.0;
    double resilience = 0.0;
    final events = <OccurredEvent>[];

    for (final phase in LifePhase.values) {
      for (final category in LifeCategory.values) {
        final pool = kLifeEventCatalog
            .where((e) => e.category == category && e.phases.contains(phase))
            .toList();
        if (pool.isEmpty) continue;
        if (rng.nextDouble() >= categoryEventChance) continue;

        final negativePool = pool.where((e) => e.isNegative).toList();
        final positivePool = pool.where((e) => !e.isNegative).toList();
        final negativeChance = (baseNegativeChance +
                vulnerability * vulnerabilityToNegativeChance)
            .clamp(0.1, 0.9);
        final wantsNegative = negativePool.isNotEmpty &&
            (positivePool.isEmpty || rng.nextDouble() < negativeChance);
        final chosenPool = wantsNegative ? negativePool : positivePool;
        if (chosenPool.isEmpty) continue;

        final event = _pickWeighted(rng, chosenPool, vulnerability);

        if (event.isNegative) {
          final processedChance = (baseProcessedChance(phase) -
                  vulnerability * vulnerabilityToProcessedPenalty)
              .clamp(0.05, 0.95);
          final processed = rng.nextDouble() < processedChance;
          if (processed) {
            vulnerability += event.severity.abs() * processedVulnerabilityGain;
            resilience += event.severity.abs() * processedResilienceGain;
          } else {
            vulnerability += event.severity.abs() * unprocessedVulnerabilityGain;
          }
          events.add(OccurredEvent(event: event, phase: phase, processed: processed));
        } else {
          vulnerability = (vulnerability -
                  event.severity * positiveVulnerabilityReduction)
              .clamp(0.0, double.infinity);
          events.add(OccurredEvent(event: event, phase: phase));
        }
      }
    }

    return NpcBackstory(events: events, vulnerability: vulnerability, resilience: resilience);
  }

  /// Picks one event from [pool] (all same valence), weighting each by how
  /// much its [LifeEvent.vulnerabilityFactor] responds to the current
  /// [vulnerability] – see the field doc for the direction/meaning.
  static LifeEvent _pickWeighted(
    Random rng,
    List<LifeEvent> pool,
    double vulnerability,
  ) {
    final weights = pool
        .map((e) => (1.0 + vulnerability * e.vulnerabilityFactor).clamp(0.05, 100.0))
        .toList();
    final total = weights.fold(0.0, (a, b) => a + b);
    var r = rng.nextDouble() * total;
    for (int i = 0; i < pool.length; i++) {
      r -= weights[i];
      if (r <= 0) return pool[i];
    }
    return pool.last;
  }
}
