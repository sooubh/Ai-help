import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for CARE-AI.
///
/// Loads API keys securely. In production, use --dart-define
/// or a secrets manager. For development, keys can be loaded via
/// flutter_dotenv from the .env file.
///
/// Usage:
///   Just `flutter run` (reads from .env)
class EnvConfig {
  EnvConfig._();

  /// Gemini API key — reads from .env file, falls back to --dart-define.
  static String get geminiApiKey {
    return dotenv.env['GEMINI_API_KEY'] ??
        const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  }

  /// Whether we have a valid Gemini API key configured.
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  /// Validate that required environment variables are set.
  /// Call this early in app startup to catch misconfigurations.
  static void validate() {
    if (!hasGeminiKey) {
      debugPrint(
        '⚠️  GEMINI_API_KEY not set. '
        'Run with: flutter run --dart-define=GEMINI_API_KEY=your_key',
      );
    }
  }
}
