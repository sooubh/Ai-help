import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/config/env_config.dart';
import '../core/utils/app_logger.dart';

enum LiveConnectionPhase { idle, connecting, connected, disconnected, failed }

class GeminiLiveService {
  WebSocketChannel? _channel;
  LiveConnectionPhase _connectionPhase = LiveConnectionPhase.idle;
  String? _lastError;

  int _messagesReceived = 0;
  int _messagesSent = 0;
  int _audioChunksSent = 0;
  int _audioChunksReceived = 0;

  static const int _maxDebugLines = 120;
  final List<String> _debugLines = [];
  final _debugController = StreamController<String>.broadcast();

  final _audioStreamController = StreamController<Uint8List>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Uint8List> get audioStream => _audioStreamController.stream;
  Stream<Map<String, dynamic>> get messagesStream => _messageController.stream;
  Stream<String> get debugStream => _debugController.stream;

  LiveConnectionPhase get connectionPhase => _connectionPhase;
  String? get lastError => _lastError;
  int get messagesReceived => _messagesReceived;
  int get messagesSent => _messagesSent;
  int get audioChunksSent => _audioChunksSent;
  int get audioChunksReceived => _audioChunksReceived;
  List<String> get debugLines => List.unmodifiable(_debugLines);

  bool get isConnected =>
      _channel != null && _connectionPhase == LiveConnectionPhase.connected;

  void _pushDebug(String message, {bool isError = false}) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final line = '[$time] ${isError ? 'ERROR' : 'INFO'} $message';

    _debugLines.add(line);
    if (_debugLines.length > _maxDebugLines) {
      _debugLines.removeAt(0);
    }

    if (isError) {
      AppLogger.error('GeminiLiveService', message);
    } else {
      AppLogger.info('GeminiLiveService', message);
    }

    if (!_debugController.isClosed) {
      _debugController.add(line);
    }
  }

  void _setError(String message) {
    _lastError = message;
    _connectionPhase = LiveConnectionPhase.failed;
    _pushDebug(message, isError: true);
  }

  Future<bool> connect(String systemInstruction) async {
    if (_channel != null) {
      _pushDebug('connect() called while socket already exists.');
      return isConnected;
    }

    _connectionPhase = LiveConnectionPhase.connecting;
    _lastError = null;
    _messagesReceived = 0;
    _messagesSent = 0;
    _audioChunksSent = 0;
    _audioChunksReceived = 0;

    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      _setError(
        'Gemini API key is missing. Set GEMINI_API_KEY in .env or --dart-define.',
      );
      return false;
    }

    final wsUrl = Uri.parse(
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$apiKey',
    );

    try {
      _pushDebug('Connecting to Gemini Live WebSocket...');
      _channel = WebSocketChannel.connect(wsUrl);

      await _channel!.ready;
      _connectionPhase = LiveConnectionPhase.connected;
      _pushDebug('WebSocket handshake complete; sending setup payload.');

      _channel!.stream.listen(
        _onMessage,
        onError: (e, stack) {
          _setError('WebSocket stream error: $e');
          disconnect(reason: 'stream_error');
        },
        onDone: () {
          final closeCode = _channel?.closeCode;
          final closeReason = _channel?.closeReason;
          final closedMsg =
              'WebSocket closed. code=$closeCode reason=${closeReason ?? 'none'}';
          if (_connectionPhase != LiveConnectionPhase.disconnected &&
              _connectionPhase != LiveConnectionPhase.failed) {
            _setError('$closedMsg (unexpected)');
          } else {
            _pushDebug(closedMsg);
          }
          disconnect(reason: 'stream_done');
        },
      );

      final setupMessage = {
        "setup": {
          "model": "models/gemini-3.1-flash-live-preview",
          "generation_config": {
            "response_modalities": ["AUDIO"],
          },
          // Server-side VAD: require clearer speech before triggering,
          // and wait longer in silence before ending a turn.
          // This prevents background noise, fans, AC, and TV from being
          // treated as valid user speech.
          "realtime_input_config": {
            "automatic_activity_detection": {
              "disabled": false,
              "start_of_speech_sensitivity": "START_SENSITIVITY_LOW",
              "end_of_speech_sensitivity": "END_SENSITIVITY_LOW",
              "prefix_padding_ms": 100,
              "silence_duration_ms": 800,
            },
          },
          "system_instruction": {
            "parts": [
              {"text": systemInstruction},
            ],
          },
          "tools": [
            {
              "function_declarations": [
                {
                  "name": "perform_app_action",
                  "description": "Trigger an app navigation or module launch.",
                  "parameters": {
                    "type": "OBJECT",
                    "properties": {
                      "action": {
                        "type": "STRING",
                        "description": "Action type: 'navigate' or 'launch'",
                      },
                      "target": {
                        "type": "STRING",
                        "description": "Target screen or module name",
                      },
                    },
                    "required": ["action", "target"],
                  },
                },
              ],
            },
          ],
        },
      };

      _channel!.sink.add(jsonEncode(setupMessage));
      _messagesSent += 1;
      _pushDebug('Setup message sent; waiting for setupComplete.');
      return true;
    } catch (e, stack) {
      _setError('Error connecting WebSocket: $e');
      AppLogger.error('GeminiLiveService', 'Connect stacktrace', e, stack);
      disconnect(reason: 'connect_exception');
      return false;
    }
  }

  bool sendJson(Map<String, dynamic> data) {
    if (_channel == null || !isConnected) {
      _pushDebug('sendJson skipped: socket is not connected.');
      return false;
    }

    try {
      _channel!.sink.add(jsonEncode(data));
      _messagesSent += 1;
      final type = data.keys.isNotEmpty ? data.keys.first : 'unknown';
      _pushDebug('JSON payload sent ($type).');
      return true;
    } catch (e, stack) {
      _setError('Error sending JSON payload: $e');
      AppLogger.error('GeminiLiveService', 'sendJson stacktrace', e, stack);
      return false;
    }
  }

  void _onMessage(dynamic message) {
    String jsonString;

    if (message is String) {
      jsonString = message;
    } else if (message is List<int>) {
      jsonString = utf8.decode(message);
    } else {
      _pushDebug('Unknown message type: ${message.runtimeType}');
      return;
    }

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        _pushDebug('Ignoring non-object message from websocket.');
        return;
      }

      final data = decoded;
      _messagesReceived += 1;

      _messageController.add(data);

      if (data.containsKey('error')) {
        _setError('Gemini API error: ${data['error']}');
      }

      if (data.containsKey('setupComplete')) {
        _pushDebug('setupComplete received.');
        return;
      }

      if (data.containsKey('serverContent')) {
        final serverContent = data['serverContent'];

        if (serverContent.containsKey('modelTurn')) {
          final parts = serverContent['modelTurn']['parts'] as List;
          for (final part in parts) {
            if (part.containsKey('inlineData')) {
              final inlineData = part['inlineData'];
              final mimeType = inlineData['mimeType'] as String?;
              if (mimeType != null && mimeType.startsWith('audio/pcm')) {
                final base64Data = inlineData['data'] as String;
                final bytes = base64Decode(base64Data);
                _audioStreamController.add(bytes);
                _audioChunksReceived += 1;
                if (_audioChunksReceived == 1 ||
                    _audioChunksReceived % 25 == 0) {
                  _pushDebug(
                    'Received $_audioChunksReceived audio chunk(s) from Gemini.',
                  );
                }
              }
            }
          }
        }

        if (serverContent['turnComplete'] == true) {
          _pushDebug('turnComplete received.');
        }

        if (serverContent['interrupted'] == true) {
          _pushDebug('interrupted received.');
        }
      }

      if (data.containsKey('toolCall')) {
        _pushDebug('toolCall received.');
      }
    } catch (e, stack) {
      _setError('Error parsing WebSocket message: $e');
      AppLogger.error('GeminiLiveService', 'onMessage stacktrace', e, stack);
    }
  }

  bool sendAudioChunk(Uint8List chunk) {
    if (_channel == null || !isConnected) return false;

    final base64Data = base64Encode(chunk);
    final message = {
      "realtimeInput": {
        "audio": {
          "data": base64Data,
          "mimeType": "audio/pcm;rate=16000",
        },
      },
    };
    try {
      _channel!.sink.add(jsonEncode(message));
      _audioChunksSent += 1;
      if (_audioChunksSent == 1 || _audioChunksSent % 50 == 0) {
        _pushDebug('Sent $_audioChunksSent audio chunk(s) to Gemini.');
      }
      return true;
    } catch (e, stack) {
      _setError('Error sending audio chunk: $e');
      AppLogger.error(
        'GeminiLiveService',
        'sendAudioChunk stacktrace',
        e,
        stack,
      );
      return false;
    }
  }

  bool sendRealtimeText(String text) {
    if (_channel == null || !isConnected) {
      _pushDebug('sendRealtimeText skipped: socket is not connected.');
      return false;
    }

    final message = {
      "realtimeInput": {
        "text": text,
      },
    };

    try {
      _channel!.sink.add(jsonEncode(message));
      _messagesSent += 1;
      _pushDebug('Realtime text sent.');
      return true;
    } catch (e, stack) {
      _setError('Error sending realtime text: $e');
      AppLogger.error(
        'GeminiLiveService',
        'sendRealtimeText stacktrace',
        e,
        stack,
      );
      return false;
    }
  }

  bool sendClientContent(String text) {
    if (_channel == null || !isConnected) {
      _pushDebug('sendClientContent skipped: socket is not connected.');
      return false;
    }

    final message = {
      "clientContent": {
        "turns": [
          {
            "role": "user",
            "parts": [
              {"text": text},
            ],
          },
        ],
        "turnComplete": true,
      },
    };
    try {
      _channel!.sink.add(jsonEncode(message));
      _messagesSent += 1;
      _pushDebug('Client content sent.');
      return true;
    } catch (e, stack) {
      _setError('Error sending client content: $e');
      AppLogger.error(
        'GeminiLiveService',
        'sendClientContent stacktrace',
        e,
        stack,
      );
      return false;
    }
  }

  void disconnect({String reason = 'manual'}) {
    try {
      _channel?.sink.close();
    } catch (e, stack) {
      AppLogger.error('GeminiLiveService', 'Error closing socket', e, stack);
    }
    _channel = null;
    if (_connectionPhase != LiveConnectionPhase.failed) {
      _connectionPhase = LiveConnectionPhase.disconnected;
    }
    _pushDebug('Socket disconnected ($reason).');
  }

  void dispose() {
    disconnect(reason: 'dispose');
    _audioStreamController.close();
    _messageController.close();
    _debugController.close();
  }
}
