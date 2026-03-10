import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/config/env_config.dart';
import '../core/utils/app_logger.dart';

class GeminiLiveService {
  WebSocketChannel? _channel;

  final _audioStreamController = StreamController<Uint8List>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Uint8List> get audioStream => _audioStreamController.stream;
  Stream<Map<String, dynamic>> get messagesStream => _messageController.stream;

  bool get isConnected => _channel != null;

  Future<void> connect(String systemInstruction) async {
    if (_channel != null) return;

    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      AppLogger.error('GeminiLiveService', 'Gemini API key is missing');
      return;
    }

    final wsUrl = Uri.parse(
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$apiKey',
    );

    try {
      AppLogger.info('GeminiLiveService', 'Connecting to WebSocket...');
      _channel = WebSocketChannel.connect(wsUrl);

      await _channel!.ready;
      AppLogger.info(
        'GeminiLiveService',
        'WebSocket handshake complete — sending setup',
      );

      _channel!.stream.listen(
        _onMessage,
        onError: (e, stack) {
          AppLogger.error('GeminiLiveService', 'WebSocket error: $e', e, stack);
          disconnect();
        },
        onDone: () {
          AppLogger.info(
            'GeminiLiveService',
            'WebSocket closed. Code: ${_channel?.closeCode} Reason: ${_channel?.closeReason}',
          );
          disconnect();
        },
      );

      final setupMessage = {
        "setup": {
          "model": "models/gemini-2.5-flash-native-audio-preview-12-2025",
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
      AppLogger.info(
        'GeminiLiveService',
        'Setup message sent — waiting for setupComplete',
      );
    } catch (e, stack) {
      AppLogger.error(
        'GeminiLiveService',
        'Error connecting WebSocket',
        e,
        stack,
      );
      disconnect();
    }
  }

  void sendJson(Map<String, dynamic> data) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (e, stack) {
      AppLogger.error('GeminiLiveService', 'Error sending JSON', e, stack);
    }
  }

  void _onMessage(dynamic message) {
    String jsonString;

    if (message is String) {
      jsonString = message;
    } else if (message is List<int>) {
      jsonString = utf8.decode(message);
    } else {
      AppLogger.info(
        'GeminiLiveService',
        'Unknown message type: ${message.runtimeType}',
      );
      return;
    }

    try {
      final data = jsonDecode(jsonString);

      _messageController.add(data);

      if (data.containsKey('setupComplete')) {
        AppLogger.info(
          'GeminiLiveService',
          'setupComplete received — mic will start now',
        );
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
              }
            }
          }
        }

        if (serverContent['turnComplete'] == true) {
          AppLogger.info('GeminiLiveService', 'turnComplete received');
        }

        if (serverContent['interrupted'] == true) {
          AppLogger.info('GeminiLiveService', 'interrupted received');
        }
      }

      if (data.containsKey('toolCall')) {
        AppLogger.info(
          'GeminiLiveService',
          'toolCall received: ${data['toolCall']}',
        );
      }
    } catch (e, stack) {
      AppLogger.error(
        'GeminiLiveService',
        'Error parsing WebSocket message',
        e,
        stack,
      );
    }
  }

  void sendAudioChunk(Uint8List chunk) {
    if (_channel == null) return;
    final base64Data = base64Encode(chunk);
    final message = {
      "realtime_input": {
        "media_chunks": [
          {"mime_type": "audio/pcm;rate=16000", "data": base64Data},
        ],
      },
    };
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e, stack) {
      AppLogger.error(
        'GeminiLiveService',
        'Error sending audio chunk',
        e,
        stack,
      );
    }
  }

  void sendClientContent(String text) {
    if (_channel == null) return;
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
    } catch (e, stack) {
      AppLogger.error(
        'GeminiLiveService',
        'Error sending client content',
        e,
        stack,
      );
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _audioStreamController.close();
    _messageController.close();
  }
}
