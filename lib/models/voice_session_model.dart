/// Enumerates the voice interaction modes.
enum VoiceMode {
  /// User manually holds/taps the mic to speak.
  pushToTalk,

  /// Microphone stays open; AI listens continuously.
  continuous,
}

/// Represents the current state of the voice assistant pipeline.
enum VoiceStatus {
  /// Session not started or fully stopped.
  idle,

  /// Microphone is active, waiting for user speech.
  listening,

  /// User speech recognized, sending to Gemini.
  processing,

  /// AI response received, playing via TTS.
  speaking,

  /// Session temporarily paused (background, user action).
  paused,

  /// An error occurred (see [VoiceSessionModel.errorMessage]).
  error,
}

/// Ephemeral model tracking the state of an active voice session.
///
/// Not persisted to Firestore — only lives during the session.
/// Actual messages are saved via [ChatMessageModel] through
/// [FirebaseService.sendChatMessage].
class VoiceSessionModel {
  final String sessionId;
  final VoiceMode mode;
  final VoiceStatus status;
  final DateTime startedAt;
  final DateTime lastActivityAt;
  final int messageCount;
  final String? errorMessage;

  const VoiceSessionModel({
    required this.sessionId,
    this.mode = VoiceMode.pushToTalk,
    this.status = VoiceStatus.idle,
    required this.startedAt,
    required this.lastActivityAt,
    this.messageCount = 0,
    this.errorMessage,
  });

  /// Create a new idle session.
  factory VoiceSessionModel.create({
    required String sessionId,
    VoiceMode mode = VoiceMode.pushToTalk,
  }) {
    final now = DateTime.now();
    return VoiceSessionModel(
      sessionId: sessionId,
      mode: mode,
      status: VoiceStatus.idle,
      startedAt: now,
      lastActivityAt: now,
    );
  }

  /// Duration since the session started.
  Duration get elapsed => DateTime.now().difference(startedAt);

  /// Whether the session is in an active state (not idle/error).
  bool get isActive =>
      status == VoiceStatus.listening ||
      status == VoiceStatus.processing ||
      status == VoiceStatus.speaking;

  /// Create a copy with updated fields.
  VoiceSessionModel copyWith({
    VoiceMode? mode,
    VoiceStatus? status,
    DateTime? lastActivityAt,
    int? messageCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VoiceSessionModel(
      sessionId: sessionId,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      startedAt: startedAt,
      lastActivityAt: lastActivityAt ?? DateTime.now(),
      messageCount: messageCount ?? this.messageCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
