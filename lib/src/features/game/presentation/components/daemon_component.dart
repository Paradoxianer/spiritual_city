import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../domain/models/daemon_model.dart';
import '../../domain/models/city_cell.dart';
import '../../../menu/domain/models/difficulty.dart';
import '../../domain/services/faith_calculator_service.dart';
import '../../domain/models/prayer_combat.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';

/// Visual and logic component for a Daemon NPC in the invisible world.
///
/// Movement is a pure pixel-space orbit around the player – like a vulture
/// circling its prey.  The radius shrinks continuously so the player is
/// gradually encircled.  Prayer accelerates the inward spiral.
///
/// The daemon leaves a visible slime trail by draining the `spiritualState`
/// of the cell it occupies every frame (proportional to `dt`).  Energy
/// management is decoupled onto its own 2-second tick.
///
/// Lastenheft Issue #31
class DaemonComponent extends PositionComponent
    with HasGameReference<SpiritWorldGame> {
  final DaemonModel model;

  static const double _baseDaemonSize = 18.0;

  double _cellDrainMultiplier = 1.0;
  double _strengthFactor = 1.0;

  // Active effect tracking (Issue #9)
  final Map<PrayerMode, double> _activeEffects = {};
  double _knockbackVelocity = 0.0;

  // ── Pure orbital movement ─────────────────────────────────────────────────

  /// Angular velocity (rad/s) – controls how fast the daemon circles the player.
  double _angularSpeed = 1.2;

  static const double _angularSpeedEasy = 0.8; // ~7.9 s / full orbit
  static const double _angularSpeedNormal = 1.2; // ~5.2 s / full orbit
  static const double _angularSpeedHard = 1.8; // ~3.5 s / full orbit

  double _orbitAngle = 0.0;
  double _orbitRadius = 260.0;

  /// Orbit radius at which the daemon strikes the player on contact.
  static const double _orbitRadiusMin = 50.0;

  /// How fast the orbit shrinks per second (continuous inward spiral).
  static const double _spiralSpeedNormal = 4.0; // px/s
  static const double _spiralSpeedPrayer = 22.0; // px/s – faster during prayer

  // ── Slime trail ───────────────────────────────────────────────────────────

  /// Darkness drained from the current cell per second.  Applied every frame
  /// via `dt` so the trail is pixel-accurate and clearly visible.
  static const double _slimeDrainRate = 0.30;

  // ── Energy tick ───────────────────────────────────────────────────────────

  double _energyTimer = 0.0;
  static const double _energyInterval = 2.0;

  // ── Hit flicker ───────────────────────────────────────────────────────────

  double _hitFlickerTimer = 0.0;
  static const double _hitFlickerDuration = 0.3;

  // ── Cached paint objects (never allocate Paint() in render()) ────────────

  /// Aura paint – colour is updated each render() call; maskFilter set once.
  late final Paint _auraPaint;
  final Paint _corePaint = Paint();
  final Paint _arcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  // Pre-computed static colours that don't change (allocated once).
  static final Color _auraFlicker = Colors.white.withValues(alpha: 0.8);
  static final Color _coreFlicker = Colors.white.withValues(alpha: 0.9);
  static final Color _coreNormal = Colors.red[800]!.withValues(alpha: 0.9);
  static final Color _arcColor = Colors.deepOrange.withValues(alpha: 0.7);
  // Lerp endpoints pre-allocated so Color.lerp() doesn't box them each frame.
  static final Color _auraLerpFrom = Colors.red[900]!.withValues(alpha: 0.6);
  static final Color _auraLerpTo = Colors.black.withValues(alpha: 0.9);

  DaemonComponent(this.model)
      : super(
          position: model.position.clone(),
          size: Vector2.all(_baseDaemonSize),
          anchor: Anchor.center,
          priority: 95,
        );

  @override
  Future<void> onLoad() async {
    _angularSpeed = switch (game.difficulty) {
      Difficulty.easy => _angularSpeedEasy,
      Difficulty.normal => _angularSpeedNormal,
      Difficulty.hard => _angularSpeedHard,
    };
    _cellDrainMultiplier =
        1.0 / FaithCalculatorService.difficultyFactorFor(game.difficulty);
    _strengthFactor = (model.initialEnergy.abs() / 260.0).clamp(0.8, 2.1);
    size = Vector2.all(_baseDaemonSize * _strengthFactor);

    // Initialise paint that requires a const expression (can't be done in field).
    _auraPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    // Arc color never changes.
    _arcPaint.color = _arcColor;

    // Give each daemon a unique starting angle and radius so they spread out.
    final rng = math.Random(model.id.hashCode);
    _orbitAngle = rng.nextDouble() * math.pi * 2;
    _orbitRadius = 180.0 + rng.nextDouble() * 180.0; // 180–360 px
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!game.isSpiritualWorld) return;
    if (model.dissolved) {
      removeFromParent();
      return;
    }

    if (_hitFlickerTimer > 0) _hitFlickerTimer -= dt;

    // ── Update active effects (Issue #9) ──────────────────────────────────────
    _activeEffects.removeWhere((mode, remaining) => remaining <= 0);
    _activeEffects.updateAll((mode, remaining) => remaining - dt);

    // ── Advance orbit angle every frame ───────────────────────────────────────
    double effectiveAngularSpeed = _angularSpeed;
    if (_activeEffects.containsKey(PrayerMode.slow)) {
      effectiveAngularSpeed *= 0.25; // Slow down movement
    }
    _orbitAngle += effectiveAngularSpeed * dt;

    // ── Shrink orbit radius (faster during prayer) ────────────────────────────
    double spiralSpeed = game.spiritualDynamics.isPrayerAttractionActive
        ? _spiralSpeedPrayer
        : _spiralSpeedNormal;

    if (_activeEffects.containsKey(PrayerMode.slow)) {
      spiralSpeed *= 0.30; // Shrink much slower
    }

    // Persistent Rebuke resistance (Option 2)
    if (_activeEffects.containsKey(PrayerMode.rebuke)) {
      // Base resistance + strength bonus. Higher faith/strength = stronger push
      final resistance = 24.0 + (game.faith / 4.0);
      spiralSpeed -= resistance; // Reduces or reverses the approach speed
    }

    // Apply and decay knockback impulse (The "Impact")
    final knockbackStep = _knockbackVelocity * dt;
    _knockbackVelocity *= math.pow(0.01, dt); // Very fast decay (0.2s)
    if (_knockbackVelocity < 1.0) _knockbackVelocity = 0;

    final newRadius = (_orbitRadius - spiralSpeed * dt) + knockbackStep;

    // ── Contact strike: daemon reached the player ─────────────────────────────
    if (newRadius <= _orbitRadiusMin) {
      _strikePlayer();
      return; // component is removed inside _strikePlayer
    }
    _orbitRadius = newRadius;

    // ── Position = exact orbit point around the player ────────────────────────
    final p = game.player.position;
    position.setValues(
      p.x + math.cos(_orbitAngle) * _orbitRadius,
      p.y + math.sin(_orbitAngle) * _orbitRadius,
    );
    model.position.setFrom(position);

    // ── Slime trail: drain current cell every frame ───────────────────────────
    _drainCurrentCell(dt);

    // ── Energy tick ───────────────────────────────────────────────────────────
    _energyTimer += dt;
    if (_energyTimer >= _energyInterval) {
      _energyTimer = 0.0;
      _tickEnergy();
    }
  }

  // ── Slime trail ────────────────────────────────────────────────────────────

  /// Drains the cell the daemon currently occupies by `_slimeDrainRate × dt`.
  /// This is called every frame, producing a clearly visible dark trail.
  void _drainCurrentCell(double dt) {
    // Liberation effect stops the daemon from draining the ground (Issue #9)
    if (_activeEffects.containsKey(PrayerMode.liberation)) return;

    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();
    final cell = game.grid.getCell(gx, gy);
    if (cell == null) return;
    cell.spiritualState = (cell.spiritualState -
            _slimeDrainRate * _cellDrainMultiplier * _strengthFactor * dt)
        .clamp(-1.0, 1.0);
  }

  // ── Energy tick ────────────────────────────────────────────────────────────

  /// Drains the daemon's energy every [_energyInterval] seconds based on the
  /// spiritual state of the cell it currently occupies.
  void _tickEnergy() {
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();
    final cell = game.grid.getCell(gx, gy);
    if (cell == null) return;

    final double energyDrain;
    if (cell.spiritualState < -0.5) {
      energyDrain = 1.0; // dark territory – daemon barely costs energy
    } else if (cell.spiritualState.abs() < 0.3) {
      energyDrain = 2.0; // neutral
    } else {
      energyDrain = 6.0; // positive territory – daemon weakened fast
    }

    model.energy += energyDrain;
    if (model.energy >= 0) _dissolve(cell);
  }

  // ── Combat ─────────────────────────────────────────────────────────────────

  /// Called by the prayer combat system when this daemon is within range.
  void takeDamage(double amount, {PrayerMode? mode, double duration = 0}) {
    if (model.dissolved) return;
    _hitFlickerTimer = _hitFlickerDuration;

    // Apply effect if provided
    if (mode != null && duration > 0) {
      _activeEffects[mode] = duration;
      if (mode == PrayerMode.rebuke) {
        // Initial physical "push" velocity (The "Impact")
        // Scaled by weight (heavier daemons are harder to push)
        final weight = (model.initialEnergy.abs() / 50.0).clamp(1.0, 5.0);
        final impulse = (180.0 + (game.faith * 0.8)) / weight;
        _knockbackVelocity = impulse;
      }
    }

    double finalDamage = amount;

    // Drain effect makes the daemon take much more damage
    if (_activeEffects.containsKey(PrayerMode.drain)) {
      finalDamage *= 2.5;
    }

    // Liberation damage is standard, but specialized for cleansing
    if (mode == PrayerMode.liberation) {
      finalDamage *= 1.2;
    }

    // CC modes (Rebuke, Slow) deal extremely little damage as their focus is utility
    if (mode == PrayerMode.rebuke || mode == PrayerMode.slow) {
      finalDamage *= 0.05;
    }

    model.energy += finalDamage;
    if (model.energy >= 0) {
      if (mode == PrayerMode.drain) {
        _absorb();
      } else {
        _explode();
      }
    }
  }

  /// Daemon killed by Liberation: cleanses a 3-cell radius around the death point.
  void _explode() {
    model.dissolved = true;
    const int radius = 3;
    final gx = (position.x / CellComponent.cellSize).floor();
    final gy = (position.y / CellComponent.cellSize).floor();

    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        final d = math.sqrt(dx * dx + dy * dy);
        if (d > radius) continue;
        final cell = game.grid.getCell(gx + dx, gy + dy);
        if (cell != null) {
          final falloff = 1.0 - (d / radius).clamp(0.0, 1.0);
          cell.spiritualState =
              (cell.spiritualState + 0.4 * falloff).clamp(-1.0, 1.0);
        }
      }
    }
    removeFromParent();
  }

  /// Daemon killed by Drain: Pastor absorbs energy, no explosion.
  void _absorb() {
    model.dissolved = true;
    // Energy transfer: Pastor gains only a small amount of Faith.
    final faithGain = (model.initialEnergy.abs() / 70.0).clamp(2.0, 6.0);
    game.gainFaith(faithGain);
    removeFromParent();
  }

  /// Natural dissolution: daemon's energy ran out; leaves a residuum marker.
  void _dissolve(CityCell cell) {
    model.dissolved = true;
    cell.spiritualState = (cell.spiritualState - 0.05).clamp(-1.0, 1.0);
    cell.hasResiduum = true;
    removeFromParent();
  }

  /// Contact strike: daemon spiralled all the way to the player without being
  /// destroyed by prayer.  Damages the player and paints the surrounding area
  /// dark red.
  ///
  /// Damage is scaled by the fraction of energy remaining (0.0–1.0), so a
  /// daemon that has been weakened by positive territory deals less damage.
  /// All three player stats are affected: ❤️ HP, 🙏 faith, 🍞 hunger.
  void _strikePlayer() {
    model.dissolved = true;

    // Strength fraction: 1.0 = full energy, 0.0 = almost dissolved.
    final strength =
        (model.energy.abs() / model.initialEnergy.abs()).clamp(0.0, 1.0);

    // Difficulty amplifier: hard daemons hit harder.
    final amp = _cellDrainMultiplier; // easy=0.67, normal=1.0, hard=2.0

    final hpDamage = (8.0 * strength * amp).clamp(1.0, 30.0);
    final faithDamage = (10.0 * strength * amp).clamp(1.0, 40.0) *
        (1.0 - game.progress.combatProfile.shieldDamageReduction);
    final hungerDamage = (12.0 * strength * amp).clamp(1.0, 50.0) *
        (1.0 - game.progress.combatProfile.helmHungerReduction);

    game.spendHealth(hpDamage);
    game.spendFaith(faithDamage);
    game.spendHunger(hungerDamage);

    // Paint a 4-cell radius around the player dark red (negative influence).
    final gx = (game.player.position.x / CellComponent.cellSize).floor();
    final gy = (game.player.position.y / CellComponent.cellSize).floor();
    const int blastRadius = 4;
    for (int dy = -blastRadius; dy <= blastRadius; dy++) {
      for (int dx = -blastRadius; dx <= blastRadius; dx++) {
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist > blastRadius) continue;
        final cell = game.grid.getCell(gx + dx, gy + dy);
        if (cell != null) {
          final falloff = 1.0 - (dist / blastRadius).clamp(0.0, 1.0);
          cell.spiritualState =
              (cell.spiritualState - 0.35 * strength * falloff)
                  .clamp(-1.0, 1.0);
        }
      }
    }

    removeFromParent();
  }

  // ── Rendering ──────────────────────────────────────────────────────────────

  @override
  void render(Canvas canvas) {
    if (!game.isSpiritualWorld) return;

    final daemonSize = size.x;
    final center = Offset(daemonSize / 2, daemonSize / 2);

    // Simple color pulse driven by the orbit angle – no extra variable needed.
    final t = (math.sin(_orbitAngle * 2) + 1) / 2;
    final isFlickering = _hitFlickerTimer > 0;

    // Aura – reuse pre-allocated paint; only update the color.
    _auraPaint.color = isFlickering
        ? _auraFlicker
        : Color.lerp(_auraLerpFrom, _auraLerpTo, t)!;
    canvas.drawCircle(center, daemonSize * 0.7, _auraPaint);

    // Core – reuse pre-allocated paint.
    _corePaint.color = isFlickering ? _coreFlicker : _coreNormal;
    canvas.drawCircle(center, daemonSize * 0.35, _corePaint);

    // Active Effect Auras (Issue #9)
    if (_activeEffects.isNotEmpty) {
      final effectModes = _activeEffects.keys.toList();
      for (int i = 0; i < effectModes.length; i++) {
        final mode = effectModes[i];
        final auraRadius = daemonSize * (0.8 + (i * 0.25));
        final effectPaint = Paint()
          ..color = mode.color.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        // Pulsing ring
        final pulse = 1.0 + math.sin(_orbitAngle * 5 + i) * 0.1;
        canvas.drawCircle(center, auraRadius * pulse, effectPaint);
      }
    }

    // Energy arc (shows remaining life, always starts full)
    final energyFraction =
        (model.energy.abs() / model.initialEnergy.abs()).clamp(0.0, 1.0);
    // _arcPaint color is set once in onLoad() and never changes.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: daemonSize * 0.45),
      -math.pi / 2,
      math.pi * 2 * energyFraction,
      false,
      _arcPaint,
    );
  }
}
