part of '../game_screen.dart';

/// Walkable interior (release_roadmap.md §3.5, simplified): the room's
/// 12×12 emoji grid, explored by tapping.
///
/// - Tap a floor cell: the pastor 🧍 walks there (shortest path, around
///   furniture).
/// - Tap furniture that stands for an action (📖 → read the Bible, 🛏️ →
///   sleep, …): he walks next to it and the action starts.
/// - Each building hides one ✨ find, deterministic from its id; it shows
///   once he comes close and pays out once.
/// - Residents stand in the room (their faith face).
class _WalkableRoom extends StatefulWidget {
  final List<List<String>> cells;
  final BuildingModel building;
  final List<GameAction<BuildingModel>> actions;
  final SpiritWorldGame game;
  final void Function(String actionType) onAction;
  final void Function(String reaction) onFind;
  final bool busy;

  const _WalkableRoom({
    required this.cells,
    required this.building,
    required this.actions,
    required this.game,
    required this.onAction,
    required this.onFind,
    required this.busy,
  });

  @override
  State<_WalkableRoom> createState() => _WalkableRoomState();
}

class _WalkableRoomState extends State<_WalkableRoom> {
  static const double _cell = 20.0;
  static const int _n = 12;

  /// Door: bottom middle, inside the wall.
  (int, int) _pos = (_n - 2, _n ~/ 2);
  List<(int, int)> _path = const [];
  Timer? _walker;
  String? _pendingAction;

  late final (int, int) _find = _findCell();
  late final Map<(int, int), String> _residents = _residentCells();

  @override
  void dispose() {
    _walker?.cancel();
    super.dispose();
  }

  bool _isFloor(int r, int c) =>
      r > 0 && c > 0 && r < _n - 1 && c < _n - 1 &&
      widget.cells[r][c] == '·' &&
      !_residents.containsKey((r, c));

  /// The ✨ find: a deterministic floor cell away from the door.
  (int, int) _findCell() {
    final floor = <(int, int)>[
      for (int r = 1; r < _n - 3; r++)
        for (int c = 1; c < _n - 1; c++)
          if (widget.cells[r][c] == '·') (r, c),
    ];
    if (floor.isEmpty) return (1, 1);
    return floor[stableStringHash('${widget.building.buildingId}#find') % floor.length];
  }

  /// Residents stand on deterministic floor cells.
  Map<(int, int), String> _residentCells() {
    final out = <(int, int), String>{};
    final rs = widget.building.residents;
    for (var i = 0; i < rs.length && i < 4; i++) {
      final h = stableStringHash('${rs[i].id}#room');
      for (var k = 0; k < 40; k++) {
        final r = 2 + (h + k * 7) % (_n - 5);
        final c = 1 + (h ~/ 13 + k * 5) % (_n - 2);
        if (widget.cells[r][c] == '·' && !out.containsKey((r, c)) && (r, c) != _find) {
          final f = rs[i].faith;
          out[(r, c)] = rs[i].isChristian ? '😇' : (f > 0 ? '🙂' : '😐');
          break;
        }
      }
    }
    return out;
  }

  /// Furniture emoji → action of this building (only actions it offers).
  String? _actionFor(String emoji) {
    const map = <String, List<String>>{
      '📖': ['readBible', 'discipleshipGroup', 'valueLecture', 'sundayService'],
      '📚': ['missions', 'letterToManagement'],
      '🛏️': ['sleep', 'counseling', 'medicalHelp'],
      '☕': ['eat', 'houseVisit', 'talkBoss'],
      '🍳': ['eat', 'houseVisit'],
      '🙏': ['pray', 'worship', 'prayerCircle'],
      '✝️': ['worship', 'sundayService', 'funeral'],
      '🕯️': ['pray', 'worship'],
      '🩺': ['medicalHelp'],
      '💊': ['medicalHelp'],
      '🛒': ['shopping'],
      '💼': ['talkBoss'],
      '🗳️': ['mayorAudience'],
      '🎫': ['travel'],
      '🏟️': ['majorEvent'],
    };
    final candidates = map[emoji];
    if (candidates == null) return null;
    for (final t in candidates) {
      if (widget.actions.any((a) => a.type == t)) return t;
    }
    return null;
  }

  /// Breadth-first path over floor cells; [to] itself may be a non-floor
  /// target (then the path ends next to it).
  List<(int, int)> _route((int, int) to, {bool adjacentOk = false}) {
    final prev = <(int, int), (int, int)>{};
    final queue = <(int, int)>[_pos];
    final seen = {_pos};
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      final reached = cur == to ||
          (adjacentOk && (cur.$1 - to.$1).abs() + (cur.$2 - to.$2).abs() == 1);
      if (reached) {
        final path = <(int, int)>[];
        var p = cur;
        while (p != _pos) {
          path.insert(0, p);
          p = prev[p]!;
        }
        return path;
      }
      for (final d in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = (cur.$1 + d.$1, cur.$2 + d.$2);
        if (seen.contains(nx)) continue;
        if (!_isFloor(nx.$1, nx.$2) && nx != _find) continue;
        seen.add(nx);
        prev[nx] = cur;
        queue.add(nx);
      }
    }
    return const [];
  }

  void _tap(int r, int c) {
    if (widget.busy) return;
    final emoji = widget.cells[r][c];
    final action = emoji == '·' || emoji == '▓' ? null : _actionFor(emoji);
    if (action != null) {
      _walk(_route((r, c), adjacentOk: true), then: action);
    } else if (_isFloor(r, c) || (r, c) == _find) {
      _walk(_route((r, c)));
    }
  }

  void _walk(List<(int, int)> path, {String? then}) {
    _walker?.cancel();
    _pendingAction = then;
    if (path.isEmpty) {
      _arrive();
      return;
    }
    _path = path;
    _walker = Timer.periodic(const Duration(milliseconds: 110), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _pos = _path.first;
        _path = _path.sublist(1);
      });
      if (_path.isEmpty) {
        t.cancel();
        _arrive();
      }
    });
  }

  void _arrive() {
    if (_pos == _find && !widget.building.findCollected) {
      widget.onFind(widget.game.collectFind(widget.building));
      setState(() {});
    }
    final a = _pendingAction;
    _pendingAction = null;
    if (a != null) widget.onAction(a);
  }

  bool get _findVisible =>
      !widget.building.findCollected &&
      (_pos.$1 - _find.$1).abs() + (_pos.$2 - _find.$2).abs() <= 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int r = 0; r < _n; r++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int c = 0; c < _n; c++) _cellWidget(r, c),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cellWidget(int r, int c) {
    final base = widget.cells[r][c];
    String glyph = base;
    if ((r, c) == _pos) {
      glyph = '🧍';
    } else if (_residents.containsKey((r, c))) {
      glyph = _residents[(r, c)]!;
    } else if ((r, c) == _find && _findVisible) {
      glyph = '✨';
    }
    final isAction = base != '·' && base != '▓' && _actionFor(base) != null;
    return GestureDetector(
      onTap: () => _tap(r, c),
      child: Container(
        width: _cell,
        height: _cell,
        alignment: Alignment.center,
        decoration: isAction
            ? BoxDecoration(
                color: const Color(0x33FFD54F),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Text(
          glyph,
          style: TextStyle(
            fontSize: 14,
            color: (glyph == '▓' || glyph == '·') ? Colors.white.withValues(alpha: 0.38) : null,
          ),
        ),
      ),
    );
  }
}
