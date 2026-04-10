import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../../core/utils/seed_manager.dart';
import '../domain/city_generator.dart';
import '../domain/models/city_grid.dart';
import '../domain/models/cell_object.dart';
import 'components/chunk_manager.dart';
import 'components/player_component.dart';
import 'components/cell_component.dart';
import 'components/radial_menu.dart';

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

  /// Notifier to signal when the initial world generation is complete
  final ValueNotifier<bool> isWorldReady = ValueNotifier<bool>(false);

  @override
  Color backgroundColor() => isSpiritualWorld ? const Color(0xFF000511) : const Color(0xFF111111);

  @override
  Future<void> onLoad() async {
    _log.info('Loading SpiritWorldGame...');

    // 1. Initialize logic
    seedManager = SeedManager(42);
    generator = CityGenerator(seedManager);
    grid = CityGrid();

    // 2. Add Player
    player = PlayerComponent(joystick: _createJoystick());
    player.position = Vector2(256, 256); 
    await world.add(player);

    // 3. Add ChunkManager
    chunkManager = ChunkManager(
      grid: grid,
      generator: generator,
      target: player,
    );
    await world.add(chunkManager);

    // 4. HUD elements
    await camera.viewport.add(joystick);
    await _addHudButtons();

    // 5. Camera Initial Position
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = player.position;

    // Wait for initial chunks to settle
    await Future.delayed(const Duration(milliseconds: 1000));
    isWorldReady.value = true;
    _log.info('SpiritWorldGame loaded.');
  }

  void toggleWorld() {
    isSpiritualWorld = !isSpiritualWorld;
    _log.info('Switched to ${isSpiritualWorld ? "Spiritual" : "Physical"} world');
  }

  void handleAction() {
    if (_currentMenu != null) {
      closeMenu();
      return;
    }

    final int gridX = (player.position.x / CellComponent.cellSize).floor();
    final int gridY = (player.position.y / CellComponent.cellSize).floor();
    
    final cell = grid.getCell(gridX, gridY);
    final actions = <RadialAction>[];

    if (cell?.data is BuildingData) {
      final building = cell!.data as BuildingData;
      actions.add(RadialAction(
        label: 'Betreten',
        icon: Icons.door_front_door,
        onSelect: () => _log.info('Entering ${building.type}...'),
      ));
    }

    actions.add(RadialAction(
      label: 'Umsehen',
      icon: Icons.search,
      onSelect: () => _log.info('Looking around...'),
    ));

    if (actions.isNotEmpty) {
      _currentMenu = RadialMenu(
        actions: actions,
        position: player.position,
      );
      world.add(_currentMenu!);
    }
  }

  void closeMenu() {
    _currentMenu?.removeFromParent();
    _currentMenu = null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_currentMenu != null) {
      _currentMenu!.position = player.position;
    }

    if (isWorldReady.value) {
      _updateCamera(dt);
    }
  }

  /// Implements smooth scrolling with 75/25 deadzone.
  void _updateCamera(double dt) {
    final viewportSize = camera.viewport.size;
    if (viewportSize.x <= 0) return;

    final camPos = camera.viewfinder.position;
    final pPos = player.position;

    // Define the deadzone (75% of the screen)
    final deadzoneX = viewportSize.x * 0.75;
    final deadzoneY = viewportSize.y * 0.75;

    // Distance from camera center to player
    final dx = pPos.x - camPos.x;
    final dy = pPos.y - camPos.y;

    double moveX = 0;
    double moveY = 0;

    // Calculate how much we need to move the camera to keep player inside deadzone
    if (dx.abs() > deadzoneX / 2) {
      moveX = dx - (deadzoneX / 2 * dx.sign);
    }
    if (dy.abs() > deadzoneY / 2) {
      moveY = dy - (deadzoneY / 2 * dy.sign);
    }

    if (moveX != 0 || moveY != 0) {
      // Apply smoothing (lerp-like) for the camera movement
      // Multiply by a factor (e.g., 5.0) for a snappy but smooth catch-up
      camera.viewfinder.position.add(Vector2(moveX, moveY) * 5.0 * dt);
    }
  }

  JoystickComponent _createJoystick() {
    final knobPaint = Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.5);
    final backgroundPaint = Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.2);
    
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    return joystick;
  }

  Future<void> _addHudButtons() async {
    actionButton = ActionButton(
      onPressed: handleAction,
      position: Vector2(size.x - 80, size.y - 80),
    );
    await camera.viewport.add(actionButton);

    prayerButton = PrayerButton(
      onPressed: toggleWorld,
      position: Vector2(size.x - 170, size.y - 80),
    );
    await camera.viewport.add(prayerButton);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (this.isLoaded) {
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
    final paint = Paint()..color = Colors.blue.withOpacity(0.6);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
    final textPainter = TextPainter(text: const TextSpan(text: 'A', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, Offset(size.x / 2 - textPainter.width / 2, size.y / 2 - textPainter.height / 2));
  }
  @override
  void onTapDown(TapDownEvent event) => onPressed();
}

class PrayerButton extends PositionComponent with TapCallbacks {
  final VoidCallback onPressed;
  PrayerButton({required this.onPressed, required super.position}) : super(anchor: Anchor.center, size: Vector2.all(70));
  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.purple.withOpacity(0.6);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
    final textPainter = TextPainter(text: const TextSpan(text: 'B', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    textPainter.paint(canvas, Offset(size.x / 2 - textPainter.width / 2, size.y / 2 - textPainter.height / 2));
  }
  @override
  void onTapDown(TapDownEvent event) => onPressed();
}
