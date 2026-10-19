import 'package:flame_audio/flame_audio.dart';
import 'package:logging/logging.dart';

/// Short sound effects (release_roadmap.md §3.7, design pillar 1 "every
/// action shows a result"). Kenney CC0 packs, see assets/LICENSES.md.
enum Sfx {
  tap('kenney/interface_sounds/click_002.ogg'),
  denied('kenney/interface_sounds/error_004.ogg'),
  book('kenney/rpg_audio/bookFlip1.ogg'),
  door('kenney/rpg_audio/doorOpen_1.ogg'),
  conversion('kenney/impact_sounds/impactBell_heavy_000.ogg'),
  daemonDefeated('kenney/impact_sounds/impactGlass_light_001.ogg'),
  chain('kenney/impact_sounds/impactGlass_heavy_002.ogg'),
  awakening('kenney/impact_sounds/impactBell_heavy_003.ogg'),
  learned('kenney/interface_sounds/confirmation_002.ogg'),
  dayEnd('kenney/interface_sounds/confirmation_004.ogg');

  /// Path below assets/audio/.
  final String file;
  const Sfx(this.file);
}

/// Plays [Sfx]. Silent when switched off in the pause menu or when the
/// platform cannot play (tests, unsupported codec) – sound must never break
/// the game.
abstract final class GameSound {
  static final _log = Logger('GameSound');

  /// Set from the app settings (MenuService) and the pause-menu toggle.
  static bool enabled = true;

  static bool _failed = false;

  static Future<void> preload() async {
    if (_failed) return;
    try {
      await FlameAudio.audioCache.loadAll([for (final s in Sfx.values) s.file]);
    } catch (e) {
      _failed = true;
      _log.warning('Sound preload failed, sounds off: $e');
    }
  }

  static void play(Sfx sfx, {double volume = 0.6}) {
    if (!enabled || _failed) return;
    _play(sfx, volume);
  }

  static Future<void> _play(Sfx sfx, double volume) async {
    try {
      await FlameAudio.play(sfx.file, volume: volume);
    } catch (e) {
      _log.fine('Sound ${sfx.name} failed: $e');
    }
  }
}
