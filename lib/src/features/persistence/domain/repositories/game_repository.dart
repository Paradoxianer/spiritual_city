import '../../../city/domain/entities/city_grid.dart';
import '../../../player/domain/entities/player_state.dart';

abstract class GameRepository {
  Future<void> saveWorld(CityGrid grid, PlayerState player);
  Future<CityGrid?> loadGrid();
  Future<PlayerState?> loadPlayerState();
  Future<void> clear();
}
