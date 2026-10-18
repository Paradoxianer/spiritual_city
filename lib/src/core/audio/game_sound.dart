import 'dart:async';

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
  dayEnd('kenney/interface_sounds/confirmation_004.ogg'),
  // Synthesised by tools/gen_ambience.py (playtest 2026-10-18).
  talk('actions/talk.ogg'),
  pray('actions/pray.ogg'),
  sleep('actions/sleep.ogg');

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

  /// The sound of a finished action: 😴 sleeping, 🙏 prayer and worship,
  /// 💬 talking and 👂 listening, 📖 reading.
  static void playAction(String actionType, String? disciplineName) {
    if (actionType == 'sleep') return play(Sfx.sleep, volume: 0.6);
    switch (disciplineName) {
      case 'prayer' || 'worship':
        play(Sfx.pray, volume: 0.5);
      case 'conversation' || 'counsel':
        play(Sfx.talk, volume: 0.6);
      case 'bible':
        play(Sfx.book, volume: 0.6);
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

/// Looping background sound per place (playtest 2026-10-18). Synthesised by
/// tools/gen_ambience.py, so no licence questions.
enum Ambience {
  none('', 0),
  city('ambience/city.ogg', 0.35),
  home('ambience/home.ogg', 0.55),
  hall('ambience/hall.ogg', 0.4),
  church('ambience/church.ogg', 0.35),
  spirit('ambience/spirit.ogg', 0.3);

  final String file;
  final double volume;
  const Ambience(this.file, this.volume);
}

/// Plays one [Ambience] at a time and cross-fades on change.
abstract final class GameAmbience {
  static final _log = Logger('GameAmbience');
  static Ambience _current = Ambience.none;
  static AudioPlayer? _player;
  static int _generation = 0;
  static bool _failed = false;

  static const Duration _fade = Duration(milliseconds: 1200);

  /// Switches to [a] (cheap no-op when it is already playing).
  static Future<void> set(Ambience a) async {
    if (!GameSound.enabled || _failed) a = Ambience.none;
    if (a == _current) return;
    final from = _current;
    _current = a;
    final gen = ++_generation;
    final old = _player;
    _player = null;
    if (old != null) _ramp(old, from.volume, 0, stopAfter: true);
    if (a == Ambience.none) return;
    try {
      final p = await FlameAudio.loop(a.file, volume: 0);
      if (gen != _generation) {
        await p.dispose();
        return;
      }
      _player = p;
      _ramp(p, 0, a.volume);
    } catch (e) {
      _failed = true;
      _log.warning('Ambience failed, off: $e');
    }
  }

  static void stop() => set(Ambience.none);

  static void _ramp(AudioPlayer p, double from, double to, {bool stopAfter = false}) {
    const steps = 20;
    var i = 0;
    Timer.periodic(_fade ~/ steps, (timer) async {
      i++;
      try {
        await p.setVolume(from + (to - from) * (i / steps));
        if (i >= steps) {
          timer.cancel();
          if (stopAfter) await p.dispose();
        }
      } catch (_) {
        timer.cancel();
      }
    });
  }
}
