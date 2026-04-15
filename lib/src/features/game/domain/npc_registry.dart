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

    // ── Step 1: collect unique buildings and all their cells ─────────────────
    // Map from buildingId → (buildingType, list of local [x,y] coords)
    final Map<String, _BuildingInfo> buildings = {};
    for (int y = 0; y < CityChunk.chunkSize; y++) {
      for (int x = 0; x < CityChunk.chunkSize; x++) {
        final cell = chunk.cells['$x,$y'];
        if (cell == null) continue;
        final data = cell.data;
        if (data is BuildingData) {
          buildings.putIfAbsent(
            data.buildingId,
            () => _BuildingInfo(data.type, data.buildingId),
          ).cells.add([x, y]);
        }
      }
    }

    // ── Step 2: for each building spawn N NPCs at a walkable start position ──
    for (final bInfo in buildings.values) {
      final count = _npcCountForType(bInfo.type);
      if (count == 0) continue;

      // Find a walkable spawn position: look for a road or open cell adjacent
      // to any cell of this building.
      final spawnCell = _findWalkableNeighbour(chunk, bInfo.cells);
      if (spawnCell == null) continue; // building is landlocked – skip

      final spawnWx = chunk.getWorldX(spawnCell[0]);
      final spawnWy = chunk.getWorldY(spawnCell[1]);
      final spawnPos = Vector2(
        spawnWx * CellComponent.cellSize + CellComponent.cellSize / 2,
        spawnWy * CellComponent.cellSize + CellComponent.cellSize / 2,
      );

      for (int i = 0; i < count; i++) {
        final id = 'npc_${bInfo.buildingId}_$i';
        final age = _generateAge();
        npcs.add(NPCModel(
          id: id,
          name: _getRandomName(),
          type: _getNPCTypeForBuilding(bInfo.type),
          homePosition: spawnPos.clone(),
          homeBuildingId: bInfo.buildingId,
          age: age,
          lifeStory: _generateLifeStory(age),
          faith: -60.0 + _random.nextDouble() * 80.0,
        ));
      }
    }

    return npcs;
  }

  /// NPC density per building type: `(min, extra)`.
  /// Total = min + random.nextInt(extra), so (1, 2) yields 1 or 2 NPCs.
  /// extra = 0 means exactly min NPCs.
  static const Map<BuildingType, (int, int)> _buildingNPCDensity = {
    BuildingType.house:        (1, 2), // 1–2
    BuildingType.apartment:    (2, 3), // 2–4
    BuildingType.church:       (1, 2), // 1–2
    BuildingType.cathedral:    (1, 2), // 1–2
    BuildingType.shop:         (1, 1), // 1
    BuildingType.supermarket:  (1, 2), // 1–2
    BuildingType.mall:         (2, 3), // 2–4
    BuildingType.office:       (1, 2), // 1–2
    BuildingType.skyscraper:   (1, 2), // 1–2
    BuildingType.school:       (1, 2), // 1–2
    BuildingType.university:   (2, 2), // 2–3
    BuildingType.hospital:     (1, 2), // 1–2
    BuildingType.policeStation:(1, 1), // 1
    BuildingType.fireStation:  (1, 1), // 1
    BuildingType.postOffice:   (1, 1), // 1
    BuildingType.trainStation: (1, 2), // 1–2
    BuildingType.cityHall:     (1, 2), // 1–2
    BuildingType.library:      (1, 1), // 1
    BuildingType.museum:       (1, 1), // 1
    BuildingType.stadium:      (2, 3), // 2–4
    BuildingType.factory:      (1, 1), // 1
    BuildingType.warehouse:    (1, 1), // 1
    BuildingType.powerPlant:   (1, 1), // 1
    BuildingType.cemetery:     (0, 0), // 0
  };

  /// How many NPCs live/work in a building of [type].
  int _npcCountForType(BuildingType type) {
    final (min, extra) = _buildingNPCDensity[type] ?? (1, 1);
    return min + (extra > 0 ? _random.nextInt(extra) : 0);
  }

  NPCType _getNPCTypeForBuilding(BuildingType type) {
    switch (type) {
      case BuildingType.church:
      case BuildingType.cathedral:
        return NPCType.priest;
      case BuildingType.shop:
      case BuildingType.supermarket:
      case BuildingType.mall:
        return _random.nextDouble() < 0.5 ? NPCType.merchant : NPCType.citizen;
      case BuildingType.policeStation:
        return NPCType.officer;
      default:
        return NPCType.citizen;
    }
  }

  /// Searches the direct neighbours of every cell in [buildingCells] for a
  /// walkable (non-building) cell inside [chunk].  Returns its [x, y] local
  /// coordinates, or null if none is found.
  List<int>? _findWalkableNeighbour(CityChunk chunk, List<List<int>> buildingCells) {
    const dirs = [
      [0, 1], [0, -1], [1, 0], [-1, 0],
    ];
    for (final cell in buildingCells) {
      for (final d in dirs) {
        final nx = cell[0] + d[0];
        final ny = cell[1] + d[1];
        if (nx < 0 || ny < 0 || nx >= CityChunk.chunkSize || ny >= CityChunk.chunkSize) {
          continue;
        }
        final neighbour = chunk.cells['$nx,$ny'];
        if (neighbour == null) continue;
        // Accept road cells or empty (null-data) cells; reject other buildings
        final data = neighbour.data;
        if (data is RoadData || data is NatureData) return [nx, ny];
      }
    }
    return null;
  }

  // ── Name generation (Issue #49) ──────────────────────────────────────────

  // 100+ first names: German, English, and further cultural diversity.
  static const List<String> _firstNames = [
    // German male
    'Lukas', 'Johannes', 'Peter', 'Thomas', 'Matthias', 'Stefan', 'Markus',
    'Michael', 'Christian', 'Andreas', 'Daniel', 'Sebastian', 'Tobias',
    'Florian', 'Niklas', 'Felix', 'Leon', 'Jonas', 'Philipp', 'Benjamin',
    // German female
    'Maria', 'Sarah', 'Anna', 'Elisabeth', 'Martha', 'Katharina', 'Laura',
    'Lena', 'Julia', 'Sophie', 'Hannah', 'Lea', 'Emma', 'Clara', 'Mia',
    'Franziska', 'Christina', 'Monika', 'Sabine', 'Ursula',
    // English male
    'James', 'John', 'William', 'David', 'Richard', 'Joseph', 'Charles',
    'Robert', 'Henry', 'Edward', 'George', 'Samuel', 'Nathan', 'Elijah',
    'Noah', 'Liam', 'Oliver', 'Ethan', 'Lucas', 'Mason',
    // English female
    'Mary', 'Emma', 'Olivia', 'Ava', 'Isabella', 'Sophia', 'Charlotte',
    'Amelia', 'Harper', 'Evelyn', 'Abigail', 'Emily', 'Elizabeth', 'Grace',
    'Chloe', 'Victoria', 'Rachel', 'Rebecca', 'Natalie', 'Audrey',
    // French
    'Pierre', 'Jacques', 'Michel', 'François', 'Henri', 'Marie', 'Isabelle',
    'Chloé', 'Manon', 'Amélie',
    // Italian
    'Marco', 'Luca', 'Antonio', 'Giuseppe', 'Giovanna', 'Lucia', 'Chiara',
    // Spanish/Portuguese
    'Carlos', 'Miguel', 'Diego', 'Isabella', 'Sofia', 'Valentina',
    // Eastern European
    'Aleksander', 'Dmitri', 'Ivan', 'Natasha', 'Oksana', 'Miroslav',
    // African/Arabic
    'Ibrahim', 'Omar', 'Fatima', 'Aisha', 'Kwame', 'Amara',
    // Asian
    'Yuki', 'Kenji', 'Lin', 'Wei', 'Priya', 'Arjun',
  ];

  // 50+ last names: diverse cultural backgrounds.
  static const List<String> _lastNames = [
    // German
    'Müller', 'Schmidt', 'Schneider', 'Fischer', 'Weber', 'Meyer', 'Wagner',
    'Becker', 'Schulz', 'Hoffmann', 'Schäfer', 'Koch', 'Bauer', 'Richter',
    'Klein', 'Wolf', 'Schröder', 'Neumann', 'Schwarz', 'Zimmermann',
    // English
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Miller', 'Davis',
    'Wilson', 'Anderson', 'Taylor', 'Thomas', 'Jackson', 'White', 'Harris',
    'Martin', 'Thompson', 'Young', 'Robinson', 'Walker', 'Hall',
    // French/Italian
    'Dubois', 'Moreau', 'Fontaine', 'Rossi', 'Ferrari', 'Conti',
    // Spanish/Portuguese
    'Garcia', 'Rodriguez', 'Martinez', 'Lopez', 'Hernandez', 'Silva',
    // Eastern European
    'Novak', 'Kowalski', 'Petrov', 'Popescu', 'Horvath',
    // African/Arabic
    'Hassan', 'Ibrahim', 'Al-Rashid', 'Diallo', 'Mensah',
    // Asian
    'Tanaka', 'Kimura', 'Wang', 'Li', 'Patel', 'Kumar',
  ];

  String _getRandomName() {
    final first = _firstNames[_random.nextInt(_firstNames.length)];
    final last = _lastNames[_random.nextInt(_lastNames.length)];
    return '$first $last';
  }

  // ── Age generation ───────────────────────────────────────────────────────

  /// Generates a realistic NPC age between 18 and 85.
  int _generateAge() => 18 + _random.nextInt(68); // 18–85

  // ── Life story generation ────────────────────────────────────────────────

  // Emoji pools for each life area: positive, neutral, negative.
  static const _childhoodPos  = '👶🏡😊';
  static const _childhoodNeu  = '👶🏫😐';
  static const _childhoodNeg  = '👶😢🌧️';

  static const _schoolPos     = '🏫📚⭐';
  static const _schoolNeu     = '🏫📚😐';
  static const _schoolNeg     = '🏫😔📚';

  static const _familyPos     = '👨‍👩‍👧😊❤️';
  static const _familyNeu     = '👪😐💭';
  static const _familyNeg     = '💔😢👪';

  static const _educationPos  = '🎓✨💼';
  static const _educationNeu  = '🎓📖😐';
  static const _educationNeg  = '🎓😔❌';

  static const _workPos       = '💼😊🏆';
  static const _workNeu       = '💼😐📋';
  static const _workNeg       = '💼😞🔥';

  static const _faithPos      = '⛪🙏✨';
  static const _faithNeu      = '🤔💭❓';
  static const _faithNeg      = '😤🚫⛪';

  static const _marriagePos   = '💑😊💍';
  static const _marriageNeu   = '💑😐🏠';
  static const _marriageNeg   = '💔😢💍';

  /// Picks one of three variants (positive/neutral/negative) randomly.
  String _pickVariant(String pos, String neu, String neg) {
    final roll = _random.nextDouble();
    if (roll < 0.35) return pos;
    if (roll < 0.65) return neu;
    return neg;
  }

  /// Generates 4–6 life story segments based on the NPC's [age].
  List<String> _generateLifeStory(int age) {
    final segments = <String>[];

    // Everyone has childhood
    segments.add(_pickVariant(_childhoodPos, _childhoodNeu, _childhoodNeg));

    if (age >= 14) {
      segments.add(_pickVariant(_schoolPos, _schoolNeu, _schoolNeg));
    }
    if (age >= 18) {
      segments.add(_pickVariant(_familyPos, _familyNeu, _familyNeg));
    }
    if (age >= 22) {
      segments.add(_pickVariant(_educationPos, _educationNeu, _educationNeg));
    }
    if (age >= 25) {
      segments.add(_pickVariant(_workPos, _workNeu, _workNeg));
    }
    // ~60 % chance of marriage segment for adults
    if (age >= 20 && _random.nextDouble() < 0.6) {
      segments.add(_pickVariant(_marriagePos, _marriageNeu, _marriageNeg));
    }
    // Faith background for older NPCs (30+)
    if (age >= 30) {
      segments.add(_pickVariant(_faithPos, _faithNeu, _faithNeg));
    }

    return segments;
  }

  List<NPCModel> getNPCsNear(Vector2 position, double radius) {
    return [];
  }
}

class _BuildingInfo {
  final BuildingType type;
  final String buildingId;
  final List<List<int>> cells = [];
  _BuildingInfo(this.type, this.buildingId);
}

