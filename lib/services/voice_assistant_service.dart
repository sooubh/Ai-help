import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/voice_session_model.dart';
import '../models/chat_message_model.dart';
import '../models/child_profile_model.dart';
import '../models/user_event_model.dart';
import 'ai_service.dart';
import 'tts_service.dart';
import 'firebase_service.dart';

/// Orchestrates the full voice assistant pipeline:
/// Microphone (STT) → Gemini AI → Speaker (TTS)
///
/// Wraps existing [AiService], [TtsService], and [FirebaseService]
/// without duplicating any logic. Extends [ChangeNotifier] to
/// drive the UI reactively.
class VoiceAssistantService extends ChangeNotifier {
  final AiService _aiService;
  final TtsService _ttsService = TtsService();
  final FirebaseService _firebaseService = FirebaseService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final Uuid _uuid = const Uuid();

  // ── Session state ────────────────────────────────────────────
  VoiceSessionModel? _session;
  VoiceSessionModel? get session => _session;

  String _lastUserText = '';
  String get lastUserText => _lastUserText;

  String _lastAiText = '';
  String get lastAiText => _lastAiText;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _speechAvailable = false;
  bool get speechAvailable => _speechAvailable;

  // ── Convenience getters for UI ───────────────────────────────
  bool get isActive => _session?.isActive ?? false;
  bool get isListening => _session?.status == VoiceStatus.listening;
  bool get isProcessing => _session?.status == VoiceStatus.processing;
  bool get isSpeaking => _session?.status == VoiceStatus.speaking;
  bool get isPaused => _session?.status == VoiceStatus.paused;
  bool get isIdle => _session == null || _session!.status == VoiceStatus.idle;
  VoiceMode get mode => _session?.mode ?? VoiceMode.pushToTalk;

  // ── Internal ─────────────────────────────────────────────────
  Timer? _silenceTimer;
  StreamSubscription? _connectivitySub;
  bool _isOnline = true;
  bool _disposed = false;

  /// Additional voice-specific instruction appended to Gemini context.
  static const String _voiceSystemAddition = '''
VOICE MODE RULES (in addition to base rules):
- Keep responses SHORT (under 100 words) — the user is listening, not reading.
- Use a warm, conversational tone. No markdown formatting.
- If the input is unclear, ask ONE short clarifying question.
- Start your response directly — no greetings or preambles after the first exchange.
- Use simple sentence structures suitable for spoken delivery.
''';

  VoiceAssistantService(this._aiService);

  // ═══════════════════════════════════════════════════════════════
  // SESSION LIFECYCLE
  // ═══════════════════════════════════════════════════════════════

  /// Initialize the voice pipeline. Must be called before [startSession].
  Future<bool> initialize() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) => _handleSttError(error.errorMsg),
        onStatus: (status) => _handleSttStatus(status),
      );

      await _ttsService.init();

      // Monitor connectivity
      _connectivitySub = Connectivity()
          .onConnectivityChanged
          .listen((results) {
        final wasOnline = _isOnline;
        _isOnline = results.any((r) => r != ConnectivityResult.none);

        if (!_isOnline && wasOnline && isActive) {
          _setError('You appear to be offline. Voice assistant needs an internet connection.');
          pauseSession();
        } else if (_isOnline && !wasOnline && isPaused) {
          clearError();
          resumeSession();
        }
        notifyListeners();
      });

      notifyListeners();
      return _speechAvailable;
    } catch (e) {
      debugPrint('VoiceAssistant init error: $e');
      _speechAvailable = false;
      notifyListeners();
      return false;
    }
  }

  /// Start a new voice session.
  Future<void> startSession({
    VoiceMode mode = VoiceMode.pushToTalk,
    ChildProfileModel? childProfile,
  }) async {
    if (!_speechAvailable) {
      _setError('Microphone is not available. Please check permissions.');
      return;
    }

    if (!_isOnline) {
      _setError('No internet connection. Please connect and try again.');
      return;
    }

    // Initialize AI chat with child context
    _aiService.startChatSession(childProfile: childProfile);

    _session = VoiceSessionModel.create(
      sessionId: _uuid.v4(),
      mode: mode,
    );
    _lastUserText = '';
    _lastAiText = '';
    _errorMessage = null;

    // Log session start event
    _logEvent('voice_session_started', {'mode': mode.name});

    _updateStatus(VoiceStatus.idle);

    // In continuous mode, start listening immediately
    if (mode == VoiceMode.continuous) {
      await startListening();
    }
  }

  /// Stop and clean up the session.
  Future<void> stopSession() async {
    _silenceTimer?.cancel();

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
      await _ttsService.stop();
    } catch (_) {}

    if (_session != null) {
      _logEvent('voice_session_ended', {
        'duration_seconds': _session!.elapsed.inSeconds,
        'message_count': _session!.messageCount,
        'mode': _session!.mode.name,
      });
    }

    _session = null;
    _lastUserText = '';
    _lastAiText = '';
    _errorMessage = null;
    notifyListeners();
  }

  /// Pause the session (e.g., app backgrounded).
  void pauseSession() {
    if (_session == null) return;
    _silenceTimer?.cancel();

    if (_speech.isListening) {
      _speech.stop();
    }
    _ttsService.stop();

    _updateStatus(VoiceStatus.paused);
  }

  /// Resume a paused session.
  Future<void> resumeSession() async {
    if (_session == null || _session!.status != VoiceStatus.paused) return;

    _updateStatus(VoiceStatus.idle);

    if (_session!.mode == VoiceMode.continuous) {
      await startListening();
    }
  }

  /// Toggle between push-to-talk and continuous modes.
  void toggleMode() {
    if (_session == null) return;

    final newMode = _session!.mode == VoiceMode.pushToTalk
        ? VoiceMode.continuous
        : VoiceMode.pushToTalk;

    // Stop any active listening first
    if (_speech.isListening) {
      _speech.stop();
    }

    _session = _session!.copyWith(mode: newMode);

    // If switching to continuous and idle, start listening
    if (newMode == VoiceMode.continuous &&
        _session!.status == VoiceStatus.idle) {
      startListening();
    }

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // LISTENING CONTROLS
  // ═══════════════════════════════════════════════════════════════

  /// Start listening for speech input.
  Future<void> startListening() async {
    if (_session == null || !_speechAvailable) return;

    // Interrupt AI if it's speaking
    if (isSpeaking) {
      await _ttsService.stop();
    }

    clearError();
    _updateStatus(VoiceStatus.listening);

    // Haptic feedback
    HapticFeedback.lightImpact();

    try {
      await _speech.listen(
        onResult: (result) {
          _lastUserText = result.recognizedWords;
          notifyListeners();

          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _processUserInput(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );

      // Start silence timer for continuous mode
      _resetSilenceTimer();
    } catch (e) {
      debugPrint('Listen error: $e');
      _setError('Could not start listening. Please try again.');
      _updateStatus(VoiceStatus.idle);
    }
  }

  /// Stop listening (used in push-to-talk mode).
  Future<void> stopListening() async {
    _silenceTimer?.cancel();
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  /// Interrupt the AI mid-speech (user starts talking).
  Future<void> interruptAI() async {
    if (isSpeaking) {
      await _ttsService.stop();
      await startListening();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // AI PROCESSING
  // ═══════════════════════════════════════════════════════════════

  /// Process recognized speech: send to Gemini, speak the response.
  Future<void> _processUserInput(String text) async {
    if (text.trim().isEmpty || _session == null) return;

    _silenceTimer?.cancel();
    _updateStatus(VoiceStatus.processing);
    _lastUserText = text;

    // Haptic feedback for processing start
    HapticFeedback.mediumImpact();

    // Save user message to Firestore
    try {
      await _firebaseService.sendChatMessage(ChatMessageModel(
        id: '',
        message: text,
        sender: 'user',
        timestamp: DateTime.now(),
      ));
    } catch (_) {
      // Non-critical: message save failed, continue with AI response
    }

    // Get AI response
    try {
      final prompt = '$_voiceSystemAddition\n\nUser said: $text';
      final stream = _aiService.getStreamingResponse(prompt);

      _updateStatus(VoiceStatus.speaking);
      String fullResponse = '';

      await for (final chunk in stream) {
        if (_disposed || _session == null) return;
        fullResponse += chunk;
        _lastAiText = fullResponse;
        notifyListeners();
      }

      if (_disposed || _session == null) return;

      _session = _session!.copyWith(
        messageCount: _session!.messageCount + 1,
      );

      // Save AI response to Firestore
      try {
        await _firebaseService.sendChatMessage(ChatMessageModel(
          id: '',
          message: fullResponse,
          sender: 'ai',
          timestamp: DateTime.now(),
        ));
      } catch (_) {
        // Non-critical
      }

      // Speak the response
      await _ttsService.speak(fullResponse);

      // After speaking, decide next action
      if (_disposed || _session == null) return;

      if (_session!.mode == VoiceMode.continuous) {
        // Auto-listen again in continuous mode
        await startListening();
      } else {
        _updateStatus(VoiceStatus.idle);
      }
    } on TimeoutException {
      _setError('Response took too long. Please try again.');
      _updateStatus(VoiceStatus.idle);
    } catch (e) {
      debugPrint('AI processing error: $e');
      _setError('Something went wrong. Please try again.');
      _updateStatus(VoiceStatus.idle);
    }

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // ERROR HANDLING
  // ═══════════════════════════════════════════════════════════════

  void _setError(String message) {
    _errorMessage = message;
    if (_session != null) {
      _session = _session!.copyWith(
        status: VoiceStatus.error,
        errorMessage: message,
      );
    }
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_session != null) {
      _session = _session!.copyWith(clearError: true);
    }
    notifyListeners();
  }

  void _handleSttError(String errorMsg) {
    debugPrint('STT error: $errorMsg');

    if (errorMsg.contains('error_no_match') ||
        errorMsg.contains('error_speech_timeout')) {
      // Silence — not a real error in push-to-talk mode
      if (_session?.mode == VoiceMode.pushToTalk) {
        _updateStatus(VoiceStatus.idle);
      } else {
        // In continuous mode, try listening again
        startListening();
      }
      return;
    }

    if (errorMsg.contains('error_permission')) {
      _setError('Microphone permission denied. Please enable it in Settings.');
      return;
    }

    if (errorMsg.contains('error_audio') ||
        errorMsg.contains('error_server')) {
      _setError('Audio error. Please check your microphone.');
      _updateStatus(VoiceStatus.idle);
      return;
    }

    // Generic error
    _updateStatus(VoiceStatus.idle);
  }

  void _handleSttStatus(String status) {
    if (status == 'notListening' && _session != null) {
      if (_session!.status == VoiceStatus.listening) {
        // STT stopped on its own (timeout)
        if (_session!.mode == VoiceMode.continuous &&
            _lastUserText.isEmpty) {
          // No speech detected, try again
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!_disposed && _session?.mode == VoiceMode.continuous) {
              startListening();
            }
          });
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  void _updateStatus(VoiceStatus status) {
    if (_session == null) return;
    _session = _session!.copyWith(status: status);
    notifyListeners();
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    if (_session?.mode == VoiceMode.continuous) {
      _silenceTimer = Timer(const Duration(seconds: 15), () {
        if (isListening && _lastUserText.isEmpty) {
          // Still here? Pause after prolonged silence
          pauseSession();
          _setError("Still there? Tap the mic when you're ready.");
        }
      });
    }
  }

  void _logEvent(String eventType, Map<String, dynamic> metadata) {
    try {
      _firebaseService.saveUserEvent(UserEventModel(
        eventType: eventType,
        screenName: 'voice_assistant',
        metadata: metadata,
        timestamp: DateTime.now(),
      ));
    } catch (_) {
      // Non-critical
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _silenceTimer?.cancel();
    _connectivitySub?.cancel();
    _speech.stop();
    _ttsService.dispose();
    super.dispose();
  }
}
