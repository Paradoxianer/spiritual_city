part of '../spirit_world_game.dart';

/// Neighbourhoods as stage goals (§3.3, #125): status for the HUD, the
/// 🏰 stronghold in the invisible world and the awakening.
extension GameQuarters on SpiritWorldGame {
  Quarter get currentQuarter => Quarter.ofCell(
        (player.position.x / CellComponent.cellSize).floor(),
        (player.position.y / CellComponent.cellSize).floor(),
      );

  /// Recomputes the status of the current neighbourhood from the people
  /// who live there (their home position) and keeps its stronghold present
  /// in the invisible world. Called about once a second.
  void _updateQuarter() {
    final q = currentQuarter;
    var people = 0;
    var christians = 0;
    for (final npc in chunkManager.allNPCModels) {
      final cx = (npc.homePosition.x / CellComponent.cellSize).floor();
      final cy = (npc.homePosition.y / CellComponent.cellSize).floor();
      if (!q.containsCell(cx, cy)) continue;
      people++;
      if (npc.isChristian) {
        christians++;
        // Christians from before the church existed join it (old saves).
        if (!progress.church.members.containsKey(npc.id)) progress.church.join(npc);
      }
    }
    final status = QuarterStatus(
      quarter: q,
      christians: christians,
      people: people,
      awakened: progress.awakenedQuarters.contains(q.key),
    );
    final before = quarterStatus.value;
    if (before != status) {
      // No permanent HUD line (playtest): only announce the moment the
      // neighbourhood's stronghold becomes attackable.
      if (before != null && before.quarter == q && !before.strongholdOpen &&
          status.strongholdOpen && !status.awakened) {
        _toast('🏘️✝️ ➡️ 🏰⚔️');
      }
      quarterStatus.value = status;
    }

    if (isSpiritualWorld) _ensureStronghold(status);
  }

  void _ensureStronghold(QuarterStatus status) {
    final forts = world.children.whereType<StrongholdComponent>().toList();
    for (final f in forts) {
      if (f.quarter != status.quarter) f.removeFromParent();
    }
    if (status.awakened) return;
    if (forts.any((f) => f.quarter == status.quarter)) return;
    world.add(StrongholdComponent(status.quarter, StrongholdComponent.centerOf(status.quarter)));
  }

  /// The stronghold fell: the neighbourhood is awakened.
  void onStrongholdFallen(StrongholdComponent fort) {
    progress.awakenedQuarters.add(fort.quarter.key);
    missionService.stage = progress.awakenedQuarters.length;
    progress.addInsight(Awakening.insightReward);
    _brightenspiritualAreaAroundPosition(fort.position, radius: 22, amount: 0.6);
    dayStats.awakenings++;
    GameSound.play(Sfx.awakening, volume: 0.8);
    quarterStatus.value = null; // recomputed on the next tick
    _toast('🏰💥 ➡️ 🏘️🔥✝️');
  }

  /// Extra daemon power from awakened neighbourhoods (#178 scaling).
  int get awakeningPower => progress.awakenedQuarters.length * Awakening.powerPerAwakening;
}
