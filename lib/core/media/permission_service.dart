import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  const PermissionService();

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
}
