import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../core/utils/app_logger.dart';

// ─── Background tap handler (top-level, required by flutter_local_notifications)
// Must be top-level + @pragma so the AOT compiler keeps it in release builds.

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  // Routing is handled on next foreground launch via getNotificationAppLaunchDetails.
  // Nothing to do here — existence of this function satisfies the plugin requirement.
}

// ─── Notification Channel Constants ──────────────────────────────────────────

/// Centralised channel metadata — referenced from both the main isolate
/// and the WorkManager isolate in main.dart so IDs never drift.
class NotificationChannels {
  NotificationChannels._();

  static const String progressId = 'progress_channel';
  static const String progressName = 'Progress Updates';
  static const Importance progressImportance = Importance.high;

  static const String dailyId = 'daily_channel';
  static const String dailyName = 'Daily Reminders';
  static const Importance dailyImportance = Importance.high;

  static const String streakId = 'streak_channel';
  static const String streakName = 'Streak Alerts';
  static const Importance streakImportance = Importance.max;

  static const String inactivityId = 'inactivity_channel';
  static const String inactivityName = 'Inactivity Reminders';
  static const Importance inactivityImportance = Importance.defaultImportance;
}

// ─── NotificationService ─────────────────────────────────────────────────────

/// Singleton — manages FCM push and local scheduled notifications.
/// Call [init] once from main() after Firebase is ready.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  // ─── Navigator key (injected by main.dart for tap-to-navigate) ───────────
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Call once in main() after the navigatorKey is created:
  ///   NotificationService.setNavigatorKey(navigatorKey)
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // ─── SharedPreferences keys ──────────────────────────────────────────────
  static const String _enabledKey = 'notifications_enabled';
  static const String _hourKey = 'reminder_hour';
  static const String _minuteKey = 'reminder_minute';

  // ─── Notification IDs ────────────────────────────────────────────────────
  static const int dailyReminderId = 100;
  static const int streakWarningId = 200;
  static const int progressUpdateId = 300;
  static const int inactivity2DayId = 401;
  static const int inactivity5DayId = 402;
  static const int inactivity7DayId = 403;

  // ─── WorkManager unique task names ───────────────────────────────────────
  static const String progressTaskUniqueName = 'care_ai_progress_update';
  static const String progressTaskName = 'progressUpdateTask';
  static const String inactivity2dUniqueName = 'care_ai_inactivity_2d';
  static const String inactivity5dUniqueName = 'care_ai_inactivity_5d';
  static const String inactivity7dUniqueName = 'care_ai_inactivity_7d';
  static const String inactivityTaskName = 'inactivityTask';

  bool _localNotifsInitialized = false;

  // ─── Initialisation ──────────────────────────────────────────────────────

  /// Must be called once from main() after Firebase is initialised.
  Future<void> init() async {
    // 1. Timezone data
    try {
      tz.initializeTimeZones();
    } catch (e, stack) {
      AppLogger.error('NotificationService', 'Timezone init failed', e, stack);
    }

    // 2. flutter_local_notifications (Android + iOS)
    await _initLocalNotifications();
    if (!_localNotifsInitialized) return;

    // 3. Cold-start: app killed while notification was tapped
    try {
      final launchDetails = await _localNotifs.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleTap(launchDetails!.notificationResponse?.payload);
        });
      }
    } catch (e, stack) {
      AppLogger.error(
          'NotificationService', 'cold-start tap check failed', e, stack);
    }

    // 4. Bail if user has disabled notifications
    final enabled = await _safeIsEnabled();
    if (!enabled) {
      AppLogger.info(
          'NotificationService', 'Notifications disabled — skipping setup');
      return;
    }

    // 5. OS permissions
    await _requestPermissions();

    // 6. FCM topics + token sync
    await _subscribeToTopics();
    await _setupFcmTokenSync();

    // 7. Daily reminder
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt(_hourKey) ?? 9;
      final minute = prefs.getInt(_minuteKey) ?? 0;
      await scheduleDailyReminder(hour: hour, minute: minute);
    } catch (e, stack) {
      AppLogger.error(
          'NotificationService', 'init: scheduleDailyReminder failed', e, stack);
    }

    AppLogger.info('NotificationService', 'init complete');
  }

  Future<void> _initLocalNotifications() async {
    try {
      const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initIOS = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: initAndroid,
        iOS: initIOS,
      );
      await _localNotifs.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (r) => _handleTap(r.payload),
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      _localNotifsInitialized = true;
      AppLogger.info(
          'NotificationService', 'flutter_local_notifications initialized');
    } catch (e, stack) {
      AppLogger.error(
          'NotificationService', '_initLocalNotifications failed', e, stack);
    }
  }

  /// Routes a tapped notification to the correct named route.
  void _handleTap(String? payload) {
    try {
      final ctx = _navigatorKey?.currentContext;
      if (ctx == null) return;
      const routes = {
        'progress': '/progress',
        'daily_plan': '/daily-plan',
        'streak': '/progress',
      };
      Navigator.pushNamed(ctx, routes[payload] ?? '/home');
      AppLogger.info('NotificationService', 'Notification tap → ${routes[payload] ?? '/home'}');
    } catch (e, stack) {
      AppLogger.error('NotificationService', '_handleTap failed', e, stack);
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Android 13+ runtime permission
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.notification.status;
        if (status.isDenied || status.isRestricted) {
          await Permission.notification.request();
        }
      }

      // iOS local notification permission
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _localNotifs
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(sound: true, alert: true, badge: true);
      }

      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      AppLogger.info(
          'NotificationService', 'Permissions — authorized: $authorized');
      return authorized;
    } catch (e, stack) {
      AppLogger.error(
          'NotificationService', '_requestPermissions failed', e, stack);
      return false;
    }
  }

  Future<void> _subscribeToTopics() async {
    try {
      await _messaging.subscribeToTopic('daily_reminders');
      await _messaging.subscribeToTopic('progress_updates');
      AppLogger.info('NotificationService', 'Subscribed to FCM topics');
    } catch (e, stack) {
      AppLogger.error(
          'NotificationService', '_subscribeToTopics failed', e, stack);
    }
  }

  Future<void> _unsubscribeFromTopics() async {
    try {
      await _messaging.unsubscribeFromTopic('daily_reminders');
      await _messaging.unsubscribeFromTopic('progress_updates');
    } catch (e, stack) {
      AppLogger.error(
          'NotificationService', '_unsubscribeFromTopics failed', e, stack);
    }
  }

  Future<void> _setupFcmTokenSync() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _saveTokenToFirestore(token);
      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
      AppLogger.info('NotificationService', 'FCM token sync configured');
    } catch (e, stack) {
      AppLogger.error(
          'NotificationService', '_setupFcmTokenSync failed', e, stack);
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token});
      AppLogger.info('NotificationService', 'FCM token persisted to Firestore');
    } catch (e, stack) {
      AppLogger.error(
          'NotificationService', '_saveTokenToFirestore failed', e, stack);
    }
  }

  // ─── Battery optimisation (Android only, asked once) ─────────────────────

  /// Requests the "ignore battery optimizations" permission on Android so
  /// WorkManager and exact alarms can fire reliably in Doze mode.
  /// Called at most once — guarded by a SharedPreferences flag.
  Future<void> requestBatteryExemption() async {
    if (!Platform.isAndroid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('battery_opt_requested') == true) return;
      await Permission.ignoreBatteryOptimizations.request();
      await prefs.setBool('battery_opt_requested', true);
      AppLogger.info(
          'NotificationService', 'Battery optimization exemption requested');
    } catch (e, stack) {
      AppLogger.error(
          'NotificationService', 'requestBatteryExemption failed', e, stack);
    }
  }

  // ─── Public helpers ──────────────────────────────────────────────────────

  Future<bool> isEnabled() async => _safeIsEnabled();

  Future<bool> _safeIsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_enabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    try {
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
    } catch (e, stack) {
      AppLogger.error('NotificationService', 'setEnabled failed', e, stack);
    }
  }

  Future<TimeOfDay> getReminderTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return TimeOfDay(
        hour: prefs.getInt(_hourKey) ?? 9,
        minute: prefs.getInt(_minuteKey) ?? 0,
      );
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e, stack) {
      AppLogger.error('NotificationService', 'getToken failed', e, stack);
      return null;
    }
  }

  // ─── Scheduling ──────────────────────────────────────────────────────────

  /// Schedules the daily check-in at [hour]:[minute] using exactAllowWhileIdle.
  /// Moves to tomorrow if the time has already passed today.
  /// Payload: 'daily_plan' → opens /daily-plan on tap.
  Future<void> scheduleDailyReminder({int hour = 9, int minute = 0}) async {
    if (!await _safeIsEnabled()) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_hourKey, hour);
      await prefs.setInt(_minuteKey, minute);

      await _localNotifs.cancel(id: dailyReminderId);

      final now = tz.TZDateTime.now(tz.local);
      var scheduled =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final androidDetails = AndroidNotificationDetails(
        NotificationChannels.dailyId,
        NotificationChannels.dailyName,
        channelDescription: 'Daily reminders to log activities or check in.',
        importance: NotificationChannels.dailyImportance,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      final details = NotificationDetails(
          android: androidDetails, iOS: const DarwinNotificationDetails());

      await _localNotifs.zonedSchedule(
        id: dailyReminderId,
        title: 'Daily Check-in',
        body: "It's time to review today's progress and activities.",
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_plan',
      );
      AppLogger.info(
          'NotificationService', 'Daily reminder scheduled for $hour:$minute');
    } catch (e, stack) {
      AppLogger.error(
          'NotificationService', 'scheduleDailyReminder failed', e, stack);
    }
  }

  /// Shows an immediate streak-at-risk notification.
  ///
  /// Pass either a custom [message] string or a [streakDays] count —
  /// the method builds a message from [streakDays] if [message] is null.
  /// Payload: 'streak' → opens /progress on tap.
  Future<void> showStreakWarning({int streakDays = 0, String? message}) async {
    if (!await _safeIsEnabled()) return;
    try {
      final body = message ??
          '$streakDays-day streak at risk! '
              'Log an activity before midnight to keep your streak.';

      final androidDetails = AndroidNotificationDetails(
        NotificationChannels.streakId,
        NotificationChannels.streakName,
        channelDescription: 'Alerts about your daily activity streak.',
        importance: NotificationChannels.streakImportance,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
      );
      final details = NotificationDetails(
          android: androidDetails, iOS: const DarwinNotificationDetails());

      await _localNotifs.show(
        id: streakWarningId,
        title: 'Streak at Risk!',
        body: body,
        notificationDetails: details,
        payload: 'streak',
      );
      AppLogger.info('NotificationService', 'Streak warning shown');
    } catch (e, stack) {
      AppLogger.error(
          'NotificationService', 'showStreakWarning failed', e, stack);
    }
  }

  /// Registers WorkManager one-off tasks for inactivity reminders at
  /// 2, 5, and 7 days. Call when the app goes to background.
  ///
  /// Uses [ExistingWorkPolicy.replace] so this is safe to call on every
  /// foreground → background transition — it simply resets the countdown.
  Future<void> scheduleInactivityReminders() async {
    if (!await _safeIsEnabled()) return;
    try {
      await cancelInactivityReminders();

      await Workmanager().registerOneOffTask(
        inactivity2dUniqueName,
        inactivityTaskName,
        initialDelay: const Duration(days: 2),
        inputData: {
          'notifId': inactivity2DayId,
          'title': '2 days since last session',
          'body': "Don't break the habit! A quick 10-min activity helps 💪",
          'payload': 'progress',
        },
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );

      await Workmanager().registerOneOffTask(
        inactivity5dUniqueName,
        inactivityTaskName,
        initialDelay: const Duration(days: 5),
        inputData: {
          'notifId': inactivity5DayId,
          'title': '5 days without activities',
          'body': 'Consistency is key for progress. Log an activity today.',
          'payload': 'progress',
        },
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );

      await Workmanager().registerOneOffTask(
        inactivity7dUniqueName,
        inactivityTaskName,
        initialDelay: const Duration(days: 7),
        inputData: {
          'notifId': inactivity7DayId,
          'title': "It's been a week!",
          'body': "Don't lose track of the great work you've started. Open the app to continue.",
          'payload': 'progress',
        },
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.notRequired),
      );

      AppLogger.info('NotificationService',
          'Inactivity WorkManager tasks scheduled (2/5/7 days)');
    } catch (e, stack) {
      AppLogger.error('NotificationService',
          'scheduleInactivityReminders failed', e, stack);
    }
  }

  /// Cancels all three inactivity WorkManager tasks.
  /// Call when the app comes back to the foreground.
  Future<void> cancelInactivityReminders() async {
    try {
      await Workmanager().cancelByUniqueName(inactivity2dUniqueName);
      await Workmanager().cancelByUniqueName(inactivity5dUniqueName);
      await Workmanager().cancelByUniqueName(inactivity7dUniqueName);
      AppLogger.info(
          'NotificationService', 'Inactivity WorkManager tasks cancelled');
    } catch (e, stack) {
      AppLogger.error('NotificationService',
          'cancelInactivityReminders failed', e, stack);
    }
  }

  /// Registers the periodic 3-hour progress update WorkManager task.
  /// Uses [ExistingWorkPolicy.replace] — safe to call on every app launch.
  Future<void> scheduleProgressUpdateNotifications() async {
    try {
      await Workmanager().registerPeriodicTask(
        progressTaskUniqueName,
        progressTaskName,
        frequency: const Duration(hours: 3),
        initialDelay: const Duration(hours: 3),
        constraints: Constraints(networkType: NetworkType.notRequired),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
      AppLogger.info(
          'NotificationService', 'Progress update periodic task registered');
    } catch (e, stack) {
      AppLogger.error('NotificationService',
          'scheduleProgressUpdateNotifications failed', e, stack);
    }
  }

  /// Cancel a single notification by [id].
  Future<void> cancel(int id) async {
    try {
      await _localNotifs.cancel(id: id);
      AppLogger.info('NotificationService', 'Notification cancelled (id=$id)');
    } catch (e, stack) {
      AppLogger.error(
          'NotificationService', 'cancel failed (id=$id)', e, stack);
    }
  }

  /// Cancel all pending local notifications.
  Future<void> cancelAll() async {
    try {
      await _localNotifs.cancelAll();
      AppLogger.info('NotificationService', 'All local notifications cancelled');
    } catch (e, stack) {
      AppLogger.error('NotificationService', 'cancelAll failed', e, stack);
    }
  }
}
