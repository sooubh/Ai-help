import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/voice_session_model.dart';
import '../../../services/voice_assistant_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  late VoiceAssistantService _voiceService;
  late AnimationController _pulseController;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _initService();
      _isInit = true;
    }
  }

  Future<void> _initService() async {
    _voiceService = context.read<VoiceAssistantService>();
    _voiceService.addListener(_onServiceChange);

    // FIX: Delay until after first frame to avoid
    // "setState() called during build" crash
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_voiceService.isActive && mounted) {
        await _voiceService.startLiveSession();
      }
    });
  }

  void _onServiceChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onServiceChange);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _voiceService.session?.status ?? VoiceStatus.idle;
    final isConnected = _voiceService.isConnected;
    final amplitudes = _voiceService.waveformAmplitudes;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white, size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Row(
                    children: [
                      Icon(
                        isConnected ? Icons.circle : Icons.error_outline,
                        color: isConnected ? Colors.greenAccent : Colors.redAccent,
                        size: 12,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isConnected ? 'Connected' : 'Connecting...',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Error banner
            if (_voiceService.errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                color: Colors.redAccent.withValues(alpha: 0.2),
                child: Text(
                  _voiceService.errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),

            const Spacer(),

            // Center Orb / Waveform
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (status == VoiceStatus.speaking) _buildSpeakingOrb(),
                  if (status == VoiceStatus.listening ||
                      status == VoiceStatus.processing)
                    _buildListeningWaveform(amplitudes),
                  if (status == VoiceStatus.idle || !isConnected) _buildIdleOrb(),
                ],
              ),
            ),

            const SizedBox(height: 64),

            // Status Text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _getStatusText(status, isConnected),
                key: ValueKey<String>(_getStatusText(status, isConnected)),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            const Spacer(),

            // End Call Button
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_buildEndCallButton()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(VoiceStatus status, bool isConnected) {
    if (!isConnected) return 'Connecting to AI...';
    switch (status) {
      case VoiceStatus.listening: return 'Listening...';
      case VoiceStatus.processing: return 'Thinking...';
      case VoiceStatus.speaking: return 'CARE-AI Speaking';
      default: return 'Ready';
    }
  }

  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: () {
        _voiceService.stopSession();
        Navigator.of(context).pop();
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _buildSpeakingOrb() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.3);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.8),
                  AppColors.primary.withValues(alpha: 0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 10),
              ],
            ),
            child: const Icon(Icons.volume_up_rounded, size: 60, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildListeningWaveform(List<double> amplitudes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(5, (index) {
        double amp = 0.1;
        if (amplitudes.isNotEmpty) {
          final historyIndex =
              amplitudes.length > index ? amplitudes.length - 1 - index : 0;
          amp = amplitudes[historyIndex];
        }
        amp = amp.clamp(0.1, 1.0);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 16,
          height: 30 + (amp * 100),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildIdleOrb() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withValues(alpha: 0.2),
      ),
      child: const Icon(Icons.mic_none_rounded, size: 60, color: Colors.white54),
    );
  }
}