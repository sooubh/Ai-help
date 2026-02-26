import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

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
      onTap: () => Navigator.push(
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
          border: Border.all(
            color: game.color.withValues(alpha: 0.2),
          ),
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
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
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

// ═══════════════════════════════════════════════════════════════
// GAME DATA
// ═══════════════════════════════════════════════════════════════

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
    screen: const _MemoryMatchGame(),
  ),
  _GameInfo(
    title: 'Attention Focus',
    skill: 'Attention',
    ageRange: 'Ages 4-12',
    icon: Icons.center_focus_strong_rounded,
    color: AppColors.accent,
    screen: const _AttentionGame(),
  ),
  _GameInfo(
    title: 'Drag & Sort',
    skill: 'Motor Skills',
    ageRange: 'Ages 3-8',
    icon: Icons.drag_indicator_rounded,
    color: const Color(0xFF10B981),
    screen: const _DragSortGame(),
  ),
  _GameInfo(
    title: 'Emotion Quiz',
    skill: 'Social Skills',
    ageRange: 'Ages 4-10',
    icon: Icons.emoji_emotions_rounded,
    color: const Color(0xFFF59E0B),
    screen: const _EmotionQuizGame(),
  ),
  _GameInfo(
    title: 'Sound Match',
    skill: 'Sensory',
    ageRange: 'Ages 3-9',
    icon: Icons.music_note_rounded,
    color: AppColors.purple,
    screen: const _SoundMatchGame(),
  ),
  _GameInfo(
    title: 'Visual Tracker',
    skill: 'Visual Motor',
    ageRange: 'Ages 3-8',
    icon: Icons.visibility_rounded,
    color: const Color(0xFFEC4899),
    screen: const _VisualTrackerGame(),
  ),
];

// ═══════════════════════════════════════════════════════════════
// GAME 1: MEMORY MATCH
// ═══════════════════════════════════════════════════════════════

class _MemoryMatchGame extends StatefulWidget {
  const _MemoryMatchGame();
  @override
  State<_MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<_MemoryMatchGame> {
  late List<String> _emojis;
  late List<bool> _revealed;
  late List<bool> _matched;
  int? _firstPick;
  int _pairsFound = 0;
  int _moves = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    final base = ['🐶', '🐱', '🐸', '🦋', '🌻', '⭐'];
    _emojis = [...base, ...base]..shuffle();
    _revealed = List.filled(12, false);
    _matched = List.filled(12, false);
    _firstPick = null;
    _pairsFound = 0;
    _moves = 0;
    _busy = false;
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
        if (_pairsFound == 6) _showWin();
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
      builder: (_) => AlertDialog(
        title: const Text('🎉 Great Job!'),
        content: Text('You matched all pairs in $_moves moves!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _resetGame());
            },
            child: const Text('Play Again'),
          ),
          TextButton(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Match'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('Moves: $_moves',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: 12,
          itemBuilder: (context, i) {
            final show = _revealed[i] || _matched[i];
            return GestureDetector(
              onTap: () => _onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: _matched[i]
                      ? AppColors.success.withValues(alpha: 0.15)
                      : (show
                          ? AppColors.primarySurface
                          : AppColors.primary.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _matched[i]
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: show
                        ? Text(_emojis[i],
                            key: ValueKey('$i-show'),
                            style: const TextStyle(fontSize: 36))
                        : Icon(Icons.question_mark_rounded,
                            key: ValueKey('$i-hide'),
                            color: AppColors.primary.withValues(alpha: 0.4),
                            size: 28),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GAME 2: ATTENTION FOCUS
// ═══════════════════════════════════════════════════════════════

class _AttentionGame extends StatefulWidget {
  const _AttentionGame();
  @override
  State<_AttentionGame> createState() => _AttentionGameState();
}

class _AttentionGameState extends State<_AttentionGame> {
  String _targetEmoji = '⭐';
  late List<String> _grid;
  int _score = 0;
  int _round = 0;
  static const _maxRounds = 5;
  final _allEmojis = ['⭐', '🌙', '☀️', '🌈', '❤️', '💎', '🎵', '🔔'];

  @override
  void initState() {
    super.initState();
    _generateRound();
  }

  void _generateRound() {
    _targetEmoji = (_allEmojis..shuffle()).first;
    final targetCount = 3 + _round;
    _grid = List.generate(12, (i) =>
      i < targetCount ? _targetEmoji : (_allEmojis.where((e) => e != _targetEmoji).toList()..shuffle()).first,
    )..shuffle();
  }

  void _onTap(int index) {
    if (_grid[index] == _targetEmoji) {
      setState(() {
        _score++;
        _grid[index] = '✅';
      });
      if (!_grid.contains(_targetEmoji)) {
        _round++;
        if (_round >= _maxRounds) {
          _showWin();
        } else {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() => _generateRound());
          });
        }
      }
    }
  }

  void _showWin() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🏆 Well Done!'),
        content: Text('You found $_score targets across $_maxRounds rounds!'),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); setState(() { _score = 0; _round = 0; _generateRound(); }); },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attention Focus')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Find all: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(_targetEmoji, style: const TextStyle(fontSize: 32)),
                  const Spacer(),
                  Text('Score: $_score',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10,
              ),
              itemCount: 12,
              itemBuilder: (context, i) {
                return GestureDetector(
                  onTap: () => _onTap(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _grid[i] == '✅'
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(_grid[i], style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GAME 3: DRAG & SORT
// ═══════════════════════════════════════════════════════════════

class _DragSortGame extends StatefulWidget {
  const _DragSortGame();
  @override
  State<_DragSortGame> createState() => _DragSortGameState();
}

class _DragSortGameState extends State<_DragSortGame> {
  final _categories = {'🍎 Fruits': ['🍎', '🍌', '🍇'], '🐾 Animals': ['🐶', '🐱', '🐸']};
  late List<String> _items;
  final Map<String, List<String>> _sorted = {'🍎 Fruits': [], '🐾 Animals': []};

  @override
  void initState() {
    super.initState();
    _items = [..._categories.values.expand((e) => e)]..shuffle();
  }

  void _checkDone() {
    if (_items.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('🎊 Sorted!'),
          content: const Text('You sorted everything correctly!'),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drag & Sort')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Drag items to the correct category!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            // Draggable items
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _items.map((item) {
                return Draggable<String>(
                  data: item,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Text(item, style: const TextStyle(fontSize: 40)),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _ItemChip(emoji: item),
                  ),
                  child: _ItemChip(emoji: item),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Drop targets
            Expanded(
              child: Row(
                children: _categories.keys.map((cat) {
                  return Expanded(
                    child: DragTarget<String>(
                      onWillAcceptWithDetails: (details) {
                        return _categories[cat]!.contains(details.data);
                      },
                      onAcceptWithDetails: (details) {
                        setState(() {
                          _items.remove(details.data);
                          _sorted[cat]!.add(details.data);
                        });
                        _checkDone();
                      },
                      builder: (context, accepted, rejected) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: accepted.isNotEmpty
                                ? AppColors.success.withValues(alpha: 0.1)
                                : (rejected.isNotEmpty
                                    ? AppColors.error.withValues(alpha: 0.1)
                                    : AppColors.surfaceVariant),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: accepted.isNotEmpty
                                  ? AppColors.success
                                  : AppColors.divider,
                              width: accepted.isNotEmpty ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(cat,
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 4,
                                children: (_sorted[cat] ?? []).map((e) =>
                                    Text(e, style: const TextStyle(fontSize: 28))).toList(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  final String emoji;
  const _ItemChip({required this.emoji});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 32)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GAME 4: EMOTION QUIZ
// ═══════════════════════════════════════════════════════════════

class _EmotionQuizGame extends StatefulWidget {
  const _EmotionQuizGame();
  @override
  State<_EmotionQuizGame> createState() => _EmotionQuizGameState();
}

class _EmotionQuizGameState extends State<_EmotionQuizGame> {
  final _questions = [
    _QuizQ('😊', 'How does this face feel?', ['Happy', 'Sad', 'Angry'], 0),
    _QuizQ('😢', 'How does this face feel?', ['Excited', 'Sad', 'Surprised'], 1),
    _QuizQ('😠', 'How does this face feel?', ['Sleepy', 'Happy', 'Angry'], 2),
    _QuizQ('😲', 'How does this face feel?', ['Surprised', 'Sad', 'Bored'], 0),
    _QuizQ('😴', 'How does this face feel?', ['Angry', 'Scared', 'Sleepy'], 2),
  ];
  int _qi = 0;
  int _score = 0;
  int? _selected;

  void _answer(int index) {
    if (_selected != null) return;
    setState(() => _selected = index);
    if (index == _questions[_qi].correct) _score++;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_qi < _questions.length - 1) {
        setState(() { _qi++; _selected = null; });
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('🌟 Quiz Done!'),
            content: Text('You got $_score out of ${_questions.length} correct!'),
            actions: [
              TextButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_qi];
    return Scaffold(
      appBar: AppBar(title: Text('Emotion Quiz (${_qi + 1}/${_questions.length})')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(q.emoji, style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            Text(q.question,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ...q.options.asMap().entries.map((e) {
              final isCorrect = e.key == q.correct;
              final isSelected = e.key == _selected;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _answer(e.key),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selected == null
                          ? AppColors.surfaceVariant
                          : (isCorrect
                              ? AppColors.success
                              : (isSelected ? AppColors.error : AppColors.surfaceVariant)),
                      foregroundColor: _selected != null && (isCorrect || isSelected)
                          ? Colors.white
                          : null,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(e.value, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              );
            }),
          ],
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

// ═══════════════════════════════════════════════════════════════
// GAME 5: SOUND MATCH (emoji-based)
// ═══════════════════════════════════════════════════════════════

class _SoundMatchGame extends StatefulWidget {
  const _SoundMatchGame();
  @override
  State<_SoundMatchGame> createState() => _SoundMatchGameState();
}

class _SoundMatchGameState extends State<_SoundMatchGame> {
  final _pairs = [
    _SoundPair('🐶', 'Woof!', 'Dog'),
    _SoundPair('🐱', 'Meow!', 'Cat'),
    _SoundPair('🐸', 'Ribbit!', 'Frog'),
    _SoundPair('🐦', 'Tweet!', 'Bird'),
    _SoundPair('🐄', 'Moo!', 'Cow'),
  ];
  int _current = 0;
  int? _selected;
  int _score = 0;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _shuffleOptions();
  }

  void _shuffleOptions() {
    _options = _pairs.map((p) => p.sound).toList()..shuffle();
  }

  void _answer(int index) {
    if (_selected != null) return;
    setState(() => _selected = index);
    if (_options[index] == _pairs[_current].sound) _score++;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_current < _pairs.length - 1) {
        setState(() { _current++; _selected = null; _shuffleOptions(); });
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('🎵 Complete!'),
            content: Text('You matched $_score out of ${_pairs.length} sounds!'),
            actions: [
              TextButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pair = _pairs[_current];
    return Scaffold(
      appBar: AppBar(title: Text('Sound Match (${_current + 1}/${_pairs.length})')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(pair.emoji, style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 12),
            Text('What sound does a ${pair.animal} make?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ...List.generate(_options.length, (i) {
              final isCorrect = _options[i] == pair.sound;
              final isSelected = i == _selected;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _answer(i),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selected == null
                          ? AppColors.purple.withValues(alpha: 0.1)
                          : (isCorrect
                              ? AppColors.success
                              : (isSelected ? AppColors.error : AppColors.surfaceVariant)),
                      foregroundColor: _selected != null && (isCorrect || isSelected)
                          ? Colors.white : null,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(_options[i],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SoundPair {
  final String emoji;
  final String sound;
  final String animal;
  const _SoundPair(this.emoji, this.sound, this.animal);
}

// ═══════════════════════════════════════════════════════════════
// GAME 6: VISUAL TRACKER
// ═══════════════════════════════════════════════════════════════

class _VisualTrackerGame extends StatefulWidget {
  const _VisualTrackerGame();
  @override
  State<_VisualTrackerGame> createState() => _VisualTrackerGameState();
}

class _VisualTrackerGameState extends State<_VisualTrackerGame> {
  int _score = 0;
  int _round = 0;
  double _targetX = 0.5;
  double _targetY = 0.5;

  @override
  void initState() {
    super.initState();
    _moveTarget();
  }

  void _moveTarget() {
    setState(() {
      _targetX = 0.1 + (0.8 * (DateTime.now().millisecond % 100) / 100);
      _targetY = 0.1 + (0.8 * (DateTime.now().microsecond % 100) / 100);
    });
  }

  void _onTap() {
    setState(() {
      _score++;
      _round++;
    });
    if (_round >= 10) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('👁️ Great Tracking!'),
          content: Text('You caught $_score out of 10 targets!'),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else {
      _moveTarget();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Visual Tracker ($_round/10)')),
      body: Stack(
        children: [
          // Instructions
          const Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text('Tap the star as fast as you can!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
          // Score
          Positioned(
            top: 56,
            left: 0,
            right: 0,
            child: Center(
              child: Text('Score: $_score',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ),
          ),
          // Target
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: MediaQuery.of(context).size.width * _targetX - 25,
            top: (MediaQuery.of(context).size.height * 0.6) * _targetY + 80,
            child: GestureDetector(
              onTap: _onTap,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Text('⭐', style: TextStyle(fontSize: 28)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
