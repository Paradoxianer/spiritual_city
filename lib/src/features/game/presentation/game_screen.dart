import 'dart:async';
import 'dart:math' show atan2, pi, Random, sin;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../features/menu/domain/menu_service.dart';
import '../domain/actions/building_actions.dart';
import '../domain/actions/game_action.dart';
import '../domain/actions/npc_actions.dart';
import '../domain/actions/practice.dart';
import '../domain/models/base_interactable_entity.dart';
import '../domain/models/building_model.dart';
import '../domain/models/cell_object.dart';
import '../domain/models/game_keymap.dart';
import '../domain/models/npc_backstory.dart';
import '../domain/models/npc_model.dart';
import '../domain/models/npc_reaction.dart';
import '../domain/models/prayer_combat.dart';
import '../domain/services/faith_calculator_service.dart';
import '../domain/services/tutorial_service.dart';
import '../presentation/components/building_component.dart';
import 'spirit_world_game.dart';
import 'widgets/action_button.dart';
import 'widgets/overlay_shell.dart';

part 'hud/hud.dart';
part 'overlays/building_interior.dart';
part 'overlays/look.dart';
part 'overlays/missions.dart';
part 'overlays/npc_dialog.dart';
part 'overlays/pause.dart';
part 'overlays/shared.dart';
part 'overlays/tutorial.dart';
part 'overlays/upgrades.dart';
part 'overlays/win.dart';

class GameScreen extends StatefulWidget {
  final Difficulty difficulty;

  /// The save slot associated with this session.  Non-null for both new and
  /// loaded games (a fresh save is created before the screen is pushed).
  final GameSave? gameSave;

  const GameScreen({
    super.key,
    this.difficulty = Difficulty.normal,
    this.gameSave,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final SpiritWorldGame _game;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _game = SpiritWorldGame(
      difficulty: widget.difficulty,
      gameSave: widget.gameSave,
    );
    // Seed the tutorial-completed flag from global app settings so that a
    // fresh save doesn't re-show the tutorial if the player has already
    // finished it in a previous session.
    if (getIt<MenuService>().isTutorialCompleted) {
      _game.tutorialService.isTutorialCompleted = true;
    }
  }

  /// Captures the current game state, persists it to Hive and returns to the
  /// main menu.  Used by the pause menu's "Save & Quit".
  Future<void> _saveAndQuit() async {
    final save = _game.gameSave;
    if (save == null) {
      if (mounted) context.go('/menu');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final state = _game.captureGameState();
      await getIt<MenuService>().updateSaveState(save.id, state);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        context.go('/menu');
      }
    }
  }

  /// Captures and persists the current game state without leaving the game.
  /// Used by the pause menu's "Save" button.
  Future<void> _saveOnly() async {
    final save = _game.gameSave;
    if (save == null) return;
    setState(() => _isSaving = true);
    try {
      final state = _game.captureGameState();
      await getIt<MenuService>().updateSaveState(save.id, state);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // There is nothing to pop – /game replaces the router stack – so the
      // Android/desktop back gesture must never be allowed to fall through
      // to the OS (which would silently kill the app with unsaved progress,
      // Issue #162).  It is routed into the game's own escape handling
      // instead, which closes overlays first and opens the pause menu.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _game.handleEscape();
      },
      child: Scaffold(
        body: Stack(
        children: [
          GameWidget(
            game: _game,
            overlayBuilderMap: {
              'DialogOverlay': (context, game) => DialogOverlay(game: _game),
              'BuildingInteriorOverlay': (context, game) =>
                  BuildingInteriorOverlay(game: _game),
              'LookOverlay': (context, game) => LookOverlay(game: _game),
              'MissionBoardOverlay': (context, game) =>
                  MissionBoardOverlay(game: _game),
              'KeymapOverlay': (context, game) =>
                  KeymapOverlay(game: _game),
              'PauseMenuOverlay': (context, game) => PauseMenuOverlay(
                    game: _game,
                    isSaving: _isSaving,
                    onSave: _saveOnly,
                    onSaveAndQuit: _saveAndQuit,
                  ),
            },
          ),
          // Loading overlay – shown until the world is ready
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (isReady) return const SizedBox.shrink();
              return const _LoadingOverlay();
            },
          ),
          // Pause button – the single entry point for Help, Save and
          // Save & Quit (Issue #162 / #174).  Replaces the former separate
          // "X" (save & quit) and "?" (help) buttons, which overlapped the
          // combat HUD buttons in the same corner.
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return Positioned(
                top: 12,
                right: 12,
                child: SafeArea(
                  child: IconButton(
                    onPressed: _isSaving ? null : _game.openPauseMenu,
                    tooltip: AppStrings.get('game.pause.button'),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.pause),
                  ),
                ),
              );
            },
          ),
          // Resource HUD + Pastorhouse compass – combined in a single Positioned
          // column so the compass is always rendered directly below the resource
          // bars, regardless of how tall the bar panel happens to be.
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, left: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ResourceHud(gameRef: _game),
                        _PastorhouseHud(game: _game),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Street-name label – persistent top-center
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return _StreetLabel(game: _game);
            },
          ),
          // Loot pickup toast – briefly shown when a material package is collected
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return _LootToast(game: _game);
            },
          ),
          // Mission complete toast – briefly shown when a mission is completed.
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return _MissionCompleteToast(game: _game);
            },
          ),
          // Health alarm – red pulsing edge overlay when health < 15%
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return _HealthAlarmOverlay(game: _game);
            },
          ),
          // Faint overlay – full-screen blackout during faint animation
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return _FaintOverlay(game: _game);
            },
          ),
          // Wakeup toast – shown after recovering from a faint
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return _WakeupToast(game: _game);
            },
          ),
          // Saving overlay – centered indicator shown while persisting to Hive.
          if (_isSaving)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save, size: 48, color: Colors.white70),
                    SizedBox(height: 16),
                    CircularProgressIndicator(
                      color: Colors.white70,
                      strokeWidth: 2,
                    ),
                  ],
                ),
              ),
            ),
          // Tutorial overlay – shown for new players until tutorial is complete.
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return _TutorialOverlay(game: _game);
            },
          ),
          // Win screen – shown when the player has converted all NPCs and
          // liberated all loaded city cells.
          ValueListenableBuilder<bool>(
            valueListenable: _game.isWorldReady,
            builder: (context, isReady, _) {
              if (!isReady) return const SizedBox.shrink();
              return _WinScreenOverlay(game: _game);
            },
          ),
        ],
        ),
      ),
    );
  }
}

/// Animated spiritual loading screen shown while the city generates.
class _LoadingOverlay extends StatefulWidget {
  const _LoadingOverlay();

  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _verses = [
    '"Der Herr ist mein Hirte" – Psalm 23,1',
    '"Bittet, so wird euch gegeben" – Mt 7,7',
    '"Die Wahrheit wird euch frei machen" – Joh 8,32',
    '"Ich kann alles durch Christus" – Phil 4,13',
    '"Gott ist Liebe" – 1 Joh 4,8',
  ];

  int _verseIndex = 0;
  Timer? _verseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Cycle through Bible verses every 2.5 s – use a cancellable Timer
    _verseTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        setState(() => _verseIndex = (_verseIndex + 1) % _verses.length);
      }
    });
  }

  @override
  void dispose() {
    _verseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = _controller.value;
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing cross / spiritual symbol
                Opacity(
                  opacity: 0.5 + pulse * 0.5,
                  child: Text(
                    '✝',
                    style: TextStyle(
                      fontSize: 64 + pulse * 12,
                      color: Colors.amber,
                      shadows: [
                        Shadow(
                          color: Colors.amber.withValues(alpha: 0.6),
                          blurRadius: 20 + pulse * 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'SPIRITWORLD CITY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Die Stadt erwacht...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),
                // Glowing progress dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final dotPhase = (pulse + i / 3) % 1.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.purpleAccent.withValues(
                            alpha: 0.3 + dotPhase * 0.7,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purpleAccent.withValues(alpha: dotPhase * 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                // Bible verse
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Text(
                    _verses[_verseIndex],
                    key: ValueKey(_verseIndex),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
