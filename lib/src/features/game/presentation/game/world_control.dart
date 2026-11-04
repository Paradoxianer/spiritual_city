part of '../spirit_world_game.dart';

/// The daily world simulation (#194): what the game hands to the pure
/// rules in [WorldSimulation], and catching up on days a part of the city
/// was not loaded.
extension GameWorld on SpiritWorldGame {
  /// Days a returning part of the city catches up at most.
  static const int maxCatchUpDays = 30;

  WorldTuning get worldTuning => WorldTuning(
        personFactor: switch (difficulty) {
          Difficulty.easy => 1.5,
          Difficulty.normal => 1.0,
          Difficulty.hard => 0.5,
        },
        spreadMultiplier: spiritualDynamics.modifierSpreadMultiplier,
        decayReduction: spiritualDynamics.modifierDecayReduction,
      );

  /// All known people where they are now – or only those on [chunk].
  List<Resident> residents({CityChunk? chunk}) => [
        for (final c in chunkManager.allActiveNPCs)
          if (chunk == null || _onChunk(c.position, chunk))
            Resident(
              c.model,
              (c.position.x / CellComponent.cellSize).floor(),
              (c.position.y / CellComponent.cellSize).floor(),
              baseStability: _baseStability(c.model),
            ),
      ];

  /// All known houses at their doors – or only those on [chunk].
  List<HouseAnchor> houseAnchors({CityChunk? chunk}) => [
        for (final b in chunkManager.allActiveBuildings)
          if (chunk == null || _onChunk(b.position, chunk))
            HouseAnchor(
              b.buildingModel.holiness,
              (b.position.x / CellComponent.cellSize).floor(),
              (b.position.y / CellComponent.cellSize).floor(),
              radius: b.buildingModel.influenceRadius.round(),
            ),
      ];

  double _baseStability(NPCModel npc) => WorldSimulation.baseStability(
        resolvedChallenges: npc.isChristian ? npc.backstory.resolvedChallenges.length : 0,
        interactions: npc.interactionCount,
        churchMember: progress.church.members.containsKey(npc.id),
        discipleLevel: Discipleship.totalLevel(npc.discipleProfile),
      );

  bool _onChunk(Vector2 p, CityChunk chunk) {
    const side = CityChunk.chunkSize * CellComponent.cellSize;
    return (p.x / side).floor() == chunk.chunkX && (p.y / side).floor() == chunk.chunkY;
  }

  /// Called once when a chunk is generated: if the save knows the day it
  /// was last simulated, the missed days (at most [maxCatchUpDays]) are
  /// queued – a part of the city does not stand still while the pastor is
  /// elsewhere. They run a few per frame ([continueCatchUp]): all at once
  /// they made walking stutter (playtest 2026-10-31).
  void catchUpChunk(CityChunk chunk) {
    final last = _savedChunkDays?.remove(chunk.id);
    if (last == null) return;
    final missed = (worldDay - last).clamp(0, maxCatchUpDays);
    if (missed == 0) return;
    _catchUps.add((chunk, missed));
  }

  /// Chunk-days of catching up per frame.
  static const int catchUpPerFrame = 3;

  /// Runs some queued catch-up days (called every frame).
  void continueCatchUp() {
    var budget = catchUpPerFrame;
    while (budget > 0 && _catchUps.isNotEmpty) {
      final (chunk, left) = _catchUps.removeAt(0);
      final days = min(budget, left);
      final people = residents(chunk: chunk);
      final houses = houseAnchors(chunk: chunk);
      for (var d = 0; d < days; d++) {
        WorldSimulation.simulateDay(grid,
            chunks: [chunk], residents: people, anchors: houses, tuning: worldTuning);
      }
      budget -= days;
      if (left > days) _catchUps.insert(0, (chunk, left - days));
    }
  }

  /// Day of the last simulation per chunk, for the save: generated chunks
  /// are up to date, the others keep the day they were saved with.
  Map<String, int> captureChunkDays() => {
        ...?_savedChunkDays,
        for (final c in grid.getLoadedChunks())
          if (c.cells.isNotEmpty) c.id: worldDay,
      };
}
