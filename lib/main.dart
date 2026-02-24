import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/profile/presentation/profile_setup_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/chat/presentation/chat_screen.dart';

/// Entry point for CARE-AI.
/// Initializes Firebase, then runs the app with named routes
/// and an auth-state listener to decide the initial screen.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CareAiApp());
}

class CareAiApp extends StatelessWidget {
  const CareAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CARE-AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Auth-state listener decides initial route
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Still loading auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // User is signed in → go to home
          if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen();
          }

          // Not signed in → show login
          return const LoginScreen();
        },
      ),

      // Named routes for navigation
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/home': (context) => HomeScreen(),
        '/chat': (context) => const ChatScreen(),
      },
    );
  }
}
