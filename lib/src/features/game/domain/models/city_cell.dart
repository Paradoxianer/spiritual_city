import 'cell_object.dart';

class CityCell {
  final int x;
  final int y;
  
  // The data defining what is in this cell
  CellData? data;
  
  // Real world values (0.0 to 1.0)
  final double crime;
  final double density;
  
  // Spiritual world values (-1.0 to 1.0)
  double spiritualState;

  /// True after a daemon naturally dissolves here, leaving an "ash" imprint.
  bool hasResiduum = false;
  
  CityCell({
    required this.x,
    required this.y,
    this.data,
    this.crime = 0.0,
    this.density = 0.0,
    this.spiritualState = 0.0,
  });
}
