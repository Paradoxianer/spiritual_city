import 'dart:async';
import 'dart:math';

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
  sleep('actions/sleep.ogg'),
  // Prayer waves, one per mode (🕊️ 🫸 ⏳ 🪫).
  waveLiberation('actions/wave_liberation.ogg'),
  waveRebuke('actions/wave_rebuke.ogg'),
  waveSlow('actions/wave_slow.ogg'),
  waveDrain('actions/wave_drain.ogg'),
  daemonNear('actions/daemon_near.ogg'),
  step0('kenney/rpg_audio/footstep00.ogg'),
  step1('kenney/rpg_audio/footstep01.ogg'),
  step2('kenney/rpg_audio/footstep02.ogg'),
  step3('kenney/rpg_audio/footstep03.ogg'),
  step4('kenney/rpg_audio/footstep04.ogg');

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

  /// Music on/off (🎵), separate from the sounds (playtest 2026-11-22).
  static bool musicOn = true;

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

  /// Sound of a prayer wave of mode [modeId] (PrayerMode.id).
  static void playWave(String modeId) {
    final sfx = switch (modeId) {
      'rebuke' => Sfx.waveRebuke,
      'slow' => Sfx.waveSlow,
      'drain' => Sfx.waveDrain,
      _ => Sfx.waveLiberation,
    };
    play(sfx, volume: 0.55);
  }

  static void play(Sfx sfx, {double volume = 0.6}) {
    if (!enabled || _failed) return;
    _play(sfx, volume);
  }

  /// At most [_perSfx] players per sound, made once and reused. Before,
  /// every sound made a new player that was never freed: after a while
  /// hundreds of them slowed the sound down (the house sound played after
  /// leaving the house), the game stuttered and the phone app crashed
  /// (playtest 2026-11-12).
  static const int _perSfx = 2;
  static final Map<Sfx, List<AudioPlayer>> _players = {};
  static final Set<AudioPlayer> _busy = {};
  static final AudioContext _context =
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build();

  static Future<void> _play(Sfx sfx, double volume) async {
    final list = _players.putIfAbsent(sfx, () => []);
    AudioPlayer? p;
    for (final q in list) {
      if (!_busy.contains(q)) {
        p = q;
        break;
      }
    }
    if (p == null) {
      // Already sounding often enough: drop it rather than pile up.
      if (list.length >= _perSfx) return;
      p = AudioPlayer()..audioCache = FlameAudio.audioCache;
      list.add(p);
      _busy.add(p);
      try {
        await p.setAudioContext(_context);
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setSource(AssetSource(sfx.file));
        p.onPlayerComplete.listen((_) => _busy.remove(p));
      } catch (e) {
        _log.fine('Sound ${sfx.name} failed: $e');
        list.remove(p);
        _busy.remove(p);
        unawaited(p.dispose());
        return;
      }
    }
    final player = p;
    _busy.add(player);
    // Free again even if "complete" never comes.
    Timer(const Duration(seconds: 4), () => _busy.remove(player));
    try {
      await player.stop();
      await player.setVolume(volume);
      await player.resume();
    } catch (e) {
      _busy.remove(player);
      _log.fine('Sound ${sfx.name} failed: $e');
    }
  }
}

/// The pastor's footsteps (playtest 2026-11-22): one step per [stride] of
/// distance walked, so sprinting sounds faster and a tired pastor slower –
/// always another of the Kenney steps, quiet and a little uneven.
abstract final class Footsteps {
  static const List<Sfx> _steps = [Sfx.step0, Sfx.step1, Sfx.step2, Sfx.step3, Sfx.step4];
  static final Random _rng = Random();
  static double _walked = 0;
  static int _last = 0;

  static void walked(double distance, {required double stride}) {
    _walked += distance;
    if (_walked < stride) return;
    _walked = 0;
    var i = _rng.nextInt(_steps.length - 1);
    if (i >= _last) i++;
    _last = i;
    GameSound.play(_steps[i], volume: 0.18 + _rng.nextDouble() * 0.08);
  }
}

/// Looping background sound per place (playtest 2026-10-18). Synthesised by
/// tools/gen_ambience.py, except the church chant and the music of the
/// invisible world (Pixabay, assets/LICENSES.md).
enum Ambience {
  none('', 0),
  city('ambience/city.ogg', 0.2),
  home('ambience/home.ogg', 0.55),
  hall('ambience/hall.ogg', 0.4),
  church('ambience/church.ogg', 0.45),
  // Playtest 2026-11-22: "Epic War" felt like spiritual warfare and fits
  // the battle sounds – a little quieter than in the probe (0.6).
  spirit('music/spirit_battle.ogg', 0.45, long: true, quiet: ('ambience/spirit.ogg', 0.3));

  final String file;
  final double volume;

  /// The sound instead of the music when music is off ([GameSound.musicOn]).
  final (String, double)? quiet;

  /// Music of several minutes: the low-latency player (SoundPool) keeps
  /// only its first seconds and starts over.
  final bool long;
  const Ambience(this.file, this.volume, {this.long = false, this.quiet});
}

/// Plays one [Ambience] at a time and cross-fades on change.
abstract final class GameAmbience {
  static final _log = Logger('GameAmbience');
  static Ambience _current = Ambience.none;
  static AudioPlayer? _player;
  static int _generation = 0;
  static double _fromVolume = 0;
  static bool _failed = false;

  static const Duration _fade = Duration(milliseconds: 1200);

  /// What [a] plays now: its music, or the quiet sound when music is off.
  static (String file, double volume, bool long) _sound(Ambience a) {
    final q = a.quiet;
    if (a.long && !GameSound.musicOn && q != null) return (q.$1, q.$2, false);
    return (a.file, a.volume, a.long);
  }

  /// Music switched on or off: start the current place's sound again.
  static Future<void> refresh() async {
    final a = _current;
    await set(Ambience.none);
    await set(a);
  }

  /// Switches to [a] (cheap no-op when it is already playing).
  static Future<void> set(Ambience a) async {
    if (!GameSound.enabled || _failed) a = Ambience.none;
    if (a == _current) return;
    _current = a;
    final gen = ++_generation;
    final old = _player;
    _player = null;
    if (old != null) _ramp(old, _fromVolume, 0, stopAfter: true);
    if (a == Ambience.none) return;
    try {
      final (file, volume, long) = _sound(a);
      final p = long
          ? await FlameAudio.loopLongAudio(file, volume: 0)
          : await FlameAudio.loop(file, volume: 0);
      if (gen != _generation) {
        await p.dispose();
        return;
      }
      _player = p;
      _fromVolume = volume;
      _ramp(p, 0, volume);
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
