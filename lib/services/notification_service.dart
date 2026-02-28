import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Notification service — handles FCM (remote) and local scheduled notifications
/// for daily reminders, streaks, and comeback retention.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  static const String _enabledKey = 'notifications_enabled';
  static const String _hourKey = 'noti_hour';
  static const String _minuteKey = 'noti_minute';

  // Notification Channel IDs
  static const String _dailyChannelId = 'daily_reminders';
  static const String _streakChannelId = 'streak_updates';
  static const String _retentionChannelId = 'comeback_reminders';

  /// Initialize Notifications: request permissions, init timezones, and set up local channels.
  Future<void> init() async {
    tz.initializeTimeZones();

    // Initialize Local Notifications
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotifs.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: null,
    );

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? true;

    if (!enabled) return;

    await _requestPermissions();
    await _subscribeToTopics();

    // Load saved time or default to 9:00 AM
    final hour = prefs.getInt(_hourKey) ?? 9;
    final minute = prefs.getInt(_minuteKey) ?? 0;
    await scheduleDailyReminder(hour: hour, minute: minute);
  }

  /// Request notification permissions from the OS (FCM + Local).
  Future<bool> _requestPermissions() async {
    // Request FCM
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Request Local (iOS)
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _localNotifs
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(sound: true, alert: true, badge: true);
    }

    // Request Local (Android 13+) -> Handled mostly by FCM request, but can be explicit if needed.

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

  /// Enable or disable ALL notifications (Push + Local).
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (enabled) {
      final granted = await _requestPermissions();
      if (granted) {
        await _subscribeToTopics();
        final hour = prefs.getInt(_hourKey) ?? 9;
        final minute = prefs.getInt(_minuteKey) ?? 0;
        await scheduleDailyReminder(hour: hour, minute: minute);
      }
    } else {
      await _unsubscribeFromTopics();
      await _localNotifs.cancelAll();
    }
  }

  /// Get the currently scheduled reminder time.
  Future<TimeOfDay> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_hourKey) ?? 9;
    final minute = prefs.getInt(_minuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Get the current FCM token (useful for server-side targeting).
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // ─── Local Scheduling Logic ──────────────────────────────────────────────

  /// Schedules a daily reminder at a specific time (e.g., 9:00 AM).
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!await isEnabled()) return;

    // Persist the choice
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _dailyChannelId,
      'Daily Reminders',
      channelDescription: 'Daily reminders to log activities or check-in.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifs.zonedSchedule(
      id: 0, // id
      title: 'Daily Check-in', // title
      body: "It's time to review today's progress and activities.", // body
      scheduledDate: scheduledDate, // scheduledDate
      notificationDetails: details, // notificationDetails
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Sends an immediate streak warning notification.
  Future<void> showStreakWarning(String message) async {
    if (!await isEnabled()) return;

    const androidDetails = AndroidNotificationDetails(
      _streakChannelId,
      'Streak Updates',
      channelDescription: 'Notifications about your activity streaks.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifs.show(
      id: 1,
      title: 'Streak at Risk!',
      body: message,
      notificationDetails: details,
    );
  }

  /// Schedules inactivity (retention) reminders holding off for 2, 5, and 7 days.
  /// Call this when the app goes into the background.
  Future<void> scheduleInactivityReminders() async {
    if (!await isEnabled()) return;

    await cancelInactivityReminders(); // Clear old ones to reset timer

    const androidDetails = AndroidNotificationDetails(
      _retentionChannelId,
      'Comeback Reminders',
      channelDescription:
          'Reminders when you haven\'t used the app in a while.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);

    // 2 Days Inactivity
    await _localNotifs.zonedSchedule(
      id: 102,
      title: 'We miss you!',
      body: 'It\'s been a couple of days. Come check your progress!',
      scheduledDate: now.add(const Duration(days: 2)),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // 5 Days Inactivity
    await _localNotifs.zonedSchedule(
      id: 105,
      title: 'Keep the momentum going',
      body: 'Consistency is key for progress. Log an activity today.',
      scheduledDate: now.add(const Duration(days: 5)),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // 7 Days Inactivity
    await _localNotifs.zonedSchedule(
      id: 107,
      title: 'It\'s been a week!',
      body:
          'Don\'t lose track of the great work you\'ve started. Open the app to continue.',
      scheduledDate: now.add(const Duration(days: 7)),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancels any scheduled inactivity reminders.
  /// Call this when the app comes back to the foreground.
  Future<void> cancelInactivityReminders() async {
    await _localNotifs.cancel(id: 102);
    await _localNotifs.cancel(id: 105);
    await _localNotifs.cancel(id: 107);
  }
}
