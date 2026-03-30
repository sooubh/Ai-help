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
    super.message = 'Please check your internet connection.',
  ]) : super(code: 'NETWORK_ERROR');
}

/// Represents an error returned from an API (e.g., Gemini, Firebase Cloud Functions).
class ApiException extends CareAiException {
  final int? statusCode;

  const ApiException(super.message, {this.statusCode, super.originalError})
    : super(code: 'API_ERROR');
}

/// Represents an error during authentication.
class AuthException extends CareAiException {
  const AuthException(super.message, {String? code})
    : super(code: code ?? 'AUTH_ERROR');
}

/// Represents a failure to read, write, or parse data.
class DataException extends CareAiException {
  const DataException(super.message, {super.originalError})
    : super(code: 'DATA_ERROR');
}

/// Represents errors interacting with the microphone or audio playback.
class AudioException extends CareAiException {
  const AudioException(super.message, {super.originalError})
    : super(code: 'AUDIO_ERROR');
}

/// Thrown when an operation takes too long to complete.
class TimeoutException extends CareAiException {
  const TimeoutException([
    super.message = 'The operation timed out. Please try again.',
  ]) : super(code: 'TIMEOUT');
}
