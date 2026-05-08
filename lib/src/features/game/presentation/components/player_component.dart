import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../domain/models/game_keymap.dart';
import '../spirit_world_game.dart';
import 'cell_component.dart';
import 'prayer_zone_component.dart';
import 'shockwave_component.dart';
import '../../domain/models/prayer_combat.dart';

class PlayerComponent extends PositionComponent 
    with HasGameReference<SpiritWorldGame>, KeyboardHandler {
  static const double playerSize = 24.0;
  final JoystickComponent joystick;
  
  final double speed = 100.0;

  // ── Sprint (Issue #50) ─────────────────────────────────────────────────────
  /// Speed multiplier applied while sprinting.
  static const double kSprintMultiplier = 1.8;

  /// Additional hunger drained per second of active sprint movement.
  static const double kSprintHungerDrainRate = 1.0;

  /// True when the player is holding a direction key after a double-tap.
  bool _isSprintingKeyboard = false;

  /// True when the joystick double-drag sprint is active (set by game).
  bool _isSprintingJoystick = false;

  /// Whether the player is currently sprinting (real world only).
  bool get isSprinting =>
      (_isSprintingKeyboard || _isSprintingJoystick) && !game.isSpiritualWorld;

  void startSprintJoystick() => _isSprintingJoystick = true;
  void stopSprintJoystick()  => _isSprintingJoystick = false;

  // Keyboard double-tap detection state.
  LogicalKeyboardKey? _lastDirKeyDown;
  int _lastDirKeyDownTime = 0;
  static const int _kDoubleTapWindowMs = 350;

  // Accumulated sprint hunger (batched to avoid sub-integer HUD flicker).
  double _sprintHungerAccum = 0.0;

  // Last non-zero movement direction (used to place dust particles).
  final Vector2 _lastMoveDir = Vector2.zero();
  // ── End Sprint ─────────────────────────────────────────────────────────────

  // Prayer Combat State
  late final PrayerZoneComponent prayerZone;
  bool _isChargingIntensity = false;

  // Gebetskampf 2.0 (Issue #9)
  PrayerMode _currentMode = PrayerMode.liberation;
  double _holdingTime = 0.0;
  double _timeSinceLastShockwave = 0.0;
  static const double _shockwaveInterval = 1.8; // Even slower rhythm

  PrayerMode get currentMode => _currentMode;
  double get holdingTime => _holdingTime;

  // Getters für das HUD
  double get faithPulse => prayerZone.pulseValue;
  double get zoneSize => prayerZone.sizeFactor;

  void setMode(PrayerMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      _holdingTime = 0;
      _timeSinceLastShockwave = 0;
    }
  }

  // ===========================================================================
  // MODIFIER VORBEREITUNG (Für Issue #29 / #32)
  // ===========================================================================
  
  /// Globaler Widerstand-Multiplikator (Kann durch Missionen gesenkt werden)
  double modifierResistanceFactor = 1.0; 

  // ===========================================================================

  PlayerComponent({required this.joystick})
      : super(
          size: Vector2.all(playerSize),
          anchor: Anchor.center,
          priority: 100,
        );

  /// Returns a speed multiplier based on current hunger level.
  /// - Hunger < 10% of max → 40% speed
  /// - Hunger < 30% of max → 60% speed
  /// - Otherwise           → 100% speed
  double get _hungerSpeedMultiplier {
    final hungerPct = game.hunger / game.progress.maxHunger;
    if (hungerPct < SpiritWorldGame.hungerCriticalThreshold) return 0.4;
    if (hungerPct < SpiritWorldGame.hungerWarnThreshold) return 0.6;
    return 1.0;
  }

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
    prayerZone = PrayerZoneComponent();
    game.world.add(prayerZone);
  }

  @override
  void render(Canvas canvas) {
    if (!game.isSpiritualWorld) {
      final isNear = game.nearestInteractable != null;
      final auraPaint = Paint()
        ..color = isNear ? Colors.yellow.withValues(alpha: 0.2) : Colors.blueAccent.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      final pulse = 1.0 + (isNear ? (DateTime.now().millisecondsSinceEpoch % 1000 / 5000) : 0);
      canvas.drawCircle((size / 2).toOffset(), SpiritWorldGame.interactionRange * pulse, auraPaint);
    }

    final paint = Paint()..color = game.isSpiritualWorld ? Colors.amberAccent : Colors.blueAccent;
    canvas.drawCircle((size / 2).toOffset(), size.x / 2, paint);
    
    paint.color = Colors.white;
    paint.strokeWidth = 2;
    canvas.drawLine(Offset(size.x / 2, size.y * 0.2), Offset(size.x / 2, size.y * 0.8), paint);
    canvas.drawLine(Offset(size.x * 0.3, size.y * 0.4), Offset(size.x * 0.7, size.y * 0.4), paint);
  }

  final Vector2 _keyboardDirection = Vector2.zero();

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keyboardDirection.setZero();
    if (keysPressed.contains(GameKeymap.moveUp)    || keysPressed.contains(GameKeymap.moveUpAlt))    _keyboardDirection.y -= 1;
    if (keysPressed.contains(GameKeymap.moveDown)  || keysPressed.contains(GameKeymap.moveDownAlt))  _keyboardDirection.y += 1;
    if (keysPressed.contains(GameKeymap.moveLeft)  || keysPressed.contains(GameKeymap.moveLeftAlt))  _keyboardDirection.x -= 1;
    if (keysPressed.contains(GameKeymap.moveRight) || keysPressed.contains(GameKeymap.moveRightAlt)) _keyboardDirection.x += 1;
    if (!_keyboardDirection.isZero()) _keyboardDirection.normalize();

    // ── Sprint: double-tap direction key (real world only) ────────────────────
    if (!game.isSpiritualWorld && event is KeyDownEvent) {
      LogicalKeyboardKey? pressedDir;
      if (event.logicalKey == GameKeymap.moveUp    || event.logicalKey == GameKeymap.moveUpAlt)    pressedDir = GameKeymap.moveUp;
      if (event.logicalKey == GameKeymap.moveDown  || event.logicalKey == GameKeymap.moveDownAlt)  pressedDir = GameKeymap.moveDown;
      if (event.logicalKey == GameKeymap.moveLeft  || event.logicalKey == GameKeymap.moveLeftAlt)  pressedDir = GameKeymap.moveLeft;
      if (event.logicalKey == GameKeymap.moveRight || event.logicalKey == GameKeymap.moveRightAlt) pressedDir = GameKeymap.moveRight;
      if (pressedDir != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (pressedDir == _lastDirKeyDown &&
            now - _lastDirKeyDownTime < _kDoubleTapWindowMs) {
          _isSprintingKeyboard = true;
        }
        _lastDirKeyDown = pressedDir;
        _lastDirKeyDownTime = now;
      }
    }
    // Also allow Shift as a direct sprint toggle (desktop convenience).
    if (!game.isSpiritualWorld) {
      if (keysPressed.contains(GameKeymap.sprint) ||
          keysPressed.contains(GameKeymap.sprintAlt)) {
        _isSprintingKeyboard = true;
      }
    }
    // Sprint ends when all direction keys are released.
    if (_isSprintingKeyboard && _keyboardDirection.isZero()) {
      _isSprintingKeyboard = false;
    }

    // ── Action button (Space) ─────────────────────────────────────────────────
    if (keysPressed.contains(GameKeymap.action)) {
      game.handleActionDown();
    } else if (event is KeyUpEvent && event.logicalKey == GameKeymap.action) {
      game.handleActionUp();
    }

    // ── Interact key (E) – open radial menu / close dialog (real world only) ──
    if (event is KeyUpEvent &&
        event.logicalKey == GameKeymap.interact &&
        !game.isSpiritualWorld) {
      game.handleActionUp();
    }

    // ── World toggle (Tab) ────────────────────────────────────────────────────
    if (event is KeyUpEvent && event.logicalKey == GameKeymap.worldToggle) {
      game.toggleWorld();
    }

    // ── Switch Mode (1-4 in Spiritual World) ─────────────────────────────────
    if (game.isSpiritualWorld && event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) setMode(PrayerMode.liberation);
      if (event.logicalKey == LogicalKeyboardKey.digit2) setMode(PrayerMode.rebuke);
      if (event.logicalKey == LogicalKeyboardKey.digit3) setMode(PrayerMode.slow);
      if (event.logicalKey == LogicalKeyboardKey.digit4) setMode(PrayerMode.drain);
    }

    // ── Close (Escape) ────────────────────────────────────────────────────────
    if (event is KeyUpEvent && event.logicalKey == GameKeymap.close) {
      game.handleEscape();
    }

    // ── Keymap overlay (F1 / ?) ───────────────────────────────────────────────
    if (event is KeyUpEvent &&
        (event.logicalKey == GameKeymap.keymapOverlay ||
            event.logicalKey == GameKeymap.keymapOverlayAlt)) {
      game.toggleKeymapOverlay();
    }

    // ── Mission board (M) ─────────────────────────────────────────────────────
    if (event is KeyUpEvent && event.logicalKey == GameKeymap.missionBoard) {
      game.toggleMissionBoard();
    }

    // ── Digit quick-select (1–6): context-sensitive ───────────────────────────
    // Priority: chat dialog > building interior > radial menu.
    if (event is KeyUpEvent) {
      final allDigitKeys = [
        GameKeymap.radial1,
        GameKeymap.radial2,
        GameKeymap.radial3,
        GameKeymap.radial4,
        GameKeymap.radial5,
        GameKeymap.radial6,
      ];
      final idx = allDigitKeys.indexOf(event.logicalKey);
      if (idx != -1) {
        if (game.activeDialog != null) {
          game.selectDialogAction(idx);
        } else if (game.activeBuildingData != null) {
          game.selectBuildingAction(idx);
        } else {
          game.selectRadialMenuAction(idx);
        }
      }
    }

    if (game.isSpiritualWorld && !_keyboardDirection.isZero()) {
      // Directional hint could be handled here if needed
    }

    // ── Debug: F9 forces the win screen immediately (debug builds only) ───────
    if (event is KeyUpEvent && event.logicalKey == GameKeymap.debugForceWin) {
      game.debugForceWin();
    }

    return true;
  }

  void startChargingIntensity() {
    if (!_isChargingIntensity && game.faith > 1.0) {
      _isChargingIntensity = true;
      _timeSinceLastShockwave = _shockwaveInterval; // Start immediately
    }
  }

  void releasePrayer() {
    if (!_isChargingIntensity) return;
    _isChargingIntensity = false;
    _holdingTime = 0;
    _timeSinceLastShockwave = 0;
    game.recordPrayerCombat();
    game.spiritualDynamics.activatePrayerAttraction();
  }

  void _emitShockwave() {
    final stats = game.modifiers.getEffectiveCombatStats(
      _currentMode,
      _holdingTime,
      game.faith,
    );

    // Faith cost per wave (higher cost for stronger waves; +50% if hunger critical)
    final cost = 5.0 * game.modifiers.faithCostMultiplier * game.hungerFaithCostMultiplier;
    if (game.faith < cost) {
      _isChargingIntensity = false;
      return;
    }
    game.faith -= cost;

    game.world.add(ShockwaveComponent(
      position: position.clone(),
      maxRadius: stats.radius,
      strength: stats.strength,
      duration: stats.duration,
      speed: stats.speed,
      color: stats.color,
      mode: _currentMode,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isSpiritualWorld) {
      _updatePrayerMechanics(dt);
    } else {
      _updateMovement(dt);
    }
  }

  void _updateMovement(double dt) {
    if (_keyboardDirection.isZero() && joystick.delta.isZero()) return;
    final moveDir = joystick.delta.isZero() ? _keyboardDirection : joystick.relativeDelta;
    // Track the last non-zero direction for particle rendering.
    if (!moveDir.isZero()) _lastMoveDir.setFrom(moveDir.normalized());
    final sprintMult = isSprinting ? kSprintMultiplier : 1.0;
    final effectiveSpeed = speed * _hungerSpeedMultiplier * sprintMult;
    final delta = moveDir * effectiveSpeed * dt;
    final newPos = position + delta;

    // Sprint hunger drain: batch into 1-unit chunks so the HUD delta is visible.
    if (isSprinting) {
      _sprintHungerAccum += kSprintHungerDrainRate * dt;
      if (_sprintHungerAccum >= 1.0) {
        final chunk = _sprintHungerAccum.floorToDouble();
        game.spendHunger(chunk);
        _sprintHungerAccum -= chunk;
      }
    } else {
      _sprintHungerAccum = 0.0;
    }

    // Grid coordinates for target position
    final gx = (newPos.x / CellComponent.cellSize).floor();
    final gy = (newPos.y / CellComponent.cellSize).floor();

    if (game.grid.isWalkable(gx, gy)) {
      position.setFrom(newPos);
    } else {
      // Try horizontal slide (move only on X)
      final newPosX = Vector2(newPos.x, position.y);
      final gxSlide = (newPosX.x / CellComponent.cellSize).floor();
      final gySlide = (newPosX.y / CellComponent.cellSize).floor();
      if (game.grid.isWalkable(gxSlide, gySlide)) {
        position.setFrom(newPosX);
      } else {
        // Try vertical slide (move only on Y)
        final newPosY = Vector2(position.x, newPos.y);
        final gxSlide2 = (newPosY.x / CellComponent.cellSize).floor();
        final gySlide2 = (newPosY.y / CellComponent.cellSize).floor();
        if (game.grid.isWalkable(gxSlide2, gySlide2)) {
          position.setFrom(newPosY);
        }
        // Both axes blocked – don't move
      }
    }
  }

  void _updatePrayerMechanics(double dt) {
    if (_isChargingIntensity && game.faith > 1.0) {
      _holdingTime += dt;
      _timeSinceLastShockwave += dt;
      
      if (_timeSinceLastShockwave >= _shockwaveInterval) {
        _emitShockwave();
        _timeSinceLastShockwave = 0;
      }

      // Aura disabled as per user request (shockwave is enough)
      prayerZone.isActive = false;
    } else {
      _isChargingIntensity = false;
      _holdingTime = 0;
      _timeSinceLastShockwave = 0;
      prayerZone.isActive = false;
    }

    prayerZone.position = position;
  }
}
