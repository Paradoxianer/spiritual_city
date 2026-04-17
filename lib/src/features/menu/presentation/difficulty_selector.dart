import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_strings.dart';
import '../domain/menu_service.dart';
import '../domain/models/game_save.dart';
import 'widgets/menu_button.dart';

/// Difficulty selection screen. Navigates to `/game` with the chosen difficulty.
class DifficultySelector extends StatefulWidget {
  final MenuService menuService;

  const DifficultySelector({super.key, required this.menuService});

  @override
  State<DifficultySelector> createState() => _DifficultySelectorState();
}

class _DifficultySelectorState extends State<DifficultySelector> {
  late Difficulty _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.menuService.difficultyNotifier.value;
  }

  void _select(Difficulty d) {
    setState(() => _selected = d);
  }

  Future<void> _startGame() async {
    await widget.menuService.setDifficulty(_selected);
    // Create a new save slot immediately so the game always has a save ID.
    final now = DateTime.now();
    final name = _buildDefaultSaveName(now);
    final save = GameSave(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: now,
      difficulty: _selected,
    );
    await widget.menuService.writeSave(save);
    if (mounted) context.go('/game', extra: save);
  }

  /// Generates a human-readable default save name, e.g. "Spiel 17.04.2026".
  String _buildDefaultSaveName(DateTime dt) {
    final day   = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return 'Spiel $day.$month.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  AppStrings.get('difficulty.title'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 22,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _DifficultyCard(
                  difficulty: Difficulty.easy,
                  icon: '☁️',
                  selected: _selected == Difficulty.easy,
                  onTap: () => _select(Difficulty.easy),
                ),
                const SizedBox(height: 12),
                _DifficultyCard(
                  difficulty: Difficulty.normal,
                  icon: '⚔️',
                  selected: _selected == Difficulty.normal,
                  onTap: () => _select(Difficulty.normal),
                ),
                const SizedBox(height: 12),
                _DifficultyCard(
                  difficulty: Difficulty.hard,
                  icon: '🔥',
                  selected: _selected == Difficulty.hard,
                  onTap: () => _select(Difficulty.hard),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MenuButton(
                      icon: Icons.arrow_back,
                      label: AppStrings.get('difficulty.back'),
                      onPressed: () => context.go('/menu'),
                      color: Colors.blueGrey.shade300,
                    ),
                    const SizedBox(width: 16),
                    MenuButton(
                      icon: Icons.play_arrow,
                      label: AppStrings.get('difficulty.start'),
                      onPressed: () => _startGame(),
                      color: Colors.lightGreenAccent.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final Difficulty difficulty;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.difficulty,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (difficulty) {
      Difficulty.easy => AppStrings.get('difficulty.easy'),
      Difficulty.normal => AppStrings.get('difficulty.normal'),
      Difficulty.hard => AppStrings.get('difficulty.hard'),
    };
    final verse = switch (difficulty) {
      Difficulty.easy => AppStrings.get('difficulty.easy.verse'),
      Difficulty.normal => AppStrings.get('difficulty.normal.verse'),
      Difficulty.hard => AppStrings.get('difficulty.hard.verse'),
    };
    final desc = switch (difficulty) {
      Difficulty.easy => AppStrings.get('difficulty.easy.desc'),
      Difficulty.normal => AppStrings.get('difficulty.normal.desc'),
      Difficulty.hard => AppStrings.get('difficulty.hard.desc'),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 340,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blueGrey.shade800
              : Colors.blueGrey.shade900.withAlpha(200),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.blueGrey.shade400 : Colors.blueGrey.shade800,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    verse,
                    style: TextStyle(
                      color: Colors.blueGrey.shade300,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      color: Colors.blueGrey.shade400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
