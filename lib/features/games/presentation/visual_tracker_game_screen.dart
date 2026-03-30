import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_session_model.dart';
import '../../../services/firebase_service.dart';

class VisualTrackerGameScreen extends StatefulWidget {
  const VisualTrackerGameScreen({super.key});

  @override
  State<VisualTrackerGameScreen> createState() =>
      _VisualTrackerGameScreenState();
}

class _VisualTrackerGameScreenState extends State<VisualTrackerGameScreen>
    with SingleTickerProviderStateMixin {
  final _firebaseService = FirebaseService();

  // Physics & Animation
  late AnimationController _controller;
  double _posX = 0.5; // 0.0 to 1.0 (relative to container width)
  double _posY = 0.5; // 0.0 to 1.0 (relative to container height)
  double _velX = 0;
  double _velY = 0;

  // Game logic
  int _level = 1; // 1 = slow, 2 = medium, 3 = fast with bouncing boundaries
  int _score = 0;
  bool _isPlaying = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  final _random = Random();
  String _targetEmoji = '🦋';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updatePosition);

    _startLevel();
  }

  void _startLevel() {
    _score = 0;
    _secondsElapsed = 0;
    _isPlaying = true;

    // Set initial position center
    _posX = 0.5;
    _posY = 0.5;

    // Set target emoji
    final emojis = ['🦋', '🚀', '🐝', '👻', '🛸'];
    _targetEmoji = emojis[_random.nextInt(emojis.length)];

    _randomizeVelocity();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
          if (_secondsElapsed >= 30) {
            _endGame();
          } else if (_secondsElapsed % 2 == 0) {
            // Randomize velocity every 2 seconds slightly
            _randomizeVelocity();
          }
        });
      }
    });

    _controller.repeat();
  }

  void _randomizeVelocity() {
    // Base speed increases with level
    double baseSpeed = _level * 0.005;

    // Give it a new vector
    double angle = _random.nextDouble() * 2 * pi;
    _velX = cos(angle) * baseSpeed;
    _velY = sin(angle) * baseSpeed;

    // Make sure it's not moving too slow
    if (_velX.abs() < 0.002) _velX = _velX < 0 ? -0.005 : 0.005;
    if (_velY.abs() < 0.002) _velY = _velY < 0 ? -0.005 : 0.005;
  }

  void _updatePosition() {
    if (!_isPlaying) return;

    setState(() {
      _posX += _velX;
      _posY += _velY;

      // Bounce off boundaries
      if (_posX <= 0.05) {
        _posX = 0.05;
        _velX = _velX.abs();
      } else if (_posX >= 0.95) {
        _posX = 0.95;
        _velX = -_velX.abs();
      }

      if (_posY <= 0.05) {
        _posY = 0.05;
        _velY = _velY.abs();
      } else if (_posY >= 0.95) {
        _posY = 0.95;
        _velY = -_velY.abs();
      }
    });
  }

  Future<void> _logGameSession() async {
    final session = GameSessionModel(
      gameType: 'visual_tracker',
      skillCategory: 'Visual Motor',
      difficultyLevel: 'Level $_level',
      score: _score,
      maxScore: 30, // Theoretical max if they tap once per second perfectly
      totalMoves: _score, // tracking taps
      durationSeconds: _secondsElapsed,
      completedAt: DateTime.now(),
      additionalMetrics: {'level': _level},
    );
    await _firebaseService.logGameSession(session);
  }

  void _onTargetTap() {
    if (!_isPlaying) return;
    setState(() {
      _score++;
      _randomizeVelocity(); // Instantly change direction on hit to keep them on their toes
    });

    // Provide some immediate feedback (haptic would be good here)
  }

  void _endGame() {
    _isPlaying = false;
    _controller.stop();
    _timer?.cancel();

    _logGameSession().then((_) => _showWin());
  }

  void _showWin() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Column(
              children: [
                const Icon(
                      Icons.remove_red_eye_rounded,
                      color: AppColors.primary,
                      size: 64,
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(duration: 600.ms, curve: Curves.easeInOut)
                    .then()
                    .scale(
                      begin: const Offset(1.2, 1.2),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                    ),
                const SizedBox(height: 16),
                const Text(
                  'Sharpshooter!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            content: Text(
              'You found the $_targetEmoji $_score times in 30 seconds!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              if (_level < 3)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _level++;
                      _startLevel();
                    });
                  },
                  child: const Text(
                    'Next Level',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context); // Go back home
                  },
                  child: const Text(
                    'Finish Game',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visual Tracker - L$_level'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${30 - _secondsElapsed}s',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 20,
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                      ),
                      children: [
                        const TextSpan(
                          text: 'Catch the ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: _targetEmoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Score: $_score',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.divider, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        // The moving target
                        Align(
                          alignment: FractionalOffset(_posX, _posY),
                          child: GestureDetector(
                            onTapDown: (_) => _onTargetTap(),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _targetEmoji,
                                  style: const TextStyle(fontSize: 48),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
