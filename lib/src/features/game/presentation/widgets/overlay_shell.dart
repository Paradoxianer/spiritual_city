import 'package:flutter/material.dart';

/// Where an [OverlayShell] sits on screen.
enum OverlayPlacement {
  /// Bottom sheet over the city (NPC dialog): the world stays visible above.
  bottom,

  /// Centred card (building interior, mission board).
  center,

  /// Small info card near the top (look-around).
  top,
}

/// Colours of an [OverlayShell].
class OverlayTheme {
  final Color background;
  final Color header;
  final Color? border;
  final Color? glow;

  const OverlayTheme({
    required this.background,
    required this.header,
    this.border,
    this.glow,
  });

  /// NPC dialog (messenger green).
  static const npc = OverlayTheme(background: Color(0xF2075E54), header: Color(0xFF128C7E));

  /// Ordinary buildings.
  static const building = OverlayTheme(background: Color(0xF71A237E), header: Color(0xFF283593));

  /// The pastor house: warm brown with a golden rim.
  static const home = OverlayTheme(
    background: Color(0xF73E2723),
    header: Color(0xFF4E342E),
    border: Color(0xFFFFD54F),
    glow: Color(0x59FFD54F),
  );

  /// Mission board.
  static const missions = OverlayTheme(
    background: Color(0xF71B2A1B),
    header: Color(0xFF2E4A2E),
    border: Color(0xFFFFD54F),
  );

  /// Neutral info card.
  static const info = OverlayTheme(background: Color(0xE0000000), header: Color(0x00000000));
}

/// The one frame for every interaction overlay
/// (docs/game_design/release_roadmap.md §2.2):
///
/// ```
/// ┌ [leading] title …… trailing  ✕ ┐   who / what this is
/// │ banner (optional)              │
/// │ body                           │   what you know
/// │ actions (optional)             │   what you can do
/// └────────────────────────────────┘
/// ```
///
/// Handles safe area, margins, max sizes per [placement] and a close button
/// with a full touch target.
class OverlayShell extends StatelessWidget {
  final Widget leading;
  final Widget? title;
  final List<Widget> trailing;
  final VoidCallback? onClose;
  final bool showClose;
  final Widget? banner;
  final Widget body;
  final Widget? actions;
  final OverlayTheme theme;
  final OverlayPlacement placement;

  const OverlayShell({
    super.key,
    required this.leading,
    required this.body,
    this.title,
    this.trailing = const [],
    this.onClose,
    this.showClose = true,
    this.banner,
    this.actions,
    this.theme = OverlayTheme.building,
    this.placement = OverlayPlacement.center,
  });

  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final landscape = media.orientation == Orientation.landscape;

    final panel = Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(_radius),
        border: theme.border == null ? null : Border.all(color: theme.border!, width: 2),
        boxShadow: [
          const BoxShadow(color: Colors.black54, blurRadius: 12),
          if (theme.glow != null) BoxShadow(color: theme.glow!, blurRadius: 24, spreadRadius: 4),
        ],
      ),
      child: Column(
        mainAxisSize: placement == OverlayPlacement.bottom ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          if (banner != null) banner!,
          if (placement == OverlayPlacement.bottom) Expanded(child: body) else Flexible(child: body),
          if (actions != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: landscape ? 6 : 10),
              decoration: const BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(_radius)),
              ),
              child: actions,
            ),
        ],
      ),
    );

    return SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : media.size.height;
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : media.size.width;
        final margin = landscape ? 10.0 : 16.0;
        switch (placement) {
          case OverlayPlacement.bottom:
            final maxH = (h - 2 * margin).clamp(0.0, double.infinity);
            final minH = maxH >= 260 ? 260.0 : maxH;
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: (h * (landscape ? 0.8 : 0.45)).clamp(minH, maxH),
                // Readable on tablets/desktop: no full-width chat line.
                constraints: const BoxConstraints(maxWidth: 760),
                margin: EdgeInsets.all(margin),
                child: panel,
              ),
            );
          case OverlayPlacement.center:
            return Align(
              child: Container(
                width: (w * 0.9).clamp(0.0, 560.0),
                constraints: BoxConstraints(maxHeight: h * (landscape ? 0.92 : 0.75)),
                margin: EdgeInsets.all(margin),
                child: panel,
              ),
            );
          case OverlayPlacement.top:
            return Align(
              alignment: const Alignment(0, -0.6),
              child: Container(
                width: (w - 48).clamp(0.0, 480.0),
                constraints: BoxConstraints(maxHeight: h * 0.6),
                child: Material(type: MaterialType.transparency, child: panel),
              ),
            );
        }
      }),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
      decoration: BoxDecoration(
        color: theme.header,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(_radius)),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(child: title ?? const SizedBox.shrink()),
          ...trailing,
          if (showClose)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onClose,
            )
          else
            const SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// Session points of the current visit: filled = used, hollow = left.
class SessionDots extends StatelessWidget {
  final int done;
  final int max;

  const SessionDots({super.key, required this.done, required this.max});

  @override
  Widget build(BuildContext context) {
    final displayMax = max.clamp(1, 12);
    final displayDone = done.clamp(0, displayMax);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < displayMax; i++)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < displayDone
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.22),
              ),
            ),
        ],
      ),
    );
  }
}

/// Relationship level with a person (♥ per level, release_roadmap.md §3.4).
class RelationshipHearts extends StatelessWidget {
  final int level;
  const RelationshipHearts({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    if (level <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        '♥' * level,
        style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12, letterSpacing: 1),
      ),
    );
  }
}
