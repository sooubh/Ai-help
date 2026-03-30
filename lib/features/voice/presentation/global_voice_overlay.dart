import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

import '../../../core/constants/app_colors.dart';
import '../../../models/voice_session_model.dart';
import '../../../services/voice_assistant_service.dart';

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
    // We use context.watch to rebuild when the voice service state changes.
    final voiceService = context.watch<VoiceAssistantService>();
    final session = voiceService.session;

    // Only show if session is active
    if (!voiceService.isActive) {
      return const SizedBox.shrink();
    }

    // Hide if the user is currently looking at the full voice screen
    // We check current route using ModalRoute natively inside build,
    // however for a global Overlay (above MaterialApp), ModalRoute isn't
    // accessible cleanly. We trust the pill can be used globally.
    // If the pill overlays the screen, taping it navigates back.

    final status = session?.status ?? VoiceStatus.idle;
    final isListening = status == VoiceStatus.listening;
    final isProcessing = status == VoiceStatus.processing;
    final isSpeaking = status == VoiceStatus.speaking;

    Color badgeColor;
    String statusText;

    if (isListening) {
      badgeColor = Colors.greenAccent;
      statusText = "Listening...";
    } else if (isProcessing) {
      badgeColor = Colors.blueAccent;
      statusText = "Thinking...";
    } else if (isSpeaking) {
      badgeColor = AppColors.primary;
      statusText = "AI Speaking";
    } else {
      badgeColor = Colors.grey;
      statusText = "Connecting...";
    }

    return Positioned(
      // Default position is bottom right
      left:
          _offset?.dx ??
          (MediaQuery.of(context).size.width -
              220), // Width approx 200px + margin
      top:
          _offset?.dy ??
          (MediaQuery.of(context).size.height -
              100), // Height approx 56px + margin
      child: SafeArea(
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              final maxDx = MediaQuery.of(context).size.width - 200;
              final maxDy = MediaQuery.of(context).size.height - 80;

              double dx =
                  (_offset?.dx ?? (MediaQuery.of(context).size.width - 220)) +
                  details.delta.dx;
              double dy =
                  (_offset?.dy ?? (MediaQuery.of(context).size.height - 100)) +
                  details.delta.dy;

              dx = math.max(0, math.min(dx, maxDx));
              dy = math.max(kToolbarHeight, math.min(dy, maxDy));

              _offset = Offset(dx, dy);
            });
          },
          onTap: () {
            // Navigate back to the full voice screen
            // If already there, this will just push another instance which is fine,
            // or we could use pushNamedAndRemoveUntil.
            HapticFeedback.lightImpact();
            Navigator.of(context).pushNamed('/voice-assistant');
          },
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final isAnimating = isListening || isSpeaking || isProcessing;
              double boxShadowSpread =
                  isAnimating ? (_pulseController.value * 5) : 1;

              return Material(
                color: Colors.transparent,
                child: Container(
                  width: 200,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: boxShadowSpread,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      // Animated Indicator Dot
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badgeColor,
                          boxShadow: [
                            BoxShadow(
                              color: badgeColor.withValues(alpha: 0.8),
                              blurRadius: isAnimating ? 8 : 0,
                              spreadRadius: isAnimating ? 2 : 0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status Text
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            statusText,
                            key: ValueKey(statusText),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // End Call Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          voiceService.stopSession();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withValues(alpha: 0.2),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.redAccent,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ).animate().fadeIn().slideY(begin: 0.5),
        ),
      ),
    );
  }
}
