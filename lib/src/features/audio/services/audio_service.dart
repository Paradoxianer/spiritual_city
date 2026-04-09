import 'package:flame_audio/flame_audio.dart';
import 'package:logging/logging.dart';

class AudioService {
  final _log = Logger('AudioService');

  Future<void> playAmbient() async {
    try {
      await FlameAudio.bgm.play('ambient.mp3');
    } catch (e) {
      _log.warning('Failed to play ambient audio: $e');
    }
  }

  Future<void> stopAmbient() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (e) {
      _log.warning('Failed to stop ambient audio: $e');
    }
  }

  Future<void> playSpiritualAmbient() async {
    try {
      await FlameAudio.bgm.play('spiritual_ambient.mp3');
    } catch (e) {
      _log.warning('Failed to play spiritual ambient audio: $e');
    }
  }

  Future<void> stopSpiritualAmbient() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (e) {
      _log.warning('Failed to stop spiritual ambient audio: $e');
    }
  }
}
