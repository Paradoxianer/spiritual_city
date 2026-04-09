import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:logging/logging.dart';

class AssetService {
  final _log = Logger('AssetService');
  final Map<String, Sprite> _cache = {};

  Future<Sprite?> getSprite(String path) async {
    if (_cache.containsKey(path)) return _cache[path];
    try {
      final image = await Flame.images.load(path);
      final sprite = Sprite(image);
      _cache[path] = sprite;
      return sprite;
    } catch (e) {
      _log.warning('Failed to load sprite at $path: $e');
      return null;
    }
  }
}
