import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../core/utils/seed_manager.dart';
import '../domain/city_generator.dart';
import '../domain/models/city_grid.dart';
import 'components/cell_component.dart';
import 'components/player_component.dart';

class SpiritWorldGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  final _log = Logger('SpiritWorldGame');
  
  late final CityGrid grid;
  late final SeedManager seedManager;
  late final CityGenerator generator;
  late final PlayerComponent player;
  late final JoystickComponent joystick;

  @override
  Future<void> onLoad() async {
    _log.info('Loading SpiritWorldGame...');

    // 1. Initialize logic
    seedManager = SeedManager(42);
    generator = CityGenerator(seedManager);
    grid = generator.generate(50, 50);

    // 2. Add World (Grid)
    final world = World();
    for (final cell in grid.getAllCells()) {
      await world.add(CellComponent(cell));
    }
    await add(world);

    // 3. Add Joystick
    final knobPaint = Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.5);
    final backgroundPaint = Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.2);
    
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    await add(joystick);

    // 4. Add Player
    player = PlayerComponent(joystick: joystick);
    player.position = Vector2(
      (grid.width * CellComponent.cellSize) / 2,
      (grid.height * CellComponent.cellSize) / 2,
    );
    await world.add(player);

    // 5. Camera Setup
    camera.viewfinder.anchor = Anchor.center;
    camera.follow(player);

    _log.info('SpiritWorldGame loaded.');
  }
}
