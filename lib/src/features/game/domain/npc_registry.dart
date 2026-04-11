import 'dart:math';
import 'package:flame/components.dart';
import 'models/npc_model.dart';
import '../presentation/components/cell_component.dart';
import 'models/city_chunk.dart';
import 'models/cell_object.dart';

class NPCRegistry {
  final Map<String, List<NPCModel>> _chunkNPCs = {};
  final Random _random;

  NPCRegistry({int? seed}) : _random = Random(seed ?? 42);

  List<NPCModel> getNPCsInChunk(int cx, int cy, {CityChunk? chunk}) {
    final key = '$cx,$cy';
    if (_chunkNPCs.containsKey(key)) {
      return _chunkNPCs[key]!;
    }

    if (chunk != null) {
      final npcs = _generateNPCsForChunk(chunk);
      _chunkNPCs[key] = npcs;
      return npcs;
    }

    return [];
  }

  List<NPCModel> _generateNPCsForChunk(CityChunk chunk) {
    final List<NPCModel> npcs = [];

    // Collect all walkable non-building cells for work-location assignment
    final List<Vector2> workCandidates = [];
    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;
        final data = cell.data;
        if (data is BuildingData &&
            !data.isEntrance &&
            (data.type == BuildingType.shop ||
                data.type == BuildingType.office ||
                data.type == BuildingType.factory ||
                data.type == BuildingType.supermarket)) {
          workCandidates.add(Vector2(
            chunk.getWorldX(x) * CellComponent.cellSize + CellComponent.cellSize / 2,
            chunk.getWorldY(y) * CellComponent.cellSize + CellComponent.cellSize / 2,
          ));
        }
      }
    }

    // Spawn NPCs at residential building entrances
    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;

        final data = cell.data;
        if (data is BuildingData && data.isEntrance) {
          if (data.type == BuildingType.house || data.type == BuildingType.apartment) {
            if (_random.nextDouble() < 0.7) {
              final workLoc = workCandidates.isNotEmpty
                  ? workCandidates[_random.nextInt(workCandidates.length)]
                  : null;
              npcs.add(_createRandomNPC(
                chunk.getWorldX(x),
                chunk.getWorldY(y),
                data.type,
                workLocation: workLoc,
              ));
            }
          }
        }
      }
    }
    return npcs;
  }

  NPCModel _createRandomNPC(int wx, int wy, BuildingType homeType,
      {Vector2? workLocation}) {
    final id = 'npc_${wx}_$wy';
    final name = _getRandomName();
    final type = _getNPCTypeForBuilding(homeType);
    final personality = NPCPersonality.values[_random.nextInt(NPCPersonality.values.length)];

    // Initialer Faith-Wert zwischen -60 und +20 (meistens eher distanziert am Anfang)
    final initialFaith = -60.0 + _random.nextDouble() * 80.0;

    return NPCModel(
      id: id,
      name: name,
      type: type,
      homePosition: Vector2(
        wx * CellComponent.cellSize + CellComponent.cellSize / 2,
        wy * CellComponent.cellSize + CellComponent.cellSize / 2,
      ),
      faith: initialFaith,
      personality: personality,
      workLocation: workLocation,
      energyLevel: 50.0 + _random.nextDouble() * 50.0,
    );
  }

  NPCType _getNPCTypeForBuilding(BuildingType bType) {
    if (bType == BuildingType.apartment) return NPCType.citizen;
    if (_random.nextDouble() < 0.2) return NPCType.merchant;
    return NPCType.citizen;
  }

  String _getRandomName() {
    // Diverse, realistic international names (Lastenheft: not biblically themed)
    const firstNames = [
      'Maria', 'Klaus', 'Ahmed', 'Sofia', 'Yuki', 'Leila', 'Jonas', 'Fatima',
      'David', 'Anna', 'Lukas', 'Mei', 'Thomas', 'Sarah', 'Omar', 'Elena',
      'Marco', 'Aisha', 'Felix', 'Priya', 'Lena', 'Carlos', 'Emma', 'Kwame',
      'Nina', 'Ravi', 'Hannah', 'Miguel', 'Laura', 'Yusuf',
    ];
    const lastNames = [
      'Müller', 'Schmidt', 'Schneider', 'Fischer', 'Weber', 'Meyer', 'Wagner',
      'Becker', 'Schulz', 'Hoffmann', 'Kaya', 'Hassan', 'Tanaka', 'Rossi',
      'Mensah', 'Santos', 'Ivanova', 'Patel', 'Nguyen', 'Okonkwo',
    ];
    return '${firstNames[_random.nextInt(firstNames.length)]} ${lastNames[_random.nextInt(lastNames.length)]}';
  }

  List<NPCModel> getNPCsNear(Vector2 position, double radius) {
    return [];
  }
}
