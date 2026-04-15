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
  static const int _kMaxDebugEntries = 120;

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
  bool _isMicMuted = false;
  bool get isMicMuted => _isMicMuted;

  bool get isActive => _session?.isActive ?? false;
  bool get isListening => _session?.status == VoiceStatus.listening;
  bool get isSpeaking => _session?.status == VoiceStatus.speaking;
  bool get isIdle => _session == null || _session!.status == VoiceStatus.idle;

  StreamSubscription? _micSub;
  StreamSubscription? _audioSub;
  StreamSubscription? _msgSub;
  StreamSubscription? _connectivitySub;
  StreamSubscription<String>? _liveDebugSub;
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool get micAvailable => _micAvailable;

  LiveConnectionPhase get liveConnectionPhase => _liveService.connectionPhase;
  String? get liveServiceError => _liveService.lastError;

  Timer? _contextRefreshTimer;
  Timer? _setupTimeoutTimer;

  // Prevents addChunk() firing before start() completes
  bool _playerStarting = false;

  int _micChunksCaptured = 0;
  int _micChunksSent = 0;
  int _audioChunksPlayed = 0;
  DateTime? _sessionStartedAt;

  final List<String> _debugEntries = [];
  List<String> get debugEntries => List.unmodifiable(_debugEntries);

  final List<double> _waveformAmplitudes = [];
  List<double> get waveformAmplitudes => _waveformAmplitudes;

  Map<String, String> get debugStats {
    return {
      'status': (_session?.status ?? VoiceStatus.idle).name,
      'connected': isConnected.toString(),
      'live_phase': liveConnectionPhase.name,
      'online': _isOnline.toString(),
      'mic_permission': _micAvailable.toString(),
      'mic_muted': _isMicMuted.toString(),
      'mic_chunks_captured': _micChunksCaptured.toString(),
      'mic_chunks_sent': _micChunksSent.toString(),
      'audio_chunks_played': _audioChunksPlayed.toString(),
        'session_uptime_sec': _sessionStartedAt == null
          ? '0'
          : DateTime.now().difference(_sessionStartedAt!).inSeconds.toString(),
      'messages_in': _liveService.messagesReceived.toString(),
      'messages_out': _liveService.messagesSent.toString(),
      'live_audio_in': _liveService.audioChunksReceived.toString(),
      'live_audio_out': _liveService.audioChunksSent.toString(),
      'last_error': _errorMessage ?? liveServiceError ?? '-',
    };
  }

  String buildDebugDump() {
    final buffer = StringBuffer();
    buffer.writeln('CARE-AI Voice Debug Dump');
    buffer.writeln('generated_at: ${DateTime.now().toIso8601String()}');
    for (final entry in debugStats.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    buffer.writeln('--- recent_events ---');
    final events = _debugEntries.length > 50
        ? _debugEntries.sublist(_debugEntries.length - 50)
        : _debugEntries;
    for (final line in events) {
      buffer.writeln(line);
    }
    return buffer.toString();
  }

  void _appendDebug(String message, {bool notify = false}) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    _debugEntries.add('[$time] $message');
    if (_debugEntries.length > _kMaxDebugEntries) {
      _debugEntries.removeAt(0);
    }
    AppLogger.info('VoiceAssistantService', message);
    if (notify) {
      notifyListeners();
    }
  }

  void _resetSessionCounters() {
    _micChunksCaptured = 0;
    _micChunksSent = 0;
    _audioChunksPlayed = 0;
  }

  Future<bool> initialize() async {
    try {
      _appendDebug('Initializing voice assistant service...');
      _micAvailable = await _audioRecorder.hasPermission();
      _appendDebug(
        'Microphone permission: ${_micAvailable ? 'granted' : 'denied'}',
      );

      final currentConnectivity = await Connectivity().checkConnectivity();
      _isOnline = currentConnectivity.any((r) => r != ConnectivityResult.none);
      _appendDebug('Initial connectivity: ${_isOnline ? 'online' : 'offline'}');

      _liveDebugSub ??= _liveService.debugStream.listen((line) {
        _appendDebug('LiveService $line', notify: true);
      });

      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        final wasOnline = _isOnline;
        _isOnline = results.any((r) => r != ConnectivityResult.none);
        _appendDebug('Connectivity changed: ${_isOnline ? 'online' : 'offline'}');

        if (!_isOnline && wasOnline && isActive) {
          _setError('You appear to be offline.');
          unawaited(stopSession(clearError: false));
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
      _appendDebug('Initialization failed: $e', notify: true);
      return false;
    }
  }

  Future<void> startLiveSession({
    ChildProfileModel? childProfile,
    String? currentScreen,
  }) async {
    _appendDebug('startLiveSession() requested.', notify: true);

    if (isActive) {
      _appendDebug('Session already active. Ignoring duplicate start request.');
      return;
    }

    final hasMicPermission =
        _micAvailable || await _audioRecorder.hasPermission();
    _micAvailable = hasMicPermission;
    if (!hasMicPermission) {
      _setError(
        'Microphone permission denied. Please allow microphone access in settings.',
      );
      return;
    }
    if (!_isOnline) {
      _setError('No internet connection. Please reconnect and try again.');
      return;
    }

    try {
      _resetSessionCounters();
      _sessionStartedAt = DateTime.now();

      _session = VoiceSessionModel.create(
        sessionId: _uuid.v4(),
        mode: VoiceMode.continuous,
      );
      _errorMessage = null;
      _updateStatus(VoiceStatus.processing);
      _appendDebug('Session created. id=${_session!.sessionId}');

      // Build full context before connecting
      final contextService = ContextBuilderService(
        SmartDataRepository(_firebaseService),
      );
      final userId = _firebaseService.currentUser?.uid;

      String fullContext = '';
      if (userId != null) {
        _appendDebug('Building personalized context for user $userId...');
        try {
          fullContext = await contextService.buildFullContext(
            userId: userId,
            childProfile: childProfile,
          );
          _appendDebug('Context ready (${fullContext.length} chars).');
        } catch (e, stack) {
          AppLogger.error(
            'VoiceAssistantService',
            'Context build failed',
            e,
            stack,
          );
          _appendDebug(
            'Context build failed; proceeding with base instruction. Error: $e',
            notify: true,
          );
        }
      } else {
        _appendDebug(
          'No authenticated user found. Starting without personalized context.',
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

      _appendDebug('Connecting to Gemini Live...');
      final connected = await _liveService.connect(systemInstruction);
      if (!connected) {
        _setError(
          'Unable to connect to live voice service. ${_liveService.lastError ?? ''}'.trim(),
        );
        return;
      }

      _appendDebug('Connected to Gemini Live. Waiting for setupComplete...');

      _setupTimeoutTimer?.cancel();
      _setupTimeoutTimer = Timer(const Duration(seconds: 12), () {
        if (_session == null || _session!.status != VoiceStatus.processing) {
          return;
        }
        _setError(
          'Voice setup timed out. Check internet/API key and try again.',
        );
        unawaited(stopSession(clearError: false));
      });

      notifyListeners(); // Safe — called after connect(), not during build

      // Context auto-refresh timer (every 5 mins)
      _contextRefreshTimer?.cancel();
      _contextRefreshTimer = Timer.periodic(const Duration(minutes: 5), (
        _,
      ) async {
        if (!isActive || userId == null) return;
        try {
          final refreshedContext = await contextService.buildFullContext(
            userId: userId,
            childProfile: childProfile,
          );
          final sent = _liveService.sendRealtimeText(
            'Context refresh: $refreshedContext',
          );
          if (!sent) {
            _appendDebug(
              'Context refresh skipped because voice socket is disconnected.',
            );
          }
        } catch (e, stack) {
          AppLogger.error(
            'VoiceAssistantService',
            'Context refresh failed',
            e,
            stack,
          );
          _appendDebug('Context refresh failed: $e');
        }
      });

      // FIX: await start() before feeding chunks to avoid race condition
      _audioSub = _liveService.audioStream.listen(
        (chunk) async {
          _audioChunksPlayed += 1;
          if (_audioChunksPlayed == 1 || _audioChunksPlayed % 25 == 0) {
            _appendDebug('Audio chunks played: $_audioChunksPlayed');
          }

          if (!_audioPlayer.isPlaying && !_playerStarting) {
            _playerStarting = true;
            try {
              await _audioPlayer.start(sampleRate: 24000);
            } finally {
              _playerStarting = false;
            }
            _updateStatus(VoiceStatus.speaking);
          }

          // Only feed chunk if player is fully ready
          if (_audioPlayer.isPlaying) {
            _audioPlayer.addChunk(chunk);
          }
        },
        onError: (e, stack) {
          AppLogger.error(
            'VoiceAssistantService',
            'Audio stream error',
            e,
            stack,
          );
          _setError('Audio playback error: $e');
        },
        onDone: () {
          _appendDebug('Live audio stream closed.');
        },
      );

      // Start mic ONLY after setupComplete is received from API
      _msgSub = _liveService.messagesStream.listen(
        (msg) async {
          if (msg.containsKey('setupComplete')) {
            _setupTimeoutTimer?.cancel();
            _appendDebug('setupComplete received; starting microphone stream.');
            await _startMicStreaming();
            if (_session?.status != VoiceStatus.error) {
              _updateStatus(VoiceStatus.listening);
            }
            return;
          }

          if (msg.containsKey('error')) {
            _setError('Live API error: ${msg['error']}');
            unawaited(stopSession(clearError: false));
            return;
          }

          // In the Gemini Live API, function/tool calls arrive as a SEPARATE
          // top-level "toolCall" message — NOT inside serverContent.modelTurn.
          if (msg.containsKey('toolCall')) {
            final calls = msg['toolCall']['functionCalls'] as List?;
            if (calls != null) {
              _appendDebug('Received toolCall with ${calls.length} function call(s).');
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
        },
        onError: (e, stack) {
          AppLogger.error(
            'VoiceAssistantService',
            'Message stream error',
            e,
            stack,
          );
          _setError('Voice stream error: $e');
          unawaited(stopSession(clearError: false));
        },
        onDone: () {
          _appendDebug('Message stream closed.');
          if (isActive) {
            _setError('Voice connection closed. Please start the session again.');
            unawaited(stopSession(clearError: false));
          }
        },
      );

      _logEvent('live_voice_session_started', {
        'sessionId': _session?.sessionId,
        'screen': currentScreen ?? 'unknown',
      });
    } catch (e, stack) {
      AppLogger.error(
        'VoiceAssistantService',
        'Unhandled startLiveSession error',
        e,
        stack,
      );
      _setError('Voice session failed to start: $e');
      await stopSession(clearError: false);
    }
  }

  Future<void> _startMicStreaming() async {
    Stream<Uint8List> stream;
    try {
      _appendDebug('Starting microphone stream...');
      stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
    } catch (e, stack) {
      AppLogger.error(
        'VoiceAssistantService',
        'Failed to start microphone stream',
        e,
        stack,
      );
      _setError(
        'Could not access microphone stream. Close other apps using the mic and retry.',
      );
      return;
    }

    _micSub = stream.listen(
      (data) {
        _micChunksCaptured += 1;
        _updateWaveform(data);
        if (_isMicMuted) return;
        // Gate 1: don't send audio while AI is speaking.
        // Prevents the AI's own speaker output or ambient noise from
        // triggering Gemini's VAD and causing unwanted interruptions.
        if (isSpeaking) return;
        // Gate 2: RMS energy check — ignore sub-threshold noise chunks
        // (background hum, fan, AC, TV, etc.) before sending to Gemini.
        if (!_rmsExceedsThreshold(data)) return;
        final sent = _liveService.sendAudioChunk(data);
        if (sent) {
          _micChunksSent += 1;
          if (_micChunksSent == 1 || _micChunksSent % 50 == 0) {
            _appendDebug('Microphone chunks sent: $_micChunksSent');
          }
        }
      },
      onError: (e, stack) {
        AppLogger.error(
          'VoiceAssistantService',
          'Microphone stream error',
          e,
          stack,
        );
        _setError('Microphone stream error: $e');
      },
      onDone: () {
        _appendDebug('Microphone stream closed.');
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
      _appendDebug('Interrupt requested while AI is speaking.');
      await _audioPlayer.stop();
      _liveService.sendRealtimeText('Stop');
      _updateStatus(VoiceStatus.listening);
    }
  }

  void setMicMuted(bool muted) {
    if (_isMicMuted == muted) return;
    _isMicMuted = muted;
    _appendDebug('Microphone muted: $_isMicMuted');
    notifyListeners();
  }

  void toggleMicMuted() {
    setMicMuted(!_isMicMuted);
  }

  void _handleFunctionCall(Map<String, dynamic> call) {
    // Live API format: {"id": "...", "name": "...", "args": {...}}
    final callId = call['id'] as String? ?? '';
    final name = call['name'] as String?;
    final args = (call['args'] as Map?)?.cast<String, dynamic>() ?? {};

    _appendDebug('Function call received. name=$name args=$args');

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
            _liveService.sendRealtimeText(
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
      _appendDebug('Function call result sent. id=$callId result=$result');
    } else {
      _appendDebug('Unhandled function call name: $name');
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
    if (route == null) {
      _appendDebug('Navigation target not recognized: "$target"');
      return false;
    }

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      route,
      (r) => r.isFirst,
    );
    _appendDebug('Navigated to route: $route');
    return true;
  }

  Future<void> stopSession({bool clearError = true}) async {
    _appendDebug('Stopping voice session...');
    _playerStarting = false;
    _setupTimeoutTimer?.cancel();
    _contextRefreshTimer?.cancel();

    try {
      await _micSub?.cancel();
    } catch (e) {
      _appendDebug('Failed to cancel mic subscription: $e');
    }
    _micSub = null;

    try {
      await _audioSub?.cancel();
    } catch (e) {
      _appendDebug('Failed to cancel audio subscription: $e');
    }
    _audioSub = null;

    try {
      await _msgSub?.cancel();
    } catch (e) {
      _appendDebug('Failed to cancel message subscription: $e');
    }
    _msgSub = null;

    try {
      await _audioRecorder.stop();
    } catch (e) {
      _appendDebug('Audio recorder stop warning: $e');
    }

    _liveService.disconnect(reason: 'voice_session_stop');

    try {
      await _audioPlayer.stop();
    } catch (e) {
      _appendDebug('Audio player stop warning: $e');
    }

    _waveformAmplitudes.clear();
    _isMicMuted = false;
    _sessionStartedAt = null;
    _resetSessionCounters();
    _session = null;
    if (clearError) {
      _errorMessage = null;
    }
    _appendDebug('Voice session stopped. clearError=$clearError');
    notifyListeners();
  }

  void _setError(String message) {
    AppLogger.error('VoiceAssistantService', 'Session Error: $message');
    _appendDebug('ERROR: $message', notify: true);
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
    _appendDebug('Clearing voice error banner.');
    _errorMessage = null;
    if (_session != null) {
      _session = _session!.copyWith(clearError: true);
    }
    notifyListeners();
  }

  void _updateStatus(VoiceStatus status) {
    if (_session == null) return;
    if (_session!.status == status) return;
    _appendDebug('Status changed: ${_session!.status.name} -> ${status.name}');
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
    _appendDebug('Disposing VoiceAssistantService');
    _setupTimeoutTimer?.cancel();
    _contextRefreshTimer?.cancel();
    _connectivitySub?.cancel();
    _liveDebugSub?.cancel();
    unawaited(stopSession());
    _liveService.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}
