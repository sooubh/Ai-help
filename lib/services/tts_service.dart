import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech service for reading AI responses aloud.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  /// Initialize TTS engine with default settings.
  Future<void> init() async {
    if (_isInitialized) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45); // Slightly slower for clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _isInitialized = true;
  }

  /// Speak the given [text] aloud.
  Future<void> speak(String text) async {
    await init();
    await _tts.speak(text);
  }

  /// Stop any ongoing speech.
  Future<void> stop() async {
    await _tts.stop();
  }

  /// Dispose the TTS engine.
  Future<void> dispose() async {
    await _tts.stop();
  }
}
