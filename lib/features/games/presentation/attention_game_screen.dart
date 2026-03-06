import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_session_model.dart';
import '../../../services/firebase_service.dart';

class AttentionGameScreen extends StatefulWidget {
  const AttentionGameScreen({super.key});

  @override
  State<AttentionGameScreen> createState() => _AttentionGameScreenState();
}

class _AttentionGameScreenState extends State<AttentionGameScreen> {
  final _firebaseService = FirebaseService();

  String _targetEmoji = '⭐';
  late List<String> _grid;

  int _score = 0;
  int _round = 1;
  static const _maxRounds = 5;

  int _secondsElapsed = 0;
  Timer? _timer;

  final _allEmojis = [
    '⭐',
    '🌙',
    '☀️',
    '🌈',
    '❤️',
    '💎',
    '🎵',
    '🔔',
    '⚽',
    '🚗',
    '🍎',
    '🐱',
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _generateRound();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  void _generateRound() {
    _targetEmoji = (_allEmojis.toList()..shuffle()).first;

    // Difficulty increases with rounds: more targets to find, and potentially confusing distractions
    final targetCount = 2 + _round;
    final otherEmojis =
        _allEmojis.where((e) => e != _targetEmoji).toList()..shuffle();

    _grid = List.generate(16, (i) {
      if (i < targetCount) {
        return _targetEmoji;
      } else {
        // More variety of distractions
        return otherEmojis[i % otherEmojis.length];
      }
    })..shuffle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _logGameSession() async {
    final session = GameSessionModel(
      gameType: 'attention_focus',
      skillCategory: 'Attention',
      difficultyLevel: 'Rounds: $_maxRounds',
      score: _score,
      maxScore: 2 + 3 + 4 + 5 + 6, // Total possible targets across 5 rounds
      totalMoves:
          _score, // We aren't tracking wrong taps specifically here, could be added
      durationSeconds: _secondsElapsed,
      completedAt: DateTime.now(),
    );
    await _firebaseService.logGameSession(session);
  }

  void _onTap(int index) {
    if (_grid[index] == _targetEmoji) {
      setState(() {
        _score++;
        _grid[index] = '✅'; // Mark as found
      });

      // Check if all targets are found in this round
      if (!_grid.contains(_targetEmoji)) {
        if (_round >= _maxRounds) {
          _timer?.cancel();
          _logGameSession().then((_) => _showWin());
        } else {
          _round++;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() => _generateRound());
          });
        }
      }
    } else if (_grid[index] != '✅') {
      // Logic for wrong tap could go here (e.g. play error sound or brief red flash)
    }
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
                      Icons.center_focus_strong_rounded,
                      color: AppColors.accent,
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
                  'Amazing Focus!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            content: Text(
              'You found $_score targets in $_secondsElapsed seconds!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
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
                  Navigator.pop(context); // Go back to hub
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attention Focus'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Round $_round/$_maxRounds',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textSecondary,
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
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Find all: ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(_targetEmoji, style: const TextStyle(fontSize: 36))
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .shimmer(
                              duration: 2.seconds,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                      ],
                    ),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4x4 grid = 16 items
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: 16,
                itemBuilder: (context, i) {
                  final isFound = _grid[i] == '✅';
                  return GestureDetector(
                    onTap: () => _onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color:
                            isFound
                                ? AppColors.success.withValues(alpha: 0.2)
                                : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isFound
                                  ? AppColors.success.withValues(alpha: 0.5)
                                  : Theme.of(context).dividerColor,
                          width: isFound ? 2 : 1,
                        ),
                        boxShadow:
                            isFound
                                ? []
                                : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder:
                              (child, animation) => ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                          child: Text(
                            _grid[i],
                            key: ValueKey(_grid[i]),
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
