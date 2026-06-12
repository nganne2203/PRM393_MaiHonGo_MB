import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'permission_service.dart';

class RecordingService {
  final AudioRecorder _recorder;
  final PermissionService _permissionService;

  RecordingService({
    AudioRecorder? recorder,
    PermissionService permissionService = const PermissionService(),
  })  : _recorder = recorder ?? AudioRecorder(),
        _permissionService = permissionService;

  Future<String> startRecording() async {
    final granted = await _permissionService.requestMicrophonePermission();
    if (!granted || !await _recorder.hasPermission()) {
      throw const RecordingException('Microphone permission denied.');
    }

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/speaking-${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    return path;
  }

  Future<String?> stopRecording() => _recorder.stop();

  Future<void> dispose() => _recorder.dispose();
}

class RecordingException implements Exception {
  final String message;

  const RecordingException(this.message);

  @override
  String toString() => message;
}
