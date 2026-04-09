import 'package:flame/components.dart';
import '../entities/prayer_pulse.dart';
import '../../../player/domain/services/player_service.dart';
import '../../../../core/constants/game_constants.dart';

class PrayerService {
  PrayerPulse? _currentPulse;
  final PlayerService _playerService;

  PrayerService(this._playerService);

  PrayerPulse? get currentPulse => _currentPulse;

  void startPrayer(Vector2 worldPosition) {
    _playerService.consumeFocus(GameConstants.prayerFocusCost);
    _currentPulse = PrayerPulse(
      position: worldPosition.clone(),
      radius: 0.0,
      maxRadius: GameConstants.prayerMaxRadius,
      isActive: true,
    );
  }

  void updatePrayer(double dt) {
    final pulse = _currentPulse;
    if (pulse == null || !pulse.isActive) return;
    final newRadius = pulse.radius + GameConstants.prayerPulseSpeed * dt;
    if (newRadius >= pulse.maxRadius) {
      _currentPulse = pulse.copyWith(radius: pulse.maxRadius, isActive: false);
    } else {
      _currentPulse = pulse.copyWith(radius: newRadius);
    }
    _playerService.consumeFocus(GameConstants.prayerFocusCost * dt);
  }

  void endPrayer() {
    _currentPulse = _currentPulse?.copyWith(isActive: false);
  }
}
