part of '../game_screen.dart';

/// Persistent top-center label showing the current street / address.
/// Only visible when there is a street name to display.
class _StreetLabel extends StatelessWidget {
  final SpiritWorldGame game;
  const _StreetLabel({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: game.currentStreetLabel,
      builder: (context, label, _) {
        if (label.isEmpty) return const SizedBox.shrink();
        return Positioned(
          top: 14,
          left: 60,
          right: 60,
          child: SafeArea(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Loot Pickup Toast ─────────────────────────────────────────────────────────

/// Brief bottom-center toast shown when the player auto-collects a material
/// package on the street.  It fades in, stays for 2 s, then fades out.
/// Tapping it (or any key that fires a tap) dismisses it immediately.
class _LootToast extends StatefulWidget {
  final SpiritWorldGame game;
  const _LootToast({required this.game});

  @override
  State<_LootToast> createState() => _LootToastState();
}

class _LootToastState extends State<_LootToast> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  Timer? _dismissTimer;
  String? _message;

  static const Duration _fadeDuration = Duration(milliseconds: 250);
  static const Duration _visibleDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _fadeDuration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    widget.game.lootPickupMessage.addListener(_onMessage);
  }

  void _onMessage() {
    final msg = widget.game.lootPickupMessage.value;
    if (msg == null || !mounted) return;
    _dismissTimer?.cancel();
    setState(() => _message = msg);
    _ctrl.forward(from: 0.0);
    _dismissTimer = Timer(_visibleDuration, _dismiss);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _ctrl.reverse().then((_) {
      if (mounted) {
        widget.game.lootPickupMessage.value = null;
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    widget.game.lootPickupMessage.removeListener(_onMessage);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_message == null) return const SizedBox.shrink();
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xCC1B2A1B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 8),
                ],
              ),
              child: Text(
                _message!,
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Brief centre toast shown when the player completes a mission.  Uses the
/// same fade-in/out animation pattern as [_LootToast].
class _MissionCompleteToast extends StatefulWidget {
  final SpiritWorldGame game;
  const _MissionCompleteToast({required this.game});

  @override
  State<_MissionCompleteToast> createState() => _MissionCompleteToastState();
}

class _MissionCompleteToastState extends State<_MissionCompleteToast> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  Timer? _dismissTimer;
  String? _message;

  static const Duration _fadeDuration = Duration(milliseconds: 300);
  static const Duration _visibleDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _fadeDuration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    widget.game.missionCompleteMessage.addListener(_onMessage);
  }

  void _onMessage() {
    final msg = widget.game.missionCompleteMessage.value;
    if (msg == null || !mounted) return;
    _dismissTimer?.cancel();
    setState(() => _message = msg);
    _ctrl.forward(from: 0.0);
    _dismissTimer = Timer(_visibleDuration, _dismiss);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _ctrl.reverse().then((_) {
      if (mounted) {
        widget.game.missionCompleteMessage.value = null;
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    widget.game.missionCompleteMessage.removeListener(_onMessage);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_message == null) return const SizedBox.shrink();
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.35,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xCC0D2C0D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 10),
                ],
              ),
              child: Text(
                _message!,
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Health alarm overlay ──────────────────────────────────────────────────────

/// Pulsing red gradient at the screen edges when health is critically low.
/// Invisible when health is at or above [SpiritWorldGame.healthAlarmThreshold].
class _HealthAlarmOverlay extends StatefulWidget {
  final SpiritWorldGame game;
  const _HealthAlarmOverlay({required this.game});

  @override
  State<_HealthAlarmOverlay> createState() => _HealthAlarmOverlayState();
}

class _HealthAlarmOverlayState extends State<_HealthAlarmOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.game.healthNotifier,
      builder: (context, health, _) {
        final pct = health / widget.game.progress.maxHealth;
        if (pct >= SpiritWorldGame.healthAlarmThreshold) {
          return const SizedBox.shrink();
        }
        // Stronger pulse when very close to fainting
        final severity = (1.0 - pct / SpiritWorldGame.healthAlarmThreshold).clamp(0.0, 1.0);
        return AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, _) {
            final alpha = ((0.25 + _pulseAnim.value * 0.40) * severity).clamp(0.0, 1.0);
            return IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.4,
                    colors: [
                      Colors.transparent,
                      Colors.red.withValues(alpha: alpha),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Faint overlay ─────────────────────────────────────────────────────────────

/// Full-screen blackout animation played when the player faints.
/// Driven by [SpiritWorldGame.isFainting].
class _FaintOverlay extends StatefulWidget {
  final SpiritWorldGame game;
  const _FaintOverlay({required this.game});

  @override
  State<_FaintOverlay> createState() => _FaintOverlayState();
}

class _FaintOverlayState extends State<_FaintOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    widget.game.isFainting.addListener(_onFaintChanged);
  }

  void _onFaintChanged() {
    if (!mounted) return;
    if (widget.game.isFainting.value) {
      _ctrl.forward(from: 0.0);
    } else {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    widget.game.isFainting.removeListener(_onFaintChanged);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        // When the animation is completely at 0, skip hit-testing entirely so
        // the invisible overlay does not block taps on dialogs beneath it.
        return IgnorePointer(
          ignoring: _ctrl.value == 0.0,
          child: FadeTransition(
            opacity: _opacity,
            child: Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('💫', style: TextStyle(fontSize: 52)),
                    SizedBox(height: 16),
                    Text('😵 ➡️ 🏥', style: TextStyle(fontSize: 28)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Wakeup toast ──────────────────────────────────────────────────────────────

/// Toast shown when the player wakes up after fainting, informing them that
/// the darkness has returned near the faint location.
class _WakeupToast extends StatefulWidget {
  final SpiritWorldGame game;
  const _WakeupToast({required this.game});

  @override
  State<_WakeupToast> createState() => _WakeupToastState();
}

class _WakeupToastState extends State<_WakeupToast> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  Timer? _dismissTimer;
  String? _message;

  static const Duration _fadeDuration = Duration(milliseconds: 400);
  static const Duration _visibleDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _fadeDuration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    widget.game.wakeupMessage.addListener(_onMessage);
  }

  void _onMessage() {
    final msg = widget.game.wakeupMessage.value;
    if (msg == null || !mounted) return;
    _dismissTimer?.cancel();
    setState(() => _message = msg);
    _ctrl.forward(from: 0.0);
    _dismissTimer = Timer(_visibleDuration, _dismiss);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    _ctrl.reverse().then((_) {
      if (mounted) widget.game.wakeupMessage.value = null;
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    widget.game.wakeupMessage.removeListener(_onMessage);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_message == null) return const SizedBox.shrink();
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.30,
      left: 24,
      right: 24,
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xDD1A0A0A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black87, blurRadius: 12),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('😔', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red[200],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Look Overlay ──────────────────────────────────────────────────────────────

/// Shows a golden 🏠 icon + direction arrow at a fixed position below the
/// resource-bar panel.  Always visible as long as the player is more than
/// 64 px (≈ 2 cells) away from the pastor house.
class _PastorhouseHud extends StatelessWidget {
  final SpiritWorldGame game;
  const _PastorhouseHud({required this.game});

  @override
  Widget build(BuildContext context) {
    // Rebuild whenever the player moves (playerWorldPosition updates every frame
    // via game.update()) so the compass direction is always current.
    return ValueListenableBuilder<Vector2>(
      valueListenable: game.playerWorldPosition,
      builder: (context, playerPx, _) {
        final housePx = game.pastorhousePosition.value;
        if (housePx == null) return const SizedBox.shrink();

        final dx = housePx.x - playerPx.x;
        final dy = housePx.y - playerPx.y;
        final distSq = dx * dx + dy * dy;
        // Hide only when the player is almost on top of the pastor house
        // (within 64 px ≈ 2 cells).
        if (distSq < 64 * 64) return const SizedBox.shrink();

        final angleDeg = atan2(dy, dx) * 180 / pi;
        final arrow = _directionArrow(angleDeg);

        // A small top margin separates the compass from the resource bar panel.
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏠', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  arrow,
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

/// Arrow for an angle in degrees (screen space, y down).
/// Uses screen-space atan2 where Y grows downward:
///   0°=→  90°=↓  ±180°=←  −90°=↑
String _directionArrow(double deg) {
  if (deg < -157.5 || deg >= 157.5) return '←';
  if (deg < -112.5) return '↖';
  if (deg < -67.5) return '↑';
  if (deg < -22.5) return '↗';
  if (deg < 22.5) return '→';
  if (deg < 67.5) return '↘';
  if (deg < 112.5) return '↓';
  return '↙';
}

/// 📍 Arrow to the accepted mission's target (playtest 2026-10-18).
class _TrackedMissionHud extends StatelessWidget {
  final SpiritWorldGame game;
  const _TrackedMissionHud({required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: game.trackedMission,
      builder: (context, key, _) {
        if (key == null) return const SizedBox.shrink();
        return ValueListenableBuilder<Vector2>(
          valueListenable: game.playerWorldPosition,
          builder: (context, me, _) {
            final t = game.trackedTargetPosition;
            if (t == null) return const SizedBox.shrink();
            final dx = t.x - me.x, dy = t.y - me.y;
            final near = dx * dx + dy * dy < 64 * 64;
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.8)),
                ),
                child: Text(
                  near ? '📍 ✅' : '📍 ${_directionArrow(atan2(dy, dx) * 180 / pi)}',
                  style: const TextStyle(color: Color(0xFFFFC107), fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Resource HUD (Flutter overlay) ──────────────────────────────────────────

/// Flutter-based resource-bar panel positioned at the top-left of the screen.
///
/// Using Flutter widgets (rather than a Flame component) ensures the bars
/// update immediately after every action – even while the Flame game loop is
/// paused (e.g. when a building or dialog overlay is open).
class _ResourceHud extends StatelessWidget {
  final SpiritWorldGame gameRef;
  const _ResourceHud({required this.gameRef});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Keep padding tight so the panel stays compact and leaves room for
      // the compass that is rendered directly below it in the column.
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListenableBuilder(
        listenable: gameRef.progress,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedResourceBar(
                notifier: gameRef.healthNotifier,
                stage: gameRef.progress.healthStage,
                max: gameRef.progress.maxHealth,
                icon: '❤️',
                label: AppStrings.get('resource.health'),
                color: Colors.redAccent,
                criticalThreshold: SpiritWorldGame.healthAlarmThreshold,
              ),
              const SizedBox(height: 2),
              _AnimatedResourceBar(
                notifier: gameRef.hungerNotifier,
                stage: gameRef.progress.hungerStage,
                max: gameRef.progress.maxHunger,
                icon: '🍞',
                label: AppStrings.get('resource.provision'),
                color: Colors.orange,
                warnThreshold: SpiritWorldGame.hungerWarnThreshold,
                criticalThreshold: SpiritWorldGame.hungerCriticalThreshold,
              ),
              const SizedBox(height: 2),
              _AnimatedResourceBar(
                notifier: gameRef.faithNotifier,
                stage: gameRef.progress.faithStage,
                max: gameRef.progress.maxFaith,
                icon: '🙏',
                label: AppStrings.get('resource.faith'),
                color: Colors.purpleAccent,
              ),
              const SizedBox(height: 2),
              _AnimatedResourceBar(
                notifier: gameRef.materialsNotifier,
                stage: gameRef.progress.materialsStage,
                max: gameRef.progress.maxMaterials,
                icon: '📦',
                label: AppStrings.get('resource.supplies'),
                color: Colors.blueGrey,
              ),
              const SizedBox(height: 4),
              const Divider(height: 1, color: Colors.white12),
              const SizedBox(height: 2),
              _InsightDisplay(progress: gameRef.progress),
              const SizedBox(height: 2),
              _ConversionCounter(gameRef: gameRef),
              const SizedBox(height: 2),
              _QuarterProgressBar(status: gameRef.quarterStatus),
            ],
          );
        },
      ),
    );
  }
}

/// Compact Insight display shown below the resource bars in the HUD.
/// Shows accumulated whole-point insight + fractional pending as 📖 N format.
class _InsightDisplay extends StatelessWidget {
  final PlayerProgress progress;
  const _InsightDisplay({required this.progress});

  @override
  Widget build(BuildContext context) {
    final label = _insightLabel(progress);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('📖', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Formats an integer with compact suffixes for large numbers.
/// E.g. 999 → '999', 1000 → '1K', 1500 → '1.5K', 1000000 → '1M'.
String _compactInt(int n) {
  if (n >= 1000000) {
    final d = n / 1000000;
    return '${d == d.truncateToDouble() ? d.toInt() : d.toStringAsFixed(1)}M';
  }
  if (n >= 1000) {
    final d = n / 1000;
    return '${d == d.truncateToDouble() ? d.toInt() : d.toStringAsFixed(1)}K';
  }
  return '$n';
}

/// Compact conversion counter shown below the Insight display in the HUD.
/// Shows ✝ N Bekehrt, and briefly flashes a fading "+1" delta chip inline
/// (same pattern as [_AnimatedResourceBar]) whenever an NPC is converted.
class _ConversionCounter extends StatefulWidget {
  final SpiritWorldGame gameRef;
  const _ConversionCounter({required this.gameRef});

  @override
  State<_ConversionCounter> createState() => _ConversionCounterState();
}

class _ConversionCounterState extends State<_ConversionCounter> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Opacity goes 1.0 → 0.0 so the "+1" chip fades out completely.
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn),
    );
    widget.gameRef.conversionToastMessage.addListener(_onConversion);
  }

  void _onConversion() {
    final msg = widget.gameRef.conversionToastMessage.value;
    if (msg == null || !mounted) return;
    setState(() {}); // rebuild to update converted count
    _fadeCtrl.forward(from: 0.0).then((_) {
      if (mounted) widget.gameRef.conversionToastMessage.value = null;
    });
  }

  @override
  void dispose() {
    widget.gameRef.conversionToastMessage.removeListener(_onConversion);
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Issue #170: use the game's merged live+saved count so the number does
    // not visibly drop after loading a save, before the player has walked
    // back through every previously-visited chunk this session.
    final converted = widget.gameRef.knownChristianCount;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('✝', style: TextStyle(fontSize: 12, color: Color(0xFFB0C4FF))),
        const SizedBox(width: 3),
        Text(
          _compactInt(converted),
          style: const TextStyle(
            color: Color(0xFFB0C4FF),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 2),
        // Inline "+1" delta chip – only visible while the fade is running.
        if (_fadeCtrl.isAnimating || _fadeCtrl.value > 0.0)
          AnimatedBuilder(
            animation: _fadeAnim,
            builder: (context, _) => Opacity(
              opacity: _fadeAnim.value.clamp(0.0, 1.0),
              child: const Text(
                '+1',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Thin bar under ✝: how far the current neighbourhood is from an
/// attackable 🏰 (playtest: replaces the old "🏘️ ✝️ 22/56" line). Fills
/// blue, turns gold when the stronghold is open and orange 🔥 once awakened.
class _QuarterProgressBar extends StatelessWidget {
  final ValueNotifier<QuarterStatus?> status;
  const _QuarterProgressBar({required this.status});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuarterStatus?>(
      valueListenable: status,
      builder: (context, s, _) {
        if (s == null) return const SizedBox.shrink();
        final color = s.awakened
            ? Colors.deepOrangeAccent
            : s.strongholdOpen
                ? Colors.amber
                : const Color(0xFFB0C4FF);
        final icon = s.awakened ? '🔥' : (s.strongholdOpen ? '⚔️' : '🏰');
        return Semantics(
          label: '${s.christians}/${s.people}',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏘️', style: TextStyle(fontSize: 10)),
              const SizedBox(width: 3),
              Container(
                width: 70,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: s.progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Text(icon, style: const TextStyle(fontSize: 10)),
            ],
          ),
        );
      },
    );
  }
}

/// A single resource bar with a brief "+N" / "−N" delta text that fades out
/// after each change.
///
/// Listens directly to a [ValueNotifier] so it rebuilds immediately on any
/// resource change, regardless of the Flame game pause state.
///
/// Optional [warnThreshold] and [criticalThreshold] (as fractions 0.0–1.0 of
/// [max]) activate colour changes and icon pulsing when the resource is low.
class _AnimatedResourceBar extends StatefulWidget {
  final ValueNotifier<double> notifier;
  final ResourceStage stage;
  final double max;
  final String icon;
  final String label;
  final Color color;

  /// When value/max drops below this fraction the bar turns amber.
  final double? warnThreshold;

  /// When value/max drops below this fraction the bar turns red and the icon pulses.
  final double? criticalThreshold;

  const _AnimatedResourceBar({
    required this.notifier,
    required this.stage,
    required this.max,
    required this.icon,
    required this.label,
    required this.color,
    this.warnThreshold,
    this.criticalThreshold,
  });

  @override
  State<_AnimatedResourceBar> createState() => _AnimatedResourceBarState();
}

class _AnimatedResourceBarState extends State<_AnimatedResourceBar> with TickerProviderStateMixin {
  static const double _barWidth = 90.0;
  static const double _barHeight = 7.0;
  static const double _stageBarHeight = 2.0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  /// Continuously repeating pulse animation used when value is critically low.
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  double _prevValue = 0.0;
  double _lastDelta = 0.0;

  static const TextStyle _iconStyle = TextStyle(fontSize: 14);

  @override
  void initState() {
    super.initState();
    _prevValue = widget.notifier.value;
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Opacity goes 1.0 → 0.0 so the delta text fades out completely.
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    widget.notifier.addListener(_onValueChanged);
  }

  void _onValueChanged() {
    if (!mounted) return;
    final newValue = widget.notifier.value;
    if (newValue == _prevValue) return;
    setState(() {
      _lastDelta = newValue - _prevValue;
      _prevValue = newValue;
    });
    // (Re-)start the fade so the delta text disappears after 1.2 s.
    _fadeCtrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onValueChanged);
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.notifier.value;
    final progress = (value / widget.max).clamp(0.0, 1.0);
    final stageProgress = widget.stage.progress;
    final deltaSign = _lastDelta >= 0 ? '+' : '';
    final deltaText = '$deltaSign${_lastDelta.toInt()}';
    final deltaColor = _lastDelta >= 0 ? Colors.amber : Colors.redAccent;

    // Dynamic bar colour based on warning/critical thresholds
    final bool isCritical = widget.criticalThreshold != null && progress < widget.criticalThreshold!;
    final bool isWarn = !isCritical && widget.warnThreshold != null && progress < widget.warnThreshold!;
    Color effectiveColor = widget.color;
    if (isCritical) {
      effectiveColor = Colors.redAccent;
    } else if (isWarn) {
      effectiveColor = Colors.amber;
    }

    // The name stays for screen readers only.
    return Semantics(
      label: '${widget.label} ${value.toInt()}/${widget.max.toInt()}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Emoji icon – pulses when critically low
          isCritical
              ? AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, _) => Opacity(
                    opacity: (0.4 + _pulseAnim.value * 0.6).clamp(0.0, 1.0),
                    child: Text(widget.icon, style: _iconStyle),
                  ),
                )
              : Text(widget.icon, style: _iconStyle),
          const SizedBox(width: 4),
          // Emoji, bar, value and stage; names only for screen readers.
          // The thin cyan strip on top is the progress to the next capacity
          // stage.
          SizedBox(
            width: _barWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: _barWidth,
                  height: _stageBarHeight,
                  color: Colors.white.withValues(alpha: 0.05),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: stageProgress,
                      child: Container(color: Colors.cyanAccent.withValues(alpha: 0.8)),
                    ),
                  ),
                ),
                Container(
                  width: _barWidth,
                  height: _barHeight,
                  decoration: const BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: effectiveColor,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Value / capacity and capacity stage (playtest: wanted back).
          SizedBox(
            width: 52,
            child: Text(
              ' ${_compactInt(value.round())}/${_compactInt(widget.max.round())}',
              style: TextStyle(color: effectiveColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Lv.${widget.stage.stage}',
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          // Delta – only shown while the fade is in progress.
          SizedBox(
            width: 26,
            child: (_fadeCtrl.isAnimating || _fadeCtrl.value < 1.0) && _lastDelta != 0
                ? AnimatedBuilder(
                    animation: _fadeAnim,
                    builder: (context, _) => Opacity(
                      opacity: _fadeAnim.value.clamp(0.0, 1.0),
                      child: Text(
                        ' $deltaText',
                        style: TextStyle(color: deltaColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

// ── Interior art abstraction ──────────────────────────────────────────────────
