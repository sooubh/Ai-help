import 'package:flutter/foundation.dart';

/// Centralized logging utility for the CARE-AI application.
/// Provides structured logging with timestamps, module names, and error traces.
/// In production, this can easily be hooked up to Crashlytics or Sentry.
class AppLogger {
  AppLogger._();

  /// Log a general informational message.
  static void info(String module, String message) {
    _log('INFO', module, message);
  }

  /// Log a warning that doesn't cause a hard failure but needs attention.
  static void warning(String module, String message) {
    _log('WARNING', module, message);
  }

  /// Log an error with an optional stack trace.
  static void error(
    String module,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _log('ERROR', module, message);
    if (error != null) {
      debugPrint('Exception: $error');
    }
    if (stackTrace != null) {
      debugPrint('StackTrace:\n$stackTrace');
    }
  }

  /// Log a debug message, only visible during development.
  static void debug(String module, String message) {
    if (kDebugMode) {
      _log('DEBUG', module, message);
    }
  }

  static void _log(String level, String module, String message) {
    final timestamp = DateTime.now().toIso8601String().substring(
      11,
      23,
    ); // Extract HH:mm:ss.ms
    // Use debugPrint to avoid 'avoid_print' lints and allow log truncation handling in IDEs.
    debugPrint('[$timestamp] [$level] [$module] $message');
  }
}
