/// Base class for all custom CARE-AI exceptions.
abstract class CareAiException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const CareAiException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    if (code != null) return '[$code] $message';
    return message;
  }
}

/// Represents a failure to communicate with the network.
class NetworkException extends CareAiException {
  const NetworkException([
    String message = 'Please check your internet connection.',
  ]) : super(message, code: 'NETWORK_ERROR');
}

/// Represents an error returned from an API (e.g., Gemini, Firebase Cloud Functions).
class ApiException extends CareAiException {
  final int? statusCode;

  const ApiException(String message, {this.statusCode, dynamic originalError})
    : super(message, code: 'API_ERROR', originalError: originalError);
}

/// Represents an error during authentication.
class AuthException extends CareAiException {
  const AuthException(String message, {String? code})
    : super(message, code: code ?? 'AUTH_ERROR');
}

/// Represents a failure to read, write, or parse data.
class DataException extends CareAiException {
  const DataException(String message, {dynamic originalError})
    : super(message, code: 'DATA_ERROR', originalError: originalError);
}

/// Represents errors interacting with the microphone or audio playback.
class AudioException extends CareAiException {
  const AudioException(String message, {dynamic originalError})
    : super(message, code: 'AUDIO_ERROR', originalError: originalError);
}

/// Thrown when an operation takes too long to complete.
class TimeoutException extends CareAiException {
  const TimeoutException([
    String message = 'The operation timed out. Please try again.',
  ]) : super(message, code: 'TIMEOUT');
}
