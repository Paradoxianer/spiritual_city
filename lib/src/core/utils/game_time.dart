/// Shared time constants for the game simulation.
///
/// All systems that simulate day/hour cycles should reference these
/// constants so the time scale stays consistent.
abstract final class GameTime {
  /// Real seconds representing one in-game day.
  /// Used by both [SpiritualDynamicsSystem] and [NPCComponent].
  static const double gameDaySeconds = 60.0;
}
