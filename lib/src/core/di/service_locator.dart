import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import '../utils/seed_manager.dart';
import '../../features/game/domain/city_generator.dart';
import '../../features/menu/data/menu_repository.dart';
import '../../features/menu/domain/menu_service.dart';
import '../../features/menu/domain/models/difficulty.dart';
import '../i18n/app_language.dart';
import '../i18n/app_strings.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final log = Logger('ServiceLocator');
  log.info('Initializing Service Locator...');

  // World Seed (Fixed for now, can be dynamic later)
  getIt.registerSingleton<SeedManager>(SeedManager(42));

  // Domain Services
  getIt.registerLazySingleton<CityGenerator>(() => CityGenerator(getIt<SeedManager>()));

  // i18n / Language
  final languageNotifier = LanguageNotifier(AppStrings.currentLanguage);
  getIt.registerSingleton<LanguageNotifier>(languageNotifier);

  // Difficulty notifier
  final difficultyNotifier = ValueNotifierDifficulty(Difficulty.normal);
  getIt.registerSingleton<ValueNotifierDifficulty>(difficultyNotifier);

  // Menu
  final menuRepository = MenuRepository();
  getIt.registerSingleton<MenuRepository>(menuRepository);

  final menuService = MenuService(
    repository: menuRepository,
    languageNotifier: languageNotifier,
    difficultyNotifier: difficultyNotifier,
  );
  getIt.registerSingleton<MenuService>(menuService);

  // Load persisted settings (language, last difficulty)
  await menuService.init();

  log.info('Service Locator initialized.');
}
