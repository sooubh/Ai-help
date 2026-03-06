import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_session_model.dart';
import '../../../services/firebase_service.dart';
import '../../../services/tts_service.dart'; // Ensure TTS is imported

class EmotionQuizGameScreen extends StatefulWidget {
  const EmotionQuizGameScreen({super.key});

  @override
  State<EmotionQuizGameScreen> createState() => _EmotionQuizGameScreenState();
}

class _EmotionQuizGameScreenState extends State<EmotionQuizGameScreen> {
  final _firebaseService = FirebaseService();
  final _ttsService = TtsService();

  // Levels: Level 1 = basic emojis, Level 2 = more complex emotion descriptions
  int _level = 1;
  late List<_QuizQ> _questions;

  int _qi = 0;
  int _score = 0;
  int? _selected;

  bool _isPlayingAudio = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    _qi = 0;
    _score = 0;
    _selected = null;
    _startTime = DateTime.now();

    if (_level == 1) {
      _questions = [
        _QuizQ('😊', 'How does this face feel?', [
          'Happy',
          'Sad',
          'Angry',
          'Scared',
        ], 0),
        _QuizQ('😢', 'How does this face feel?', [
          'Excited',
          'Sad',
          'Surprised',
          'Happy',
        ], 1),
        _QuizQ('😠', 'How does this face feel?', [
          'Sleepy',
          'Happy',
          'Angry',
          'Surprised',
        ], 2),
        _QuizQ('😲', 'How does this face feel?', [
          'Surprised',
          'Sad',
          'Bored',
          'Angry',
        ], 0),
        _QuizQ('😴', 'How does this face feel?', [
          'Angry',
          'Scared',
          'Sleepy',
          'Excited',
        ], 2),
      ];
    } else {
      // Level 2 adds scenarios
      _questions = [
        _QuizQ('🧸', 'Tommy lost his favorite toy. How does he feel?', [
          'Happy',
          'Sad',
          'Angry',
          'Sleepy',
        ], 1),
        _QuizQ('🎁', 'Sarah just got a big present! How does she feel?', [
          'Happy',
          'Scared',
          'Bored',
          'Angry',
        ], 0),
        _QuizQ('🌩️', 'There is a loud thunderstorm. How does Leo feel?', [
          'Scared',
          'Happy',
          'Sleepy',
          'Surprised',
        ], 0),
        _QuizQ(
          '🏃',
          'Alex ran a long race and is very tired. How does he feel?',
          ['Angry', 'Happy', 'Excited', 'Sleepy'],
          3,
        ),
      ];
    }

    // Auto-read first question
    _readQuestionText(_questions[_qi].question);
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _readQuestionText(String text) async {
    setState(() => _isPlayingAudio = true);
    await _ttsService.speak(text);
    if (mounted) setState(() => _isPlayingAudio = false);
  }

  Future<void> _logGameSession() async {
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    final session = GameSessionModel(
      gameType: 'emotion_quiz',
      skillCategory: 'Social Skills',
      difficultyLevel: 'Level $_level',
      score: _score,
      maxScore: _questions.length,
      totalMoves: _questions.length,
      durationSeconds: duration,
      completedAt: DateTime.now(),
      additionalMetrics: {'level': _level},
    );
    await _firebaseService.logGameSession(session);
  }

  void _answer(int index) {
    if (_selected != null) return;

    _ttsService.stop();
    setState(() => _selected = index);

    final isCorrect = (index == _questions[_qi].correct);
    if (isCorrect) {
      _score++;
      _ttsService.speak('Great job!');
    } else {
      _ttsService.speak('Not quite.');
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_qi < _questions.length - 1) {
        setState(() {
          _qi++;
          _selected = null;
        });
        _readQuestionText(_questions[_qi].question);
      } else {
        _logGameSession().then((_) => _showWin());
      }
    });
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
                      Icons.emoji_events_rounded,
                      color: AppColors.gold,
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
                Text(
                  'Quiz Complete!',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            content: Text(
              'You got $_score out of ${_questions.length} correct in Level $_level!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              if (_level == 1)
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
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return const SizedBox();
    final q = _questions[_qi];

    return Scaffold(
      appBar: AppBar(
        title: Text('Emotion Quiz - L$_level'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_qi + 1}/${_questions.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: (_qi) / _questions.length,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                borderRadius: BorderRadius.circular(8),
                minHeight: 12,
              ).animate().fadeIn(),

              const SizedBox(height: 48),

              // Emoji / Scenario Visual
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(q.emoji, style: const TextStyle(fontSize: 80))
                    .animate(key: ValueKey(q.emoji))
                    .scale(curve: Curves.elasticOut, duration: 800.ms),
              ),

              const SizedBox(height: 32),

              // Question Text + Read Aloud Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                          q.question,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate(key: ValueKey(q.question))
                        .fadeIn()
                        .slideY(begin: 0.2),
                  ),
                  IconButton(
                    icon: Icon(
                      _isPlayingAudio
                          ? Icons.volume_up_rounded
                          : Icons.volume_up_outlined,
                      color:
                          _isPlayingAudio
                              ? AppColors.primary
                              : AppColors.textSecondary,
                      size: 32,
                    ),
                    onPressed: () => _readQuestionText(q.question),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Custom Options Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  physics: const NeverScrollableScrollPhysics(),
                  children:
                      q.options.asMap().entries.map((e) {
                        final isCorrect = e.key == q.correct;
                        final isSelected = e.key == _selected;

                        Color bgColor = AppColors.surfaceVariant;
                        Color textColor = AppColors.textPrimary;
                        Color borderColor = AppColors.divider;

                        if (_selected != null) {
                          if (isCorrect) {
                            bgColor = AppColors.success.withValues(alpha: 0.2);
                            borderColor = AppColors.success;
                            textColor = AppColors.success;
                          } else if (isSelected) {
                            bgColor = AppColors.error.withValues(alpha: 0.2);
                            borderColor = AppColors.error;
                            textColor = AppColors.error;
                          } else {
                            // Unselected wrong options get faded out
                            textColor = AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            );
                          }
                        }

                        return GestureDetector(
                              onTap: () => _answer(e.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: borderColor,
                                    width:
                                        isSelected ||
                                                (isCorrect && _selected != null)
                                            ? 2
                                            : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    e.value,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                          _selected != null && isCorrect
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 100 * e.key))
                            .slideY(begin: 0.2);
                      }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizQ {
  final String emoji;
  final String question;
  final List<String> options;
  final int correct;
  const _QuizQ(this.emoji, this.question, this.options, this.correct);
}
