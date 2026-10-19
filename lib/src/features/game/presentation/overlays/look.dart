part of '../game_screen.dart';

/// Data passed to the [LookOverlay].
class LookCellInfo {
  final String label; // e.g. "Hauptstraße" or "Rathaus Nr. 12"
  final double spiritualState; // -1..1
  final String? npcName; // first NPC name seen in that cell, or null
  final String? streetName; // nearest named road, or null

  const LookCellInfo({
    required this.label,
    required this.spiritualState,
    this.npcName,
    this.streetName,
  });
}

class GameLookData {
  final List<LookCellInfo> cells;
  final double playerSpiritualState;
  GameLookData({required this.cells, required this.playerSpiritualState});
}

// ── Street name HUD label ─────────────────────────────────────────────────────

/// Rich look overlay – shows spiritual state, building/NPC info, and street
/// info for all 8 neighbouring cells.  Activated by the 👀 radial-menu action.
class LookOverlay extends StatelessWidget {
  final SpiritWorldGame game;
  const LookOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final data = game.activeLookData;
    if (data == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: OverlayShell(
          theme: OverlayTheme.info,
          placement: OverlayPlacement.top,
          showClose: false,
          leading: const Text('👀', style: TextStyle(fontSize: 18)),
          trailing: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _SpiritualDot(state: data.playerSpiritualState),
            ),
          ],
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.cells.isEmpty
                  ? [const Text('🌫️', style: TextStyle(fontSize: 20))]
                  : data.cells.map((c) => _LookCellRow(cell: c)).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpiritualDot extends StatelessWidget {
  final double state; // -1..1
  const _SpiritualDot({required this.state});

  @override
  Widget build(BuildContext context) {
    final Color col = state > 0
        ? Color.lerp(Colors.grey, Colors.amber, state)!
        : Color.lerp(Colors.grey, Colors.red, state.abs())!;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: col,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30),
      ),
    );
  }
}

class _LookCellRow extends StatelessWidget {
  final LookCellInfo cell;
  const _LookCellRow({required this.cell});

  @override
  Widget build(BuildContext context) {
    final spiritualPct = (cell.spiritualState * 100).round();
    final spiritualLabel = cell.spiritualState >= 0 ? '+$spiritualPct%' : '$spiritualPct%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _SpiritualDot(state: cell.spiritualState),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cell.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                spiritualLabel,
                style: TextStyle(
                  color: cell.spiritualState >= 0
                      ? Colors.amber.withValues(alpha: 0.85)
                      : Colors.red.withValues(alpha: 0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (cell.npcName != null) ...[
                const SizedBox(width: 6),
                Text(
                  cell.npcName!,
                  style: TextStyle(
                    color: Colors.cyan.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          if (cell.streetName != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 1),
              child: Text(
                '🛣️ ${cell.streetName}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Mission board data classes ─────────────────────────────────────────────────
