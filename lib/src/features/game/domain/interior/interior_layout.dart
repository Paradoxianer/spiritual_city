import 'dart:math';

import '../../../../core/utils/stable_hash.dart';
import '../models/cell_object.dart';

/// Walkable building interiors – the third layer next to the city and the
/// invisible world (playtest 2026-10-18).
///
/// A room is generated the first time the pastor enters a building and is
/// the same on every later visit: everything is derived from the building
/// id, so nothing needs to be saved. Furniture that stands for an action of
/// the building is a *station* – walk up to the 📖 bookshelf to read, to
/// the 😴 bed to sleep, to the ⛪ altar to hold a service.
enum InteriorTile { wall, wallFace, floor, door }

enum FloorStyle { wood, stone, tiles }

/// Furniture in cells (w × h). Floor-level pieces (rugs, carpet) don't
/// block; wall decor hangs on the wall-face row.
enum FurnitureKind {
  bed(2, 2),
  hospitalBed(2, 2),
  diningTable(3, 2),
  roundTable(2, 2),
  chair(1, 1),
  armchair(1, 1),
  bookshelf(2, 1),
  lectern(1, 1),
  desk(2, 1),
  altar(3, 1),
  pew(4, 1),
  piano(2, 2),
  counter(1, 1),
  stove(1, 1),
  sink(1, 1),
  goodsShelf(1, 1),
  dresser(1, 1),
  plant(1, 1),
  candelabra(1, 1),
  barrel(1, 1),
  bench(2, 1),
  prayerCross(1, 1),
  fireplace(1, 1),
  rug(3, 2, blocks: false),
  carpet(1, 1, blocks: false),
  painting(1, 1, onWall: true),
  window(1, 1, onWall: true),
  cross(1, 1, onWall: true),
  banner(1, 1, onWall: true);

  const FurnitureKind(this.w, this.h, {this.blocks = true, this.onWall = false});
  final int w;
  final int h;
  final bool blocks;
  final bool onWall;
}

class Furniture {
  final FurnitureKind kind;
  final int x;
  final int y;

  /// The building action this piece stands for (a station), if any.
  final String? action;

  const Furniture(this.kind, this.x, this.y, {this.action});

  bool covers(int cx, int cy) =>
      cx >= x && cx < x + kind.w && cy >= y && cy < y + kind.h;

  /// Distance in cells from the cell centre ([px], [py]) to this piece.
  double distanceTo(double px, double py) {
    final dx = px < x ? x - px : (px > x + kind.w ? px - (x + kind.w) : 0.0);
    final dy = py < y ? y - py : (py > y + kind.h ? py - (y + kind.h) : 0.0);
    return sqrt(dx * dx + dy * dy);
  }
}

class InteriorLayout {
  final int width;
  final int height;
  final FloorStyle floor;
  final List<InteriorTile> _tiles;
  final List<Furniture> furniture;

  /// Door cell in the bottom wall; stepping onto it leaves the building.
  final (int, int) door;

  /// The hidden ✨ find.
  final (int, int) find;

  /// Where residents stand (as many as asked for, if the room has space).
  final List<(int, int)> residentSpots;

  InteriorLayout._(this.width, this.height, this.floor, this._tiles, this.furniture,
      this.door, this.find, this.residentSpots);

  InteriorTile tileAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return InteriorTile.wall;
    return _tiles[y * width + x];
  }

  Furniture? furnitureAt(int x, int y) {
    for (final f in furniture) {
      if (!f.kind.onWall && f.covers(x, y)) return f;
    }
    return null;
  }

  bool isWalkable(int x, int y) {
    final t = tileAt(x, y);
    if (t != InteriorTile.floor && t != InteriorTile.door) return false;
    for (final f in furniture) {
      if (f.kind.blocks && !f.kind.onWall && f.covers(x, y)) return false;
    }
    return true;
  }

  Iterable<Furniture> get stations => furniture.where((f) => f.action != null);

  /// Cell where the pastor stands after coming in.
  (int, int) get entry => (door.$1, door.$2 - 1);

  // ── Generation ──────────────────────────────────────────────────────────

  /// Extra stations the game may ask for besides the building actions.
  static const String churchOverview = 'churchOverview';
  static const String upgrades = 'upgrades';

  /// Which furniture stands for [action].
  static FurnitureKind stationKind(String action) => switch (action) {
        'readBible' => FurnitureKind.bookshelf,
        'eat' || 'houseVisit' => FurnitureKind.roundTable,
        'sleep' => FurnitureKind.bed,
        'pray' || 'prayForPoliticians' => FurnitureKind.prayerCross,
        'missions' || 'letterToManagement' || 'talkDirector' || 'blessPolice' ||
        'mayorAudience' || 'talkBoss' =>
          FurnitureKind.desk,
        'fast' || 'intercede' || 'counseling' => FurnitureKind.armchair,
        'practicalHelp' => FurnitureKind.sink,
        'discipleshipGroup' || churchOverview => FurnitureKind.diningTable,
        'blessHousehold' => FurnitureKind.fireplace,
        'sundayService' || 'chapelService' || 'funeral' => FurnitureKind.altar,
        'worship' => FurnitureKind.piano,
        'preach' || 'valueLecture' || 'majorEvent' => FurnitureKind.lectern,
        'medicalHelp' => FurnitureKind.hospitalBed,
        'prayerCircle' => FurnitureKind.rug,
        'comfort' => FurnitureKind.pew,
        'witness' => FurnitureKind.bench,
        'travel' || 'requestDonation' => FurnitureKind.counter,
        'shopping' => FurnitureKind.goodsShelf,
        'bless' => FurnitureKind.plant,
        'distribute' => FurnitureKind.barrel,
        upgrades => FurnitureKind.dresser,
        _ => FurnitureKind.candelabra,
      };

  static InteriorLayout generate({
    required String buildingId,
    required BuildingType type,
    required List<String> actions,
    int residents = 0,
  }) {
    final rand = Random(stableStringHash('$buildingId#interior'));
    final b = _Builder(rand, type);
    final isChurch = type == BuildingType.church || type == BuildingType.cathedral;
    if (isChurch) {
      b.church(actions);
    } else {
      b.room(actions);
    }
    return b.finish(residents);
  }
}

class _Builder {
  final Random rand;
  final BuildingType type;
  late int w;
  late int h;
  late FloorStyle floor;
  late List<InteriorTile> tiles;
  final List<Furniture> items = [];

  _Builder(this.rand, this.type);

  int get doorX => w ~/ 2;

  void _shell(int width, int height, FloorStyle style) {
    w = width;
    h = height;
    floor = style;
    tiles = List.filled(w * h, InteriorTile.floor);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (x == 0 || y == 0 || x == w - 1 || y == h - 1) {
          tiles[y * w + x] = InteriorTile.wall;
        } else if (y == 1) {
          tiles[y * w + x] = InteriorTile.wallFace;
        }
      }
    }
    tiles[(h - 1) * w + doorX] = InteriorTile.door;
  }

  bool _isFloor(int x, int y) =>
      x > 0 && y > 1 && x < w - 1 && y < h - 1 && tiles[y * w + x] == InteriorTile.floor;

  bool _occupied(int x, int y, {bool onWall = false}) {
    for (final f in items) {
      if (f.kind.onWall != onWall) continue;
      if (f.covers(x, y)) return true;
    }
    return false;
  }

  /// Cells in front of the door stay free so the way in is never blocked.
  bool _reserved(int x, int y) => (x - doorX).abs() <= 0 && y >= h - 3;

  bool _fits(FurnitureKind k, int x, int y) {
    for (int yy = y; yy < y + k.h; yy++) {
      for (int xx = x; xx < x + k.w; xx++) {
        if (!_isFloor(xx, yy) || _reserved(xx, yy) || _occupied(xx, yy)) return false;
      }
    }
    return true;
  }

  bool _walkable(int x, int y) {
    if (x == doorX && y == h - 1) return true;
    if (!_isFloor(x, y)) return false;
    for (final f in items) {
      if (f.kind.blocks && !f.kind.onWall && f.covers(x, y)) return false;
    }
    return true;
  }

  /// Every free floor cell can be reached from the door, and every station
  /// has a free neighbour.
  bool _connected() {
    final seen = <int>{};
    final queue = <(int, int)>[(doorX, h - 1)];
    seen.add((h - 1) * w + doorX);
    while (queue.isNotEmpty) {
      final (x, y) = queue.removeLast();
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = x + dx, ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        if (!_walkable(nx, ny) || !seen.add(ny * w + nx)) continue;
        queue.add((nx, ny));
      }
    }
    for (int y = 2; y < h - 1; y++) {
      for (int x = 1; x < w - 1; x++) {
        if (_walkable(x, y) && !seen.contains(y * w + x)) return false;
      }
    }
    for (final f in items.where((f) => f.action != null && f.kind.blocks)) {
      var reachable = false;
      for (int yy = f.y - 1; yy <= f.y + f.kind.h && !reachable; yy++) {
        for (int xx = f.x - 1; xx <= f.x + f.kind.w && !reachable; xx++) {
          if (seen.contains(yy * w + xx)) reachable = true;
        }
      }
      if (!reachable) return false;
    }
    return true;
  }

  /// Places [k] at a random spot that keeps the room walkable; [where]
  /// filters candidate top-left cells. Returns false if nothing fits.
  bool place(FurnitureKind k, {String? action, bool Function(int x, int y)? where}) {
    final candidates = <(int, int)>[
      for (int y = 2; y <= h - 1 - k.h; y++)
        for (int x = 1; x <= w - 1 - k.w; x++)
          if ((where == null || where(x, y)) && _fits(k, x, y)) (x, y),
    ];
    candidates.shuffle(rand);
    for (final (x, y) in candidates.take(40)) {
      items.add(Furniture(k, x, y, action: action));
      if (!k.blocks || _connected()) return true;
      items.removeLast();
    }
    return false;
  }

  bool _againstNorth(int x, int y) => y == 2;
  bool _againstWall(FurnitureKind k, int x, int y) =>
      y == 2 || x == 1 || x + k.w == w - 1 || y + k.h == h - 1;

  void _wallDecor(List<FurnitureKind> kinds) {
    final xs = [for (int x = 1; x < w - 1; x++) x]..shuffle(rand);
    var i = 0;
    for (final x in xs) {
      if (i >= kinds.length) break;
      if (items.any((f) => f.kind.onWall && (f.x - x).abs() <= 1)) continue;
      items.add(Furniture(kinds[i++], x, 1));
    }
  }

  // ── Templates ────────────────────────────────────────────────────────────

  void church(List<String> actions) {
    final big = type == BuildingType.cathedral;
    _shell(big ? 17 : 15, big ? 18 : 16, FloorStyle.stone);
    final cx = doorX;
    // Aisle carpet from the door to the altar.
    for (int y = 4; y < h - 1; y++) {
      items.add(Furniture(FurnitureKind.carpet, cx, y));
    }
    String? take(String a) => actions.contains(a) ? a : null;
    items.add(Furniture(FurnitureKind.altar, cx - 1, 2, action: take('sundayService')));
    items.add(Furniture(FurnitureKind.candelabra, cx - 2, 2));
    items.add(Furniture(FurnitureKind.candelabra, cx + 2, 2));
    items.add(Furniture(FurnitureKind.lectern, cx - 3, 4, action: take('preach')));
    items.add(Furniture(FurnitureKind.piano, cx + 3, 3, action: take('worship')));
    for (int y = 7; y < h - 3; y += 2) {
      items.add(Furniture(FurnitureKind.pew, cx - 5, y));
      items.add(Furniture(FurnitureKind.pew, cx + 2, y));
    }
    items.add(Furniture(FurnitureKind.plant, 1, h - 2));
    items.add(Furniture(FurnitureKind.plant, w - 2, h - 2));
    items.add(Furniture(FurnitureKind.cross, cx, 1));
    items.add(Furniture(FurnitureKind.banner, cx - 3, 1));
    items.add(Furniture(FurnitureKind.banner, cx + 3, 1));
    for (final x in [2, w - 3]) {
      items.add(Furniture(FurnitureKind.window, x, 1));
    }
    // Any other action (e.g. a future one) still gets a station.
    for (final a in actions) {
      if (items.any((f) => f.action == a)) continue;
      place(InteriorLayout.stationKind(a), action: a);
    }
  }

  void room(List<String> actions) {
    final large = switch (type) {
      BuildingType.hospital || BuildingType.school || BuildingType.university ||
      BuildingType.cityHall || BuildingType.mall || BuildingType.trainStation ||
      BuildingType.stadium || BuildingType.skyscraper || BuildingType.museum =>
        true,
      _ => false,
    };
    final style = switch (type) {
      BuildingType.hospital || BuildingType.policeStation || BuildingType.office ||
      BuildingType.skyscraper || BuildingType.supermarket || BuildingType.mall =>
        FloorStyle.tiles,
      BuildingType.cityHall || BuildingType.museum || BuildingType.trainStation ||
      BuildingType.cemetery || BuildingType.university =>
        FloorStyle.stone,
      _ => FloorStyle.wood,
    };
    _shell(
      large ? 16 + rand.nextInt(3) : 12 + rand.nextInt(3),
      large ? 13 + rand.nextInt(2) : 10 + rand.nextInt(2),
      style,
    );

    final homeLike = type == BuildingType.house ||
        type == BuildingType.apartment ||
        type == BuildingType.pastorHouse;

    // Kitchen row against the north wall at homes.
    if (homeLike) {
      final kitchen = [
        FurnitureKind.counter,
        if (!actions.contains('practicalHelp')) FurnitureKind.sink,
        FurnitureKind.stove,
        FurnitureKind.counter,
      ];
      final x0 = rand.nextBool() ? 1 : w - 1 - kitchen.length;
      for (var i = 0; i < kitchen.length; i++) {
        if (_fits(kitchen[i], x0 + i, 2)) items.add(Furniture(kitchen[i], x0 + i, 2));
      }
    }
    if (type == BuildingType.hospital) {
      for (int x = 2; x + 2 < w - 1; x += 3) {
        final first = x == 2;
        items.add(Furniture(FurnitureKind.hospitalBed, x, 2,
            action: first && actions.contains('medicalHelp') ? 'medicalHelp' : null));
      }
    }
    if (type == BuildingType.school || type == BuildingType.university) {
      for (int y = 6; y < h - 3; y += 2) {
        for (int x = 2; x + 2 < w - 1; x += 3) {
          if (x <= doorX && doorX < x + 2) continue;
          items.add(Furniture(FurnitureKind.desk, x, y));
        }
      }
    }
    if (type == BuildingType.supermarket || type == BuildingType.mall || type == BuildingType.shop) {
      for (int y = 5; y < h - 3; y += 3) {
        for (int x = 2; x < w - 2; x++) {
          if ((x - doorX).abs() <= 1 || x == w ~/ 4 || x == 3 * w ~/ 4) continue;
          items.add(Furniture(FurnitureKind.goodsShelf, x, y));
        }
      }
    }

    _specialFurniture(actions);

    // One station per action, big pieces first.
    final todo = [
      for (final a in actions)
        if (!items.any((f) => f.action == a)) a,
    ]..sort((a, b) {
        final ka = InteriorLayout.stationKind(a), kb = InteriorLayout.stationKind(b);
        return (kb.w * kb.h).compareTo(ka.w * ka.h);
      });
    for (final a in todo) {
      final k = InteriorLayout.stationKind(a);
      final ok = place(k, action: a, where: (x, y) => k.onWall || _againstWall(k, x, y)) ||
          place(k, action: a) ||
          place(FurnitureKind.candelabra, action: a);
      if (!ok) items.add(Furniture(FurnitureKind.carpet, 1, h - 2, action: a));
    }

    // Chairs next to tables.
    for (final t in items.where((f) =>
        f.kind == FurnitureKind.diningTable || f.kind == FurnitureKind.roundTable).toList()) {
      for (final (x, y) in [(t.x - 1, t.y), (t.x + t.kind.w, t.y), (t.x - 1, t.y + 1)]) {
        if (_fits(FurnitureKind.chair, x, y)) {
          items.add(Furniture(FurnitureKind.chair, x, y));
          if (!_connected()) items.removeLast();
        }
      }
    }

    // Decoration.
    if (homeLike) {
      place(FurnitureKind.rug, where: (x, y) => y > 3);
      place(FurnitureKind.dresser, where: (x, y) => _againstWall(FurnitureKind.dresser, x, y));
      if (!items.any((f) => f.kind == FurnitureKind.bookshelf)) {
        place(FurnitureKind.bookshelf, where: _againstNorth);
      }
    }
    for (var i = 0; i < 2 + rand.nextInt(2); i++) {
      place(FurnitureKind.plant, where: (x, y) => _againstWall(FurnitureKind.plant, x, y));
    }
    if (!homeLike) place(FurnitureKind.bench, where: (x, y) => y + 1 == h - 1);
    _wallDecor([
      FurnitureKind.window,
      FurnitureKind.painting,
      if (w > 12) FurnitureKind.window,
      if (type == BuildingType.pastorHouse || type == BuildingType.hospital) FurnitureKind.cross,
    ]);
  }

  /// Character pieces of the special buildings (registry landmarks and
  /// per-zone civic buildings); stations are placed afterwards around them.
  void _specialFurniture(List<String> actions) {
    void row(FurnitureKind k, int y, {int step = 0, bool skipDoor = true}) {
      final s = step == 0 ? k.w : step;
      for (int x = 2; x + k.w <= w - 2; x += s) {
        if (skipDoor && x <= doorX + 1 && doorX - 1 < x + k.w) continue;
        if (_fits(k, x, y)) {
          items.add(Furniture(k, x, y));
          if (k.blocks && !_connected()) items.removeLast();
        }
      }
    }

    switch (type) {
      case BuildingType.cityHall:
        // Council hall: red carpet to the mayor's desk, flags, benches.
        for (int y = 4; y < h - 1; y++) {
          items.add(Furniture(FurnitureKind.carpet, doorX, y));
        }
        items.add(Furniture(FurnitureKind.desk, doorX - 1, 2,
            action: actions.contains('mayorAudience') ? 'mayorAudience' : null));
        for (int y = 6; y < h - 3; y += 3) {
          row(FurnitureKind.bench, y, step: 3);
        }
        _wallDecorFixed([FurnitureKind.banner, FurnitureKind.banner], [doorX - 3, doorX + 3]);
      case BuildingType.trainStation:
        // Ticket counters along the back, waiting benches.
        for (int x = 2; x < w - 2; x += 2) {
          if (_fits(FurnitureKind.counter, x, 2)) {
            items.add(Furniture(FurnitureKind.counter, x, 2,
                action: x == 2 && actions.contains('travel') ? 'travel' : null));
          }
        }
        for (int y = 6; y < h - 3; y += 3) {
          row(FurnitureKind.bench, y, step: 3);
        }
      case BuildingType.stadium:
        // Event hall: a stage with a big rug at the front, stands behind.
        if (_fits(FurnitureKind.rug, doorX - 1, 3)) {
          items.add(Furniture(FurnitureKind.rug, doorX - 1, 3));
        }
        for (int y = 7; y < h - 3; y += 2) {
          row(FurnitureKind.pew, y, step: 5);
        }
      case BuildingType.policeStation:
        row(FurnitureKind.desk, 5, step: 4);
        row(FurnitureKind.chair, 6, step: 4);
        place(FurnitureKind.bench, where: (x, y) => y + 1 == h - 1);
      case BuildingType.fireStation:
        // Equipment along the walls.
        for (int y = 3; y < h - 2; y += 2) {
          for (final x in [1, w - 2]) {
            if (_fits(FurnitureKind.barrel, x, y)) items.add(Furniture(FurnitureKind.barrel, x, y));
          }
        }
        place(FurnitureKind.diningTable, where: (x, y) => y > 3);
      case BuildingType.postOffice:
        for (int x = 2; x < w - 2; x++) {
          if (x == doorX) continue;
          if (_fits(FurnitureKind.counter, x, 4)) items.add(Furniture(FurnitureKind.counter, x, 4));
          if (!_connected()) items.removeLast();
        }
        for (final x in [1, w - 2]) {
          if (_fits(FurnitureKind.barrel, x, 2)) items.add(Furniture(FurnitureKind.barrel, x, 2));
        }
      case BuildingType.library:
        // Rows of bookshelves with reading tables.
        for (int y = 2; y < h - 3; y += 3) {
          row(FurnitureKind.bookshelf, y, step: 3);
        }
        place(FurnitureKind.roundTable, where: (x, y) => y > 3);
      case BuildingType.museum:
        // Paintings and pedestals with plants.
        for (int y = 4; y < h - 3; y += 3) {
          row(FurnitureKind.plant, y, step: 3);
        }
        _wallDecor(const [
          FurnitureKind.painting,
          FurnitureKind.painting,
          FurnitureKind.painting,
          FurnitureKind.painting,
        ]);
      case BuildingType.powerPlant || BuildingType.factory || BuildingType.warehouse:
        for (int y = 3; y < h - 3; y += 3) {
          row(FurnitureKind.barrel, y, step: 2);
        }
      case BuildingType.cemetery:
        // Cemetery chapel: altar, candles, a few pews.
        items.add(Furniture(FurnitureKind.altar, doorX - 1, 2,
            action: actions.contains('funeral') ? 'funeral' : null));
        items.add(Furniture(FurnitureKind.candelabra, doorX - 2, 2));
        items.add(Furniture(FurnitureKind.candelabra, doorX + 2, 2));
        for (int y = 5; y < h - 3; y += 2) {
          if (_fits(FurnitureKind.pew, doorX - 5, y)) {
            items.add(Furniture(FurnitureKind.pew, doorX - 5, y,
                action: y == 5 && actions.contains('comfort') ? 'comfort' : null));
          }
          if (_fits(FurnitureKind.pew, doorX + 2, y)) items.add(Furniture(FurnitureKind.pew, doorX + 2, y));
        }
        _wallDecorFixed([FurnitureKind.cross], [doorX]);
      default:
        break;
    }
  }

  void _wallDecorFixed(List<FurnitureKind> kinds, List<int> xs) {
    for (var i = 0; i < kinds.length && i < xs.length; i++) {
      if (xs[i] > 0 && xs[i] < w - 1) items.add(Furniture(kinds[i], xs[i], 1));
    }
  }

  InteriorLayout finish(int residents) {
    final free = <(int, int)>[
      for (int y = 2; y < h - 1; y++)
        for (int x = 1; x < w - 1; x++)
          if (_walkable(x, y) && !_reserved(x, y) && !_occupied(x, y)) (x, y),
    ]..shuffle(rand);
    // ✨ prefers the back half of the room.
    final back = free.where((c) => c.$2 < h ~/ 2 + 1).toList();
    final find = back.isNotEmpty ? back.first : (free.isNotEmpty ? free.first : (1, 2));
    final spots = <(int, int)>[];
    for (final c in free) {
      if (spots.length >= residents) break;
      if (c == find) continue;
      // Not right next to a station, so the way to it stays clear.
      if (items.any((f) => f.action != null && f.distanceTo(c.$1 + 0.5, c.$2 + 0.5) < 0.9)) continue;
      if (spots.any((s) => (s.$1 - c.$1).abs() + (s.$2 - c.$2).abs() < 2)) continue;
      spots.add(c);
    }
    return InteriorLayout._(w, h, floor, tiles, List.unmodifiable(items), (doorX, h - 1), find,
        spots);
  }
}
