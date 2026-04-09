import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import '../utils/seed_manager.dart';
import '../../features/game/domain/city_generator.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final log = Logger('ServiceLocator');
  log.info('Initializing Service Locator...');

  // World Seed (Fixed for now, can be dynamic later)
  getIt.registerSingleton<SeedManager>(SeedManager(42));

  // Domain Services
  getIt.registerLazySingleton<CityGenerator>(() => CityGenerator(getIt<SeedManager>()));
  
  log.info('Service Locator initialized.');
}
