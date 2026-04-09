import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../player/domain/services/player_service.dart';
import '../../interaction/domain/services/prayer_service.dart';
import 'spirit_world_game.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final SpiritWorldGame _game;

  @override
  void initState() {
    super.initState();
    _game = SpiritWorldGame(
      playerService: getIt<PlayerService>(),
      prayerService: getIt<PrayerService>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        loadingBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
