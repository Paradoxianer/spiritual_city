import 'dart:math' as math;
import 'dart:ui';

/// Lightweight sparkle-particle system for positive (green) territory zones.
///
/// Each [SpiritualRenderer] owns one instance. Particles live in the local
/// coordinate space of their parent chunk (Johannes 3,8 – the Spirit moves).
class ParticleService {
  final List<_Particle> _particles = [];
  final math.Random _rng;

  /// Hard cap to prevent unbounded growth.
  static const int maxParticles = 300;

  final Paint _paint = Paint()..blendMode = BlendMode.screen;

  ParticleService({int seed = 0}) : _rng = math.Random(seed);

  int get particleCount => _particles.length;

  /// Spawns a sparkle near ([localX], [localY]) (chunk-local coordinates).
  void spawnSparkle(double localX, double localY) {
    if (_particles.length >= maxParticles) return;

    final dx = (_rng.nextDouble() - 0.5) * 16;
    final dy = (_rng.nextDouble() - 0.5) * 16;
    final vx = (_rng.nextDouble() - 0.5) * 20;
    final vy = -15.0 - _rng.nextDouble() * 25; // drift upward (rising light)
    final lifetime = 0.4 + _rng.nextDouble() * 0.8;

    _particles.add(_Particle(
      x: localX + dx,
      y: localY + dy,
      vx: vx,
      vy: vy,
      lifetime: lifetime,
      maxLifetime: lifetime,
    ));
  }

  /// Advances all particles and removes dead ones.
  void update(double dt) {
    _particles.removeWhere((p) => p.lifetime <= 0);
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.lifetime -= dt;
    }
  }

  /// Renders all live particles onto [canvas] using additive blending.
  void render(Canvas canvas) {
    if (_particles.isEmpty) return;

    for (final p in _particles) {
      final progress = (p.lifetime / p.maxLifetime).clamp(0.0, 1.0);
      final alpha = progress * 0.78; // fade to transparent
      final radius = 1.5 + progress * 2.0;
      _paint.color = const Color(0xFFFFFF99).withValues(alpha: alpha);
      canvas.drawCircle(Offset(p.x, p.y), radius, _paint);
    }
  }
}

class _Particle {
  double x, y;
  final double vx, vy;
  double lifetime;
  final double maxLifetime;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.lifetime,
    required this.maxLifetime,
  });
}
