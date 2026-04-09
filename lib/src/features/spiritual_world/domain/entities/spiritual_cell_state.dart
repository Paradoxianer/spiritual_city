class SpiritualCellState {
  final double lightIntensity;
  final bool isActive;

  const SpiritualCellState({
    this.lightIntensity = 0.0,
    this.isActive = false,
  });

  SpiritualCellState copyWith({double? lightIntensity, bool? isActive}) =>
      SpiritualCellState(
        lightIntensity: lightIntensity ?? this.lightIntensity,
        isActive: isActive ?? this.isActive,
      );
}
