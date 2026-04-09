import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import '../error/error_handler.dart';
import '../../features/player/domain/services/player_service.dart';
import '../../features/interaction/domain/services/prayer_service.dart';
import '../../features/audio/services/audio_service.dart';
import '../../features/assets/services/asset_service.dart';
import '../../features/persistence/data/hive_game_repository.dart';
import '../../features/persistence/domain/repositories/game_repository.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final log = Logger('ServiceLocator');
  log.info('Initializing Service Locator...');

  try {
    final box = await Hive.openBox<dynamic>('game_world');

    getIt.registerLazySingleton<PlayerService>(() => PlayerService());
    getIt.registerLazySingleton<PrayerService>(
      () => PrayerService(getIt<PlayerService>()),
    );
    getIt.registerLazySingleton<AudioService>(() => AudioService());
    getIt.registerLazySingleton<AssetService>(() => AssetService());
    getIt.registerLazySingleton<GameRepository>(
      () => HiveGameRepository(box),
    );
  } catch (e, st) {
    ErrorHandler.handle(e, st, context: 'setupServiceLocator');
  }

  log.info('Service Locator initialized.');
}
