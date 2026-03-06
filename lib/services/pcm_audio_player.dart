import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import '../core/utils/app_logger.dart';

class PcmAudioPlayer {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isInitialized = false;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _player.openPlayer();
      _isInitialized = true;
    }
  }

  Future<void> start({int sampleRate = 24000}) async {
    try {
      await _ensureInitialized();
      if (_isPlaying) await stop();

      await _player.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: sampleRate,
        bufferSize: 8192,
        interleaved: true, 
      );
      _isPlaying = true;
      AppLogger.info('PcmAudioPlayer', 'Player started at ${sampleRate}Hz');
    } catch (e, stack) {
      AppLogger.error('PcmAudioPlayer', 'Failed to start player', e, stack);
      _isPlaying = false;
    }
  }

  void addChunk(Uint8List chunk) {
    if (!_isPlaying) return;
    try {
      _player.feedFromStream(chunk);
    } catch (e, stack) {
      AppLogger.error('PcmAudioPlayer', 'Error feeding audio chunk', e, stack);
    }
  }

  Future<void> stop() async {
    if (!_isPlaying) return;
    try {
      await _player.stopPlayer();
    } catch (_) {}
    _isPlaying = false;
    AppLogger.info('PcmAudioPlayer', 'Player stopped');
  }

  Future<void> dispose() async {
    await stop();
    if (_isInitialized) {
      await _player.closePlayer();
      _isInitialized = false;
    }
  }
}