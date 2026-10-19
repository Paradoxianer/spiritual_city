/// The pastor's resources (docs/game_design/release_roadmap.md §2.1).
///
/// One enum so that costs, affordability checks and the cost hints shown on
/// action buttons all speak the same language.
enum Resource {
  faith('🙏'),
  health('❤️'),
  hunger('🍞'),
  materials('📦'),
  insight('📖');

  final String emoji;
  const Resource(this.emoji);
}

/// Read access to the player's current resource amounts.
///
/// Implemented by the game (and by simple fakes in tests), so domain code can
/// check affordability without depending on Flame.
abstract interface class ResourceWallet {
  double amountOf(Resource r);
}

/// What an action costs, e.g. `{faith: 5, health: 2}`.
///
/// The same object is used for the affordability check *and* for the hint on
/// the button, so the two can no longer drift apart.
class ResourceCost {
  final Map<Resource, double> amounts;

  const ResourceCost([this.amounts = const {}]);

  static const ResourceCost none = ResourceCost();

  bool get isFree => amounts.values.every((v) => v <= 0);

  double of(Resource r) => amounts[r] ?? 0.0;

  /// Health may never be spent down to zero (that would make the pastor
  /// faint), every other resource may be spent completely.
  static bool _enough(Resource r, double have, double need) =>
      r == Resource.health ? have > need : have >= need;

  /// The first resource the [wallet] cannot cover, or `null` if affordable.
  Resource? missing(ResourceWallet wallet) {
    for (final e in amounts.entries) {
      if (e.value <= 0) continue;
      if (!_enough(e.key, wallet.amountOf(e.key), e.value)) return e.key;
    }
    return null;
  }

  bool affordableBy(ResourceWallet wallet) => missing(wallet) == null;

  /// Emoji-only cost hint, e.g. `−5🙏−2❤️` (empty when free).
  String get hint {
    final b = StringBuffer();
    for (final r in Resource.values) {
      final v = of(r);
      if (v <= 0) continue;
      b.write('−${_fmt(v)}${r.emoji}');
    }
    return b.toString();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
