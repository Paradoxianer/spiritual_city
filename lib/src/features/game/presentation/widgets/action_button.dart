import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../core/audio/game_sound.dart';
import '../../../menu/domain/models/difficulty.dart';
import '../../domain/actions/game_action.dart';
import '../../domain/actions/practice.dart';
import '../../domain/actions/resource.dart';

/// Whether keyboard shortcut badges are shown (desktop and web, not mobile).
bool showKeyHints() {
  if (kIsWeb) return true;
  try {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  } catch (_) {
    return false;
  }
}

/// The one tappable action widget of the game
/// (docs/game_design/release_roadmap.md §2.2): emoji, generated cost hint,
/// the reason when unavailable, practice stars and an optional key badge.
///
/// Used by the NPC dialog and the building interior alike.
class ActionButton extends StatelessWidget {
  final String emoji;

  /// Cost/effect hint below the emoji, e.g. `−5🙏→🌱`.
  final String? hint;

  /// Unavailable actions ignore taps; locked ones show the lock (`🔒3`)
  /// instead of the hint, unaffordable ones show the hint in red.
  final Availability availability;

  /// Extra switch for transient states (waiting, reading, countdown).
  final bool enabled;

  /// 1-based keyboard shortcut (shown on desktop/web only).
  final int? keyIndex;

  /// Practice level of the action's discipline (0 = no stars).
  final int practiceLevel;

  /// Accent for special actions (✝️🕊️) or the active mission's action.
  final bool highlighted;

  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.emoji,
    required this.onTap,
    this.hint,
    this.availability = const AvailableNow(),
    this.enabled = true,
    this.keyIndex,
    this.practiceLevel = 0,
    this.highlighted = false,
  });

  /// Builds the button straight from a [GameAction] definition.
  static ActionButton of<T>(
    GameAction<T> action,
    T subject, {
    Key? key,
    required ResourceWallet wallet,
    required Difficulty difficulty,
    required Practice practice,
    required VoidCallback onTap,
    int? keyIndex,
    bool enabled = true,
    bool highlighted = false,
    String? emoji,
  }) {
    final d = action.discipline;
    return ActionButton(
      key: key,
      emoji: emoji ?? action.emoji,
      hint: action.hint(difficulty),
      availability: action.availability(subject, wallet, difficulty),
      enabled: enabled,
      keyIndex: keyIndex,
      practiceLevel: d == null ? 0 : practice.level(d),
      highlighted: highlighted,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = availability.isOk;
    final active = available && enabled;
    // Locked: show the lock reason. Unaffordable: show the cost in red, so
    // the player sees how much is missing.
    final reason = switch (availability) {
      Locked(:final emoji) => emoji,
      CannotAfford() => hint ?? availability.reason,
      AvailableNow() => null,
    };
    final showBadge = keyIndex != null && showKeyHints();

    final Color bg;
    final Color border;
    if (!available) {
      bg = Colors.red.shade900.withValues(alpha: 0.35);
      border = Colors.red.shade300;
    } else if (highlighted) {
      bg = Colors.amber.shade800;
      border = Colors.amber;
    } else {
      bg = Colors.white70;
      border = Colors.transparent;
    }

    return Opacity(
      opacity: active || !available ? 1.0 : 0.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: bg,
                shape: StadiumBorder(side: BorderSide(color: border)),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  // Unavailable actions answer with the "denied" sound, so a
                  // tap is never silent.
                  onTap: active
                      ? () {
                          GameSound.play(Sfx.tap, volume: 0.4);
                          onTap();
                        }
                      : (available ? null : () => GameSound.play(Sfx.denied, volume: 0.4)),
                  child: ConstrainedBox(
                    // ≥ 48 px touch target (mobile_ui.md).
                    constraints: const BoxConstraints(minWidth: 52, minHeight: 44),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Center(
                        widthFactor: 1,
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                ),
              ),
              if (showBadge)
                Positioned(top: -4, right: -4, child: _Badge('$keyIndex')),
              if (practiceLevel > 0)
                Positioned(
                  bottom: -5,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '⭐' * practiceLevel.clamp(0, Practice.thresholds.length),
                      style: const TextStyle(fontSize: 7, height: 1),
                    ),
                  ),
                ),
            ],
          ),
          if (reason != null || hint != null) ...[
            const SizedBox(height: 4),
            Text(
              reason ?? hint!,
              style: TextStyle(
                color: reason != null ? Colors.red.shade200 : Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(color: Color(0xFFFFA000), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          color: Colors.black,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}

/// Horizontal action bar at the bottom of every interaction overlay.
/// Wraps to a second line instead of scrolling sideways on narrow phones.
class ActionBar extends StatelessWidget {
  final List<Widget> children;
  const ActionBar({super.key, required this.children});

  /// One row only (playtest: a second row could stick out of the dialog,
  /// and buttons outside it could not be tapped). Too many buttons scroll
  /// sideways instead.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth.isFinite ? constraints.maxWidth : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
