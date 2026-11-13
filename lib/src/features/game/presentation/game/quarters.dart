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
        _toast('🏘️✝️ ➡️ 🏰⚔️', 'strongholdOpen');
      }
      quarterStatus.value = status;
    }

    _checkQuarterAllChristian(status);
    if (isSpiritualWorld) _ensureStronghold(status);
    _updateCityProgress(q);
  }

  /// Liberated ground of [q] and of every known chunk – generated ones
  /// live, the rest from the save – plus all known people. Only the
  /// chunks of [q], new ones and a rotating few others are counted again
  /// per call; the rest keep their last tally.
  void _updateCityProgress(Quarter q) {
    final tallies = _chunkTallies ??= Liberation.savedByChunk(_savedCellStates ?? const {});
    final chunks = grid.getLoadedChunks();
    void count(CityChunk chunk) {
      if (chunk.cells.isEmpty) return;
      final key = chunk.id;
      tallies[key] = Liberation.ofStates(chunk.cells.values.map((c) => c.spiritualState));
      _liveTallied.add(key);
    }

    for (final chunk in chunks) {
      if (!_liveTallied.contains(chunk.id) ||
          Liberation.quarterOfChunk(chunk.chunkX, chunk.chunkY) == q) {
        count(chunk);
      }
    }
    if (chunks.isNotEmpty) {
      for (var i = 0; i < _tallyRefreshPerCall; i++) {
        count(chunks[_tallyCursor++ % chunks.length]);
      }
    }

    var quarter = Tally.zero;
    var city = Tally.zero;
    for (final t in tallies.values) {
      city += t;
    }
    const side = Quarter.chunksPerSide;
    for (var dy = 0; dy < side; dy++) {
      for (var dx = 0; dx < side; dx++) {
        quarter += tallies['${q.qx * side + dx},${q.qy * side + dy}'] ?? Tally.zero;
      }
    }
    final people = knownNpcCounts;
    cityProgress.value = CityProgress(
      quarterCells: quarter,
      cityCells: city,
      cityPeople: Tally(people.converted, people.total),
      spiritWorld: isSpiritualWorld,
    );
  }

  /// Generated chunks outside the current neighbourhood counted again per
  /// call – the whole city line catches up within a minute or so.
  static const int _tallyRefreshPerCall = 12;

  void _ensureStronghold(QuarterStatus status) {
    final forts = world.children.whereType<StrongholdComponent>().toList();
    for (final f in forts) {
      if (f.quarter != status.quarter) f.removeFromParent();
    }
    if (status.awakened) return;
    if (forts.any((f) => f.quarter == status.quarter)) return;
    world.add(StrongholdComponent(
      status.quarter,
      StrongholdComponent.centerOf(status.quarter),
      kind: strongholdKind(status.quarter),
    ));
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
    _toast('🏰💥 ➡️ 🏘️🔥✝️', 'awakened');
  }

  /// Everyone who lives in this neighbourhood is a Christian – once all of
  /// its houses are known (every chunk generated). A neighbourhood without
  /// people (park, water) counts too. Christians are never lost, so it stays.
  void _checkQuarterAllChristian(QuarterStatus status) {
    final q = status.quarter;
    if (progress.christianQuarters.contains(q.key)) return;
    if (status.christians < status.people) return;
    const side = Quarter.chunksPerSide;
    for (var dy = 0; dy < side; dy++) {
      for (var dx = 0; dx < side; dx++) {
        if (!chunkManager.npcRegistry.hasGeneratedChunk(q.qx * side + dx, q.qy * side + dy)) return;
      }
    }
    progress.christianQuarters.add(q.key);
    if (status.people > 0) _toast('🏘️ ✝️✝️✝️ 🙌', 'allChristian');
    _checkWinCondition();
  }

  /// Back from the invisible world: is this neighbourhood prayed free
  /// (≥ 95 % green)? Then it is celebrated 🎉 – once per neighbourhood.
  void _checkQuarterPrayedFree() {
    final q = currentQuarter;
    if (progress.celebratedQuarters.contains(q.key)) return;
    _updateQuarter();
    final cells = cityProgress.value?.quarterCells ?? Tally.zero;
    final status = quarterStatus.value;
    if (status == null || !Awakening.prayedFree(cells)) return;
    progress.celebratedQuarters.add(q.key);
    progress.addInsight(Awakening.insightReward);
    GameSound.play(Sfx.awakening, volume: 0.8);
    final percent = (cells.free * 100 ~/ (Quarter.sizeCells * Quarter.sizeCells)).clamp(0, 100);
    quarterCelebration.value = QuarterCelebration(
      quarter: q,
      percent: percent,
      christians: status.christians,
      people: status.people,
      church: progress.church.members.length,
      day: progress.dayStats.day,
      awakened: status.awakened,
      prayedFree: CityLayout.current.quarters.where((q) => progress.celebratedQuarters.contains(q.key)).length,
      cityQuarters: CityLayout.current.quarters.length,
      allChristian: CityLayout.current.quarters.where((q) => progress.christianQuarters.contains(q.key)).length,
    );
    Narrator.say('celebrate', '🎉', '', HelpContent.toasts['prayedFree']?.text
        .replaceAll('{p}', '$percent')
        .replaceAll('{c}', '${status.christians}')
        .replaceAll('{n}', '${status.people}'), force: true);
  }

  /// 🏰 / 🏰🏰 / 🏯 of [q] – decided by the city (district, city hall, home).
  StrongholdKind strongholdKind(Quarter q) => StrongholdKind.of(
        q,
        district: (_districts ??= DistrictSelector(seed: seedManager.seed)).getDistrictType,
        homeCell: SpecialBuildingRegistry.pastorHouseCell,
        cityHallCell: SpecialBuildingRegistry.cityHallCell,
      );

  /// Extra daemon power from awakened neighbourhoods (#178 scaling).
  int get awakeningPower => progress.awakenedQuarters.length * Awakening.powerPerAwakening;
}
