import 'dart:async';
import 'dart:math' as math;
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
import 'cache/smart_data_repository.dart';
import '../core/utils/app_logger.dart';

class VoiceAssistantService extends ChangeNotifier {
  // RMS amplitude threshold below which audio is treated as silence/noise.
  // PCM16 range is 0–32768. 400 ≈ -38 dBFS — filters fans, AC, background TV.
  static const double _kNoiseFloor = 400.0;

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
    final contextService = ContextBuilderService(SmartDataRepository(_firebaseService));
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

    // Start mic ONLY after setupComplete is received from API
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

      // In the Gemini Live API, function/tool calls arrive as a SEPARATE
      // top-level "toolCall" message — NOT inside serverContent.modelTurn.
      if (msg.containsKey('toolCall')) {
        final calls = msg['toolCall']['functionCalls'] as List?;
        if (calls != null) {
          for (final call in calls) {
            _handleFunctionCall(call as Map<String, dynamic>);
          }
        }
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
        // Gate 1: don't send audio while AI is speaking.
        // Prevents the AI's own speaker output or ambient noise from
        // triggering Gemini's VAD and causing unwanted interruptions.
        if (isSpeaking) return;
        // Gate 2: RMS energy check — ignore sub-threshold noise chunks
        // (background hum, fan, AC, TV, etc.) before sending to Gemini.
        if (!_rmsExceedsThreshold(data)) return;
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

  /// Returns true when the RMS amplitude of [data] exceeds [_kNoiseFloor].
  /// Filters out background noise (fans, AC, ambient sound) so only genuine
  /// speech reaches the Gemini WebSocket.
  bool _rmsExceedsThreshold(Uint8List data) {
    if (data.length < 2) return false;
    final sampleCount = data.length ~/ 2;
    double sumSq = 0;
    for (int i = 0; i < sampleCount; i++) {
      int sample = (data[i * 2 + 1] << 8) | data[i * 2];
      if (sample > 32767) sample -= 65536;
      sumSq += sample * sample;
    }
    final rms = math.sqrt(sumSq / sampleCount);
    return rms > _kNoiseFloor;
  }

  Future<void> interruptAI() async {
    if (isSpeaking) {
      await _audioPlayer.stop();
      _liveService.sendClientContent("Stop");
      _updateStatus(VoiceStatus.listening);
    }
  }

  void _handleFunctionCall(Map<String, dynamic> call) {
    // Live API format: {"id": "...", "name": "...", "args": {...}}
    final callId = call['id'] as String? ?? '';
    final name = call['name'] as String?;
    final args = (call['args'] as Map?)?.cast<String, dynamic>() ?? {};

    String result = 'error';

    if (name == 'perform_app_action') {
      final action = args['action'] as String?;
      final target = args['target'] as String?;

      if (action == 'navigate' && target != null) {
        final navigated = _navigateToTarget(target);
        result = navigated ? 'success' : 'unknown_target';

        if (!navigated) {
          // Tell Gemini the target wasn't found so it gives a verbal fallback
          Future.delayed(const Duration(milliseconds: 300), () {
            _liveService.sendClientContent(
              'Navigation failed: screen "$target" was not recognised. '
              'Tell the user the available screens they can go to: '
              'Home, Chat, Activities, Progress, Daily Plan, Wellness, '
              'Games, Emergency, Community, Settings, Achievements.',
            );
          });
        }
      }

      // Correct Gemini Live API tool-response envelope (requires the call id)
      _liveService.sendJson({
        "toolResponse": {
          "functionResponses": [
            {
              "id": callId,
              "name": "perform_app_action",
              "response": {"result": result},
            },
          ],
        },
      });
    }
  }

  /// Maps a voice-spoken target name to a Flutter route and navigates to it.
  /// Returns `true` if a matching route was found, `false` if the target is
  /// unrecognised (so the caller can trigger a verbal fallback).
  bool _navigateToTarget(String target) {
    const routeMap = <String, String>{
      // Home / Dashboard
      'home': '/home', 'dashboard': '/home', 'main': '/home',
      'start': '/home', 'overview': '/home',
      // Chat
      'chat': '/chat', 'assistant': '/chat', 'ai': '/chat',
      // Activities / Modules
      'activities': '/activities', 'activity': '/activities',
      'modules': '/activities', 'library': '/activities',
      // Progress
      'progress': '/progress', 'report': '/progress',
      'stats': '/progress', 'statistics': '/progress',
      // Daily plan
      'daily plan': '/daily-plan', 'dailyplan': '/daily-plan',
      'plan': '/daily-plan', 'daily': '/daily-plan',
      'schedule': '/daily-plan', 'tasks': '/daily-plan',
      // Wellness
      'wellness': '/wellness', 'wellbeing': '/wellness',
      'health': '/wellness', 'mood': '/wellness',
      // Games
      'games': '/games', 'game': '/games', 'play': '/games',
      // Emergency
      'emergency': '/emergency', 'sos': '/emergency',
      'help': '/emergency', 'crisis': '/emergency',
      // Community
      'community': '/community', 'social': '/community',
      'forum': '/community',
      // Settings
      'settings': '/settings', 'preferences': '/settings',
      'options': '/settings', 'configuration': '/settings',
      // Achievements
      'achievements': '/achievements', 'achievement': '/achievements',
      'badges': '/achievements', 'rewards': '/achievements',
      // About
      'about': '/about',
    };

    final route = routeMap[target.toLowerCase().trim()];
    if (route == null) return false;

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      route,
      (r) => r.isFirst,
    );
    AppLogger.info('VoiceAssistantService', 'Navigated to $route');
    return true;
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
