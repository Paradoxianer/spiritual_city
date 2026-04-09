import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import '../domain/repositories/game_repository.dart';
import '../../city/domain/entities/city_grid.dart';
import '../../player/domain/entities/player_state.dart';
import '../../city/domain/services/city_generator.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/error/app_exceptions.dart';

class HiveGameRepository implements GameRepository {
  final Box<dynamic> _box;
  final _log = Logger('HiveGameRepository');

  static const _keySeed = 'seed';
  static const _keyFocus = 'player_focus';
  static const _keyEnergy = 'player_energy';
  static const _keySpiritual = 'player_spiritual';
  static const _keyWidth = 'grid_width';
  static const _keyHeight = 'grid_height';

  HiveGameRepository(this._box);

  @override
  Future<void> saveWorld(CityGrid grid, PlayerState player) async {
    try {
      await _box.put(_keySeed, GameConstants.defaultSeed);
      await _box.put(_keyWidth, grid.width);
      await _box.put(_keyHeight, grid.height);
      await _box.put(_keyFocus, player.focus);
      await _box.put(_keyEnergy, player.energy);
      await _box.put(_keySpiritual, player.spiritualStrength);
    } catch (e, st) {
      _log.severe('Failed to save world', e, st);
      throw StorageException('Failed to save world: $e');
    }
  }

  @override
  Future<CityGrid?> loadGrid() async {
    try {
      final seed = _box.get(_keySeed) as int?;
      final width = _box.get(_keyWidth) as int?;
      final height = _box.get(_keyHeight) as int?;
      if (seed == null || width == null || height == null) return null;
      return CityGeneratorService().generate(seed, width, height);
    } catch (e, st) {
      _log.severe('Failed to load grid', e, st);
      return null;
    }
  }

  @override
  Future<PlayerState?> loadPlayerState() async {
    try {
      final focus = _box.get(_keyFocus) as double?;
      final energy = _box.get(_keyEnergy) as double?;
      final spiritual = _box.get(_keySpiritual) as double?;
      if (focus == null || energy == null || spiritual == null) return null;
      return PlayerState(
        focus: focus,
        energy: energy,
        spiritualStrength: spiritual,
      );
    } catch (e, st) {
      _log.severe('Failed to load player state', e, st);
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _box.clear();
    } catch (e, st) {
      _log.severe('Failed to clear storage', e, st);
      throw StorageException('Failed to clear storage: $e');
    }
  }
}
