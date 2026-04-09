import 'package:flame/game.dart';
import 'package:logging/logging.dart';

class SpiritWorldGame extends FlameGame {
  final _log = Logger('SpiritWorldGame');

  @override
  Future<void> onLoad() async {
    _log.info('Loading SpiritWorldGame...');
    // Initial load logic here
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Game logic updates
  }
}
