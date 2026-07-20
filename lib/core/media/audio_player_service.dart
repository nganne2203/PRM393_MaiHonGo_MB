import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/settings/repositories/app_preferences_repository.dart';

class AudioPlayerService {
  final AudioPlayer _player;
  final AppPreferencesRepository preferencesRepository;

  AudioPlayerService({
    AudioPlayer? player,
    AppPreferencesRepository? preferencesRepository,
  })  : _player = player ?? AudioPlayer(),
        preferencesRepository =
            preferencesRepository ?? AppPreferencesRepository();

  Future<void> playUrl(String url) async {
    await _configureSession();
    await _applyPreferences();
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> playLocalFile(String path) async {
    await _configureSession();
    await _applyPreferences();
    await _player.setFilePath(path);
    await _player.play();
  }

  Future<void> pause() => _player.pause();

  Future<void> stop() => _player.stop();

  Future<void> replay() async {
    await _player.seek(Duration.zero);
    await _player.play();
  }

  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  Future<void> dispose() => _player.dispose();

  Future<void> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  Future<void> _applyPreferences() async {
    final settings = await preferencesRepository.getSettings();
    final volume =
        settings.soundEffectsEnabled ? settings.soundEffectVolume / 100 : 0.0;
    await _player.setVolume(volume);
  }
}
