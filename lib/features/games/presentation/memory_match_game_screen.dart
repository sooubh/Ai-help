import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_session_model.dart';
import '../../../services/firebase_service.dart';

class MemoryMatchGameScreen extends StatefulWidget {
  const MemoryMatchGameScreen({super.key});

  @override
  State<MemoryMatchGameScreen> createState() => _MemoryMatchGameScreenState();
}

class _MemoryMatchGameScreenState extends State<MemoryMatchGameScreen> {
  final _firebaseService = FirebaseService();

  // Game Setup
  late List<String> _emojis;
  late List<bool> _revealed;
  late List<bool> _matched;
  int? _firstPick;

  // Stats
  int _pairsFound = 0;
  int _moves = 0;
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _busy = false;

  // Level configuration
  int _level = 1;
  int _gridColumns = 2; // Starts 2x2

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    // Config based on level
    final allEmojis = [
      '🐶',
      '🐱',
      '🐸',
      '🦋',
      '🌻',
      '⭐',
      '🍎',
      '🚗',
      '🎈',
      '🧸',
    ];
    final pairsCount = _level == 1 ? 2 : (_level == 2 ? 4 : 6);
    _gridColumns = _level == 1 ? 2 : (_level == 2 ? 2 : 3);

    final selectedEmojis =
        (allEmojis.toList()..shuffle()).take(pairsCount).toList();
    _emojis = [...selectedEmojis, ...selectedEmojis]..shuffle();

    _revealed = List.filled(_emojis.length, false);
    _matched = List.filled(_emojis.length, false);

    _firstPick = null;
    _pairsFound = 0;
    _moves = 0;
    _secondsElapsed = 0;
    _busy = false;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _logGameSession() async {
    final session = GameSessionModel(
      gameType: 'memory_match',
      skillCategory: 'Cognitive',
      difficultyLevel: 'Level $_level',
      score: _pairsFound,
      maxScore: _emojis.length ~/ 2,
      totalMoves: _moves,
      durationSeconds: _secondsElapsed,
      completedAt: DateTime.now(),
      additionalMetrics: {'level': _level},
    );
    await _firebaseService.logGameSession(session);
  }

  void _onTap(int index) {
    if (_busy || _revealed[index] || _matched[index]) return;

    setState(() => _revealed[index] = true);

    if (_firstPick == null) {
      _firstPick = index;
    } else {
      _moves++;
      _busy = true;
      final first = _firstPick!;
      _firstPick = null;

      if (_emojis[first] == _emojis[index]) {
        setState(() {
          _matched[first] = true;
          _matched[index] = true;
          _pairsFound++;
          _busy = false;
        });

        // Win condition for current level
        if (_pairsFound == _emojis.length ~/ 2) {
          _timer?.cancel();
          _logGameSession().then((_) => _showWin());
        }
      } else {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _revealed[first] = false;
              _revealed[index] = false;
              _busy = false;
            });
          }
        });
      }
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
                const Icon(Icons.star_rounded, color: AppColors.gold, size: 64)
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
                  'Great Job!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            content: Text(
              'You found all pairs in $_moves moves and $_secondsElapsed seconds!',
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
                    Navigator.pop(context);
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

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Match - L$_level'),
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_secondsElapsed),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
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
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Moves: $_moves',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Pairs: $_pairsFound/${_emojis.length ~/ 2}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldDark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridColumns,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: _emojis.length,
                    itemBuilder: (context, i) {
                      final show = _revealed[i] || _matched[i];
                      return GestureDetector(
                        onTap: () => _onTap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color:
                                _matched[i]
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : (show
                                        ? AppColors.primarySurface
                                        : AppColors.primary.withValues(
                                          alpha: 0.08,
                                        )),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              width: 2,
                              color:
                                  _matched[i]
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : AppColors.primary.withValues(
                                        alpha: 0.15,
                                      ),
                            ),
                            boxShadow:
                                show && !_matched[i]
                                    ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder:
                                  (child, animation) => ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                              child:
                                  show
                                      ? Text(
                                        _emojis[i],
                                        key: ValueKey('$i-show'),
                                        style: TextStyle(
                                          fontSize: _gridColumns == 2 ? 64 : 48,
                                        ),
                                      )
                                      : Icon(
                                        Icons.question_mark_rounded,
                                        key: ValueKey('$i-hide'),
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        size: _gridColumns == 2 ? 48 : 36,
                                      ),
                            ),
                          ),
                        ),
                      );
                    },
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
