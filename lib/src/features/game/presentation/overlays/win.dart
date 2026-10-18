part of '../game_screen.dart';

class _ConfettiParticle {
  final double x;
  final double startY;
  final double size;
  final double speed;
  final double wobble;
  final double wobbleFreq;
  final Color color;

  const _ConfettiParticle({
    required this.x,
    required this.startY,
    required this.size,
    required this.speed,
    required this.wobble,
    required this.wobbleFreq,
    required this.color,
  });
}

// ── Win Screen ────────────────────────────────────────────────────────────────

/// Full-screen celebration overlay shown when the player has converted all
/// NPCs and liberated all loaded city cells.
/// Driven by [SpiritWorldGame.isWon].
class _WinScreenOverlay extends StatefulWidget {
  final SpiritWorldGame game;
  const _WinScreenOverlay({required this.game});

  @override
  State<_WinScreenOverlay> createState() => _WinScreenOverlayState();
}

class _WinScreenOverlayState extends State<_WinScreenOverlay> with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _confettiCtrl;
  late final Animation<double> _fadeAnim;

  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    widget.game.isWon.addListener(_onWin);
  }

  void _onWin() {
    if (!mounted || !widget.game.isWon.value) return;
    setState(() => _visible = true);
    _fadeCtrl.forward(from: 0.0);
    _confettiCtrl.repeat();
  }

  @override
  void dispose() {
    widget.game.isWon.removeListener(_onWin);
    _fadeCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  /// Formats a [Duration] as "X m Y s" (or just "Y s" for < 60 s).
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (minutes == 0) return '${seconds}s';
    return '${minutes}min ${seconds}s';
  }

  /// Starts a brand-new game with the same difficulty.
  Future<void> _startNewGame(BuildContext context) async {
    final game = widget.game;
    final difficulty = game.difficulty;
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final prefix = AppStrings.get('game.saveName.prefix');
    final name = '$prefix $day.$month.${now.year}';
    final save = GameSave(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: now,
      difficulty: difficulty,
      seed: now.millisecondsSinceEpoch,
    );
    await getIt<MenuService>().writeSave(save);
    if (context.mounted) context.go('/game', extra: save);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final game = widget.game;
    // Issue #170: merged live+saved counts so the ratio is consistent
    // (converted never exceeds total) and doesn't regress after a load.
    final npcCounts = game.knownNpcCounts;
    final convertedCount = npcCounts.converted;
    final totalNpcs = npcCounts.total;

    int totalCells = 0;
    int positiveCells = 0;
    for (final chunk in game.grid.getLoadedChunks()) {
      for (final cell in chunk.cells.values) {
        totalCells++;
        if (cell.spiritualState > 0) positiveCells++;
      }
    }

    final playTime = _formatDuration(game.sessionPlayTime);
    final faithCollected = game.progress.faithStage.totalAccumulated.round();

    return FadeTransition(
      opacity: _fadeAnim,
      child: Stack(
        children: [
          // Dark gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A1628),
                  Color(0xFF0D2240),
                  Color(0xFF0A1628),
                ],
              ),
            ),
          ),
          // Confetti layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (context, _) => CustomPaint(
                painter: _WinConfettiPainter(_confettiCtrl.value),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cross / celebration emoji
                    const Text('✝️', style: TextStyle(fontSize: 72)),
                    const SizedBox(height: 12),
                    // Main heading
                    // Emoji only (no text to translate).
                    const Text(
                      '🏙️✝️🙌',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '🕊️ 🎉 🕊️',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26),
                    ),
                    const SizedBox(height: 32),
                    // Stats card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _WinStatRow(
                            emoji: '✝️',
                            label: '',
                            value: '$convertedCount / $totalNpcs',
                          ),
                          const SizedBox(height: 10),
                          _WinStatRow(
                            emoji: '🟢',
                            label: '',
                            value: '$positiveCells / $totalCells',
                          ),
                          const SizedBox(height: 10),
                          _WinStatRow(
                            emoji: '⏱️',
                            label: '',
                            value: playTime,
                          ),
                          const SizedBox(height: 10),
                          _WinStatRow(
                            emoji: '✨',
                            label: '',
                            value: '$faithCollected',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _startNewGame(context),
                        icon: const Text('🔄', style: TextStyle(fontSize: 18)),
                        label: const Text('▶️'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/menu'),
                        icon: const Text('🏠', style: TextStyle(fontSize: 18)),
                        label: const Text('☰'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single statistics row on the win screen.
class _WinStatRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _WinStatRow({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Confetti painter for the win screen.  Uses a different seed and more
/// "divine" color palette for the celebration.
class _WinConfettiPainter extends CustomPainter {
  final double progress;

  static final List<_ConfettiParticle> _particles = _generateParticles();

  static List<_ConfettiParticle> _generateParticles() {
    final rng = Random(137);
    return List.generate(
        80,
        (_) => _ConfettiParticle(
              x: rng.nextDouble(),
              startY: -rng.nextDouble() * 0.5,
              size: 4.0 + rng.nextDouble() * 9.0,
              speed: 0.3 + rng.nextDouble() * 0.6,
              wobble: rng.nextDouble() * 2 * pi,
              wobbleFreq: 1.5 + rng.nextDouble() * 3.5,
              color: _winColors[rng.nextInt(_winColors.length)],
            ));
  }

  static const _winColors = [
    Color(0xFFFFD700), // gold
    Color(0xFFFFFFFF), // white
    Color(0xFF90EE90), // light green
    Color(0xFF00E5FF), // cyan
    Color(0xFFFFF176), // yellow
    Color(0xFFB2EBF2), // light blue
    Color(0xFFA5D6A7), // mint
  ];

  const _WinConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    int idx = 0;
    for (final p in _particles) {
      final t = ((progress * p.speed) % 1.0).clamp(0.0, 1.0);
      final y = (p.startY + t) * size.height;
      if (y < 0 || y > size.height) {
        idx++;
        continue;
      }
      final wobbleX = sin(t * p.wobbleFreq * pi + p.wobble) * 28.0;
      final x = p.x * size.width + wobbleX;
      final alpha = (1.0 - t * 0.7).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      // Alternate between circles and small crosses for a divine touch.
      if (idx % 4 == 0) {
        // Draw a tiny cross ✝ shape
        final cx = Offset(x, y);
        final arm = p.size * (1.0 - t * 0.3);
        canvas.drawRect(
          Rect.fromCenter(center: cx, width: arm * 0.4, height: arm),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx.dx, cx.dy - arm * 0.15),
            width: arm,
            height: arm * 0.4,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset(x, y), p.size * (1.0 - t * 0.4), paint);
      }
      idx++;
    }
  }

  @override
  bool shouldRepaint(_WinConfettiPainter old) => old.progress != progress;
}
