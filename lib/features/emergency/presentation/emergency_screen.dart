import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Emergency Meltdown Mode — quick-access crisis support.
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  int _currentStep = 0;
  bool _breathingActive = false;
  bool _breathingIn = true;
  Timer? _breathingTimer;
  int _breathingCycles = 0;

  static const _steps = [
    _CalmingStep(
      '🫂',
      'You Are Not Alone',
      'Take a moment. This is temporary. You and your child will get through this.',
      Color(0xFF5B6EF5),
    ),
    _CalmingStep(
      '🔇',
      'Reduce Stimulation',
      'Turn off loud sounds. Dim lights if possible. Move to a quieter space.',
      Color(0xFF8B5CF6),
    ),
    _CalmingStep(
      '🧘',
      'Breathe Together',
      'Use the breathing exercise below. Breathe slowly and calmly near your child.',
      Color(0xFF2DD4A8),
    ),
    _CalmingStep(
      '🗣️',
      'Speak Softly',
      'Use a calm, low voice. Say: "I\'m here. You\'re safe. It\'s okay."',
      Color(0xFFF59E0B),
    ),
    _CalmingStep(
      '⏰',
      'Wait Patiently',
      'Stay nearby. Don\'t force eye contact or touch. Let them process.',
      Color(0xFFEC4899),
    ),
    _CalmingStep(
      '💛',
      'After It Passes',
      'Offer comfort. A gentle hug, favorite blanket, or familiar object.',
      Color(0xFF10B981),
    ),
  ];

  @override
  void dispose() {
    _breathingTimer?.cancel();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _breathingActive = true;
      _breathingIn = true;
      _breathingCycles = 0;
    });
    _breathingTimer?.cancel();
    _breathingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _breathingIn = !_breathingIn;
        if (_breathingIn) _breathingCycles++;
      });
      if (_breathingCycles >= 5) {
        _breathingTimer?.cancel();
        if (mounted) setState(() => _breathingActive = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    return Scaffold(
      backgroundColor: step.color,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentStep + 1} / ${_steps.length}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(step.emoji, style: const TextStyle(fontSize: 72))
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          duration: 400.ms,
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 24),
                    Text(
                      step.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: 16),
                    Text(
                      step.instruction,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 18,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                    if (_currentStep == 2) ...[
                      const SizedBox(height: 32),
                      _buildBreathingExercise(),
                    ],
                  ],
                ),
              ),
            ),
            // Navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep < _steps.length - 1) {
                          setState(() => _currentStep++);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: step.color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentStep < _steps.length - 1
                            ? 'Next Step'
                            : 'I\'m Okay Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Helpline
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton.icon(
                onPressed: () => _showHelplines(context),
                icon: Icon(
                  Icons.phone_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
                label: Text(
                  'Need more help? View helpline numbers',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelplines(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Need More Help?'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔹 NIMHANS: 080-46110007'),
                SizedBox(height: 4),
                Text('🔹 Vandrevala Foundation: 1860-2662-345'),
                SizedBox(height: 4),
                Text('🔹 iCall: 9152987821'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildBreathingExercise() {
    return GestureDetector(
      onTap: _breathingActive ? null : _startBreathing,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 4),
            curve: Curves.easeInOut,
            width: _breathingActive ? (_breathingIn ? 140 : 80) : 100,
            height: _breathingActive ? (_breathingIn ? 140 : 80) : 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                _breathingActive
                    ? (_breathingIn ? 'Breathe In' : 'Breathe Out')
                    : 'Tap to Start',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (_breathingActive) ...[
            const SizedBox(height: 12),
            Text(
              'Cycle ${_breathingCycles + 1} of 5',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalmingStep {
  final String emoji;
  final String title;
  final String instruction;
  final Color color;
  const _CalmingStep(this.emoji, this.title, this.instruction, this.color);
}
