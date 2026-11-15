part of '../spirit_world_game.dart';

/// 🌊 Waves in the invisible world, second attempt (playtest 2026-11-15,
/// SpiritWaves): a beaten wave breaks through as a green wave from the
/// pastor – bigger the longer they hold out.
extension GameSpiritWaves on SpiritWorldGame {
  /// A new wave comes after the pause: only a sound, the HUD shows it.
  void onWaveStarted(int wave) => GameSound.play(Sfx.tap, volume: 0.5);

  /// On entering: the narrator explains the waves once per game.
  void onWavesBegin() {
    if (_explained.add('wave')) Narrator.say('toast.wave', '🌊', '', HelpContent.toasts['wave']?.text);
  }

  void onWaveCleared(int wave) {
    final r = SpiritWaves.breakthroughCells(wave) * CellComponent.cellSize;
    final center = player.position.clone();
    world.add(ShockwaveComponent(
      position: center,
      maxRadius: r,
      strength: SpiritWaves.breakthroughStrength(wave),
      duration: 2,
      speed: r / 2.5,
      color: const Color(0xFF66BB6A),
      mode: PrayerMode.liberation,
      source: ShockwaveComponent.breakthrough,
    ));
    // The people it reaches are more open for the gospel.
    final r2 = r * r;
    final open = SpiritWaves.openness(wave);
    for (final c in chunkManager.allActiveNPCs) {
      final m = c.model;
      if (m.isConverted || c.position.distanceToSquared(center) > r2) continue;
      m.faith = min(100.0, m.faith + open);
    }
    GameSound.play(Sfx.awakening, volume: 0.6);
    // The narrator explains it once per game.
    if (_explained.add('breakthrough')) {
      Narrator.say('toast.breakthrough', '🌊', '', HelpContent.toasts['breakthrough']?.text);
    }
  }
}
