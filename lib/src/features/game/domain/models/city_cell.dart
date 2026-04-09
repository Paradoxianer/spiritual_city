enum CellType {
  empty,
  road,
  building,
  park,
}

class CityCell {
  final int x;
  final int y;
  final CellType type;
  
  // Real world values (0.0 to 1.0)
  final double crime;
  final double density;
  
  // Spiritual world values (-1.0 to 1.0)
  // -1.0 = Very Negative (Red/Grey), 1.0 = Very Positive (Gold/Blue)
  double spiritualState;
  
  CityCell({
    required this.x,
    required this.y,
    required this.type,
    this.crime = 0.0,
    this.density = 0.0,
    this.spiritualState = 0.0,
  });
}
