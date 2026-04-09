import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../../core/utils/seed_manager.dart';
import '../domain/city_generator.dart';
import '../domain/models/city_grid.dart';
import 'components/chunk_manager.dart';
import 'components/player_component.dart';
import 'components/cell_component.dart';

class SpiritWorldGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection, TapCallbacks {
  final _log = Logger('SpiritWorldGame');
  
  late final CityGrid grid;
  late final SeedManager seedManager;
  late final CityGenerator generator;
  late final PlayerComponent player;
  late final JoystickComponent joystick;
  late final ChunkManager chunkManager;

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
    
    // Icon-like drawing
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
