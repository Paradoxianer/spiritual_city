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
  bool isLoadedAndReady = false;

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

    // 5. Camera Configuration (Deadzone & Smoothing)
    camera.viewfinder.anchor = Anchor.center;
    
    // Initial snap
    camera.viewfinder.position = player.position;

    _log.info('SpiritWorldGame loaded.');
    isLoadedAndReady = true;
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
      
      if (building.type == BuildingType.church || building.type == BuildingType.cathedral) {
        actions.add(RadialAction(
          label: 'Beten',
          icon: Icons.auto_awesome,
          onSelect: () => _log.info('Praying in church...'),
        ));
      }
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

    // Manual smooth camera with deadzone (75/25 rule)
    _updateCamera(dt);
  }

  void _updateCamera(double dt) {
    if (!isLoadedAndReady) return;

    // Viewport size in world coordinates
    final viewportSize = camera.viewport.size;
    
    // Deadzone: 40% center free move
    final deadzoneWidth = viewportSize.x * 0.4; 
    final deadzoneHeight = viewportSize.y * 0.4;

    // Player position relative to camera center
    final relativeX = player.position.x - camera.viewfinder.position.x;
    final relativeY = player.position.y - camera.viewfinder.position.y;

    double moveX = 0;
    double moveY = 0;

    if (relativeX.abs() > deadzoneWidth / 2) {
      moveX = relativeX - (deadzoneWidth / 2 * relativeX.sign);
    }

    if (relativeY.abs() > deadzoneHeight / 2) {
      moveY = relativeY - (deadzoneHeight / 2 * relativeY.sign);
    }

    if (moveX != 0 || moveY != 0) {
      // Lerp for smoothness
      camera.viewfinder.position.add(Vector2(moveX, moveY) * 4 * dt);
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

  ActionButton({
    required this.onPressed,
    required super.position,
  }) : super(anchor: Anchor.center, size: Vector2.all(80));

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.blue.withOpacity(0.6);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
    
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.35, paint);
    
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'A',
        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.x / 2 - textPainter.width / 2, size.y / 2 - textPainter.height / 2));
  }

  @override
  void onTapDown(TapDownEvent event) {
    onPressed();
  }
}

class PrayerButton extends PositionComponent with TapCallbacks {
  final VoidCallback onPressed;

  PrayerButton({
    required this.onPressed,
    required super.position,
  }) : super(anchor: Anchor.center, size: Vector2.all(70));

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.purple.withOpacity(0.6);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
    
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.35, paint);
    
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'B',
        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.x / 2 - textPainter.width / 2, size.y / 2 - textPainter.height / 2));
  }

  @override
  void onTapDown(TapDownEvent event) {
    onPressed();
  }
}
