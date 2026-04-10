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

  RadialMenu? _currentMenu;
  bool isSpiritualWorld = false;

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

    // 5. Camera follow
    camera.viewfinder.anchor = Anchor.center;
    camera.follow(player);

    _log.info('SpiritWorldGame loaded.');
  }

  void toggleWorld() {
    isSpiritualWorld = !isSpiritualWorld;
    _log.info('Switched to ${isSpiritualWorld ? "Spiritual" : "Physical"} world');
  }

  void handleAction() {
    if (_currentMenu != null) {
      _currentMenu?.removeFromParent();
      _currentMenu = null;
      return;
    }

    final int gridX = (player.position.x / CellComponent.cellSize).floor();
    final int gridY = (player.position.y / CellComponent.cellSize).floor();
    
    final cell = grid.getCell(gridX, gridY);
    final actions = <RadialAction>[];

    // Check for building interaction
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

    // Default actions
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

  @override
  void update(double dt) {
    super.update(dt);
    // Move menu with player if open
    if (_currentMenu != null) {
      _currentMenu!.position = player.position;
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
    final toggleButton = WorldToggleButton(
      onPressed: toggleWorld,
      position: Vector2(size.x - 80, 80),
    );
    await camera.viewport.add(toggleButton);

    actionButton = ActionButton(
      onPressed: handleAction,
      position: Vector2(size.x - 80, size.y - 80),
    );
    await camera.viewport.add(actionButton);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (this.isLoaded) {
      actionButton.position = Vector2(size.x - 80, size.y - 80);
    }
  }
}

class WorldToggleButton extends PositionComponent with TapCallbacks {
  final VoidCallback onPressed;

  WorldToggleButton({
    required this.onPressed,
    required super.position,
  }) : super(anchor: Anchor.center, size: Vector2.all(60));

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.purple.withOpacity(0.5);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
    
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * 0.3, paint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    onPressed();
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
    final paint = Paint()..color = Colors.blue.withOpacity(0.5);
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
