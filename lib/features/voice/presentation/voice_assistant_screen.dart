import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/voice_session_model.dart';
import '../../../services/ai_service.dart';
import '../../../services/voice_assistant_service.dart';

/// Full-screen voice assistant UI.
/// Designed for hands-free and eyes-free use.
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
    final aiService = context.read<AiService>();
    _voiceService = VoiceAssistantService(aiService);
    
    // We listen to service changes manually to trigger rebuilds
    _voiceService.addListener(_onServiceChange);

    final success = await _voiceService.initialize();
    if (success && mounted) {
      await _voiceService.startSession(mode: VoiceMode.pushToTalk);
    }
  }

  void _onServiceChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onServiceChange);
    _voiceService.stopSession();
    _voiceService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit || _voiceService.session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _voiceService.session!.status;
    final mode = _voiceService.session!.mode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_rounded, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text('CARE-AI Voice', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Error banner
            if (_voiceService.errorMessage != null)
              _buildErrorBanner(isDark),

            const Spacer(flex: 2),

            // Main Audio Visualizer
            _buildAudioVisualizer(status, isDark),

            const SizedBox(height: 48),

            // Status Text
            Text(
              _getStatusText(status),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status, isDark),
                  ),
              textAlign: TextAlign.center,
            ).animate(key: ValueKey(status)).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Last message display (User or AI)
            SizedBox(
              height: 120,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Text(
                    _getDisplayText(status),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          height: 1.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ).animate(key: ValueKey(_getDisplayText(status))).fadeIn(),
                ),
              ),
            ),

            const Spacer(flex: 3),

            // Controls
            _buildControls(status, mode, isDark),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.error.withValues(alpha: 0.2) : AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _voiceService.errorMessage!,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => _voiceService.clearError(),
            color: AppColors.error,
          )
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildAudioVisualizer(VoiceStatus status, bool isDark) {
    final color = _getStatusColor(status, isDark);
    final isAnimating = status == VoiceStatus.listening ||
        status == VoiceStatus.processing ||
        status == VoiceStatus.speaking;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isAnimating ? 1.0 + (_pulseController.value * 0.2) : 1.0;
        final opacity =
            isAnimating ? 0.3 + (_pulseController.value * 0.3) : 0.1;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse
            Transform.scale(
              scale: scale * 1.5,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: opacity * 0.5),
                ),
              ),
            ),
            // Inner pulse
            Transform.scale(
              scale: scale * 1.2,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: opacity),
                ),
              ),
            ),
            // Center hero element
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  _getStatusIcon(status),
                  size: 64,
                  color: color,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(VoiceStatus status, VoiceMode mode, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mode Toggle Button
          _buildControlButton(
            icon: mode == VoiceMode.pushToTalk
                ? Icons.touch_app_rounded
                : Icons.all_inclusive_rounded,
            label: mode == VoiceMode.pushToTalk ? 'Push to Talk' : 'Continuous',
            onTap: () {
              HapticFeedback.lightImpact();
              _voiceService.toggleMode();
            },
            isDark: isDark,
          ),

          // Main Action Button (Mic)
          GestureDetector(
            onTapDown: mode == VoiceMode.pushToTalk
                ? (_) => _voiceService.startListening()
                : null,
            onTapUp: mode == VoiceMode.pushToTalk
                ? (_) => _voiceService.stopListening()
                : null,
            onTapCancel: mode == VoiceMode.pushToTalk
                ? () => _voiceService.stopListening()
                : null,
            onTap: mode == VoiceMode.continuous
                ? () {
                    if (status == VoiceStatus.listening) {
                      _voiceService.pauseSession();
                    } else if (status == VoiceStatus.speaking) {
                      _voiceService.interruptAI();
                    } else {
                      _voiceService.startListening();
                    }
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: mode == VoiceMode.pushToTalk &&
                        status == VoiceStatus.listening
                    ? AppColors.error
                    : AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (mode == VoiceMode.pushToTalk &&
                                status == VoiceStatus.listening
                            ? AppColors.error
                            : AppColors.primary)
                        .withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                mode == VoiceMode.continuous && status == VoiceStatus.listening
                    ? Icons.stop_rounded
                    : Icons.mic_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),

          // End/Pause Button
          _buildControlButton(
            icon: status == VoiceStatus.paused
                ? Icons.play_arrow_rounded
                : Icons.close_rounded,
            label: status == VoiceStatus.paused ? 'Resume' : 'End',
            onTap: () {
              HapticFeedback.lightImpact();
              if (status == VoiceStatus.paused) {
                _voiceService.resumeSession();
              } else {
                Navigator.of(context).pop();
              }
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(VoiceStatus status) {
    if (_voiceService.errorMessage != null) return 'Error';
    switch (status) {
      case VoiceStatus.idle:
        return 'Tap mic to speak';
      case VoiceStatus.listening:
        return 'Listening...';
      case VoiceStatus.processing:
        return 'Thinking...';
      case VoiceStatus.speaking:
        return 'CARE-AI';
      case VoiceStatus.paused:
        return 'Paused';
      case VoiceStatus.error:
        return 'Error';
    }
  }

  IconData _getStatusIcon(VoiceStatus status) {
    switch (status) {
      case VoiceStatus.idle:
        return Icons.mic_none_rounded;
      case VoiceStatus.listening:
        return Icons.mic_rounded;
      case VoiceStatus.processing:
        return Icons.graphic_eq_rounded;
      case VoiceStatus.speaking:
        return Icons.volume_up_rounded;
      case VoiceStatus.paused:
        return Icons.pause_rounded;
      case VoiceStatus.error:
        return Icons.error_outline_rounded;
    }
  }

  Color _getStatusColor(VoiceStatus status, bool isDark) {
    if (_voiceService.errorMessage != null) return AppColors.error;
    switch (status) {
      case VoiceStatus.idle:
      case VoiceStatus.paused:
        return isDark ? AppColors.darkTextTertiary : AppColors.textTertiary;
      case VoiceStatus.listening:
        return AppColors.error; // Red for active rec
      case VoiceStatus.processing:
        return AppColors.purple; // Processing color
      case VoiceStatus.speaking:
        return AppColors.primary; // Active speaker color
      case VoiceStatus.error:
        return AppColors.error;
    }
  }

  String _getDisplayText(VoiceStatus status) {
    if (_voiceService.errorMessage != null) return '';
    switch (status) {
      case VoiceStatus.idle:
      case VoiceStatus.paused:
        return 'I am ready when you are.';
      case VoiceStatus.listening:
        return _voiceService.lastUserText.isEmpty
            ? '...'
            : _voiceService.lastUserText;
      case VoiceStatus.processing:
        return _voiceService.lastUserText;
      case VoiceStatus.speaking:
        return _voiceService.lastAiText;
      case VoiceStatus.error:
        return '';
    }
  }
}
