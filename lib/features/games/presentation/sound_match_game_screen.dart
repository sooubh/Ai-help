import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_session_model.dart';
import '../../../services/firebase_service.dart';
import '../../../services/tts_service.dart';

class SoundMatchGameScreen extends StatefulWidget {
  const SoundMatchGameScreen({super.key});

  @override
  State<SoundMatchGameScreen> createState() => _SoundMatchGameScreenState();
}

class _SoundMatchGameScreenState extends State<SoundMatchGameScreen> {
  final _firebaseService = FirebaseService();
  final _ttsService = TtsService();

  // Assuming we use TTS to simulate sounds (e.g. "Meow!", "Woof!") if actual audio files aren't provided
  final List<_SoundPair> _allPairs = [
    _SoundPair('🐶', 'Dog', 'Woof woof!'),
    _SoundPair('🐱', 'Cat', 'Meow meow!'),
    _SoundPair('🐸', 'Frog', 'Ribbit ribbit!'),
    _SoundPair('🐦', 'Bird', 'Tweet tweet!'),
    _SoundPair('🐄', 'Cow', 'Moooooo!'),
    _SoundPair('🦁', 'Lion', 'Roarrrrr!'),
    _SoundPair('🦆', 'Duck', 'Quack quack!'),
    _SoundPair('🐔', 'Chicken', 'Cluck cluck!'),
  ];

  late List<_SoundPair> _levelPairs;
  int _current = 0;
  int? _selected;
  int _score = 0;
  late List<_SoundPair> _options;

  bool _isPlayingAudio = false;
  DateTime? _startTime;
  int _level = 1;

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    _current = 0;
    _score = 0;
    _selected = null;
    _startTime = DateTime.now();

    final pairsCount = _level == 1 ? 4 : (_level == 2 ? 6 : 8);
    _levelPairs = (_allPairs.toList()..shuffle()).take(pairsCount).toList();

    _setupQuestion();
  }

  void _setupQuestion() {
    // Pick 3 options for the current question
    final currentPair = _levelPairs[_current];
    final otherPairs =
        _allPairs.where((p) => p.animal != currentPair.animal).toList()
          ..shuffle();
    _options = [currentPair, otherPairs[0], otherPairs[1]]..shuffle();

    // Auto-play sound
    _playSound(currentPair.sound);
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _playSound(String text) async {
    setState(() => _isPlayingAudio = true);
    // Add pitch variance to make it slightly more interesting
    // Since TtsService doesn't expose pitch easily, we'll just speak it.
    await _ttsService.speak(text);
    if (mounted) setState(() => _isPlayingAudio = false);
  }

  Future<void> _logGameSession() async {
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    final session = GameSessionModel(
      gameType: 'sound_match',
      skillCategory: 'Sensory',
      difficultyLevel: 'Level $_level',
      score: _score,
      maxScore: _levelPairs.length,
      totalMoves: _levelPairs.length,
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

    final isCorrect = _options[index] == _levelPairs[_current];
    if (isCorrect) {
      _score++;
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_current < _levelPairs.length - 1) {
        setState(() {
          _current++;
          _selected = null;
        });
        _setupQuestion();
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
                      Icons.music_note_rounded,
                      color: AppColors.purple,
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
                  'Great Listening!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
            content: Text(
              'You matched $_score out of ${_levelPairs.length} sounds clearly in Level $_level!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              if (_level < 3)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
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
    if (_levelPairs.isEmpty || _options.isEmpty) return const SizedBox();
    final pair = _levelPairs[_current];

    return Scaffold(
      appBar: AppBar(
        title: Text('Sound Match - L$_level'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_current + 1}/${_levelPairs.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
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
                value: (_current) / _levelPairs.length,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.purple,
                ),
                borderRadius: BorderRadius.circular(8),
                minHeight: 12,
              ).animate().fadeIn(),

              const SizedBox(height: 48),

              const Text(
                'What makes this sound?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Big Sound Button
              GestureDetector(
                onTap: () => _playSound(pair.sound),
                child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color:
                            _isPlayingAudio
                                ? AppColors.purple
                                : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.purple, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(
                              alpha: _isPlayingAudio ? 0.5 : 0.2,
                            ),
                            blurRadius: _isPlayingAudio ? 32 : 16,
                            spreadRadius: _isPlayingAudio ? 8 : 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 80,
                          color:
                              _isPlayingAudio ? Colors.white : AppColors.purple,
                        ),
                      ),
                    )
                    .animate(target: _isPlayingAudio ? 1 : 0)
                    .scale(end: const Offset(1.1, 1.1), duration: 200.ms)
                    .shimmer(duration: 1.seconds),
              ),

              const Spacer(),

              // Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    _options.asMap().entries.map((e) {
                      final isCorrect = e.value == pair;
                      final isSelected = e.key == _selected;

                      Color bgColor = AppColors.surfaceVariant;
                      Color borderColor = AppColors.divider;

                      if (_selected != null) {
                        if (isCorrect) {
                          bgColor = AppColors.success.withValues(alpha: 0.2);
                          borderColor = AppColors.success;
                        } else if (isSelected) {
                          bgColor = AppColors.error.withValues(alpha: 0.2);
                          borderColor = AppColors.error;
                        }
                      }

                      return Expanded(
                        child: GestureDetector(
                              onTap: () => _answer(e.key),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                height: 120,
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: borderColor,
                                    width:
                                        isSelected ||
                                                (isCorrect && _selected != null)
                                            ? 3
                                            : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    e.value.emoji,
                                    style: const TextStyle(fontSize: 64),
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 100 * e.key))
                            .slideY(begin: 0.2, curve: Curves.easeOutBack),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoundPair {
  final String emoji;
  final String animal;
  final String sound;
  const _SoundPair(this.emoji, this.animal, this.sound);
}
