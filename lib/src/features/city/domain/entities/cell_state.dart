import 'cell_type.dart';

class CellState {
  final CellType type;
  final double crime;
  final double hope;
  final double spiritualStrength;
  final int population;

  const CellState({
    required this.type,
    this.crime = 0.0,
    this.hope = 0.5,
    this.spiritualStrength = 0.5,
    this.population = 0,
  });
}
