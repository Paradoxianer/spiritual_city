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
  late final AnimationController _story;
  late final AnimationController _confettiCtrl;

  bool _visible = false;

  /// The victory unfolds (playtest 2026-11-21: "make it epic"): the light
  /// breaks through, the officer steps up and speaks, the numbers count up,
  /// and last the bridge. A tap skips to the end.
  static const Duration _storyLength = Duration(seconds: 14);

  @override
  void initState() {
    super.initState();
    _story = AnimationController(vsync: this, duration: _storyLength);
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    widget.game.isWon.addListener(_onWin);
  }

  void _onWin() {
    if (!mounted || !widget.game.isWon.value) return;
    setState(() => _visible = true);
    Narrator.close(); // the officer speaks now
    GameSound.play(Sfx.awakening);
    _story.forward(from: 0.0);
    _confettiCtrl.repeat();
    Future.delayed(_storyLength * 0.14, () {
      if (mounted) GameSound.play(Sfx.conversion, volume: 0.8);
    });
  }

  @override
  void dispose() {
    widget.game.isWon.removeListener(_onWin);
    _story.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  /// 0 → 1 while the story is between [from] and [to].
  double _phase(double from, double to, [Curve curve = Curves.easeOut]) =>
      curve.transform(((_story.value - from) / (to - from)).clamp(0.0, 1.0));

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
      citySize: CityLayout.current.size, // the same size again
    );
    await getIt<MenuService>().writeSave(save);
    if (context.mounted) context.go('/game', extra: save);
  }

  /// 🌉 Over the bridge into the next, bigger city: the pastor comes
  /// along, the city stays behind (playtest 2026-11-21).
  Future<void> _crossBridge(BuildContext context) async {
    final game = widget.game;
    final now = DateTime.now();
    final next = CityCrossing.next(CityLayout.current.size);
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final prefix = AppStrings.get('game.saveName.prefix');
    final seed = now.millisecondsSinceEpoch;
    final save = GameSave(
      id: now.millisecondsSinceEpoch.toString(),
      name: '$prefix $day.$month.${now.year} ${next.emoji}',
      createdAt: now,
      difficulty: game.difficulty,
      seed: seed,
      citySize: next,
      gameState: CityCrossing.startState(game.progress.toJson(),
          schemaVersion: SpiritWorldGame.kSaveDataVersion, worldSeed: seed),
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
    final p = game.progress;
    final quarters = CityLayout.current.quarters.length;
    final speech = HelpContent.toasts['victory']?.text ?? '';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // A tap skips the story; the buttons work once they are there.
      onTap: () {
        if (_story.value < 1) _story.value = 1;
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_story, _confettiCtrl]),
        builder: (context, _) {
          final light = _phase(0.0, 0.16);
          final officer = _phase(0.10, 0.22, Curves.elasticOut);
          final bubble = _phase(0.20, 0.24);
          final typed = (speech.length * _phase(0.22, 0.62, Curves.linear)).round();
          final count = _phase(0.60, 0.78, Curves.easeOutCubic);
          final stats = _phase(0.58, 0.64);
          final buttons = _phase(0.76, 0.86);
          int up(int n) => (n * count).round();
          return Stack(
            children: [
              // The city behind fades into the night sky, then the light
              // breaks through from the middle.
              Positioned.fill(
                child: Opacity(
                  opacity: light,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF0A1628), Color(0xFF0D2240), Color(0xFF0A1628)],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _GloryPainter(light: light, turn: _confettiCtrl.value),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: light,
                  child: CustomPaint(painter: _WinConfettiPainter(_confettiCtrl.value)),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // The Salvation Army officer, big and in pixels.
                          Transform.scale(
                            scale: officer,
                            child: Image.asset(
                              officerFigure,
                              width: 176,
                              height: 176,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Opacity(
                            opacity: officer.clamp(0.0, 1.0),
                            child: const Text('🏙️✝️🙌  🕊️🎉🕊️', style: TextStyle(fontSize: 26)),
                          ),
                          const SizedBox(height: 14),
                          // His words in the narrator's style, letter by letter.
                          Opacity(
                            opacity: bubble,
                            child: _VictorySpeech(
                              text: TextMode.on ? speech.substring(0, typed.clamp(0, speech.length)) : null,
                              full: speech,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Opacity(
                            opacity: stats,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xCC0A1628),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                children: [
                                  _WinStatRow(
                                      emoji: '✝️',
                                      label: '',
                                      value: '${up(npcCounts.converted)} / ${npcCounts.total}'),
                                  const SizedBox(height: 8),
                                  _WinStatRow(emoji: '⛪👥', label: '', value: '${up(p.church.members.length)}'),
                                  const SizedBox(height: 8),
                                  _WinStatRow(emoji: '🏘️✝️', label: '', value: '${up(quarters)} / $quarters'),
                                  const SizedBox(height: 8),
                                  _WinStatRow(emoji: '🙏⚔️', label: '', value: '${up(p.prayerCombatsCompleted)}'),
                                  const SizedBox(height: 8),
                                  _WinStatRow(emoji: '📅', label: '', value: '${up(p.dayStats.day)}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          IgnorePointer(
                            ignoring: buttons < 1,
                            child: Opacity(
                              opacity: buttons,
                              child: Column(
                                children: [
                                  // 🌉 On to the next, bigger city – with the pastor.
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _crossBridge(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFB300),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text('🌉 ➡️ ${CityCrossing.next(CityLayout.current.size).emoji}',
                                          style: const TextStyle(fontSize: 26)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _startNewGame(context),
                                          style: _smallButton,
                                          child: const Text('🔄 ▶️', style: TextStyle(fontSize: 18)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          // Share the victory (the picture is this screen).
                                          onPressed: () => ShareProgress.share(game,
                                                  shot: context.findAncestorStateOfType<_GameScreenState>()?._shotKey)
                                              .catchError((_) {}),
                                          style: _smallButton,
                                          child: Icon(Icons.adaptive.share, color: Colors.amber),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => context.go('/menu'),
                                          style: _smallButton,
                                          child: const Text('🏠 ☰', style: TextStyle(fontSize: 18)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Text('Soli Deo Gloria',
                                      style: TextStyle(
                                          color: Colors.amber.withValues(alpha: 0.7),
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                          letterSpacing: 1.5)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static final ButtonStyle _smallButton = OutlinedButton.styleFrom(
    foregroundColor: Colors.white70,
    backgroundColor: const Color(0xCC0A1628),
    side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

/// The officer's words in a speech bubble – the narrator's style. Without
/// text mode only emoji ([text] is null); the bubble keeps the size of the
/// [full] text while it is being typed, so nothing jumps.
class _VictorySpeech extends StatelessWidget {
  final String? text;
  final String full;
  const _VictorySpeech({required this.text, required this.full});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Color(0xFF1B1B1B), fontSize: 16, height: 1.35);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB300), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x88FFC107), blurRadius: 24)],
      ),
      child: text == null
          ? const Text('👏✝️  🏙️🌟  ➡️ 🌉', textAlign: TextAlign.center, style: TextStyle(fontSize: 28))
          : Stack(
              children: [
                Opacity(opacity: 0, child: Text(full, style: style)),
                Text(text!, style: style),
              ],
            ),
    );
  }
}

/// Light breaking through: a golden glow from the middle with slowly
/// turning rays behind the officer.
class _GloryPainter extends CustomPainter {
  final double light;
  final double turn;
  const _GloryPainter({required this.light, required this.turn});

  @override
  void paint(Canvas canvas, Size size) {
    if (light <= 0) return;
    final c = Offset(size.width / 2, size.height * 0.24);
    final reach = size.longestSide * (0.2 + 0.9 * light);
    canvas.drawCircle(
      c,
      reach,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFE082).withValues(alpha: 0.55 * light),
          const Color(0xFFFFC107).withValues(alpha: 0.15 * light),
          const Color(0x00FFC107),
        ], stops: const [0.0, 0.35, 1.0])
            .createShader(Rect.fromCircle(center: c, radius: reach)),
    );
    final ray = Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.07 * light);
    const n = 14;
    for (var i = 0; i < n; i++) {
      final a = (i / n + turn / n) * 2 * pi;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + cos(a - 0.07) * reach, c.dy + sin(a - 0.07) * reach)
        ..lineTo(c.dx + cos(a + 0.07) * reach, c.dy + sin(a + 0.07) * reach)
        ..close();
      canvas.drawPath(path, ray);
    }
  }

  @override
  bool shouldRepaint(_GloryPainter old) => old.light != light || old.turn != turn;
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
