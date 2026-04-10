import 'package:flame/components.dart';

/// Data model for a Daemon entity in the invisible world.
///
/// Daemons wander through strongly negative cells and drain them further,
/// then dissolve when their energy is exhausted.
///
/// Lastenheft §31 / Issue #31
class DaemonModel {
  final String id;

  /// Position in world coordinates
  Vector2 position;

  /// Darkness energy (starts negative, drains toward 0, then dissolves)
  double energy;

  /// Whether this daemon has dissolved
  bool dissolved = false;

  DaemonModel({
    required this.id,
    required this.position,
    required this.energy,
  });
}
