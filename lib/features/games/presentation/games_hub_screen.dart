import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

// Import newly separated game screens
import 'memory_match_game_screen.dart';
import 'attention_game_screen.dart';
import 'drag_sort_game_screen.dart';
import 'emotion_quiz_game_screen.dart';
import 'sound_match_game_screen.dart';
import 'visual_tracker_game_screen.dart';
import 'breathing_bubble_game_screen.dart';
import 'shape_matcher_game_screen.dart';
import 'sequence_memory_game_screen.dart';

/// Games Hub — grid of interactive therapy games.
class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Therapy Games')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.85,
        ),
        itemCount: _games.length,
        itemBuilder: (context, index) {
          final game = _games[index];
          return _GameCard(game: game, index: index, isDark: isDark);
        },
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final _GameInfo game;
  final int index;
  final bool isDark;

  const _GameCard({
    required this.game,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => game.screen),
          ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              game.color.withValues(alpha: isDark ? 0.25 : 0.12),
              game.color.withValues(alpha: isDark ? 0.1 : 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: game.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: game.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(game.icon, color: game.color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              game.title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Text(
              game.skill,
              style: TextStyle(
                color: game.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              game.ageRange,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 80 * index),
      duration: 400.ms,
    );
  }
}

class _GameInfo {
  final String title;
  final String skill;
  final String ageRange;
  final IconData icon;
  final Color color;
  final Widget screen;

  const _GameInfo({
    required this.title,
    required this.skill,
    required this.ageRange,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

final _games = [
  _GameInfo(
    title: 'Memory Match',
    skill: 'Cognitive',
    ageRange: 'Ages 3-10',
    icon: Icons.grid_view_rounded,
    color: AppColors.primary,
    screen: const MemoryMatchGameScreen(),
  ),
  _GameInfo(
    title: 'Attention Focus',
    skill: 'Attention',
    ageRange: 'Ages 4-12',
    icon: Icons.center_focus_strong_rounded,
    color: AppColors.accent,
    screen: const AttentionGameScreen(),
  ),
  _GameInfo(
    title: 'Drag & Sort',
    skill: 'Motor Skills',
    ageRange: 'Ages 3-8',
    icon: Icons.drag_indicator_rounded,
    color: const Color(0xFF10B981),
    screen: const DragSortGameScreen(),
  ),
  _GameInfo(
    title: 'Emotion Quiz',
    skill: 'Social Skills',
    ageRange: 'Ages 4-10',
    icon: Icons.emoji_emotions_rounded,
    color: const Color(0xFFF59E0B),
    screen: const EmotionQuizGameScreen(),
  ),
  _GameInfo(
    title: 'Sound Match',
    skill: 'Sensory',
    ageRange: 'Ages 3-9',
    icon: Icons.music_note_rounded,
    color: AppColors.purple,
    screen: const SoundMatchGameScreen(),
  ),
  _GameInfo(
    title: 'Visual Tracker',
    skill: 'Visual Motor',
    ageRange: 'Ages 3-8',
    icon: Icons.visibility_rounded,
    color: const Color(0xFFEC4899),
    screen: const VisualTrackerGameScreen(),
  ),
  _GameInfo(
    title: 'Breathing Bubble',
    skill: 'Wellness',
    ageRange: 'Ages 3-12',
    icon: Icons.air_rounded,
    color: const Color(0xFF38BDF8),
    screen: const BreathingBubbleGameScreen(),
  ),
  _GameInfo(
    title: 'Shape Matcher',
    skill: 'Motor Skills',
    ageRange: 'Ages 3-7',
    icon: Icons.category_rounded,
    color: const Color(0xFF8B5CF6),
    screen: const ShapeMatcherGameScreen(),
  ),
  _GameInfo(
    title: 'Sequence Memory',
    skill: 'Cognitive',
    ageRange: 'Ages 5-12',
    icon: Icons.memory_rounded,
    color: const Color(0xFFF43F5E),
    screen: const SequenceMemoryGameScreen(),
  ),
];
