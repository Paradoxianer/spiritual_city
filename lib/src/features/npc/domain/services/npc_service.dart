import 'dart:math';
import 'package:flame/components.dart';
import '../entities/npc.dart';
import '../../../city/domain/entities/cell_type.dart';
import '../../../city/domain/entities/city_grid.dart';
import '../../../../core/constants/game_constants.dart';

class NpcService {
  List<Npc> generateNpcs(CityGrid grid, int seed) {
    final random = Random(seed);
    final roadCells = <(int, int)>[];

    for (int y = 0; y < grid.height; y++) {
      for (int x = 0; x < grid.width; x++) {
        if (grid.cellAt(x, y).type == CellType.road) {
          roadCells.add((x, y));
        }
      }
    }

    final npcs = <Npc>[];
    for (int i = 0; i < roadCells.length && npcs.length < 20; i += 10) {
      final (x, y) = roadCells[i];
      final spiritualState = (random.nextDouble() * 200) - 100;
      npcs.add(Npc(
        id: 'npc_$i',
        name: 'Resident ${npcs.length + 1}',
        spiritualState: spiritualState,
        position: Vector2(
          x * GameConstants.cellSize,
          y * GameConstants.cellSize,
        ),
      ));
    }
    return npcs;
  }
}
