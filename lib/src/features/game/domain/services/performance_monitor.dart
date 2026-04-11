import 'package:logging/logging.dart';

/// Lightweight frame-rate and metric tracker used during development and
/// debugging.  Attach it to the game loop by calling [startFrame] at the
/// beginning of every [update] call and [endFrame] at the end.
///
/// Metrics are logged at [logInterval] real seconds.  Set [lowFpsThreshold]
/// to receive a [Logger.warning] whenever the instantaneous FPS drops below
/// that value.
class PerformanceMonitor {
  static final _log = Logger('PerformanceMonitor');

  final double lowFpsThreshold;
  final double logInterval;

  // Internal state
  final Stopwatch _frameStopwatch = Stopwatch();
  double _elapsedSinceLog = 0.0;
  int _frameCount = 0;
  double _currentFps = 60.0;
  int _activeNPCCount = 0;
  int _loadedChunkCount = 0;

  PerformanceMonitor({
    this.lowFpsThreshold = 55.0,
    this.logInterval = 5.0,
  });

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Call at the very start of a game update tick.
  void startFrame() {
    _frameStopwatch
      ..reset()
      ..start();
  }

  /// Call at the very end of a game update tick.  [dt] is the delta-time in
  /// seconds that was passed to [update].
  void endFrame(double dt) {
    _frameStopwatch.stop();
    _frameCount++;
    _elapsedSinceLog += dt;

    final frameMs = _frameStopwatch.elapsedMicroseconds / 1000.0;
    if (frameMs > 0) {
      _currentFps = 1000.0 / frameMs;
    }

    if (_currentFps < lowFpsThreshold) {
      _log.warning(
          'Low FPS: ${_currentFps.toStringAsFixed(1)} '
          '(frame: ${frameMs.toStringAsFixed(2)} ms)');
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

  /// Most-recently measured frames per second.
  double get currentFps => _currentFps;

  // ─── Private ───────────────────────────────────────────────────────────────

  void _logMetrics() {
    _log.info(
      'Performance | FPS: ${_currentFps.toStringAsFixed(1)} '
      '| Active NPCs: $_activeNPCCount '
      '| Loaded Chunks: $_loadedChunkCount',
    );
  }
}
