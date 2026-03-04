import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

import '../../../core/constants/app_colors.dart';
import '../../../models/voice_session_model.dart';
import '../../../services/voice_assistant_service.dart';
import 'voice_assistant_screen.dart';

/// A floating overlay that displays the voice assistant status
/// globally across all screens and allows quick interactions.
class GlobalVoiceOverlay extends StatefulWidget {
  const GlobalVoiceOverlay({super.key});

  @override
  State<GlobalVoiceOverlay> createState() => _GlobalVoiceOverlayState();
}

class _GlobalVoiceOverlayState extends State<GlobalVoiceOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  
  // Custom drag position
  Offset? _offset;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = context.watch<VoiceAssistantService>();
    final session = voiceService.session;
    
    // Only show if session is active or processing/listening
    if (!voiceService.isActive && session?.status != VoiceStatus.speaking && session?.status != VoiceStatus.listening && session?.status != VoiceStatus.processing) {
      if (session == null || (session.status == VoiceStatus.idle && session.mode == VoiceMode.pushToTalk)) {
        return const SizedBox.shrink();
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = session?.status ?? VoiceStatus.idle;
    
    final color = _getStatusColor(status, isDark);
    final isAnimating = status == VoiceStatus.listening ||
        status == VoiceStatus.processing ||
        status == VoiceStatus.speaking;

    return Positioned(
      left: _offset?.dx ?? MediaQuery.of(context).size.width - 80,
      top: _offset?.dy ?? MediaQuery.of(context).size.height - 180,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
             // Calculate new offset and keep it within bounds
             final maxDx = MediaQuery.of(context).size.width - 60;
             final maxDy = MediaQuery.of(context).size.height - 60;
             
             double dx = (_offset?.dx ?? (MediaQuery.of(context).size.width - 80)) + details.delta.dx;
             double dy = (_offset?.dy ?? (MediaQuery.of(context).size.height - 180)) + details.delta.dy;
             
             dx = math.max(0, math.min(dx, maxDx));
             dy = math.max(kToolbarHeight, math.min(dy, maxDy));
             
             _offset = Offset(dx, dy);
          });
        },
        onTap: () {
          // Open the full voice assistant screen
          Navigator.of(context).pushNamed('/voice-assistant');
        },
        onDoubleTap: () {
           // Quick stop/pause
           if (voiceService.isActive) {
             voiceService.stopSession();
           } else {
             voiceService.startLiveSession();
           }
        },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = isAnimating ? 1.0 + (_pulseController.value * 0.15) : 1.0;
            final opacity = isAnimating ? 0.3 + (_pulseController.value * 0.3) : 0.0;
            
            return Material(
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (status != VoiceStatus.idle)
                    Transform.scale(
                      scale: scale * 1.3,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: opacity * 0.5),
                        ),
                      ),
                    ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: color.withValues(alpha: 0.8),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getStatusIcon(status),
                        size: 30,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ).animate().fadeIn().scale(),
      ),
    );
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
    switch (status) {
      case VoiceStatus.idle:
      case VoiceStatus.paused:
        return isDark ? AppColors.darkTextTertiary : AppColors.textTertiary;
      case VoiceStatus.listening:
        return AppColors.error; 
      case VoiceStatus.processing:
        return AppColors.purple; 
      case VoiceStatus.speaking:
        return AppColors.primary;
      case VoiceStatus.error:
        return AppColors.error;
    }
  }
}
