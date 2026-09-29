// NPC life-history simulation ("Lebensphasen").
//
// Design: `docs/game_design/npc_backstory.md` (v4). Every NPC's backstory is
// generated once, deterministically from its id (and never persisted itself
// – like [NpcNeed], Issue #171, it is simply recomputed identically every
// time). What the *player does with it* – working through a specific event
// via ongoing conversation/counseling – is real, persisted progress.
//
// Core ideas:
// - Three chronological phases (childhood → youth → now) are resolved *in
//   order*. A running vulnerability value carries forward between phases,
//   so unprocessed hardship early in life skews later phases toward further
//   hardship and away from positive outcomes.
// - Most generated events are ordinary, mildly-toned life events (school,
//   friendships, a sports club, an ordinary job) – [LifeEvent.baseWeight]
//   makes the dramatic ones (addiction, imprisonment, violent loss)
//   deliberately rare outliers, not the norm.
// - A fourth phase, "Christ", unlocks once the NPC is converted and is
//   generated (once) at that point.
// - Processing a negative event is not decided at generation time. It
//   starts unprocessed and only becomes processed through repeated player
//   attention (see [OccurredEvent.advanceWork]) – "the more you work
//   through it with them, the more resilient they become".

import 'dart:math';
import '../../../../core/utils/stable_hash.dart';

/// The four life phases an NPC's backstory can hold. [christ] only ever
/// appears for a converted NPC, generated once conversion happens (not
/// upfront, since at generation time we don't yet know whether/when the NPC
/// will convert – see [NpcBackstory.ensureChristPhaseFor]).
enum LifePhase { childhood, youth, now, christ }

/// Broad theme of a life event. Only [faith] and [money] currently have a
/// concrete gameplay effect (the same two resources the pastor himself
/// has); the rest exist purely for narrative variety – see
/// `npc_backstory.md` §5 for why NPCs don't mirror all four pastor resources.
enum LifeCategory { faith, money, relationship, loss, health }

/// A single possible life event in the fixed backstory catalog.
///
/// Data only – no authored prose, in keeping with the game's emoji-first
/// presentation style.
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

  /// How strongly rising `vulnerability` shifts this event's likelihood
  /// *within its own valence pool* (negative events only compete with other
  /// negative events for a slot, same for positive).
  /// - `0.0` ("nein"): unaffected.
  /// - `0.5` / `1.0`: a negative event becomes more likely as vulnerability
  ///   rises.
  /// - `-1.0` ("invers"): a positive event becomes *less* likely as
  ///   vulnerability rises.
  final double vulnerabilityFactor;

  /// Base rarity, independent of vulnerability. `1.0` is an ordinary event;
  /// well below `1.0` (down to ~0.1) marks a deliberately rare, dramatic
  /// outlier (addiction, imprisonment, violent loss) so that most NPCs'
  /// revealed pasts read as ordinary lives with a few hard chapters, not a
  /// string of catastrophes.
  final double baseWeight;

  const LifeEvent({
    required this.id,
    required this.category,
    required this.severity,
    required this.glyph,
    required this.phases,
    this.vulnerabilityFactor = 0.0,
    this.baseWeight = 1.0,
  });

  bool get isNegative => severity < 0;
}

/// One event that actually occurred in a specific NPC's generated backstory.
///
/// [processed] and [workProgress] are **mutable and persisted** (unlike
/// everything else about the backstory) – working through a wound is
/// something the player does over time, not a coin flip at generation.
class OccurredEvent {
  final LifeEvent event;
  final LifePhase phase;

  /// How many "work" units (see [advanceWork]) a negative event needs
  /// before it counts as processed.
  static const int workRequired = 3;

  bool processed;
  int workProgress;

  OccurredEvent({
    required this.event,
    required this.phase,
    this.processed = false,
    this.workProgress = 0,
  });

  /// Whether this event can be worked on at all (only negative, unprocessed
  /// events can be).
  bool get isWorkable => event.isNegative && !processed;

  /// Spends one unit of player attention (a Seelsorge/conversation session
  /// spent specifically on this event) working through it. Returns `true`
  /// if this call completed the processing (crossed [workRequired]).
  bool advanceWork() {
    if (!isWorkable) return false;
    workProgress = (workProgress + 1).clamp(0, workRequired);
    if (workProgress >= workRequired) {
      processed = true;
    }
    return processed;
  }

  /// Short caption shown once revealed, e.g. "Kindheit · Beziehung".
  String get caption => '${_phaseLabel(phase)} · ${_categoryLabel(event.category)}';

  /// Emoji shown once revealed: the event's own glyph, plus a coping glyph
  /// for negative events (🌱 processed / 🌫️ still being worked through).
  String get displayGlyph {
    if (!event.isNegative) return event.glyph;
    return '${event.glyph}${processed ? '🌱' : '🌫️'}';
  }

  static String _phaseLabel(LifePhase phase) => switch (phase) {
        LifePhase.childhood => 'Kindheit',
        LifePhase.youth => 'Jugend',
        LifePhase.now => 'Jetzt',
        LifePhase.christ => 'Als Christ',
      };

  static String _categoryLabel(LifeCategory category) => switch (category) {
        LifeCategory.faith => 'Glaube',
        LifeCategory.money => 'Geld',
        LifeCategory.relationship => 'Beziehung',
        LifeCategory.loss => 'Verlust',
        LifeCategory.health => 'Gesundheit',
      };
}

/// The generated (and, for the Christ phase, later-extended) result: every
/// event that occurred, plus live-computed vulnerability/resilience that
/// reflect the *current* processed-state of those events – not a frozen
/// generation-time snapshot.
class NpcBackstory {
  /// Growable: the childhood/youth/now events are fixed at generation, but
  /// [ensureChristPhaseFor] appends more once the NPC converts.
  final List<OccurredEvent> events;

  bool _christPhaseGenerated = false;

  NpcBackstory({required this.events});

  /// Accumulated from currently-*unprocessed* negative events (full weight)
  /// and currently-*processed* ones (much reduced weight), minus a small
  /// pull-down from positive events. Recomputed live, so it falls as the
  /// player works through more of this NPC's past.
  double get vulnerability {
    double v = 0.0;
    for (final o in events) {
      if (o.event.isNegative) {
        final rate = o.processed
            ? NpcBackstoryService.processedVulnerabilityGain
            : NpcBackstoryService.unprocessedVulnerabilityGain;
        v += o.event.severity.abs() * rate;
      } else {
        v = (v - o.event.severity * NpcBackstoryService.positiveVulnerabilityReduction)
            .clamp(0.0, double.infinity);
      }
    }
    return v;
  }

  /// Accumulated from *processed* negative events only ("post-traumatic
  /// growth") – grows as the player works through this NPC's past.
  double get resilience {
    double r = 0.0;
    for (final o in events) {
      if (o.event.isNegative && o.processed) {
        r += o.event.severity.abs() * NpcBackstoryService.processedResilienceGain;
      }
    }
    return r;
  }

  /// Sum of this NPC's faith-category event severities, scaled – applied as
  /// a one-time offset to the NPC's spawn faith by [NPCRegistry]. Fixed
  /// (severities don't change when an event is processed), so it is safe to
  /// apply only once at spawn.
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

  /// Generates and appends this NPC's "Als Christ" chapter, once, the first
  /// time it's called after conversion. Safe to call unconditionally on
  /// every load/interaction – idempotent, and a no-op before conversion.
  void ensureChristPhaseFor(String npcId, {required bool isConverted}) {
    if (!isConverted || _christPhaseGenerated) return;
    _christPhaseGenerated = true;
    events.addAll(NpcBackstoryService.generateChristPhase(npcId));
  }

  // ── Persistence of player-driven processing progress ─────────────────────
  //
  // Everything else about the backstory is derived from the NPC id and
  // therefore never persisted. Only *processing progress* is real, mutable
  // game state (Issue: interactive "bearbeiten"), saved sparsely – only
  // events with any progress at all are written.

  /// `{ eventId: workProgress }` for every event with non-zero progress.
  Map<String, int> captureProgress() => {
        for (final o in events)
          if (o.workProgress > 0) o.event.id: o.workProgress,
      };

  /// Restores progress captured by [captureProgress] onto the (freshly
  /// regenerated, deterministic) event list. Matches by the catalog event
  /// id, not list position, so it stays robust if the catalog is retuned
  /// later. Unmatched ids (e.g. from a since-removed event) are ignored.
  void restoreProgress(Map<String, dynamic> saved) {
    for (final o in events) {
      final p = (saved[o.event.id] as num?)?.toInt();
      if (p == null) continue;
      o.workProgress = p.clamp(0, OccurredEvent.workRequired);
      o.processed = o.workProgress >= OccurredEvent.workRequired;
    }
  }
}

/// Fixed catalog of possible life events (`npc_backstory.md` §3/§9). Data
/// only, deliberately small and reviewable – no authored prose. The large
/// majority are ordinary, mildly-toned events; dramatic ones are marked
/// with a low [LifeEvent.baseWeight] so they stay rare outliers.
const List<LifeEvent> kLifeEventCatalog = [
  // ── Beziehung: gewöhnlicher Alltag (häufig) ───────────────────────────
  LifeEvent(id: 'best_friends_childhood', category: LifeCategory.relationship, severity: 2, glyph: '🧑‍🤝‍🧑', phases: {LifePhase.childhood}, baseWeight: 2.0),
  LifeEvent(id: 'playground_fun', category: LifeCategory.relationship, severity: 1, glyph: '🛝', phases: {LifePhase.childhood}, baseWeight: 2.0),
  LifeEvent(id: 'sports_club', category: LifeCategory.relationship, severity: 2, glyph: '⚽', phases: {LifePhase.childhood, LifePhase.youth}, baseWeight: 1.8),
  LifeEvent(id: 'minor_sibling_rivalry', category: LifeCategory.relationship, severity: -1, glyph: '😤', phases: {LifePhase.childhood}, baseWeight: 1.5),
  LifeEvent(id: 'first_crush', category: LifeCategory.relationship, severity: 2, glyph: '😊💕', phases: {LifePhase.youth}, baseWeight: 1.8),
  LifeEvent(id: 'circle_of_friends', category: LifeCategory.relationship, severity: 2, glyph: '👯', phases: {LifePhase.youth}, baseWeight: 1.8),
  LifeEvent(id: 'small_argument_with_friends', category: LifeCategory.relationship, severity: -1, glyph: '🙄', phases: {LifePhase.childhood, LifePhase.youth}, baseWeight: 1.5),
  LifeEvent(id: 'steady_friendships_now', category: LifeCategory.relationship, severity: 2, glyph: '🤝', phases: {LifePhase.now}, baseWeight: 2.0),
  LifeEvent(id: 'occasional_loneliness', category: LifeCategory.relationship, severity: -2, glyph: '🥀', phases: {LifePhase.now}, baseWeight: 1.5),
  // ── Beziehung: seltener, schwerer ─────────────────────────────────────
  LifeEvent(id: 'neglect', category: LifeCategory.relationship, severity: -4, glyph: '😠', phases: {LifePhase.childhood}, baseWeight: 0.5),
  LifeEvent(id: 'parents_separation', category: LifeCategory.relationship, severity: -5, glyph: '💔', phases: {LifePhase.childhood, LifePhase.youth}, baseWeight: 0.4),
  LifeEvent(id: 'failed_relationship', category: LifeCategory.relationship, severity: -5, glyph: '💔', phases: {LifePhase.youth, LifePhase.now}, baseWeight: 0.6, vulnerabilityFactor: 0.5),
  LifeEvent(id: 'sheltered_childhood', category: LifeCategory.relationship, severity: 4, glyph: '🤱', phases: {LifePhase.childhood}, baseWeight: 1.2, vulnerabilityFactor: -1.0),
  LifeEvent(id: 'first_love', category: LifeCategory.relationship, severity: 4, glyph: '💞', phases: {LifePhase.youth}, baseWeight: 1.5, vulnerabilityFactor: -1.0),
  LifeEvent(id: 'happy_relationship', category: LifeCategory.relationship, severity: 6, glyph: '💑', phases: {LifePhase.now}, baseWeight: 0.8, vulnerabilityFactor: -1.0),

  // ── Verlust: gewöhnlicher (häufiger, aber immer noch ein Verlust) ─────
  LifeEvent(id: 'lost_pet', category: LifeCategory.loss, severity: -2, glyph: '🐾', phases: {LifePhase.childhood, LifePhase.youth}, baseWeight: 1.8),
  LifeEvent(id: 'moved_away_lost_friends', category: LifeCategory.loss, severity: -2, glyph: '📦', phases: {LifePhase.childhood, LifePhase.youth}, baseWeight: 1.5),
  LifeEvent(id: 'family_illness', category: LifeCategory.loss, severity: -4, glyph: '🏥', phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now}, baseWeight: 1.0),
  // ── Verlust: selten, schwer ────────────────────────────────────────────
  LifeEvent(id: 'loss_of_parent', category: LifeCategory.loss, severity: -7, glyph: '⚰️', phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now}, baseWeight: 0.3),
  LifeEvent(id: 'violent_loss', category: LifeCategory.loss, severity: -8, glyph: '🕯️', phases: {LifePhase.youth, LifePhase.now}, baseWeight: 0.05),

  // ── Gesundheit: gewöhnlicher (häufig) ──────────────────────────────────
  LifeEvent(id: 'normal_childhood_illness', category: LifeCategory.health, severity: -1, glyph: '🤧', phases: {LifePhase.childhood}, baseWeight: 2.0),
  LifeEvent(id: 'active_and_fit', category: LifeCategory.health, severity: 2, glyph: '🏃', phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now}, baseWeight: 2.0),
  LifeEvent(id: 'robust_health', category: LifeCategory.health, severity: 2, glyph: '💪', phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now}, baseWeight: 1.5, vulnerabilityFactor: -1.0),
  LifeEvent(id: 'minor_health_worries', category: LifeCategory.health, severity: -2, glyph: '🤒', phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now}, baseWeight: 1.5),
  // ── Gesundheit: selten, schwer (Sucht/Straffälligkeit) ────────────────
  LifeEvent(id: 'alcohol_abuse', category: LifeCategory.health, severity: -6, glyph: '🍺', phases: {LifePhase.youth, LifePhase.now}, baseWeight: 0.06, vulnerabilityFactor: 1.0),
  LifeEvent(id: 'drugs', category: LifeCategory.health, severity: -8, glyph: '💉', phases: {LifePhase.youth, LifePhase.now}, baseWeight: 0.03, vulnerabilityFactor: 1.0),
  LifeEvent(id: 'imprisonment', category: LifeCategory.health, severity: -7, glyph: '👊', phases: {LifePhase.youth, LifePhase.now}, baseWeight: 0.03, vulnerabilityFactor: 1.0),

  // ── Geld / Beruf: gewöhnlicher (häufig) ────────────────────────────────
  LifeEvent(id: 'pocket_money', category: LifeCategory.money, severity: 1, glyph: '🪙', phases: {LifePhase.childhood}, baseWeight: 2.0),
  LifeEvent(id: 'finished_school_ok', category: LifeCategory.money, severity: 2, glyph: '🎓', phases: {LifePhase.youth}, baseWeight: 2.0),
  LifeEvent(id: 'enjoyed_school_days', category: LifeCategory.relationship, severity: 2, glyph: '🏫', phases: {LifePhase.youth}, baseWeight: 1.8),
  LifeEvent(id: 'normal_job', category: LifeCategory.money, severity: 2, glyph: '👔', phases: {LifePhase.now}, baseWeight: 2.0),
  LifeEvent(id: 'had_to_budget', category: LifeCategory.money, severity: -1, glyph: '💶', phases: {LifePhase.youth, LifePhase.now}, baseWeight: 1.8),
  // ── Geld: seltener, schwerer ────────────────────────────────────────────
  LifeEvent(id: 'unemployment', category: LifeCategory.money, severity: -4, glyph: '📉', phases: {LifePhase.youth, LifePhase.now}, baseWeight: 0.6, vulnerabilityFactor: 0.5),
  LifeEvent(id: 'debt', category: LifeCategory.money, severity: -5, glyph: '💸', phases: {LifePhase.now}, baseWeight: 0.5, vulnerabilityFactor: 0.5),
  LifeEvent(id: 'career_success', category: LifeCategory.money, severity: 5, glyph: '💼✨', phases: {LifePhase.youth, LifePhase.now}, baseWeight: 0.8, vulnerabilityFactor: -1.0),
  LifeEvent(id: 'inheritance', category: LifeCategory.money, severity: 4, glyph: '💰', phases: {LifePhase.now}, baseWeight: 0.6),

  // ── Glaube: gewöhnlicher (häufig) ───────────────────────────────────────
  LifeEvent(id: 'sunday_school', category: LifeCategory.faith, severity: 2, glyph: '⛪🧒', phases: {LifePhase.childhood}, baseWeight: 1.8),
  LifeEvent(id: 'said_grace_at_home', category: LifeCategory.faith, severity: 1, glyph: '🙏🏠', phases: {LifePhase.childhood}, baseWeight: 1.8),
  LifeEvent(id: 'questioned_faith_as_teen', category: LifeCategory.faith, severity: -1, glyph: '🤔', phases: {LifePhase.youth}, baseWeight: 1.8),
  // ── Glaube: seltener, prägender ──────────────────────────────────────
  LifeEvent(id: 'church_disappointment', category: LifeCategory.faith, severity: -5, glyph: '✝️💔', phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now}, baseWeight: 0.5),
  LifeEvent(id: 'unanswered_prayer', category: LifeCategory.faith, severity: -4, glyph: '🙏💔', phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now}, baseWeight: 0.8),
  LifeEvent(id: 'conversion_experience', category: LifeCategory.faith, severity: 6, glyph: '✝️✨', phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now}, baseWeight: 0.5),
  LifeEvent(id: 'answered_prayer', category: LifeCategory.faith, severity: 5, glyph: '🙏✨', phases: {LifePhase.childhood, LifePhase.youth, LifePhase.now}, baseWeight: 0.6),
];

/// Separate, smaller catalog for the "Als Christ" phase – only ever
/// generated once an NPC converts (see [NpcBackstory.ensureChristPhaseFor]).
/// Predominantly positive (growth after conversion), with a couple of
/// realistic, mild setbacks so it doesn't read as saccharine.
const List<LifeEvent> kChristPhaseCatalog = [
  LifeEvent(id: 'first_bible_study', category: LifeCategory.faith, severity: 2, glyph: '📖', phases: {LifePhase.christ}, baseWeight: 2.0),
  LifeEvent(id: 'new_church_friends', category: LifeCategory.relationship, severity: 3, glyph: '🤝✝️', phases: {LifePhase.christ}, baseWeight: 2.0),
  LifeEvent(id: 'baptism', category: LifeCategory.faith, severity: 4, glyph: '💧✝️', phases: {LifePhase.christ}, baseWeight: 1.2),
  LifeEvent(id: 'shared_faith_with_someone', category: LifeCategory.faith, severity: 3, glyph: '🗣️✝️', phases: {LifePhase.christ}, baseWeight: 1.5),
  LifeEvent(id: 'grown_through_setback', category: LifeCategory.faith, severity: 3, glyph: '🌱✝️', phases: {LifePhase.christ}, baseWeight: 1.2),
  LifeEvent(id: 'doubted_if_it_was_real', category: LifeCategory.faith, severity: -2, glyph: '🤔✝️', phases: {LifePhase.christ}, baseWeight: 1.5),
  LifeEvent(id: 'small_group_conflict', category: LifeCategory.relationship, severity: -2, glyph: '😕⛪', phases: {LifePhase.christ}, baseWeight: 1.3),
];

/// Generates a deterministic [NpcBackstory] from an NPC id.
///
/// All balance numbers are illustrative starting values (Issue #83:
/// centralise once a `GameBalance` file exists), kept together here so they
/// are easy to find and tune as one block.
abstract final class NpcBackstoryService {
  /// Chance that *something* from a given category happens in a given phase
  /// at all (before deciding positive/negative). Raised from the original
  /// 0.38 so most phase×category slots produce *some* ordinary event – "jede
  /// Altersphase sollte Geschichten erzählen".
  static const double categoryEventChance = 0.55;

  /// Base chance (before vulnerability) that an occurring event is negative.
  static const double baseNegativeChance = 0.5;

  /// How much each point of `vulnerability` shifts that chance.
  static const double vulnerabilityToNegativeChance = 0.05;

  /// How much a still-*unprocessed* negative event's severity contributes to
  /// `vulnerability` per point – used both during generation (to drive the
  /// phase-to-phase cascade, since nothing is processed yet at that point)
  /// and live thereafter, for as long as the event stays unprocessed.
  static const double unprocessedVulnerabilityGain = 0.6;

  /// Same, once the player has worked an event through to processed – much
  /// smaller, and feeds [NpcBackstory.resilience] instead.
  static const double processedVulnerabilityGain = 0.15;
  static const double processedResilienceGain = 0.3;

  /// How much a positive event's severity reduces `vulnerability`.
  static const double positiveVulnerabilityReduction = 0.1;

  /// If every category roll in a phase happened to miss, force one ordinary
  /// event so no phase ever comes up completely empty.
  static const int minEventsPerPhase = 1;

  static final List<LifePhase> _chronologicalPhases = [
    LifePhase.childhood,
    LifePhase.youth,
    LifePhase.now,
  ];

  /// Generates the childhood/youth/now backstory for the NPC with the given
  /// [npcId]. The "Christ" phase is deliberately not included here – see
  /// [generateChristPhase].
  ///
  /// Uses a [Random] seeded purely from a hash of [npcId] – deterministic
  /// forever for the same id, and does not touch any shared/chunk RNG
  /// sequence, so calling this has no effect on world-generation
  /// determinism.
  static NpcBackstory generate(String npcId) {
    final rng = Random(stableStringHash('$npcId#backstory'));
    double vulnerability = 0.0;
    final events = <OccurredEvent>[];

    for (final phase in _chronologicalPhases) {
      final beforeCount = events.length;
      for (final category in LifeCategory.values) {
        final pool = kLifeEventCatalog
            .where((e) => e.category == category && e.phases.contains(phase))
            .toList();
        if (pool.isEmpty) continue;
        if (rng.nextDouble() >= categoryEventChance) continue;

        final chosen = _rollOne(rng, pool, vulnerability);
        if (chosen == null) continue;
        vulnerability = _apply(events, chosen, phase, vulnerability);
      }

      // Guarantee: no phase stays completely empty.
      if (events.length - beforeCount < minEventsPerPhase) {
        final fallbackPool = kLifeEventCatalog
            .where((e) => e.phases.contains(phase) && !e.isNegative)
            .toList();
        if (fallbackPool.isNotEmpty) {
          final chosen = _pickWeighted(rng, fallbackPool, 0.0);
          vulnerability = _apply(events, chosen, phase, vulnerability);
        }
      }
    }

    return NpcBackstory(events: events);
  }

  /// Generates the (small, mostly positive) "Als Christ" chapter for
  /// [npcId] – a separate deterministic sequence so it doesn't consume any
  /// of the childhood/youth/now generation's randomness.
  static List<OccurredEvent> generateChristPhase(String npcId) {
    final rng = Random(stableStringHash('$npcId#backstory#christ'));
    double vulnerability = 0.0;
    final events = <OccurredEvent>[];
    for (int i = 0; i < 3; i++) {
      if (rng.nextDouble() >= categoryEventChance && events.isNotEmpty) continue;
      final chosen = _pickWeighted(rng, kChristPhaseCatalog, vulnerability);
      vulnerability = _apply(events, chosen, LifePhase.christ, vulnerability);
    }
    return events;
  }

  /// Picks a valence (negative vs. positive) weighted by [vulnerability],
  /// then one event from that pool – or `null` if the winning valence has no
  /// events available in this phase/category.
  static LifeEvent? _rollOne(Random rng, List<LifeEvent> pool, double vulnerability) {
    final negativePool = pool.where((e) => e.isNegative).toList();
    final positivePool = pool.where((e) => !e.isNegative).toList();
    final negativeChance =
        (baseNegativeChance + vulnerability * vulnerabilityToNegativeChance).clamp(0.1, 0.9);
    final wantsNegative =
        negativePool.isNotEmpty && (positivePool.isEmpty || rng.nextDouble() < negativeChance);
    final chosenPool = wantsNegative ? negativePool : positivePool;
    if (chosenPool.isEmpty) return null;
    return _pickWeighted(rng, chosenPool, vulnerability);
  }

  /// Records [event] as occurred and returns the updated running
  /// vulnerability. Negative events always start unprocessed (processing is
  /// exclusively a later, player-driven action – see [OccurredEvent]).
  static double _apply(
    List<OccurredEvent> events,
    LifeEvent event,
    LifePhase phase,
    double vulnerability,
  ) {
    events.add(OccurredEvent(event: event, phase: phase));
    if (event.isNegative) {
      return vulnerability + event.severity.abs() * unprocessedVulnerabilityGain;
    }
    return (vulnerability - event.severity * positiveVulnerabilityReduction)
        .clamp(0.0, double.infinity);
  }

  /// Picks one event from [pool] (all same valence), weighting each by its
  /// [LifeEvent.baseWeight] and by how much its [LifeEvent.vulnerabilityFactor]
  /// responds to the current [vulnerability].
  static LifeEvent _pickWeighted(
    Random rng,
    List<LifeEvent> pool,
    double vulnerability,
  ) {
    final weights = pool
        .map((e) => (e.baseWeight * (1.0 + vulnerability * e.vulnerabilityFactor))
            .clamp(0.02, 100.0))
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
