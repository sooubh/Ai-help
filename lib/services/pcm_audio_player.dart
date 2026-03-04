import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../core/utils/app_logger.dart';
import '../core/errors/app_exceptions.dart';

/// Plays a continuous stream of raw 16-bit PCM audio chunks.
/// Specifically designed to play the 24kHz PCM output from the Gemini Live API.
class PcmAudioPlayer {
  final AudioPlayer _player = AudioPlayer();
  StreamController<Uint8List>? _streamController;
  
  bool get isPlaying => _player.playing;

  Future<void> init() async {
    // Initial setup if needed
  }

  /// Start playing a given stream of raw PCM data.
  /// [sampleRate] is 24000 for Gemini Live API output.
  Future<void> playStream(Stream<Uint8List> pcmStream, {int sampleRate = 24000}) async {
    await stop();

    _streamController = StreamController<Uint8List>();
    
    // Forward the external stream to our internal controller
    pcmStream.listen(
      (data) {
        if (!(_streamController?.isClosed ?? true)) {
          _streamController?.add(data);
        }
      },
      onDone: () => _streamController?.close(),
      onError: (e, stack) {
        AppLogger.error('PcmAudioPlayer', 'Error in PCM stream', e, stack);
        if (!(_streamController?.isClosed ?? true)) {
          _streamController?.addError(e);
        }
      },
    );

    final source = _PcmStreamAudioSource(_streamController!.stream, sampleRate);

    try {
      await _player.setAudioSource(source);
      await _player.play();
    } catch (e, stack) {
      AppLogger.error('PcmAudioPlayer', 'Failed to play PCM stream', e, stack);
      throw AudioException('Failed to play audio stream', originalError: e);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    if (_streamController != null && !_streamController!.isClosed) {
      await _streamController!.close();
    }
    _streamController = null;
  }

  void dispose() {
    stop();
    _player.dispose();
  }
}

/// Custom audio source that wraps a raw PCM stream into a WAV stream
/// by prepending a 44-byte WAV header with unknown length.
class _PcmStreamAudioSource extends StreamAudioSource {
  final Stream<Uint8List> _stream;
  final int _sampleRate;
  
  _PcmStreamAudioSource(this._stream, this._sampleRate);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final header = _buildWavHeader(_sampleRate, 1, 16);
    
    final controller = StreamController<List<int>>();
    controller.add(header);
    
    _stream.listen(
      (data) => controller.add(data),
      onError: (e) => controller.addError(e),
      onDone: () => controller.close(),
    );

    return StreamAudioResponse(
      sourceLength: null,
      contentLength: null,
      offset: start ?? 0,
      stream: controller.stream,
      contentType: 'audio/wav',
    );
  }

  Uint8List _buildWavHeader(int sampleRate, int channels, int bitDepth) {
    final byteRate = (sampleRate * channels * bitDepth) ~/ 8;
    final blockAlign = (channels * bitDepth) ~/ 8;
    
    final header = ByteData(44);
    
    // RIFF
    header.setUint8(0, 0x52); 
    header.setUint8(1, 0x49); 
    header.setUint8(2, 0x46); 
    header.setUint8(3, 0x46); 
    header.setUint32(4, 0xFFFFFFFF, Endian.little); 
    
    // WAVE
    header.setUint8(8, 0x57); 
    header.setUint8(9, 0x41); 
    header.setUint8(10, 0x56); 
    header.setUint8(11, 0x45); 
    
    // fmt 
    header.setUint8(12, 0x66); 
    header.setUint8(13, 0x6D); 
    header.setUint8(14, 0x74); 
    header.setUint8(15, 0x20); 
    header.setUint32(16, 16, Endian.little); 
    header.setUint16(20, 1, Endian.little); 
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitDepth, Endian.little);
    
    // data
    header.setUint8(36, 0x64); 
    header.setUint8(37, 0x61); 
    header.setUint8(38, 0x74); 
    header.setUint8(39, 0x61); 
    header.setUint32(40, 0xFFFFFFFF, Endian.little); 
    
    return header.buffer.asUint8List();
  }
}
