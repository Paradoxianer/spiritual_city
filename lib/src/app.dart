import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/di/service_locator.dart';
import 'features/game/presentation/game_screen.dart';
import 'features/menu/domain/menu_service.dart';
import 'features/menu/presentation/difficulty_selector.dart';
import 'features/menu/presentation/load_game_screen.dart';
import 'features/menu/presentation/menu_screen.dart';
import 'features/menu/presentation/settings_screen.dart';

class SpiritWorldCityApp extends StatelessWidget {
  const SpiritWorldCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SpiritWorld City',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueGrey,
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/menu',
  routes: [
    GoRoute(
      path: '/menu',
      builder: (context, state) => MenuScreen(
        menuService: getIt<MenuService>(),
      ),
    ),
    GoRoute(
      path: '/difficulty',
      builder: (context, state) => DifficultySelector(
        menuService: getIt<MenuService>(),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => SettingsScreen(menuService: getIt<MenuService>()),
    ),
    GoRoute(
      path: '/info/:page',
      builder: (context, state) => InfoScreen(page: state.pathParameters['page'] ?? 'privacy'),
    ),
    GoRoute(
      path: '/load',
      builder: (context, state) => LoadGameScreen(
        menuService: getIt<MenuService>(),
      ),
    ),
    GoRoute(
      path: '/game',
      // The save only travels as `extra`, which a browser reload or a web
      // update (page reloaded at /#/game) does not keep: the game then ran
      // without a save behind it and 💾 silently did nothing (playtest
      // 2026-10-19). Back to the menu instead, to load the save again.
      redirect: (context, state) => state.extra == null ? '/menu' : null,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is GameSave) {
          return GameScreen(difficulty: extra.difficulty, gameSave: extra);
        }
        final difficulty = extra as Difficulty? ?? Difficulty.normal;
        return GameScreen(difficulty: difficulty);
      },
    ),
  ],
);
