class PlayerState {
  final double focus;
  final double energy;
  final double spiritualStrength;
  final bool isInSpiritualWorld;

  const PlayerState({
    this.focus = 100.0,
    this.energy = 100.0,
    this.spiritualStrength = 0.0,
    this.isInSpiritualWorld = false,
  });

  PlayerState copyWith({
    double? focus,
    double? energy,
    double? spiritualStrength,
    bool? isInSpiritualWorld,
  }) =>
      PlayerState(
        focus: focus ?? this.focus,
        energy: energy ?? this.energy,
        spiritualStrength: spiritualStrength ?? this.spiritualStrength,
        isInSpiritualWorld: isInSpiritualWorld ?? this.isInSpiritualWorld,
      );
}
