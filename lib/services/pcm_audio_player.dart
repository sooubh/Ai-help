import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import '../core/utils/app_logger.dart';

class PcmAudioPlayer {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isInitialized = false;
  bool _isPlaying = false;

  // Queue to process chunks sequentially — prevents buffer corruption
  final List<Uint8List> _feedQueue = [];
  bool _isFeeding = false;

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

  // FIX: Queue chunks and feed one at a time — never overlap feed calls
  void addChunk(Uint8List chunk) {
    if (!_isPlaying) return;
    _feedQueue.add(chunk);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isFeeding || _feedQueue.isEmpty) return;
    _isFeeding = true;

    while (_feedQueue.isNotEmpty && _isPlaying) {
      final chunk = _feedQueue.removeAt(0);
      try {
        // CRITICAL: await each feed call before the next one
        await _player.feedUint8FromStream(chunk);
      } catch (e) {
        // Silently ignore — race condition on stop
        break;
      }
    }

    _isFeeding = false;
  }

  Future<void> stop() async {
    if (!_isPlaying) return;
    // Set false BEFORE stopPlayer so queue stops immediately
    _isPlaying = false;
    _feedQueue.clear();
    _isFeeding = false;
    try {
      await _player.stopPlayer();
    } catch (_) {}
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
