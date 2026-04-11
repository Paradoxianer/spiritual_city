import 'package:flame/components.dart';
import 'package:logging/logging.dart';
import '../../domain/models/npc_model.dart';
import 'npc_component.dart';

/// Object pool that recycles [NPCComponent] instances to avoid per-frame
/// allocations and GC pressure when NPCs are spawned / despawned as the
/// player moves across chunk boundaries.
///
/// Usage:
/// ```dart
/// final npc = pool.borrow(model);   // reuse or create
/// world.add(npc);
///
/// // … later …
/// pool.returnNPC(npc);             // deactivate + return to pool
/// ```
class NPCPool {
  static final _log = Logger('NPCPool');

  final int maxSize;
  final List<NPCComponent> _pool = [];

  int _totalCreated = 0;
  int _totalReused = 0;

  NPCPool({this.maxSize = 150});

  /// Returns an [NPCComponent] configured for [model].
  ///
  /// If a recycled component is available it is reset with the new model,
  /// otherwise a fresh component is allocated.
  NPCComponent borrow(NPCModel model) {
    if (_pool.isNotEmpty) {
      final npc = _pool.removeLast();
      npc.assignModel(model);
      _totalReused++;
      return npc;
    }
    _totalCreated++;
    return NPCComponent(model: model);
  }

  /// Deactivates [npc] and returns it to the pool if there is room.
  void returnNPC(NPCComponent npc) {
    npc.deactivateForPool();
    if (_pool.length < maxSize) {
      _pool.add(npc);
    } else {
      _log.fine('Pool full ($maxSize), discarding NPC');
    }
  }

  /// Number of components currently sitting idle in the pool.
  int get available => _pool.length;

  /// Cumulative allocation count since construction.
  int get totalCreated => _totalCreated;

  /// Cumulative reuse count since construction.
  int get totalReused => _totalReused;
}
