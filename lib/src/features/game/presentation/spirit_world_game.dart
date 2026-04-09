import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:logging/logging.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/error/error_handler.dart';
import '../../city/domain/services/city_generator.dart';
import '../../city/domain/entities/city_grid.dart';
import '../../city/presentation/components/city_render_component.dart';
import '../../spiritual_world/presentation/components/spiritual_overlay_component.dart';
import '../../player/domain/services/player_service.dart';
import '../../player/presentation/components/player_component.dart';
import '../../player/presentation/components/joystick_component.dart';
import '../../hud/presentation/components/hud_overlay_component.dart';
import '../../interaction/domain/services/prayer_service.dart';
import '../../interaction/presentation/components/prayer_pulse_component.dart';
import '../../npc/domain/services/npc_service.dart';
import '../../npc/presentation/components/npc_component.dart';

class SpiritWorldGame extends FlameGame with TapCallbacks {
  final _log = Logger('SpiritWorldGame');

  late final CityGrid _cityGrid;
  late final SpiritualOverlayComponent _spiritualOverlay;
  late final PlayerComponent _player;
  late final PlayerJoystickComponent _joystick;
  late final HudOverlayComponent _hud;
  late final PrayerPulseComponent _prayerPulse;

  final PlayerService _playerService;
  final PrayerService _prayerService;

  SpiritWorldGame({
    required PlayerService playerService,
    required PrayerService prayerService,
  })  : _playerService = playerService,
        _prayerService = prayerService;

  @override
  Future<void> onLoad() async {
    _log.info('Loading SpiritWorldGame...');
    try {
      final generator = CityGeneratorService();
      _cityGrid = generator.generate(
        GameConstants.defaultSeed,
        GameConstants.gridWidth,
        GameConstants.gridHeight,
      );

      await add(CityRenderComponent(_cityGrid));

      _spiritualOverlay = SpiritualOverlayComponent(
        width: GameConstants.gridWidth,
        height: GameConstants.gridHeight,
      );
      await add(_spiritualOverlay);

      _player = PlayerComponent();
      _player.position = Vector2(100, 100);
      await add(_player);

      _joystick = PlayerJoystickComponent();
      _joystick.position = Vector2(70, size.y - 70);
      await add(_joystick);

      _hud = HudOverlayComponent(_playerService);
      await add(_hud);

      _prayerPulse = PrayerPulseComponent(_prayerService);
      await add(_prayerPulse);

      final npcService = NpcService();
      final npcs =
          npcService.generateNpcs(_cityGrid, GameConstants.defaultSeed);
      for (final npc in npcs) {
        await add(NpcComponent(npc));
      }

      _log.info('SpiritWorldGame loaded successfully.');
    } catch (e, st) {
      ErrorHandler.handle(e, st, context: 'SpiritWorldGame.onLoad');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    try {
      if (!_playerService.state.isInSpiritualWorld) {
        _player.setVelocity(_joystick.direction);
      } else {
        _player.setVelocity(Vector2.zero());
      }

      _prayerService.updatePrayer(dt);
      _prayerPulse.isInSpiritualWorld =
          _playerService.state.isInSpiritualWorld;
      _spiritualOverlay.isVisible = _playerService.state.isInSpiritualWorld;

      _playerService.consumeEnergy(GameConstants.energyCostPerSecond * dt);
      if (_playerService.state.isInSpiritualWorld) {
        _playerService.consumeFocus(GameConstants.focusCostPerSecond * dt);
      }
    } catch (e, st) {
      ErrorHandler.handle(e, st, context: 'SpiritWorldGame.update');
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_playerService.state.isInSpiritualWorld) {
      _prayerService.startPrayer(event.canvasPosition);
    }
  }

  void toggleWorld() {
    _playerService.toggleWorld();
    _joystick.isVisible = !_playerService.state.isInSpiritualWorld;
  }
}
