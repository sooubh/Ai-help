import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'core/config/env_config.dart';
import 'dart:ui';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/app_logger.dart';
import 'services/ai_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/auth/presentation/password_reset_screen.dart';
import 'features/auth/presentation/phone_otp_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/onboarding/presentation/parent_onboarding_screen.dart';
import 'features/onboarding/presentation/doctor_onboarding_screen.dart';
import 'features/profile/presentation/profile_setup_screen.dart';
import 'features/profile/presentation/full_profile_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/activities/presentation/modules_library_screen.dart';
import 'features/progress/presentation/progress_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/daily_plan/presentation/daily_plan_screen.dart';
import 'features/emergency/presentation/emergency_screen.dart';
import 'features/games/presentation/games_hub_screen.dart';
import 'features/wellness/presentation/wellness_screen.dart';
import 'features/report/presentation/doctor_report_screen.dart';
import 'features/about/presentation/about_screen.dart';
import 'features/community/presentation/community_screen.dart';
import 'features/achievements/presentation/achievements_screen.dart';
import 'features/voice/presentation/voice_assistant_screen.dart';
import 'features/voice/presentation/global_voice_overlay.dart';
import 'features/doctor/presentation/doctor_dashboard_screen.dart';
import 'features/doctor/presentation/patient_detail_screen.dart';
import 'features/doctor/presentation/assign_plan_screen.dart';
import 'features/doctor/presentation/compose_guidance_note_screen.dart';
import 'services/notification_service.dart';
import 'services/firebase_service.dart';
import 'services/voice_assistant_service.dart';
import 'services/cache/local_cache_service.dart';
import 'services/cache/smart_data_repository.dart';
import 'services/cache/sync_manager.dart';

// ─── WorkManager Callback (top-level, separate isolate) ──────────────────────
// Must be top-level (not inside a class) and annotated with
// @pragma('vm:entry-point') so the AOT compiler keeps it in release builds.
//
// RULES:
//  - Zero Firebase / network calls — Hive cache reads ONLY
//  - Every Hive read wrapped in its own try/catch with a safe fallback
//  - If the Hive box itself fails to open → show a generic fallback notification
//    and return true so WorkManager does not retry immediately

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // ── 1. Flutter bindings (required in headless isolate) ──────────────────
    WidgetsFlutterBinding.ensureInitialized();

    // ── 2. Re-initialise flutter_local_notifications in this isolate ────────
    final plugin = FlutterLocalNotificationsPlugin();
    try {
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
    } catch (_) {}

    // Reusable notification detail constants (no const for runtime channel IDs)
    const androidProgress = AndroidNotificationDetails(
      'progress_channel', 'Progress Updates',
      channelDescription: 'Regular progress updates for your child',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const androidInactivity = AndroidNotificationDetails(
      'inactivity_channel', 'Inactivity Reminders',
      channelDescription: "Reminders when you haven't used the app in a while.",
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    // ── 3. Handle inactivityTask ─────────────────────────────────────────────
    if (taskName == 'inactivityTask') {
      try {
        final notifId = inputData?['notifId'] as int? ?? 401;
        final title = inputData?['title'] as String? ?? 'Come back!';
        final body =
            inputData?['body'] as String? ?? 'Your child needs you today.';
        final payload = inputData?['payload'] as String? ?? 'progress';
        await plugin.show(
          id: notifId,
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(
            android: androidInactivity,
            iOS: iosDetails,
          ),
          payload: payload,
        );
      } catch (e) {
        debugPrint('[callbackDispatcher] inactivityTask error: $e');
      }
      return Future.value(true);
    }

    // ── 4. Ignore unknown tasks ──────────────────────────────────────────────
    if (taskName != 'progressUpdateTask') return Future.value(false);

    // ── 5. progressUpdateTask — read Hive cache, NO Firebase ────────────────

    // Helper: safe fallback notification when cache is unavailable
    Future<void> showFallback() async {
      try {
        await plugin.show(
          id: 300,
          title: 'CARE-AI Progress Update',
          body: 'Keep up the great work today!',
          notificationDetails: const NotificationDetails(
            android: androidProgress,
            iOS: iosDetails,
          ),
          payload: 'progress',
        );
      } catch (_) {}
    }

    try {
      // ── 5a. Open the Hive data box safely ─────────────────────────────────
      try {
        await Hive.initFlutter();
      } catch (_) {
        // Already initialised in this isolate — safe to continue
      }

      late Box dataBox;
      try {
        dataBox = Hive.isBoxOpen('care_ai_data')
            ? Hive.box('care_ai_data')
            : await Hive.openBox('care_ai_data');
      } catch (e) {
        debugPrint('[callbackDispatcher] Hive box open failed: $e');
        await showFallback();
        return Future.value(true);
      }

      // ── 5b. Read weekly_stats ──────────────────────────────────────────────
      int activitiesCount = 0;
      int streakDays = 0;
      try {
        // Service may persist under 'weekly_stats' or inside 'dashboard_data'
        final wsRaw = dataBox.get('weekly_stats') as String?;
        if (wsRaw != null) {
          final stats = jsonDecode(wsRaw) as Map<String, dynamic>;
          // Support both {activitiesCount, streakDays} and {count, streak}
          activitiesCount =
              (stats['activitiesCount'] as num? ?? stats['count'] as num?)
                  ?.toInt() ??
                  0;
          streakDays =
              (stats['streakDays'] as num? ?? stats['streak'] as num?)
                  ?.toInt() ??
                  0;
        } else {
          // Fallback: extract from dashboard_data
          final ddRaw = dataBox.get('dashboard_data') as String?;
          if (ddRaw != null) {
            final dd = jsonDecode(ddRaw) as Map<String, dynamic>;
            final ws = dd['weeklyStats'] as Map<String, dynamic>? ?? {};
            activitiesCount = (ws['count'] as num?)?.toInt() ?? 0;
            streakDays = (ws['streak'] as num?)?.toInt() ?? 0;
          }
        }
      } catch (_) {}

      // ── 5c. Read child name ────────────────────────────────────────────────
      String childName = 'your child';
      try {
        // Try 'children_list' (spec key) then 'child_profiles' (actual key)
        final raw = (dataBox.get('children_list') ??
                dataBox.get('child_profiles')) as String?;
        if (raw != null) {
          final list = jsonDecode(raw) as List<dynamic>;
          if (list.isNotEmpty) {
            final first = list.first;
            if (first is Map) {
              // Handle {name: ...} and {data: {name: ...}, id: ...} formats
              final data = first['data'] as Map?;
              childName = (data?['name'] as String?) ??
                  (first['name'] as String?) ??
                  'your child';
            }
          }
        }
      } catch (_) {}

      // ── 5d. Read daily_plan ────────────────────────────────────────────────
      int completedTasks = 0;
      int totalTasks = 0;
      try {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        // Try 'daily_plan' (spec key) then date-keyed 'daily_plan_YYYY-MM-DD'
        final raw = (dataBox.get('daily_plan') ??
                dataBox.get('daily_plan_$today')) as String?;
        if (raw != null) {
          final plan = jsonDecode(raw) as List<dynamic>;
          totalTasks = plan.length;
          completedTasks = plan
              .whereType<Map<String, dynamic>>()
              .where((t) => t['isCompleted'] == true)
              .length;
        }
      } catch (_) {}

      // ── 5e. Build dynamic message (rotates by hour) ───────────────────────
      final variant = DateTime.now().hour % 3;
      String notifTitle;
      String notifBody;

      switch (variant) {
        case 0:
          notifTitle = 'Great progress!';
          notifBody = activitiesCount > 0
              ? '$childName has completed $activitiesCount activities this week!'
              : 'Keep going — every activity counts for $childName!';
          break;
        case 1:
          notifTitle =
              streakDays > 1 ? '$streakDays-day streak!' : 'Start your streak!';
          notifBody = streakDays > 1
              ? '$streakDays-day streak going strong! Keep it up.'
              : "Log an activity today to start $childName's streak!";
          break;
        default:
          notifTitle = "Today's plan";
          notifBody = totalTasks > 0
              ? '$completedTasks/$totalTasks tasks done today. '
                  "You're doing great!"
              : "Open the app to check today's plan for $childName.";
      }

      // ── 5f. Show notification ──────────────────────────────────────────────
      await plugin.show(
        id: 300,
        title: notifTitle,
        body: notifBody,
        notificationDetails: const NotificationDetails(
          android: androidProgress,
          iOS: iosDetails,
        ),
        payload: 'progress',
      );
    } catch (e) {
      debugPrint('[callbackDispatcher] progressUpdateTask error: $e');
      await showFallback();
    }

    return Future.value(true);
  });
}

// ─────────────────────────────────────────────────────────────────────────────

/// Entry point for CARE-AI.
/// Initializes Firebase, validates environment, sets up providers,
/// then launches the app with auth-state routing.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file (try/catch in case it's missing in prod)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('No .env file found. Falling back to environment variables.');
  }

  // Global Error Handlers
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'FlutterError',
      details.exceptionAsString(),
      details.exception,
      details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('PlatformDispatcher', error.toString(), error, stack);
    return true; // Prevent default crash
  };

  // User-friendly UI for rendering errors
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              details.exceptionAsString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  };

  // Initialize local cache FIRST
  await LocalCacheService.initialize();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable offline persistence with unlimited cache
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  try {
    // Validate environment configuration
    EnvConfig.validate();

    // Initialize Gemini AI service
    final aiService = AiService();
    aiService.initialize();

    // Initialize Voice Assistant Service
    final voiceService = VoiceAssistantService();
    try {
      await voiceService.initialize();
    } catch (e) {
      debugPrint('Voice service init failed: $e');
    }

    // Initialize push notifications
    final notificationService = NotificationService();
    try {
      await notificationService.init();
    } catch (e) {
      debugPrint('Notification service init failed: $e');
    }

    // Initialize WorkManager for background tasks and register the
    // 3-hour progress update periodic task.
    try {
      await Workmanager().initialize(callbackDispatcher);
      await notificationService.scheduleProgressUpdateNotifications();
    } catch (e) {
      debugPrint('WorkManager init failed: $e');
    }

    // Battery optimization exemption (Android only, asked once)
    try {
      await notificationService.requestBatteryExemption();
    } catch (e) {
      debugPrint('Battery exemption request failed: $e');
    }

    // Reset inactivity countdown on every app launch
    try {
      await Workmanager().cancelByUniqueName(NotificationService.inactivity2dUniqueName);
      await Workmanager().cancelByUniqueName(NotificationService.inactivity5dUniqueName);
      await Workmanager().cancelByUniqueName(NotificationService.inactivity7dUniqueName);
      await notificationService.scheduleInactivityReminders();
    } catch (e) {
      debugPrint('Inactivity tasks reset failed: $e');
    }

    // Load saved theme preference
    final themeProvider = ThemeProvider();
    try {
      await themeProvider.loadTheme();
    } catch (e, stack) {
      AppLogger.error('Main', 'Theme provider init failed', e, stack);
    }

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Give NotificationService access to the navigator so tapped
    // notifications can route to the correct screen.
    NotificationService.setNavigatorKey(navigatorKey);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          Provider.value(value: aiService),
          ChangeNotifierProvider.value(value: voiceService),
          Provider<FirebaseService>(create: (_) => FirebaseService()),
          Provider<LocalCacheService>(create: (_) => LocalCacheService.instance),
          Provider<SmartDataRepository>(
            create: (ctx) => SmartDataRepository(ctx.read<FirebaseService>()),
          ),
          Provider<SyncManager>(
            create: (ctx) => SyncManager(
              ctx.read<SmartDataRepository>(),
            ),
          ),
        ],
        child: const CareAiApp(),
      ),
    );
  } catch (e, stack) {
    AppLogger.error('Main', 'Fatal error during startup', e, stack);
    // Fallback run app so it never gets stuck on black screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Startup Error: $e\n\nPlease restart the app.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

class CareAiApp extends StatefulWidget {
  const CareAiApp({super.key});

  @override
  State<CareAiApp> createState() => _CareAiAppState();
}

class _CareAiAppState extends State<CareAiApp> with WidgetsBindingObserver {
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is in background — schedule inactivity reminders
      _notificationService.scheduleInactivityReminders();
    } else if (state == AppLifecycleState.resumed) {
      // App is in foreground — cancel reminders as user is active
      _notificationService.cancelInactivityReminders();

      // Sync on app resume
      final userId = context.read<FirebaseService>().currentUser?.uid;
      if (userId != null) {
        context.read<SyncManager>().onAppResume(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'CARE-AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      builder: (context, child) {
        return Stack(
          children: [if (child != null) child, const GlobalVoiceOverlay()],
        );
      },

      // Auth-state listener decides initial route
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }

          if (snapshot.hasData && snapshot.data != null) {
            // User is signed in — Check profile completion
            return FutureBuilder<bool>(
              future: _checkProfileCompletion(),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const _SplashScreen();
                }

                return const _SplashScreen();
              },
            );
          }

          // Not signed in → show onboarding
          return const OnboardingScreen();
        },
      ),

      // Named routes for navigation
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/password-reset': (context) => const PasswordResetScreen(),
        '/phone-otp': (context) => const PhoneOtpScreen(),
        '/parent-onboarding': (context) => const ParentOnboardingScreen(),
        '/doctor-onboarding': (context) => const DoctorOnboardingScreen(),
        '/full-profile': (context) => const FullProfileScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/home': (context) => const HomeScreen(),
        '/chat': (context) => const ChatScreen(),
        '/activities': (context) => const ModulesLibraryScreen(),
        '/progress': (context) => const ProgressScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/daily-plan': (context) => const DailyPlanScreen(),
        '/emergency': (context) => const EmergencyScreen(),
        '/games': (context) => const GamesHubScreen(),
        '/wellness': (context) => const WellnessScreen(),
        '/doctor-report': (context) => const DoctorReportScreen(),
        '/about': (context) => const AboutScreen(),
        '/community': (context) => const CommunityScreen(),
        '/achievements': (context) => const AchievementsScreen(),
        '/voice-assistant': (context) => const VoiceAssistantScreen(),
        '/doctor-dashboard': (context) => const DoctorDashboardScreen(),
        '/patient-detail': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return PatientDetailScreen(
            childId: args?['childId'] ?? '',
            childName: args?['childName'] ?? 'Unknown Patient',
            parentUid: args?['parentUid'] ?? '',
          );
        },
        '/assign-plan': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return AssignPlanScreen(
            childId: args?['childId'] ?? '',
            parentUid: args?['parentUid'] ?? '',
          );
        },
        '/compose-note': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return ComposeGuidanceNoteScreen(childId: args?['childId'] ?? '');
        },
      },
    );
  }

  /// Checks if the user has completed their profile setup and navigates accordingly.
  Future<bool> _checkProfileCompletion() async {
    final nav = navigatorKey.currentState;
    if (nav == null) return false;

    final service = FirebaseService();
    final profile = await service.getUserProfile();

    if (profile == null) {
      await service.signOut();
      return false;
    }

    if (profile.role == 'doctor') {
      final docProfile = await service.getDoctorProfile();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (docProfile == null ||
            docProfile.specialization.isEmpty ||
            docProfile.name == 'Dr. Unknown') {
          nav.pushReplacementNamed('/doctor-onboarding');
        } else {
          nav.pushReplacementNamed('/doctor-dashboard');
        }
      });
    } else {
      final children = await service.getChildProfiles();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (children.isEmpty) {
          nav.pushReplacementNamed('/parent-onboarding');
        } else {
          nav.pushReplacementNamed('/home');
        }
      });
    }
    return true;
  }
}

/// Global navigator key to be used within the build context safely
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Animated splash screen shown while Firebase initializes.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF3B0764)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing logo
              Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B6EF5), Color(0xFFA855F7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5B6EF5).withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.06, 1.06),
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.2, duration: 600.ms),

              const SizedBox(height: 28),

              // App name with shimmer
              const Text(
                    'CARE-AI',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(begin: 0.3, duration: 500.ms),

              const SizedBox(height: 8),

              // Tagline
              Text(
                'AI Parenting Companion',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

              const SizedBox(height: 48),

              // Loading indicator
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
