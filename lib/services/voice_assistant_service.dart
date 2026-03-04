import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../main.dart'; // For navigatorKey
import '../models/voice_session_model.dart';
import '../models/child_profile_model.dart';
import '../models/user_event_model.dart';
import 'gemini_live_service.dart';
import 'pcm_audio_player.dart';
import 'firebase_service.dart';

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
  bool _disposed = false;

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
    } catch (e) {
      debugPrint('VoiceAssistant init error: $e');
      _micAvailable = false;
      return false;
    }
  }

  Future<void> startLiveSession({ChildProfileModel? childProfile}) async {
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

    final profileContext = childProfile != null 
        ? "Child profile: ${childProfile.name}, age ${childProfile.age}, conditions: ${childProfile.conditions.join(', ')}. "
        : "";
    
    final systemInstruction = '''You are CARE-AI Voice, a warm, supportive virtual therapist.
$profileContext
RULES:
- Respond ONLY with audio. Keep responses UNDER 20 seconds. 
- Be conversational. Do not use Markdown formatting.
- If they ask to navigate somewhere, use the function tool to navigate.''';

    await _liveService.connect(systemInstruction);

    _audioSub = _liveService.audioStream.listen((chunk) {
      if (!_audioPlayer.isPlaying) {
        _updateStatus(VoiceStatus.speaking);
        _audioPlayer.playStream(_liveService.audioStream, sampleRate: 24000);
      }
    });

    _msgSub = _liveService.messagesStream.listen((msg) {
      if (msg.containsKey('serverContent')) {
        final content = msg['serverContent'];
        
        // Handle interruptions
        if (content['interrupted'] == true) {
          _audioPlayer.stop();
          _updateStatus(VoiceStatus.listening);
        }

        // Handle Function calls
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

    await _startMicStreaming();
    
    _updateStatus(VoiceStatus.listening);
    _logEvent('live_voice_session_started', {});
  }

  Future<void> _startMicStreaming() async {
    final stream = await _audioRecorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    ));

    _micSub = stream.listen((data) {
      _updateWaveform(data);
      // Stream mic input directly to Gemini
      _liveService.sendAudioChunk(data);
    }, onError: (e) {
      _setError('Microphone error.');
    });
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
      
      // Acknowledge function call
      final response = {
        "clientContent": {
          "turns": [
            {
              "role": "user",
              "parts": [
                {
                  "functionResponse": {
                    "name": "perform_app_action",
                    "response": {"result": "Success"}
                  }
                }
              ]
            }
          ],
          "turnComplete": true
        }
      };
      // Send directly via WebSocket
      _liveService.sendJson(response);
    }
  }

  void _navigateToTarget(String target) {
    String route = '/home'; 
    switch (target.toLowerCase()) {
      case 'dashboard': route = '/home'; break;
      case 'wellness': route = '/wellness'; break;
      case 'daily plan': route = '/daily-plan'; break;
      case 'games': route = '/games'; break;
      case 'emergency': route = '/emergency'; break;
      case 'progress': route = '/progress'; break;
      case 'community': route = '/community'; break;
      case 'activities': route = '/activities'; break;
      case 'settings': route = '/settings'; break;
    }
    navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (r) => r.isFirst);
  }

  Future<void> stopSession() async {
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
      _firebaseService.saveUserEvent(UserEventModel(
        eventType: eventType,
        screenName: 'voice_assistant_live',
        metadata: metadata,
        timestamp: DateTime.now(),
      ));
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySub?.cancel();
    stopSession();
    _liveService.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}
