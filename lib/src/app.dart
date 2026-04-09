import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/game/presentation/game_screen.dart';

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
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const GameScreen(),
    ),
  ],
);
