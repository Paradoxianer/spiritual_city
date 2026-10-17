part of '../game_screen.dart';

/// Countdown shown in place of the action bar while a timed action runs
/// (📖 in the dialog, timed building actions).
class _Countdown extends StatelessWidget {
  final String emoji;
  final int seconds;
  const _Countdown({required this.emoji, required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Text(
          '${seconds}s',
          style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        const Text('⏳', style: TextStyle(fontSize: 18)),
      ],
    );
  }
}

/// Compact progress bar for multi-step missions shown in building/NPC dialog headers.
class _MissionProgressBar extends StatelessWidget {
  final int progress;
  final int targetCount;

  const _MissionProgressBar({
    required this.progress,
    required this.targetCount,
  });

  @override
  Widget build(BuildContext context) {
    final pct = targetCount > 0 ? (progress / targetCount).clamp(0.0, 1.0) : 0.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFD54F),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$progress/$targetCount',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ── Pause Menu Overlay (Issue #162 / #174) ──────────────────────────────────

/// Vertical faith-level bar shown on the right edge of an NPC dialog or
/// building interior overlay.
///
/// Works for any [BaseInteractableEntity] since [isFaithVague] and
/// [isFaithRevealed] are defined on the shared base class.
///
/// * Not vague (< 3 interactions) → question mark placeholder.
/// * Vague (3–5 interactions) → bar rounded to nearest 25 %.
/// * Revealed (6+ interactions) → exact bar + numeric label.
class _FaithBarWidget extends StatelessWidget {
  final BaseInteractableEntity entity;

  const _FaithBarWidget({required this.entity});

  @override
  Widget build(BuildContext context) {
    if (!entity.isFaithVague) {
      // Not enough interactions yet – show a question mark placeholder.
      return SizedBox(
        width: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✝️', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text('?', style: TextStyle(color: Colors.white38, fontSize: 9)),
              ),
            ),
          ],
        ),
      );
    }

    final faithNorm = ((entity.faith + 100) / 200.0).clamp(0.0, 1.0);
    final barColor = Color.lerp(Colors.red[700]!, Colors.green[600]!, faithNorm)!;

    // Vague: round to nearest 25 %; revealed: exact value.
    final displayNorm =
        entity.isFaithRevealed ? faithNorm : ((faithNorm * 4).round() / 4.0).clamp(0.0, 1.0);

    const barHeight = 80.0;

    return SizedBox(
      width: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✝️', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 8,
                height: barHeight,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 8,
                height: barHeight * displayNorm,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (entity.isFaithRevealed)
            Text(
              entity.faith.toStringAsFixed(0),
              style: const TextStyle(color: Colors.white60, fontSize: 9),
            )
          else
            const Text('~', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Upgrade-Zentrale (Issue #4) ───────────────────────────────────────────────

/// Formats an insight total (whole + pending) as a compact string.
/// Returns the integer string if the value is whole (e.g. "3"),
/// otherwise one decimal place (e.g. "3.5").
String _insightLabel(PlayerProgress progress) {
  final total = progress.insight + progress.pendingInsight;
  return total == total.truncateToDouble() ? total.toInt().toString() : total.toStringAsFixed(1);
}

/// Formats a modifier multiplier as a +N% percent string.
/// E.g. multiplier 1.3 → '+30%'.
String _pct(double multiplier) => '+${(multiplier * 100 - 100).toStringAsFixed(0)}%';
