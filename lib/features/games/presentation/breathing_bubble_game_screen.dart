import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/firebase_service.dart';
import '../../../../models/game_session_model.dart';

class BreathingBubbleGameScreen extends StatefulWidget {
  const BreathingBubbleGameScreen({super.key});

  @override
  State<BreathingBubbleGameScreen> createState() =>
      _BreathingBubbleGameScreenState();
}

enum BreathPhase { idle, inhale, hold, exhale }

class _BreathingBubbleGameScreenState extends State<BreathingBubbleGameScreen>
    with SingleTickerProviderStateMixin {
  BreathPhase _phase = BreathPhase.idle;
  int _cyclesCompleted = 0;
  final int _targetCycles = 5;
  String _instructionText = "Tap start to begin breathing";

  // Timings
  final int _inhaleTimeMs = 4000;
  final int _holdTimeMs = 4000;
  final int _exhaleTimeMs = 4000;

  DateTime? _startTime;
  bool _isDisposed = false;

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animController.dispose();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _cyclesCompleted = 0;
      _startTime = DateTime.now();
      _runBreathCycle();
    });
  }

  Future<void> _runBreathCycle() async {
    if (_isDisposed || _cyclesCompleted >= _targetCycles) {
      if (_cyclesCompleted >= _targetCycles) _finishGame();
      return;
    }

    // Inhale
    if (_isDisposed) return;
    setState(() {
      _phase = BreathPhase.inhale;
      _instructionText = "Breathe In...";
    });

    _animController.duration = Duration(milliseconds: _inhaleTimeMs);
    await _animController.forward();

    // Hold
    if (_isDisposed) return;
    setState(() {
      _phase = BreathPhase.hold;
      _instructionText = "Hold...";
    });
    await Future.delayed(Duration(milliseconds: _holdTimeMs));

    // Exhale
    if (_isDisposed) return;
    setState(() {
      _phase = BreathPhase.exhale;
      _instructionText = "Breathe Out...";
    });

    _animController.duration = Duration(milliseconds: _exhaleTimeMs);
    await _animController.reverse();

    if (_isDisposed) return;
    setState(() {
      _cyclesCompleted++;
    });

    if (_cyclesCompleted < _targetCycles) {
      _runBreathCycle();
    } else {
      _finishGame();
    }
  }

  void _finishGame() {
    if (_isDisposed) return;
    setState(() {
      _phase = BreathPhase.idle;
      _instructionText = "Great job! You are so calm.";
    });
    _saveSession();
  }

  Future<void> _saveSession() async {
    final service = context.read<FirebaseService>();
    final session = GameSessionModel(
      gameType: 'breathing_bubble',
      skillCategory: 'Wellness',
      difficultyLevel: 'Easy',
      score: _targetCycles,
      maxScore: _targetCycles,
      totalMoves: _targetCycles,
      durationSeconds:
          DateTime.now().difference(_startTime ?? DateTime.now()).inSeconds,
      completedAt: DateTime.now(),
    );
    await service.logGameSession(session);
  }

  Color _getBubbleColor() {
    switch (_phase) {
      case BreathPhase.inhale:
        return AppColors.primary;
      case BreathPhase.hold:
        return AppColors.accent;
      case BreathPhase.exhale:
        return const Color(0xFF10B981); // Calming green
      default:
        return AppColors.primary.withValues(alpha: 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathing Bubble'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Cycle $_cyclesCompleted of $_targetCycles",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 60),

            // The animated Bubble
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                // scale goes from 1.0 to 2.5
                final scale = 1.0 + (_animController.value * 1.5);
                return Transform.scale(
                  scale: scale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getBubbleColor().withValues(alpha: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: _getBubbleColor().withValues(alpha: 0.5),
                          blurRadius: 30 * scale,
                          spreadRadius: 10 * scale,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 80),

            // Instruction Text
            Text(
                  _instructionText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                )
                .animate(key: ValueKey(_instructionText))
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2),

            const SizedBox(height: 40),

            if (_phase == BreathPhase.idle && _cyclesCompleted == 0)
              ElevatedButton.icon(
                onPressed: _startBreathing,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

            if (_phase == BreathPhase.idle && _cyclesCompleted >= _targetCycles)
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Finish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
