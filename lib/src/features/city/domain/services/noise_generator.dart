class SeededNoiseGenerator {
  final int _seed;

  SeededNoiseGenerator(this._seed);

  double _noise2d(int x, int y) {
    int n = x + y * 57 + _seed * 131;
    n = (n << 13) ^ n;
    return 1.0 -
        ((n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff) /
            1073741824.0;
  }

  double getValue(int x, int y) {
    return ((_noise2d(x, y) + 1.0) / 2.0).clamp(0.0, 1.0);
  }
}
