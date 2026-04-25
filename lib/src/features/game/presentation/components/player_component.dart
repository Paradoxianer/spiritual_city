import 'dart:math' as math;
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
  
  // Prayer Combat State
  late final PrayerZoneComponent prayerZone;
  bool _isChargingIntensity = false;

  // Gebetskampf 2.0 (Issue #9)
  PrayerMode _currentMode = PrayerMode.liberation;
  double _holdingTime = 0.0;
  double _timeSinceLastShockwave = 0.0;
  static const double _shockwaveInterval = 1.2; // Slower interval (every 1.2s) for more impact

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
  bool _pressedShift = false;

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keyboardDirection.setZero();
    if (keysPressed.contains(GameKeymap.moveUp)    || keysPressed.contains(GameKeymap.moveUpAlt))    _keyboardDirection.y -= 1;
    if (keysPressed.contains(GameKeymap.moveDown)  || keysPressed.contains(GameKeymap.moveDownAlt))  _keyboardDirection.y += 1;
    if (keysPressed.contains(GameKeymap.moveLeft)  || keysPressed.contains(GameKeymap.moveLeftAlt))  _keyboardDirection.x -= 1;
    if (keysPressed.contains(GameKeymap.moveRight) || keysPressed.contains(GameKeymap.moveRightAlt)) _keyboardDirection.x += 1;
    if (!_keyboardDirection.isZero()) _keyboardDirection.normalize();

    _pressedShift = keysPressed.contains(GameKeymap.prayerSize) ||
        keysPressed.contains(GameKeymap.prayerSizeAlt);

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

    return true;
  }

  void startChargingIntensity() {
    if (game.faith > 0.1) {
      _isChargingIntensity = true;
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

    // Faith cost per wave (higher cost for stronger waves)
    final cost = 5.0 * game.modifiers.faithCostMultiplier;
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
    final delta = moveDir * speed * dt;
    final newPos = position + delta;

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
