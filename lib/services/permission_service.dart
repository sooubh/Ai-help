import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  /// Requests essential permissions required for the app to function fully.
  /// This includes Microphone (for Voice Assistant) and Camera (for profile/activities).
  Future<void> requestEssentialPermissions() async {
    try {
      final statuses =
          await [Permission.microphone, Permission.camera].request();

      // Log statuses for debugging
      if (kDebugMode) {
        statuses.forEach((permission, status) {
          debugPrint('${permission.toString()}: ${status.toString()}');
        });
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }
}
