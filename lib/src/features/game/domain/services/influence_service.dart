import 'dart:math' as math;

import '../models/city_grid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Influence System (Issues #59 + #118)
//
// This service manages Area-of-Effect spiritual influence events.  Each call
// to [applyAoE] immediately nudges the cell spiritualState values in a
// radius around the origin and – for non-permanent effects – registers a
// timed entry so the effect fades or reverses over time.
//
// Duration types:
//   permanent – applied once, never reversed (e.g. discipleship group).
//   temporary – applied once, instantly reversed when timer expires.
//   decaying  – applied once, linearly reduced back to zero over the duration.
//
// Cell-Glow (Issue #118):
//   Every cell touched by applyAoE gets its glowTimer reset to [glowDuration]
//   and glowStrength set proportional to the applied delta.  ChunkComponent
//   draws a coloured overlay while glowTimer > 0.
// ─────────────────────────────────────────────────────────────────────────────

/// How long (seconds) the visual glow persists on a cell.
const double kCellGlowDuration = 2.0;

/// Duration category for an influence effect.
enum InfluenceDurationType {
  /// Effect is permanent: applied once, never reversed.
  permanent,

  /// Effect is temporary: applied once, instantly reversed after [durationSeconds].
  temporary,

  /// Effect decays linearly over [durationSeconds] back to zero.
  decaying,
}

// ── Internal effect entry ─────────────────────────────────────────────────────

class _ActiveEffect {
  final int originX;
  final int originY;
  final double totalDelta;
  final double radius;
  final InfluenceDurationType durationType;
  final double totalSeconds;
  double remainingSeconds;

  _ActiveEffect({
    required this.originX,
    required this.originY,
    required this.totalDelta,
    required this.radius,
    required this.durationType,
    required this.totalSeconds,
  }) : remainingSeconds = totalSeconds;

  bool get isExpired => remainingSeconds <= 0;
}

// ── Service ──────────────────────────────────────────────────────────────────

/// Manages all active AoE influence effects and their decay over time.
///
/// Wire this into the main game loop by calling [update] every frame.
/// Create effects with [applyAoE].
class InfluenceService {
  final List<_ActiveEffect> _effects = [];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the number of currently tracked (non-permanent) active effects.
  int get activeEffectCount => _effects.length;

  /// Apply an AoE spiritual influence around ([originX], [originY]).
  ///
  /// [delta]            – base spiritual-state delta per cell at the origin
  ///                      (positive = light, negative = dark; scaled by falloff).
  /// [radius]           – influence radius in grid cells.
  /// [durationType]     – how the effect evolves over time.
  /// [durationSeconds]  – lifetime of the effect (ignored for [permanent]).
  /// [buildingMultiplier] – named-constant multiplier from [BuildingInfluenceConstants].
  ///
  /// Cells within radius receive an immediate spiritualState nudge and a
  /// glow trigger.  Non-permanent effects are stored for timed reversal /
  /// decay via [update].
  void applyAoE({
    required CityGrid grid,
    required int originX,
    required int originY,
    required double delta,
    required double radius,
    required InfluenceDurationType durationType,
    double durationSeconds = 0.0,
    double buildingMultiplier = 1.0,
  }) {
    final effectiveDelta = delta * buildingMultiplier;

    _applyToCells(
      grid,
      originX,
      originY,
      effectiveDelta,
      radius,
      triggerGlow: true,
    );

    if (durationType != InfluenceDurationType.permanent &&
        durationSeconds > 0) {
      _effects.add(_ActiveEffect(
        originX: originX,
        originY: originY,
        totalDelta: effectiveDelta,
        radius: radius,
        durationType: durationType,
        totalSeconds: durationSeconds,
      ));
    }
  }

  /// Tick the influence service; call once per game frame.
  ///
  /// Advances all active effect timers.  Expired temporary effects are
  /// reversed; decaying effects receive a proportional negative nudge each
  /// tick.
  void update(double dt, CityGrid grid) {
    _effects.removeWhere((effect) {
      effect.remainingSeconds -= dt;

      if (effect.isExpired) {
        if (effect.durationType == InfluenceDurationType.temporary) {
          // Instantly reverse the full effect when time is up.
          // No glow: the reversal is a silent backend correction, not a
          // player action – triggering a red flash here would be misleading.
          _applyToCells(
            grid,
            effect.originX,
            effect.originY,
            -effect.totalDelta,
            effect.radius,
          );
        }
        return true; // remove expired effects
      }

      if (effect.durationType == InfluenceDurationType.decaying) {
        // Linear decay: remove a proportional slice each frame.
        final decayRate = effect.totalDelta / effect.totalSeconds;
        _applyToCells(
          grid,
          effect.originX,
          effect.originY,
          -decayRate * dt,
          effect.radius,
        );
      }

      return false;
    });
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  /// Apply [delta] to all cells within [radius] of ([cx], [cy]).
  ///
  /// The delta is scaled linearly with distance so the centre receives the
  /// full [delta] and cells at the edge receive ~0.
  ///
  /// When [triggerGlow] is true each affected cell's glow timer is reset.
  void _applyToCells(
    CityGrid grid,
    int cx,
    int cy,
    double delta,
    double radius, {
    bool triggerGlow = false,
  }) {
    final radiusInt = radius.ceil();
    final radiusSq = radius * radius;

    for (int dy = -radiusInt; dy <= radiusInt; dy++) {
      for (int dx = -radiusInt; dx <= radiusInt; dx++) {
        final distSq = (dx * dx + dy * dy).toDouble();
        if (distSq > radiusSq) continue;

        final cell = grid.getCell(cx + dx, cy + dy);
        if (cell == null) continue;

        // Linear falloff: 1.0 at centre → 0.0 at radius edge.
        final falloff = 1.0 - math.sqrt(distSq) / radius;
        final cellDelta = delta * falloff;

        cell.spiritualState =
            (cell.spiritualState + cellDelta).clamp(-1.0, 1.0);

        if (triggerGlow && cellDelta.abs() > 0.001) {
          cell.glowTimer = kCellGlowDuration;
          // Accumulate glow strength; clamp so successive effects don't
          // produce out-of-range values.
          cell.glowStrength = (cell.glowStrength + cellDelta).clamp(-1.0, 1.0);
        }
      }
    }
  }
}
