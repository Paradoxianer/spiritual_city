import 'package:flame/game.dart';
import 'package:logging/logging.dart';
import '../../core/utils/seed_manager.dart';
import '../domain/city_generator.dart';
import '../domain/models/city_grid.dart';
import 'components/cell_component.dart';

class SpiritWorldGame extends FlameGame {
  final _log = Logger('SpiritWorldGame');
  
  late final CityGrid grid;
  late final SeedManager seedManager;
  late final CityGenerator generator;

  @override
  Future<void> onLoad() async {
    _log.info('Loading SpiritWorldGame...');

    // Initialize deterministic seed (e.g., 42 for testing)
    seedManager = SeedManager(42);
    generator = CityGenerator(seedManager);

    // Generate a 20x20 grid for the MVP start
    grid = generator.generate(20, 20);

    // Add cells to the game
    for (final cell in grid.getAllCells()) {
      add(CellComponent(cell));
    }

    // Adjust camera to see the grid
    camera.viewfinder.anchor = Anchor.topLeft;
    _log.info('SpiritWorldGame loaded with ${grid.getAllCells().length} cells.');
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Game logic updates
  }
}
