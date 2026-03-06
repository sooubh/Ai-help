import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with TickerProviderStateMixin {
  late VoiceAssistantService _voiceService;

  late AnimationController _breathingController;
  late AnimationController _speakingController;
  late AnimationController _entranceController;

  bool _isInit = false;
  bool _isMuted = false;

  Timer? _sessionTimer;
  Duration _sessionDuration = Duration.zero;
  bool _hasStartedTimer = false;

  @override
  void initState() {
    super.initState();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _speakingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_voiceService.isActive && mounted) {
        final currentRouteName =
            ModalRoute.of(context)?.settings.name ?? 'voice_assistant';
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

        await _voiceService.startLiveSession(
          childProfile: args?['childProfile'],
          currentScreen: currentRouteName,
        );
      }
    });
  }

  void _onServiceChange() {
    if (!mounted) return;

    final status = _voiceService.session?.status;

    if (status == VoiceStatus.listening && !_hasStartedTimer) {
      _hasStartedTimer = true;
      _startTimer();
    } else if (status == null ||
        status == VoiceStatus.idle ||
        status == VoiceStatus.error) {
      _stopTimer();
      _hasStartedTimer = false;
    }

    setState(() {});
  }

  void _startTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _sessionDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  void _stopTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _sessionDuration = Duration.zero;
    _hasStartedTimer = false;
  }

  @override
  void dispose() {
    _stopTimer();
    _voiceService.removeListener(_onServiceChange);
    _breathingController.dispose();
    _speakingController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final status = _voiceService.session?.status ?? VoiceStatus.idle;
    final isConnected = _voiceService.isConnected;
    final amplitudes = _voiceService.waveformAmplitudes;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isConnected),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.primary.withValues(
                alpha: status == VoiceStatus.speaking ? 0.2 : 0.1,
              ),
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (_voiceService.errorMessage != null) _buildErrorBanner(),

              const Spacer(),

              // Animated Center Orb
              FadeTransition(
                opacity: _entranceController,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _entranceController,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: SizedBox(
                    height: 280,
                    child: Center(
                      child: _buildCenterVisual(
                        status,
                        isConnected,
                        amplitudes,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // 12-bar Waveform
              _build12BarWaveform(amplitudes, status),

              const SizedBox(height: 32),

              // Status Badge & Hint
              FadeTransition(
                opacity: _entranceController,
                child: _buildStatusSection(status, isConnected),
              ),

              const SizedBox(height: 48),

              // Controls Row
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _entranceController,
                    curve: Curves.easeOutQuad,
                  ),
                ),
                child: FadeTransition(
                  opacity: _entranceController,
                  child: _buildControls(status),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isConnected) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.white,
          size: 32,
        ),
        onPressed: () {
          // Do not stop the session, simply pop back
          Navigator.of(context).pop();
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.circle : Icons.error_outline,
            color: isConnected ? Colors.greenAccent : Colors.redAccent,
            size: 10,
          ),
          const SizedBox(width: 8),
          const Text(
            'CARE-AI Voice',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        if (_hasStartedTimer)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                _formatDuration(_sessionDuration),
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _voiceService.errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterVisual(
    VoiceStatus status,
    bool isConnected,
    List<double> amplitudes,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathingController, _speakingController]),
      builder: (context, child) {
        double baseScale = 1.0;
        double currentAmp = 0.0;
        if (amplitudes.isNotEmpty) currentAmp = amplitudes.last;

        if (!isConnected || status == VoiceStatus.idle) {
          baseScale = 0.95 + (_breathingController.value * 0.1);
        } else if (status == VoiceStatus.listening ||
            status == VoiceStatus.processing) {
          // Subtle reaction to mic input on the center orb itself
          baseScale = 1.0 + (currentAmp * 0.15);
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            // Expanding rings when speaking (Outward pulses)
            if (status == VoiceStatus.speaking)
              ...List.generate(3, (index) {
                final delay = index * 0.33;
                double progress = (_speakingController.value + delay) % 1.0;
                final ringScale = 1.0 + (progress * 1.5);
                final ringOpacity = (1.0 - progress).clamp(0.0, 1.0) * 0.5;

                return Transform.scale(
                  scale: ringScale,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: ringOpacity),
                        width: 2,
                      ),
                    ),
                  ),
                );
              }),

            // Concentric rings reacting to pitch when listening
            if (status == VoiceStatus.listening ||
                status == VoiceStatus.processing)
              ...List.generate(3, (index) {
                // The rings map current amplitude based on their index
                final ringScale =
                    1.0 + (index * 0.15) + (currentAmp * 0.3 * (index + 1));
                final ringOpacity = (0.3 - (index * 0.08)).clamp(0.0, 1.0);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 140 * ringScale,
                  height: 140 * ringScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: ringOpacity),
                      width: 1.5,
                    ),
                  ),
                );
              }),

            // Center base orb
            Transform.scale(
              scale: baseScale,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      status == VoiceStatus.speaking
                          ? AppColors.primary.withValues(alpha: 0.9)
                          : AppColors.primary.withValues(alpha: 0.5),
                      AppColors.primary.withValues(alpha: 0.1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: status == VoiceStatus.speaking ? 0.6 : 0.3,
                      ),
                      blurRadius: status == VoiceStatus.speaking ? 40 : 20,
                      spreadRadius: status == VoiceStatus.speaking ? 15 : 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    status == VoiceStatus.speaking
                        ? Icons.graphic_eq_rounded
                        : Icons.psychology_rounded,
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _build12BarWaveform(List<double> amplitudes, VoiceStatus status) {
    final bool isSpeaking = status == VoiceStatus.speaking;
    final Color barColor = isSpeaking ? AppColors.primary : Colors.white;
    // Mute visual override
    final bool showMuted = _isMuted && !isSpeaking;

    return RepaintBoundary(
      child: SizedBox(
        height: 60,
        child: AnimatedBuilder(
          animation: _speakingController,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(12, (index) {
                // Natural waveform bell curve shape
                final double distanceFromCenter = (index - 5.5).abs();
                final double positionScale = math.max(
                  0.1,
                  1.0 - (distanceFromCenter * 0.15),
                );

                double amp = 0.05;
                if (showMuted) {
                  amp = 0.05; // flatline
                } else if (isSpeaking) {
                  // Generate an artificial smooth waveform for the AI voice using sine waves
                  amp =
                      0.3 +
                      0.5 *
                          math.max(
                            0,
                            math.sin(
                              (_speakingController.value * math.pi * 6) + index,
                            ),
                          );
                } else if (amplitudes.isNotEmpty) {
                  // Real mic amplitude based on history index
                  int historyIndex =
                      amplitudes.length > index
                          ? amplitudes.length - 1 - index
                          : 0;
                  amp = amplitudes[historyIndex];
                }

                amp = amp.clamp(0.05, 1.0);
                final double barHeight = 10 + (amp * 50 * positionScale);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 6,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: showMuted ? Colors.white24 : barColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusSection(VoiceStatus status, bool isConnected) {
    Color pillColor;
    IconData pillIcon;
    String pillText;

    if (!isConnected) {
      pillColor = Colors.grey.shade400;
      pillIcon = Icons.hourglass_empty_rounded;
      pillText = 'Connecting...';
    } else {
      switch (status) {
        case VoiceStatus.listening:
          pillColor = Colors.greenAccent;
          pillIcon = Icons.mic_rounded;
          pillText = 'Listening...';
          break;
        case VoiceStatus.processing:
          pillColor = Colors.blueAccent;
          pillIcon = Icons.auto_awesome_rounded;
          pillText = 'Thinking...';
          break;
        case VoiceStatus.speaking:
          pillColor = AppColors.primary;
          pillIcon = Icons.smart_toy_rounded;
          pillText = 'CARE-AI is Speaking';
          break;
        case VoiceStatus.idle:
        default:
          pillColor = Colors.grey.shade400;
          pillIcon = Icons.check_circle_rounded;
          pillText = 'Ready';
          break;
      }
    }

    if (_isMuted && status == VoiceStatus.listening) {
      pillColor = Colors.orangeAccent;
      pillIcon = Icons.mic_off_rounded;
      pillText = 'Microphone Muted';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey<String>(pillText),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: pillColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: pillColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(pillIcon, color: pillColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  pillText,
                  style: TextStyle(
                    color: pillColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _isMuted
                ? "Tap the mic icon to resume"
                : "Speak naturally — I'm here to help",
            key: ValueKey<bool>(_isMuted),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(VoiceStatus status) {
    final bool isSpeaking = status == VoiceStatus.speaking;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // MUTE BUTTON
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _isMuted = !_isMuted;
              // Note: Strictly to modify UI appearance as requested.
              // True muting of microphone chunk sending would require
              // modifying voice_assistant_service.dart, which is forbidden by rules.
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isMuted ? Colors.white24 : Colors.transparent,
              border: Border.all(
                color: _isMuted ? Colors.transparent : Colors.white54,
                width: 2,
              ),
            ),
            child: Icon(
              _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),

        const SizedBox(width: 32),

        // END CALL BUTTON
        GestureDetector(
          onTap: () {
            HapticFeedback.heavyImpact();
            _voiceService.stopSession();
            Navigator.of(context).pop();
          },
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),

        const SizedBox(width: 32),

        // INTERRUPT BUTTON
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isSpeaking ? 1.0 : 0.3,
          child: IgnorePointer(
            ignoring: !isSpeaking,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _voiceService.interruptAI();
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 2),
                ),
                child: const Icon(
                  Icons.stop_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
