import 'package:logging/logging.dart';

/// Lightweight frame-rate and metric tracker used during development and
/// debugging.  Attach it to the game loop by calling [startFrame] at the
/// beginning of every [update] call and [endFrame] at the end.
///
/// Metrics are logged at [logInterval] real seconds at [Level.FINE] so they
/// are hidden at the default [Level.CONFIG] and only appear when the developer
/// explicitly lowers the log level.  Set [lowFpsThreshold] to receive a
/// [Logger.warning] when sustained FPS is low; warnings are throttled to at
/// most once per [_warnCooldown] seconds to avoid log spam.
class PerformanceMonitor {
  static final _log = Logger('PerformanceMonitor');

  final double lowFpsThreshold;
  final double logInterval;

  // Internal state
  double _elapsedSinceLog = 0.0;
  int _frameCount = 0;

  /// Most-recently measured frames per second (1 / dt from the game loop).
  double _currentFps = 60.0;

  /// Smoothed FPS (exponential moving average) – less noisy for display.
  double _smoothFps = 60.0;
  static const double _smoothAlpha = 0.1; // 0 = infinite lag, 1 = instant

  int _activeNPCCount = 0;
  int _loadedChunkCount = 0;

  /// How many seconds must pass before another low-FPS warning is emitted.
  static const double _warnCooldown = 10.0;
  double _timeSinceLastWarn = _warnCooldown; // ready to warn immediately

  PerformanceMonitor({
    this.lowFpsThreshold = 30.0,
    this.logInterval = 30.0,
  });

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Called at the very start of a game update tick.
  /// Previously used a Stopwatch to measure update() duration – which only
  /// measured the logic time (e.g. 0.4 ms → 2500 "fps"), NOT the real rendered
  /// frame rate.  Nothing needs to happen here now; the method is kept only
  /// for API compatibility with existing call sites.
  @Deprecated(
    'startFrame() is a no-op since FPS is now derived from the game-loop dt. '
    'Remove call sites at your convenience.',
  )
  void startFrame() {}

  /// Call at the very end of a game update tick.  [dt] is the delta-time in
  /// seconds that was passed to [update] by the Flame game loop.
  ///
  /// Using [dt] (= time since the PREVIOUS FRAME) gives the true rendered FPS,
  /// including render time, widget overhead, and vsync jank.
  void endFrame(double dt) {
    if (dt <= 0) return;

    _frameCount++;
    _elapsedSinceLog += dt;
    _timeSinceLastWarn += dt;

    // Instantaneous FPS from game-loop delta (real rendered frame rate).
    _currentFps = 1.0 / dt;

    // Smoothed FPS for stable display / warning decisions.
    _smoothFps = _smoothFps * (1.0 - _smoothAlpha) + _currentFps * _smoothAlpha;

    if (_smoothFps < lowFpsThreshold && _timeSinceLastWarn >= _warnCooldown) {
      _timeSinceLastWarn = 0.0;
      _log.warning(
        'Low FPS: ${_smoothFps.toStringAsFixed(1)} '
        '(dt: ${(dt * 1000).toStringAsFixed(2)} ms)',
      );
    }

    if (_elapsedSinceLog >= logInterval) {
      _logMetrics();
      _elapsedSinceLog = 0.0;
      _frameCount = 0;
    }
  }

  /// Update the NPC / chunk counters so they appear in the periodic log.
  void updateCounters({int activeNPCs = 0, int loadedChunks = 0}) {
    _activeNPCCount = activeNPCs;
    _loadedChunkCount = loadedChunks;
  }

  // ─── Accessors ─────────────────────────────────────────────────────────────

  /// Most-recently measured frames per second (instantaneous, from game-loop dt).
  double get currentFps => _currentFps;

  /// Exponentially-smoothed frames per second (more stable for UI display).
  double get smoothFps => _smoothFps;

  // ─── Private ───────────────────────────────────────────────────────────────

  void _logMetrics() {
    final avgFps = _elapsedSinceLog > 0 ? _frameCount / _elapsedSinceLog : 0.0;
    // Use FINE so this only appears when the developer explicitly enables it.
    _log.fine(
      'Performance | avgFPS: ${avgFps.toStringAsFixed(1)} '
      '| smoothFPS: ${_smoothFps.toStringAsFixed(1)} '
      '| Active NPCs: $_activeNPCCount '
      '| Loaded Chunks: $_loadedChunkCount',
    );
  }
}
