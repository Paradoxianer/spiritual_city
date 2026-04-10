import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../../core/utils/seed_manager.dart';
import '../domain/city_generator.dart';
import '../domain/models/city_grid.dart';
import '../domain/models/interactions.dart';
import 'components/chunk_manager.dart';
import 'components/player_component.dart';
import 'components/cell_component.dart';
import 'components/chunk_component.dart';
import 'components/radial_menu.dart';
import 'components/prayer_hud_component.dart';
import 'game_screen.dart';

class SpiritWorldGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection, TapCallbacks {
  final _log = Logger('SpiritWorldGame');
  
  late final CityGrid grid;
  late final SeedManager seedManager;
  late final CityGenerator generator;
  late final PlayerComponent player;
  late final JoystickComponent joystick;
  late final ChunkManager chunkManager;
  late final HudButton actionButton;
  late final HudButton worldToggleButton;
  late final PrayerHudComponent prayerHud;

  RadialMenu? _currentMenu;
  bool isSpiritualWorld = false;
  final ValueNotifier<bool> isWorldReady = ValueNotifier<bool>(false);

  // Ressourcen
  double faith = 100.0;
  static const double maxFaith = 100.0;
  static const double worldToggleCost = 10.0;

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
    
    prayerHud = PrayerHudComponent();
    await camera.viewport.add(prayerHud);

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = player.position.clone();

    await Future.delayed(const Duration(milliseconds: 1000));
    isWorldReady.value = true;
    _log.info('--- GAME READY ---');
  }

  void toggleWorld() {
    if (!isSpiritualWorld && faith < worldToggleCost) {
      _log.warning('Not enough faith to enter spiritual world');
      return;
    }
    
    if (!isSpiritualWorld) {
      faith -= worldToggleCost;
    }
    
    isSpiritualWorld = !isSpiritualWorld;
    _updateButtonStyles();
    _log.info('Switched World: $isSpiritualWorld');
  }

  void handleActionDown() {
    if (isSpiritualWorld) {
      player.startChargingIntensity();
    }
  }

  void handleActionUp() {
    if (isSpiritualWorld) {
      player.releasePrayer();
    } else {
      if (activeDialog != null) { closeDialog(); return; }
      if (_currentMenu != null) { closeMenu(); return; }
      _openRadialMenu();
    }
  }

  void _updateButtonStyles() {
    actionButton.updateContent(
      isSpiritualWorld ? '✨' : '🖐️',
      isSpiritualWorld ? Colors.amber.withValues(alpha: 0.7) : Colors.blue.withValues(alpha: 0.6)
    );
    worldToggleButton.updateContent(
      isSpiritualWorld ? '🏙️' : '🙏',
      isSpiritualWorld ? Colors.grey.withValues(alpha: 0.7) : Colors.purple.withValues(alpha: 0.6)
    );
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

  void showDialog(String name, String emoji) {
    activeDialog = GameDialogData(npcName: name, npcEmoji: emoji);
    overlays.add('DialogOverlay');
    paused = true; 
  }

  String handleInteraction(String type) {
    if (_nearestInteractable != null) {
      return _nearestInteractable!.handleInteraction(type);
    }
    return '❓';
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
      knob: CircleComponent(radius: 20, paint: Paint()..color = Colors.white.withValues(alpha: 0.5)),
      background: CircleComponent(radius: 50, paint: Paint()..color = Colors.white.withValues(alpha: 0.2)),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
  }

  Future<void> _addHudButtons() async {
    actionButton = HudButton(
      icon: '🖐️',
      color: Colors.blue.withValues(alpha: 0.6),
      onDown: handleActionDown, 
      onUp: handleActionUp, 
      position: Vector2(size.x - 80, size.y - 80)
    );
    await camera.viewport.add(actionButton);

    worldToggleButton = HudButton(
      icon: '🙏',
      color: Colors.purple.withValues(alpha: 0.6),
      onDown: toggleWorld,
      position: Vector2(size.x - 170, size.y - 80)
    );
    await camera.viewport.add(worldToggleButton);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      actionButton.position = Vector2(size.x - 80, size.y - 80);
      worldToggleButton.position = Vector2(size.x - 170, size.y - 80);
    }
  }
}

class HudButton extends PositionComponent with TapCallbacks {
  final VoidCallback? onDown;
  final VoidCallback? onUp;
  String icon;
  Color color;
  
  HudButton({
    required this.icon,
    required this.color,
    this.onDown, 
    this.onUp, 
    required super.position
  }) : super(anchor: Anchor.center, size: Vector2.all(75)); // Einheitliche Größe

  void updateContent(String newIcon, Color newColor) {
    icon = newIcon;
    color = newColor;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;

    // 1. Schwarzer Rand / Schatten
    canvas.drawCircle(center, radius + 2, Paint()..color = Colors.black.withValues(alpha: 0.5));
    
    // 2. Haupt-Button
    canvas.drawCircle(center, radius, Paint()..color = color);

    // 3. Glanz-Effekt oben
    final shinePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha: 0.3), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shinePaint);

    // 4. Icon
    TextPainter(
      text: TextSpan(text: icon, style: const TextStyle(fontSize: 30)),
      textDirection: TextDirection.ltr
    )..layout()..paint(canvas, Offset(size.x / 2 - 15, size.y / 2 - 19));
  }

  @override
  void onTapDown(TapDownEvent event) => onDown?.call();

  @override
  void onTapUp(TapUpEvent event) => onUp?.call();

  @override
  void onTapCancel(TapCancelEvent event) => onUp?.call();
}
