import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FCM notification service — request permissions,
/// handle foreground/background, and store user preference.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _enabledKey = 'notifications_enabled';

  /// Initialize FCM: request permissions and get token.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? true;

    if (!enabled) return;

    await _requestPermissions();
    await _subscribeToTopics();
  }

  /// Request notification permissions from the OS.
  Future<bool> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Subscribe to default topics for daily reminders.
  Future<void> _subscribeToTopics() async {
    await _messaging.subscribeToTopic('daily_reminders');
    await _messaging.subscribeToTopic('progress_updates');
  }

  /// Unsubscribe from notification topics.
  Future<void> _unsubscribeFromTopics() async {
    await _messaging.unsubscribeFromTopic('daily_reminders');
    await _messaging.unsubscribeFromTopic('progress_updates');
  }

  /// Check if push notifications are currently enabled.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  /// Enable or disable push notifications.
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (enabled) {
      await _requestPermissions();
      await _subscribeToTopics();
    } else {
      await _unsubscribeFromTopics();
    }
  }

  /// Get the current FCM token (useful for server-side targeting).
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
