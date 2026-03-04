import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/config/env_config.dart';

/// Service for managing the bidirectional WebSocket connection 
/// to the Gemini Live API with Native Audio support.
class GeminiLiveService {
  WebSocketChannel? _channel;
  
  final _audioStreamController = StreamController<Uint8List>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Uint8List> get audioStream => _audioStreamController.stream;
  Stream<Map<String, dynamic>> get messagesStream => _messageController.stream;

  bool get isConnected => _channel != null;

  /// Connects to the Gemini Live API and sends the initial setup message.
  Future<void> connect(String systemInstruction) async {
    if (_channel != null) return;
    
    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      debugPrint('Gemini API key is missing');
      return;
    }

    final wsUrl = Uri.parse(
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey');

    try {
      _channel = WebSocketChannel.connect(wsUrl);

      // Listen to incoming messages before sending setup
      _channel!.stream.listen(
        _onMessage,
        onError: (e) {
          debugPrint('WebSocket error: $e');
          disconnect();
        },
        onDone: () {
          debugPrint('WebSocket closed');
          disconnect();
        },
      );

      // Send setup message
      final setupMessage = {
        "setup": {
          "model": "models/gemini-2.5-flash-native-audio-preview-12-2025",
          "generation_config": {
            "response_modalities": ["AUDIO"]
          },
          "system_instruction": {
            "parts": [
              {"text": systemInstruction}
            ]
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
                        "description": "Action type: 'navigate' or 'launch'"
                      },
                      "target": {
                        "type": "STRING",
                        "description": "Target screen or module name"
                      }
                    },
                    "required": ["action", "target"]
                  }
                }
              ]
            }
          ]
        }
      };
      
      _channel!.sink.add(jsonEncode(setupMessage));
    } catch (e) {
      debugPrint('Error connecting WebSocket: $e');
      disconnect();
    }
  }

  /// Send generic JSON data (e.g. function responses)
  void sendJson(Map<String, dynamic> data) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('Error sending JSON: $e');
    }
  }

  void _onMessage(dynamic message) {
    if (message is! String) return;
    
    try {
      final data = jsonDecode(message);
      
      // Notify generic message stream
      _messageController.add(data);

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
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  /// Sends a chunk of 16-bit PCM 16kHz audio data to the exact API
  void sendAudioChunk(Uint8List chunk) {
    if (_channel == null) return;

    final base64Data = base64Encode(chunk);
    final message = {
      "realtime_input": {
        "media_chunks": [
          {
            "mime_type": "audio/pcm;rate=16000",
            "data": base64Data
          }
        ]
      }
    };
    
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('Error sending audio: $e');
    }
  }
  
  void sendClientContent(String text) {
    if (_channel == null) return;
    final message = {
      "clientContent": {
        "turns": [
          {
            "role": "user",
            "parts": [{"text": text}]
          }
        ],
        "turnComplete": true
      }
    };
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('Error sending client content: $e');
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
