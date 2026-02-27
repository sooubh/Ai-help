import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'services/ai_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/auth/presentation/password_reset_screen.dart';
import 'features/auth/presentation/phone_otp_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/profile/presentation/profile_setup_screen.dart';
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
import 'features/doctor/presentation/doctor_dashboard_screen.dart';
import 'features/doctor/presentation/patient_detail_screen.dart';
import 'features/doctor/presentation/assign_plan_screen.dart';
import 'features/doctor/presentation/compose_guidance_note_screen.dart';
import 'services/notification_service.dart';

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

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable offline persistence with unlimited cache
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Validate environment configuration
  EnvConfig.validate();

  // Initialize Gemini AI service
  final aiService = AiService();
  aiService.initialize();

  // Initialize push notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // Load saved theme preference
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        Provider.value(value: aiService),
      ],
      child: const CareAiApp(),
    ),
  );
}

class CareAiApp extends StatelessWidget {
  const CareAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'CARE-AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,

      // Auth-state listener decides initial route
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Still loading auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }

          // User is signed in → go to home
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }

          // Not signed in → show onboarding/login
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
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return PatientDetailScreen(
            childId: args?['childId'] ?? '',
            childName: args?['childName'] ?? 'Unknown Patient',
          );
        },
        '/assign-plan': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return AssignPlanScreen(childId: args?['childId'] ?? '');
        },
        '/compose-note': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ComposeGuidanceNoteScreen(childId: args?['childId'] ?? '');
        },
      },
    );
  }
}

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
