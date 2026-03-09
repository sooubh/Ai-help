import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/firebase_service.dart';
import '../../../../models/game_session_model.dart';
import 'package:audioplayers/audioplayers.dart';

class ShapeMatcherGameScreen extends StatefulWidget {
  const ShapeMatcherGameScreen({super.key});

  @override
  State<ShapeMatcherGameScreen> createState() => _ShapeMatcherGameScreenState();
}

enum ShapeType { circle, square, triangle, star }

class _ShapeItem {
  final ShapeType type;
  final Color color;
  final IconData icon;

  _ShapeItem(this.type, this.color, this.icon);
}

class _ShapeMatcherGameScreenState extends State<ShapeMatcherGameScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  DateTime? _startTime;
  int _score = 0;
  final int _targetScore = 4;

  final List<_ShapeItem> _shapes = [
    _ShapeItem(ShapeType.circle, Colors.redAccent, Icons.circle),
    _ShapeItem(ShapeType.square, Colors.blueAccent, Icons.square),
    _ShapeItem(ShapeType.triangle, Colors.greenAccent, Icons.change_history),
    _ShapeItem(ShapeType.star, Colors.orangeAccent, Icons.star),
  ];

  late List<_ShapeItem> _draggableShapes;
  final Set<ShapeType> _matchedShapes = {};

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startGame() {
    _startTime = DateTime.now();
    _score = 0;
    _matchedShapes.clear();
    _draggableShapes = List.from(_shapes)..shuffle(Random());
    setState(() {});
  }

  Future<void> _handleMatch(ShapeType type) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (_) {
      // Ignore if sound missing
    }

    setState(() {
      _matchedShapes.add(type);
      _draggableShapes.removeWhere((s) => s.type == type);
      _score++;
    });

    if (_score >= _targetScore) {
      _finishGame();
    }
  }

  void _finishGame() {
    final service = context.read<FirebaseService>();
    final session = GameSessionModel(
      gameType: 'shape_matcher',
      skillCategory: 'Fine Motor',
      difficultyLevel: 'Easy',
      score: _score,
      maxScore: _targetScore,
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
            title: const Text('🌟 Fantastic Object Matching!'),
            content: const Text('You sorted all the shapes perfectly!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startGame();
                },
                child: const Text('Play Again'),
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

  Widget _buildDragTarget(_ShapeItem shape) {
    final isMatched = _matchedShapes.contains(shape.type);

    return DragTarget<_ShapeItem>(
      builder: (context, candidateData, rejectedData) {
        return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isMatched ? shape.color : Colors.transparent,
                border: Border.all(
                  color:
                      isMatched
                          ? shape.color
                          : shape.color.withValues(alpha: 0.5),
                  width: 4,
                  style: isMatched ? BorderStyle.solid : BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(
                  shape.type == ShapeType.circle ? 40 : 16,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                shape.icon,
                color:
                    isMatched
                        ? Colors.white
                        : shape.color.withValues(alpha: 0.3),
                size: 40,
              ),
            )
            .animate(target: isMatched ? 1 : 0)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 200.ms,
            );
      },
      onWillAcceptWithDetails: (details) => details.data.type == shape.type,
      onAcceptWithDetails: (details) => _handleMatch(shape.type),
    );
  }

  Widget _buildDraggable(_ShapeItem shape) {
    if (_matchedShapes.contains(shape.type)) {
      return const SizedBox(width: 70, height: 70); // Placeholder
    }

    return Draggable<_ShapeItem>(
      data: shape,
      feedback: Material(
        color: Colors.transparent,
        child: Icon(shape.icon, color: shape.color, size: 85),
      ),
      childWhenDragging: Icon(
        shape.icon,
        color: shape.color.withValues(alpha: 0.3),
        size: 70,
      ),
      child: Icon(shape.icon, color: shape.color, size: 70)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 800.ms,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shape Matcher'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDark
                    ? [AppColors.darkBackground, const Color(0xFF1E1B4B)]
                    : [const Color(0xFFEEF2FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Drag the shapes to their outlines!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Matched: $_score / $_targetScore',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 60),

            // Targets (Top Row)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _shapes.map(_buildDragTarget).toList(),
              ),
            ),

            const Spacer(),

            // Draggables (Bottom Row)
            Container(
              padding: const EdgeInsets.only(
                top: 40,
                bottom: 60,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _draggableShapes.map(_buildDraggable).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
