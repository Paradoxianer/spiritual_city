import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final log = Logger('ServiceLocator');
  log.info('Initializing Service Locator...');

  // Here we will register our Repositories, Services and BloCs/Models
  // Example:
  // getIt.registerLazySingleton<GameRepository>(() => HiveGameRepository());
  
  log.info('Service Locator initialized.');
}
