import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_session_model.dart';
import '../../../services/firebase_service.dart';

class DragSortGameScreen extends StatefulWidget {
  const DragSortGameScreen({super.key});

  @override
  State<DragSortGameScreen> createState() => _DragSortGameScreenState();
}

class _DragSortGameScreenState extends State<DragSortGameScreen> {
  final _firebaseService = FirebaseService();

  // Levels: 2 categories up to 4 categories
  int _level = 1;
  late Map<String, List<String>> _currentCategories;
  late List<String> _itemsToSort;
  final Map<String, List<String>> _sortedItems = {};

  int _moves = 0;
  int _wrongMoves = 0;
  int _secondsElapsed = 0;
  Timer? _timer;

  final Map<String, List<String>> _allCategories = {
    '🍎 Fruits': ['🍎', '🍌', '🍇', '🍓', '🍊', '🍉'],
    '🐾 Animals': ['🐶', '🐱', '🐸', '🦁', '🐮', '🐘'],
    '🚙 Vehicles': ['🚗', '🚕', '🚓', '🚑', '🚒', '🚜'],
    '⚽ Sports': ['⚽', '🏀', '🏈', '⚾', '🎾', '🏐'],
  };

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    _secondsElapsed = 0;
    _moves = 0;
    _wrongMoves = 0;
    _sortedItems.clear();

    // Determine number of categories based on level
    final numCategories = _level == 1 ? 2 : (_level == 2 ? 3 : 4);

    // Pick categories
    final availableKeys = _allCategories.keys.toList()..shuffle();
    final selectedKeys = availableKeys.take(numCategories).toList();

    _currentCategories = {};
    _itemsToSort = [];

    for (final key in selectedKeys) {
      _currentCategories[key] =
          _allCategories[key]!.take(4).toList(); // 4 items per category
      _itemsToSort.addAll(_currentCategories[key]!);
      _sortedItems[key] = [];
    }

    _itemsToSort.shuffle();

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
      gameType: 'drag_and_sort',
      skillCategory: 'Motor Skills',
      difficultyLevel: 'Level $_level',
      score: _itemsToSort.length * 2, // Arbitrary scoring metric
      maxScore: _itemsToSort.length * 2,
      totalMoves: _moves,
      durationSeconds: _secondsElapsed,
      completedAt: DateTime.now(),
      additionalMetrics: {'wrong_moves': _wrongMoves},
    );
    await _firebaseService.logGameSession(session);
  }

  void _checkLevelComplete() {
    if (_itemsToSort.isEmpty) {
      _timer?.cancel();
      _logGameSession().then((_) => _showWin());
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
                  'Perfect Sorting!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            content: Text(
              'You sorted everything in $_moves moves!',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drag & Sort - L$_level'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Moves: $_moves',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Drag items to their matching category!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Unsorted Items Area (Draggables)
              Container(
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children:
                        _itemsToSort.map((item) {
                          return Draggable<String>(
                            data: item,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 56),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.2,
                              child: _ItemChip(emoji: item),
                            ),
                            onDragStarted: () => setState(() => _moves++),
                            child: _ItemChip(emoji: item),
                          );
                        }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Icon(
                Icons.arrow_downward_rounded,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),

              // Drop Targets (Categories)
              Expanded(
                child: Row(
                  children:
                      _currentCategories.keys.map((catString) {
                        final split = catString.split(' ');
                        final iconStr = split[0];
                        final nameStr = split.sublist(1).join(' ');

                        return Expanded(
                          child: DragTarget<String>(
                            onWillAcceptWithDetails: (details) {
                              return true; // We accept everything, but handle correctness in onAccept
                            },
                            onAcceptWithDetails: (details) {
                              final droppedItem = details.data;
                              final isCorrect = _currentCategories[catString]!
                                  .contains(droppedItem);

                              setState(() {
                                if (isCorrect) {
                                  _itemsToSort.remove(droppedItem);
                                  _sortedItems[catString]!.add(droppedItem);
                                  _checkLevelComplete();
                                } else {
                                  _wrongMoves++;
                                  // Show brief error visual if you wanted, but it naturally snaps back
                                }
                              });
                            },
                            builder: (context, candidateItems, rejectedItems) {
                              final isHovered = candidateItems.isNotEmpty;

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      isHovered
                                          ? AppColors.primary.withValues(
                                            alpha: 0.15,
                                          )
                                          : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color:
                                        isHovered
                                            ? AppColors.primary
                                            : AppColors.divider,
                                    width: isHovered ? 3 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      iconStr,
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      nameStr,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Divider(height: 24),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          alignment: WrapAlignment.center,
                                          children:
                                              (_sortedItems[catString] ?? [])
                                                  .map(
                                                    (e) => Text(
                                                      e,
                                                      style: const TextStyle(
                                                        fontSize: 28,
                                                      ),
                                                    ).animate().scale(
                                                      curve: Curves.elasticOut,
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 40)),
    );
  }
}
