import 'package:flame/components.dart';

import 'daemon_kind.dart';

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

  /// The energy value at spawn time – used for normalising the health arc.
  final double initialEnergy;

  /// Whether this daemon has dissolved
  bool dissolved = false;

  /// Type with its weakness (#178).
  final DaemonKind kind;

  /// Visible strength 1–3: bigger body and trail, more energy.
  final int tier;

  /// For a [DaemonKind.possessor]: id of the possessed NPC it came from.
  final String? hostNpcId;

  DaemonModel({
    required this.id,
    required this.position,
    required this.energy,
    this.kind = DaemonKind.leech,
    this.tier = 1,
    this.hostNpcId,
  }) : initialEnergy = energy;
}
