import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../../core/utils/seed_manager.dart';
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
  Color backgroundColor() => const Color(0xFF111111);

  @override
  Future<void> onLoad() async {
    _log.info('Loading SpiritWorldGame...');

    // 1. Initialize logic
    seedManager = SeedManager(42);
    generator = CityGenerator(seedManager);
    grid = generator.generate(30, 30); // Reduced size for faster initial load

    // 2. Add Grid to world (using addAll for performance)
    final cellComponents = grid.getAllCells().map((cell) => CellComponent(cell)).toList();
    await world.addAll(cellComponents);

    // 3. Add Player to world
    player = PlayerComponent(joystick: _createJoystick());
    player.position = Vector2(
      (grid.width * CellComponent.cellSize) / 2,
      (grid.height * CellComponent.cellSize) / 2,
    );
    await world.add(player);

    // 4. Add Joystick to Camera Viewport (HUD)
    // In Flame 1.x, elements added to camera.viewport stay on screen
    await camera.viewport.add(joystick);

    // 5. Camera Setup
    camera.viewfinder.anchor = Anchor.center;
    camera.follow(player);

    _log.info('SpiritWorldGame loaded and visible.');
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
}
