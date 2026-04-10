import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../../core/utils/seed_manager.dart';
import '../domain/city_generator.dart';
import '../domain/models/city_grid.dart';
import '../domain/models/cell_object.dart';
import '../domain/models/interactions.dart';
import 'components/chunk_manager.dart';
import 'components/player_component.dart';
import 'components/cell_component.dart';
import 'components/radial_menu.dart';
import 'game_screen.dart';

class SpiritWorldGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection, TapCallbacks {
  final _log = Logger('SpiritWorldGame');
  
  late final CityGrid grid;
  late final SeedManager seedManager;
  late final CityGenerator generator;
  late final PlayerComponent player;
  late final JoystickComponent joystick;
  late final ChunkManager chunkManager;
  late final ActionButton actionButton;
  late final PrayerButton prayerButton;

  RadialMenu? _currentMenu;
  bool isSpiritualWorld = false;
  final ValueNotifier<bool> isWorldReady = ValueNotifier<bool>(false);

  // Interaction State
  Interactable? _nearestInteractable;
  Interactable? get nearestInteractable => _nearestInteractable;
  static const double interactionRange = 60.0;
  
  GameDialogData? activeDialog;

  @override
  Color backgroundColor() => isSpiritualWorld ? const Color(0xFF000511) : const Color(0xFF111111);

  @override
  Future<void> onLoad() async {
    _log.info('--- INITIALIZING GAME ---');
    seedManager = SeedManager(42);
    generator = CityGenerator(seedManager);
    grid = CityGrid();

    player = PlayerComponent(joystick: _createJoystick());
    player.position = Vector2(256, 256); 
    await world.add(player);

    chunkManager = ChunkManager(grid: grid, generator: generator, target: player);
    await world.add(chunkManager);

    await camera.viewport.add(joystick);
    await _addHudButtons();

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = player.position.clone();

    await Future.delayed(const Duration(milliseconds: 1000));
    isWorldReady.value = true;
    _log.info('--- GAME READY ---');
  }

  void toggleWorld() {
    isSpiritualWorld = !isSpiritualWorld;
    _log.info('Switched World: $isSpiritualWorld');
  }

  void handleAction() {
    if (activeDialog != null) { closeDialog(); return; }
    if (_currentMenu != null) { closeMenu(); return; }
    
    // Radial Menu immer öffnen
    _openRadialMenu();
  }

  void _openRadialMenu() {
    final actions = <RadialAction>[
      RadialAction(label: '👀', icon: Icons.search, onSelect: () => _log.info('Looking around')),
    ];

    if (_nearestInteractable != null) {
      actions.add(RadialAction(
        label: '💬', 
        icon: Icons.chat_bubble, 
        onSelect: () => _nearestInteractable!.onInteract()
      ));
    }

    _currentMenu = RadialMenu(actions: actions, position: player.position);
    world.add(_currentMenu!);
  }

  void showDialog(String title, String emoji) {
    activeDialog = GameDialogData(title: title, emoji: emoji);
    overlays.add('DialogOverlay');
    paused = true; 
  }

  void closeDialog() {
    activeDialog = null;
    overlays.remove('DialogOverlay');
    paused = false;
  }

  void closeMenu() { _currentMenu?.removeFromParent(); _currentMenu = null; }

  @override
  void update(double dt) {
    super.update(dt);
    if (_currentMenu != null) _currentMenu!.position = player.position;
    if (isWorldReady.value && !paused) {
      _updateCamera(dt);
      _updateNearestInteractable();
    }
  }

  void _updateNearestInteractable() {
    Interactable? nearest;
    double minDistance = interactionRange;

    for (final interactable in world.children.whereType<Interactable>()) {
      final dist = player.position.distanceTo(interactable.interactionPosition);
      if (dist < minDistance) {
        minDistance = dist;
        nearest = interactable;
      }
    }

    if (_nearestInteractable != nearest) {
      _nearestInteractable = nearest;
    }
  }

  void _updateCamera(double dt) {
    final viewportSize = camera.viewport.size;
    if (viewportSize.x <= 0) return;

    final camPos = camera.viewfinder.position;
    final pPos = player.position;

    final limitX = viewportSize.x * 0.375; 
    final limitY = viewportSize.y * 0.375;

    final dx = pPos.x - camPos.x;
    final dy = pPos.y - camPos.y;

    double pushX = 0;
    double pushY = 0;

    if (dx.abs() > limitX) pushX = dx - (limitX * dx.sign);
    if (dy.abs() > limitY) pushY = dy - (limitY * dy.sign);

    if (pushX != 0 || pushY != 0) {
      camera.viewfinder.position = Vector2(camPos.x + pushX, camPos.y + pushY);
    }
  }

  JoystickComponent _createJoystick() {
    return joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: Paint()..color = Colors.white.withOpacity(0.5)),
      background: CircleComponent(radius: 50, paint: Paint()..color = Colors.white.withOpacity(0.2)),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
  }

  Future<void> _addHudButtons() async {
    actionButton = ActionButton(onPressed: handleAction, position: Vector2(size.x - 80, size.y - 80));
    await camera.viewport.add(actionButton);
    prayerButton = PrayerButton(onPressed: toggleWorld, position: Vector2(size.x - 170, size.y - 80));
    await camera.viewport.add(prayerButton);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      actionButton.position = Vector2(size.x - 80, size.y - 80);
      prayerButton.position = Vector2(size.x - 170, size.y - 80);
    }
  }
}

class ActionButton extends PositionComponent with TapCallbacks {
  final VoidCallback onPressed;
  ActionButton({required this.onPressed, required super.position}) : super(anchor: Anchor.center, size: Vector2.all(80));

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, Paint()..color = Colors.blue.withOpacity(0.6));
    TextPainter(
      text: const TextSpan(text: '🖐️', style: TextStyle(fontSize: 32)),
      textDirection: TextDirection.ltr
    )..layout()..paint(canvas, Offset(size.x / 2 - 16, size.y / 2 - 20));
  }
  @override
  void onTapDown(TapDownEvent event) => onPressed();
}

class PrayerButton extends PositionComponent with TapCallbacks {
  final VoidCallback onPressed;
  PrayerButton({required this.onPressed, required super.position}) : super(anchor: Anchor.center, size: Vector2.all(70));
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, Paint()..color = Colors.purple.withOpacity(0.6));
    TextPainter(
      text: const TextSpan(text: '🙏', style: TextStyle(fontSize: 28)), 
      textDirection: TextDirection.ltr
    )..layout()..paint(canvas, Offset(size.x / 2 - 14, size.y / 2 - 18));
  }
  @override
  void onTapDown(TapDownEvent event) => onPressed();
}
