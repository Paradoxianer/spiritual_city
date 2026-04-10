import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:logging/logging.dart';
import '../spirit_world_game.dart';
import '../../domain/models/city_chunk.dart';
import '../../domain/models/city_cell.dart';
import '../../domain/models/cell_object.dart';
import '../../domain/models/daemon_model.dart';
import 'daemon_component.dart';
import 'cell_component.dart';

/// Implements the Game-of-Life-style spiritual dynamics for the invisible world.
///
/// Each tick (every [tickInterval] seconds, representing one "game hour"):
/// - Cells with strong spiritual state influence their neighbours
/// - Positive cells spread light; negative cells spread darkness
/// - Church cells exert a constant positive baseline
/// - Very weakly-held cells decay slightly toward neutral
///
/// Lastenheft §5.2 & §5.3
class SpiritualDynamicsSystem extends Component with HasGameReference<SpiritWorldGame> {
  static final _log = Logger('SpiritualDynamicsSystem');

  /// How often (in real seconds) the spiritual world updates.
  /// 60 s = one "game day" – matches the NPC influence interval.
  static const double tickInterval = 60.0;

  /// Spread strength: how much a cell's state bleeds into neighbours per tick.
  static const double spreadFactor = 0.04;

  /// Natural decay toward neutral for weakly-held cells (|state| < 0.1).
  static const double decayRate = 0.98;

  /// Church passive bonus applied to the cell each tick.
  static const double churchBonus = 0.02;

  /// Fall-back rate (negative drift) for cells without neighbours or support.
  static const double fallbackRate = 0.005;

  double _timer = 0.0;

  // Daemon spawning
  static const int maxDaemons = 8;
  static const double daemonSpawnChance = 0.15; // per tick, per strongly-negative region
  int _daemonIdCounter = 0;
  final math.Random _rng = math.Random(77);

  // Modifier support – injected by the ModifierManager
  double modifierSpreadMultiplier = 1.0;  // Wachstum modifier
  double modifierDecayReduction = 0.0;    // Bewahrung modifier

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer >= tickInterval) {
      _timer = 0.0;
      _tick();
    }
  }

  void _tick() {
    final chunks = game.grid.getLoadedChunks();

    // We compute deltas first to avoid order-dependent updates.
    final Map<CityCell, double> deltas = {};

    for (final chunk in chunks) {
      for (int y = 0; y < CityChunk.chunkSize; y++) {
        for (int x = 0; x < CityChunk.chunkSize; x++) {
          final cell = chunk.cells['$x,$y'];
          if (cell == null) continue;

          double delta = 0.0;

          // 1. Neighbour influence (4-directional)
          double neighborSum = 0.0;
          int neighborCount = 0;
          for (final dir in _dirs) {
            final neighbor = game.grid.getCell(cell.x + dir[0], cell.y + dir[1]);
            if (neighbor != null) {
              neighborSum += neighbor.spiritualState;
              neighborCount++;
            }
          }
          if (neighborCount > 0) {
            final avgNeighbor = neighborSum / neighborCount;
            // Nudge toward the average of neighbours
            delta += (avgNeighbor - cell.spiritualState) *
                spreadFactor *
                modifierSpreadMultiplier;
          }

          // 2. Church cells act as anchors of positivity
          if (cell.data is BuildingData) {
            final bData = cell.data as BuildingData;
            if (bData.type == BuildingType.church ||
                bData.type == BuildingType.cathedral) {
              delta += churchBonus;
            }
          }

          // 3. Natural fallback – areas not actively supported drift negative
          //    (represents ongoing spiritual "pressure" in a fallen world)
          if (cell.spiritualState > -0.05) {
            delta -= fallbackRate * (1.0 - modifierDecayReduction);
          }

          // 4. Decay toward neutral for very weakly-held cells
          if (cell.spiritualState.abs() < 0.08) {
            delta += -cell.spiritualState * (1.0 - decayRate);
          }

          deltas[cell] = delta;
        }
      }
    }

    // Apply all deltas at once
    int updates = 0;
    for (final entry in deltas.entries) {
      final newState = (entry.key.spiritualState + entry.value).clamp(-1.0, 1.0);
      if ((newState - entry.key.spiritualState).abs() > 1e-6) {
        entry.key.spiritualState = newState;
        updates++;
      }
    }

    _log.fine('Spiritual tick: $updates cells updated');

    // Spawn daemons in strongly negative regions
    _maybeSpawnDaemons(chunks);
  }

  void _maybeSpawnDaemons(List<CityChunk> chunks) {
    int existingDaemons = game.world.children.whereType<DaemonComponent>().length;
    if (existingDaemons >= maxDaemons) return;

    outer:
    for (final chunk in chunks) {
      for (int y = 0; y < CityChunk.chunkSize; y += 4) {
        for (int x = 0; x < CityChunk.chunkSize; x += 4) {
          if (existingDaemons >= maxDaemons) break outer;
          final cell = chunk.cells['$x,$y'];
          if (cell == null) continue;
          if (cell.spiritualState < -0.8 && _rng.nextDouble() < daemonSpawnChance) {
            _spawnDaemon(cell);
            existingDaemons++;
          }
        }
      }
    }
  }

  void _spawnDaemon(CityCell cell) {
    final id = 'daemon_${_daemonIdCounter++}';
    final spawnPos = Vector2(
      cell.x * CellComponent.cellSize + CellComponent.cellSize / 2,
      cell.y * CellComponent.cellSize + CellComponent.cellSize / 2,
    );
    // Energy starts at -100 (strong) and drains toward 0
    final model = DaemonModel(id: id, position: spawnPos, energy: -100.0);
    final component = DaemonComponent(model);
    game.world.add(component);
    _log.fine('Spawned daemon $id at (${cell.x}, ${cell.y})');
  }

  static const List<List<int>> _dirs = [
    [1, 0], [-1, 0], [0, 1], [0, -1],
  ];
}
