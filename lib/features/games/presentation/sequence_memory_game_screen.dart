import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/firebase_service.dart';
import '../../../../models/game_session_model.dart';
import 'package:audioplayers/audioplayers.dart';

class SequenceMemoryGameScreen extends StatefulWidget {
  const SequenceMemoryGameScreen({super.key});

  @override
  State<SequenceMemoryGameScreen> createState() =>
      _SequenceMemoryGameScreenState();
}

class _Pad {
  final int id;
  final Color baseColor;
  final Color highlightColor;

  _Pad(this.id, this.baseColor, this.highlightColor);
}

class _SequenceMemoryGameScreenState extends State<SequenceMemoryGameScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<_Pad> _pads = [
    _Pad(0, Colors.red[700]!, Colors.redAccent[100]!),
    _Pad(1, Colors.blue[700]!, Colors.blueAccent[100]!),
    _Pad(2, Colors.green[700]!, Colors.greenAccent[100]!),
    _Pad(3, Colors.amber[700]!, Colors.amberAccent[100]!),
  ];

  final List<int> _sequence = [];
  int _userStep = 0;
  int _score = 0;

  bool _isPlayingSequence = false;
  int? _activePadIndex;

  DateTime? _startTime;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startGame() {
    _sequence.clear();
    _score = 0;
    _nextRound();
  }

  Future<void> _nextRound() async {
    if (_isDisposed) return;
    setState(() {
      _userStep = 0;
      _isPlayingSequence = true;
      _sequence.add(Random().nextInt(_pads.length));
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    for (int padIndex in _sequence) {
      if (_isDisposed) return;

      setState(() {
        _activePadIndex = padIndex;
      });
      _playSound(padIndex);

      await Future.delayed(const Duration(milliseconds: 400));

      if (_isDisposed) return;
      setState(() {
        _activePadIndex = null;
      });

      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (_isDisposed) return;
    setState(() {
      _isPlayingSequence = false;
    });
  }

  Future<void> _playSound(int index) async {
    try {
      // Different pitch per pad if we had distinct files, using generic success/chime here or rely entirely on visual.
      // We will just do a light visual flash if no sound is specifically prepared for 4 tones.
      // await _audioPlayer.play(AssetSource('sounds/tone_$index.mp3'));
    } catch (_) {}
  }

  Future<void> _playFailureSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
    } catch (_) {}
  }

  void _handlePadTap(int index) {
    if (_isPlayingSequence) return;

    setState(() {
      _activePadIndex = index;
    });
    _playSound(index);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (_isDisposed) return;
      setState(() {
        _activePadIndex = null;
      });
    });

    if (index == _sequence[_userStep]) {
      // Correct!
      _userStep++;
      if (_userStep == _sequence.length) {
        // Round complete
        _score++;
        _nextRound();
      }
    } else {
      // Wrong!
      _playFailureSound();
      _finishGame();
    }
  }

  void _finishGame() {
    final service = context.read<FirebaseService>();
    final session = GameSessionModel(
      gameType: 'sequence_memory',
      skillCategory: 'Cognitive',
      difficultyLevel: 'Medium',
      score: _score,
      maxScore: _score + 1,
      totalMoves: _score,
      durationSeconds:
          DateTime.now().difference(_startTime ?? DateTime.now()).inSeconds,
      completedAt: DateTime.now(),
    );
    service.logGameSession(session);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Game Over!'),
            content: Text('You remembered a sequence of $_score!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startGame();
                },
                child: const Text('Try Again'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          ),
    );
  }

  Widget _buildPad(_Pad pad) {
    final isHighlighted = _activePadIndex == pad.id;
    return GestureDetector(
      onTapDown: (_) {
        if (!_isPlayingSequence) {
          _handlePadTap(pad.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isHighlighted ? pad.highlightColor : pad.baseColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (isHighlighted)
              BoxShadow(
                color: pad.highlightColor,
                blurRadius: 20,
                spreadRadius: 5,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sequence Memory'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Score: $_score',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Text(
              _sequence.isEmpty
                  ? 'Tap Start to watch the pattern'
                  : (_isPlayingSequence
                      ? 'Watch Carefully...'
                      : 'Now repeat the pattern!'),
              style: TextStyle(
                fontSize: 18,
                color:
                    _isPlayingSequence ? AppColors.accent : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 40),

            // Simon Says Board
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E1E2C)
                          : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: GridView.count(
                  crossAxisCount: 2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _pads.map(_buildPad).toList(),
                ),
              ),
            ).animate().scale(
              delay: 200.ms,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            ),

            const SizedBox(height: 60),

            if (_sequence.isEmpty)
              ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Game', style: TextStyle(fontSize: 18)),
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
              ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
