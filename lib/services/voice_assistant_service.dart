import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../main.dart';
import '../models/voice_session_model.dart';
import '../models/child_profile_model.dart';
import '../models/user_event_model.dart';
import 'gemini_live_service.dart';
import 'pcm_audio_player.dart';
import 'firebase_service.dart';
import 'context_builder_service.dart';
import '../core/utils/app_logger.dart';

class VoiceAssistantService extends ChangeNotifier {
  final GeminiLiveService _liveService = GeminiLiveService();
  final PcmAudioPlayer _audioPlayer = PcmAudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  VoiceSessionModel? _session;
  VoiceSessionModel? get session => _session;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _micAvailable = false;
  bool get isConnected => _liveService.isConnected;

  bool get isActive => _session?.isActive ?? false;
  bool get isListening => _session?.status == VoiceStatus.listening;
  bool get isSpeaking => _session?.status == VoiceStatus.speaking;
  bool get isIdle => _session == null || _session!.status == VoiceStatus.idle;

  StreamSubscription? _micSub;
  StreamSubscription? _audioSub;
  StreamSubscription? _msgSub;
  StreamSubscription? _connectivitySub;
  bool _isOnline = true;

  Timer? _contextRefreshTimer;

  // Prevents addChunk() firing before start() completes
  bool _playerStarting = false;

  final List<double> _waveformAmplitudes = [];
  List<double> get waveformAmplitudes => _waveformAmplitudes;

  Future<bool> initialize() async {
    try {
      _micAvailable = await _audioRecorder.hasPermission();

      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        final wasOnline = _isOnline;
        _isOnline = results.any((r) => r != ConnectivityResult.none);

        if (!_isOnline && wasOnline && isActive) {
          _setError('You appear to be offline.');
          stopSession();
        }
      });

      return _micAvailable;
    } catch (e, stack) {
      AppLogger.error(
        'VoiceAssistantService',
        'Initialization error',
        e,
        stack,
      );
      _micAvailable = false;
      return false;
    }
  }

  Future<void> startLiveSession({
    ChildProfileModel? childProfile,
    String? currentScreen,
  }) async {
    if (!_micAvailable) {
      _setError('Microphone permission denied.');
      return;
    }
    if (!_isOnline) {
      _setError('No internet connection.');
      return;
    }

    _session = VoiceSessionModel.create(
      sessionId: _uuid.v4(),
      mode: VoiceMode.continuous,
    );
    _errorMessage = null;
    _updateStatus(VoiceStatus.processing);

    // Build full context before connecting
    final contextService = ContextBuilderService(_firebaseService);
    final userId = _firebaseService.currentUser?.uid;

    String fullContext = "";
    if (userId != null) {
      fullContext = await contextService.buildFullContext(
        userId: userId,
        childProfile: childProfile,
      );
    }

    final systemInstruction =
        '''You are CARE-AI Voice, a warm, empathetic, and professional AI therapist assistant built into the CARE-AI app.

$fullContext

BEHAVIORAL RULES:
- Respond ONLY with audio. Keep responses UNDER 20 seconds. 
- Be conversational. Do not use Markdown formatting.
- Reference the user's actual data when relevant (e.g. "I see you completed your breathing exercise today — great work!")
- If the user seems distressed based on recent wellness scores, be extra gentle and offer specific coping strategies.
- If they ask to navigate somewhere, use the function tool to navigate.
- Current screen context: ${currentScreen ?? 'unknown'}
''';

    await _liveService.connect(systemInstruction);
    notifyListeners(); // Safe — called after connect(), not during build

    // Context auto-refresh timer (every 5 mins)
    _contextRefreshTimer?.cancel();
    _contextRefreshTimer = Timer.periodic(const Duration(minutes: 5), (
      _,
    ) async {
      if (!isActive || userId == null) return;
      final refreshedContext = await contextService.buildFullContext(
        userId: userId,
        childProfile: childProfile,
      );
      _liveService.sendClientContent('Context refresh: $refreshedContext');
    });

    // FIX: await start() before feeding chunks to avoid race condition
    _audioSub = _liveService.audioStream.listen((chunk) async {
      if (!_audioPlayer.isPlaying && !_playerStarting) {
        _playerStarting = true;
        await _audioPlayer.start(sampleRate: 24000);
        _playerStarting = false;
        _updateStatus(VoiceStatus.speaking);
      }
      // Only feed chunk if player is fully ready
      if (_audioPlayer.isPlaying) {
        _audioPlayer.addChunk(chunk);
      }
    });

    // FIX: Start mic ONLY after setupComplete is received from API
    _msgSub = _liveService.messagesStream.listen((msg) async {
      if (msg.containsKey('setupComplete')) {
        AppLogger.info(
          'VoiceAssistantService',
          'Setup complete — starting mic',
        );
        await _startMicStreaming();
        _updateStatus(VoiceStatus.listening);
        return;
      }

      if (msg.containsKey('serverContent')) {
        final content = msg['serverContent'];

        // AI finished speaking — reset to listening
        if (content['turnComplete'] == true) {
          await _audioPlayer.stop();
          _updateStatus(VoiceStatus.listening);
        }

        // AI was interrupted — reset to listening
        if (content['interrupted'] == true) {
          await _audioPlayer.stop();
          _updateStatus(VoiceStatus.listening);
        }

        // Handle function calls
        if (content.containsKey('modelTurn')) {
          final parts = content['modelTurn']['parts'] as List;
          for (final part in parts) {
            if (part.containsKey('functionCall')) {
              _handleFunctionCall(part['functionCall']);
            }
          }
        }
      }
    });

    _logEvent('live_voice_session_started', {});
  }

  Future<void> _startMicStreaming() async {
    final stream = await _audioRecorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _micSub = stream.listen(
      (data) {
        _updateWaveform(data);
        _liveService.sendAudioChunk(data);
      },
      onError: (e, stack) {
        AppLogger.error(
          'VoiceAssistantService',
          'Microphone stream error',
          e,
          stack,
        );
        _setError('Microphone error: hardware disconnected.');
      },
    );
  }

  void _updateWaveform(Uint8List data) {
    if (data.isEmpty) return;
    int sum = 0;
    for (int i = 0; i < data.length - 1; i += 2) {
      int sample = (data[i + 1] << 8) | data[i];
      if (sample > 32767) sample -= 65536;
      sum += sample.abs();
    }
    final avg = sum / (data.length / 2);
    final normalized = (avg / 32768.0).clamp(0.0, 1.0);

    _waveformAmplitudes.add(normalized);
    if (_waveformAmplitudes.length > 20) {
      _waveformAmplitudes.removeAt(0);
    }
    notifyListeners();
  }

  Future<void> interruptAI() async {
    if (isSpeaking) {
      await _audioPlayer.stop();
      _liveService.sendClientContent("Stop");
      _updateStatus(VoiceStatus.listening);
    }
  }

  void _handleFunctionCall(Map<String, dynamic> call) {
    if (call['name'] == 'perform_app_action') {
      final args = call['args'] as Map<String, dynamic>;
      final action = args['action'];
      final target = args['target'];

      if (action == 'navigate' && target != null) {
        _navigateToTarget(target);
      }

      final response = {
        "clientContent": {
          "turns": [
            {
              "role": "user",
              "parts": [
                {
                  "functionResponse": {
                    "name": "perform_app_action",
                    "response": {"result": "Success"},
                  },
                },
              ],
            },
          ],
          "turnComplete": true,
        },
      };
      _liveService.sendJson(response);
    }
  }

  void _navigateToTarget(String target) {
    String route = '/home';
    switch (target.toLowerCase()) {
      case 'dashboard':
        route = '/home';
        break;
      case 'wellness':
        route = '/wellness';
        break;
      case 'daily plan':
        route = '/daily-plan';
        break;
      case 'games':
        route = '/games';
        break;
      case 'emergency':
        route = '/emergency';
        break;
      case 'progress':
        route = '/progress';
        break;
      case 'community':
        route = '/community';
        break;
      case 'activities':
        route = '/activities';
        break;
      case 'settings':
        route = '/settings';
        break;
    }
    navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (r) => r.isFirst);
  }

  Future<void> stopSession() async {
    _playerStarting = false;
    _contextRefreshTimer?.cancel();
    _micSub?.cancel();
    await _audioRecorder.stop();
    _liveService.disconnect();
    _audioSub?.cancel();
    _msgSub?.cancel();
    await _audioPlayer.stop();

    _waveformAmplitudes.clear();
    _session = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    AppLogger.error('VoiceAssistantService', 'Session Error: $message');
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

  void _updateStatus(VoiceStatus status) {
    if (_session == null) return;
    _session = _session!.copyWith(status: status);
    notifyListeners();
  }

  void _logEvent(String eventType, Map<String, dynamic> metadata) {
    try {
      _firebaseService.saveUserEvent(
        UserEventModel(
          eventType: eventType,
          screenName: 'voice_assistant_live',
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _contextRefreshTimer?.cancel();
    _connectivitySub?.cancel();
    stopSession();
    _liveService.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}
