import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_strings.dart';
import '../domain/menu_service.dart';
import '../domain/models/game_save.dart';
import 'widgets/menu_button.dart';

final _random = Random();

/// Difficulty selection screen. Clicking a difficulty card immediately starts
/// the game with the chosen difficulty and the seed entered in the seed field.
class DifficultySelector extends StatefulWidget {
  final MenuService menuService;

  const DifficultySelector({super.key, required this.menuService});

  @override
  State<DifficultySelector> createState() => _DifficultySelectorState();
}

class _DifficultySelectorState extends State<DifficultySelector> {
  final TextEditingController _seedController = TextEditingController();
  bool _isStarting = false;

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  /// Returns the seed from the text field, or a random seed if the field is
  /// empty / non-numeric.
  int _resolveSeed() {
    final parsed = int.tryParse(_seedController.text.trim());
    return parsed ?? _random.nextInt(999999999);
  }

  Future<void> _startGame(Difficulty difficulty) async {
    if (_isStarting) return;
    setState(() => _isStarting = true);
    try {
      await widget.menuService.setDifficulty(difficulty);
      final seed = _resolveSeed();
      final now = DateTime.now();
      final name = _buildDefaultSaveName(now);
      final save = GameSave(
        id: now.millisecondsSinceEpoch.toString(),
        name: name,
        createdAt: now,
        difficulty: difficulty,
        seed: seed,
      );
      await widget.menuService.writeSave(save);
      if (mounted) context.go('/game', extra: save);
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  /// Generates a human-readable default save name, e.g. "Spiel 17.04.2026".
  String _buildDefaultSaveName(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final prefix = AppStrings.get('game.saveName.prefix');
    return '$prefix $day.$month.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                  // Difficulty cards — clicking one immediately starts the game
                  _DifficultyCard(
                    difficulty: Difficulty.easy,
                    icon: '☁️',
                    onTap: () => _startGame(Difficulty.easy),
                    isLoading: _isStarting,
                  ),
                  const SizedBox(height: 10),
                  _DifficultyCard(
                    difficulty: Difficulty.normal,
                    icon: '⚔️',
                    onTap: () => _startGame(Difficulty.normal),
                    isLoading: _isStarting,
                  ),
                  const SizedBox(height: 10),
                  _DifficultyCard(
                    difficulty: Difficulty.hard,
                    icon: '🔥',
                    onTap: () => _startGame(Difficulty.hard),
                    isLoading: _isStarting,
                  ),
                  const SizedBox(height: 20),
                  // Seed input — shared for all difficulties, below the cards
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _seedController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        labelText: AppStrings.get('difficulty.seed'),
                        labelStyle: TextStyle(
                          color: Colors.blueGrey.shade400,
                          fontSize: 13,
                        ),
                        hintText: AppStrings.get('difficulty.seed.hint'),
                        hintStyle: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                        prefixIcon: Icon(
                          Icons.casino_outlined,
                          color: Colors.blueGrey.shade400,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.blueGrey.shade900,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blueGrey.shade700),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blueGrey.shade700),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.blueGrey.shade400,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  MenuButton(
                    icon: Icons.arrow_back,
                    label: AppStrings.get('difficulty.back'),
                    onPressed: _isStarting ? null : () => context.go('/menu'),
                    color: Colors.blueGrey.shade300,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
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
  final VoidCallback onTap;
  final bool isLoading;

  const _DifficultyCard({
    required this.difficulty,
    required this.icon,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (difficulty) {
      Difficulty.easy => AppStrings.get('difficulty.easy'),
      Difficulty.normal => AppStrings.get('difficulty.normal'),
      Difficulty.hard => AppStrings.get('difficulty.hard'),
    };
    final desc = switch (difficulty) {
      Difficulty.easy => AppStrings.get('difficulty.easy.desc'),
      Difficulty.normal => AppStrings.get('difficulty.normal.desc'),
      Difficulty.hard => AppStrings.get('difficulty.hard.desc'),
    };

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade900.withAlpha(220),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.blueGrey.shade700,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
            Icon(
              Icons.play_arrow,
              color: Colors.blueGrey.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
