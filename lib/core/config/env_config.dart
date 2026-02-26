/// Environment configuration for CARE-AI.
///
/// Loads API keys securely. In production, use --dart-define
/// or a secrets manager. For development, keys can be passed via
/// compile-time constants.
///
/// Usage:
///   flutter run --dart-define=GEMINI_API_KEY=your_key_here
class EnvConfig {
  EnvConfig._();

  /// Gemini API key — injected at compile time via --dart-define.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Whether we have a valid Gemini API key configured.
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  /// Validate that required environment variables are set.
  /// Call this early in app startup to catch misconfigurations.
  static void validate() {
    if (!hasGeminiKey) {
      // ignore: avoid_print
      print(
        '⚠️  GEMINI_API_KEY not set. '
        'Run with: flutter run --dart-define=GEMINI_API_KEY=your_key',
      );
    }
  }
}
