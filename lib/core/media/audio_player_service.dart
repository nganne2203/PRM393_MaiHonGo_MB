import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _player;

  AudioPlayerService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  Future<void> playUrl(String url) async {
    await _configureSession();
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> playLocalFile(String path) async {
    await _configureSession();
    await _player.setFilePath(path);
    await _player.play();
  }

  Future<void> pause() => _player.pause();

  Future<void> stop() => _player.stop();

  Future<void> replay() async {
    await _player.seek(Duration.zero);
    await _player.play();
  }

  Future<void> dispose() => _player.dispose();

  Future<void> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }
}
