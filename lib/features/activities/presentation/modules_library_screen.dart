import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/therapy_module_model.dart';
import '../../../services/firebase_service.dart';
import 'module_detail_screen.dart';

/// Therapy Modules Library — browse, filter, and search activities.
class ModulesLibraryScreen extends StatefulWidget {
  const ModulesLibraryScreen({super.key});

  @override
  State<ModulesLibraryScreen> createState() => _ModulesLibraryScreenState();
}

class _ModulesLibraryScreenState extends State<ModulesLibraryScreen> {
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';
  String _searchQuery = '';
  bool _showBookmarksOnly = false;
  Set<String> _bookmarkedIds = {};
  final _searchController = TextEditingController();
  final _firebaseService = FirebaseService();

  // Sample categories for filters
  static const _categories = [
    'All',
    'Communication',
    'Motor Skills',
    'Sensory',
    'Cognitive',
    'Social Skills',
    'Behavioral',
  ];

  static const _difficulties = ['All', 'Beginner', 'Easy', 'Medium', 'Hard', 'Expert'];

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final ids = await _firebaseService.getBookmarkedIds();
    if (mounted) setState(() => _bookmarkedIds = ids);
  }

  Future<void> _toggleBookmark(String id) async {
    if (_bookmarkedIds.contains(id)) {
      await _firebaseService.unbookmarkActivity(id);
      setState(() => _bookmarkedIds.remove(id));
    } else {
      await _firebaseService.bookmarkActivity(id);
      setState(() => _bookmarkedIds.add(id));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TherapyModuleModel> get _filteredModules {
    var modules = _sampleModules;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      modules = modules
          .where((m) =>
              m.title.toLowerCase().contains(q) ||
              m.objective.toLowerCase().contains(q))
          .toList();
    }

    if (_selectedCategory != 'All') {
      modules = modules
          .where((m) => m.skillCategory == _selectedCategory)
          .toList();
    }

    if (_selectedDifficulty != 'All') {
      final diffLevel = _difficulties.indexOf(_selectedDifficulty);
      modules =
          modules.where((m) => m.difficultyLevel == diffLevel).toList();
    }

    if (_showBookmarksOnly) {
      modules = modules.where((m) => _bookmarkedIds.contains(m.id)).toList();
    }

    return modules;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredModules;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities & Therapy'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _showBookmarksOnly = !_showBookmarksOnly);
            },
            icon: Icon(
              _showBookmarksOnly
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              color: _showBookmarksOnly ? AppColors.gold : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search activities...',
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.surfaceVariant),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Difficulty filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Text(
                  'Difficulty:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _difficulties.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final diff = _difficulties[index];
                        final isSelected = _selectedDifficulty == diff;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedDifficulty = diff),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.divider),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              diff,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.accent
                                    : (isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.textTertiary),
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${filtered.length} activities found',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Modules list
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final module = filtered[index];
                      return _ModuleCard(
                        module: module,
                        index: index,
                        isBookmarked: _bookmarkedIds.contains(module.id),
                        onBookmark: () => _toggleBookmark(module.id),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ModuleDetailScreen(
                                module: module),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No activities found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MODULE CARD
// ═══════════════════════════════════════════════════════════════

class _ModuleCard extends StatelessWidget {
  final TherapyModuleModel module;
  final int index;
  final bool isBookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.module,
    required this.index,
    required this.isBookmarked,
    required this.onBookmark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Assign colors based on skill category
    final categoryColor = _getCategoryColor(module.skillCategory);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: categoryColor.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: isDark
              ? Border.all(color: AppColors.darkBorder.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _getCategoryIcon(module.skillCategory),
                color: categoryColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.objective,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Tags row
                  Row(
                    children: [
                      _Tag(
                        label: module.skillCategory,
                        color: categoryColor,
                      ),
                      const SizedBox(width: 6),
                      _Tag(
                        label: module.difficultyLabel,
                        color: _getDifficultyColor(module.difficultyLevel),
                      ),
                      const SizedBox(width: 6),
                      _Tag(
                        label: '${module.durationMinutes} min',
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow + Bookmark
            Column(
              children: [
                GestureDetector(
                  onTap: onBookmark,
                  child: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    size: 22,
                    color: isBookmarked ? AppColors.gold : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 50 * index),
          duration: 400.ms,
        );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Communication':
        return AppColors.primary;
      case 'Motor Skills':
        return AppColors.accent;
      case 'Sensory':
        return AppColors.purple;
      case 'Cognitive':
        return const Color(0xFFF59E0B);
      case 'Social Skills':
        return const Color(0xFF10B981);
      case 'Behavioral':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Communication':
        return Icons.chat_bubble_rounded;
      case 'Motor Skills':
        return Icons.accessibility_new_rounded;
      case 'Sensory':
        return Icons.sensors_rounded;
      case 'Cognitive':
        return Icons.psychology_rounded;
      case 'Social Skills':
        return Icons.groups_rounded;
      case 'Behavioral':
        return Icons.emoji_emotions_rounded;
      default:
        return Icons.extension_rounded;
    }
  }

  Color _getDifficultyColor(int level) {
    switch (level) {
      case 1:
        return AppColors.success;
      case 2:
        return const Color(0xFF10B981);
      case 3:
        return AppColors.warning;
      case 4:
        return const Color(0xFFF97316);
      case 5:
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SAMPLE DATA (will be replaced by Firestore in production)
// ═══════════════════════════════════════════════════════════════
final _sampleModules = [
  TherapyModuleModel(
    id: '1',
    title: 'Picture Card Communication',
    objective: 'Help your child express needs and feelings using picture cards for visual communication support.',
    conditionTypes: ['ASD', 'Speech Delay'],
    ageRange: '3-8',
    skillCategory: 'Communication',
    difficultyLevel: 1,
    materials: ['Picture cards', 'Board or table'],
    instructions: [
      'Lay 4-6 picture cards on the table',
      'Ask your child "What do you want?"',
      'Guide them to point or pick a card',
      'Reinforce by naming the item out loud',
      'Praise their effort warmly',
    ],
    durationMinutes: 10,
    safetyNotes: 'Use age-appropriate images. Avoid scolding for wrong choices.',
  ),
  TherapyModuleModel(
    id: '2',
    title: 'Texture Exploration Box',
    objective: 'Develop sensory tolerance and awareness through guided texture exploration activities.',
    conditionTypes: ['Sensory Processing', 'ASD'],
    ageRange: '2-6',
    skillCategory: 'Sensory',
    difficultyLevel: 2,
    materials: ['Soft cloth', 'Sand', 'Rice', 'Slime', 'Container'],
    instructions: [
      'Place materials in separate containers',
      'Let the child observe first',
      'Encourage gentle touching of each material',
      'Name the textures: "This is soft", "This is grainy"',
      'Never force contact — let the child lead',
    ],
    durationMinutes: 15,
    safetyNotes: 'Watch for signs of distress. Stop if overwhelmed. Non-toxic materials only.',
  ),
  TherapyModuleModel(
    id: '3',
    title: 'Block Stacking Challenge',
    objective: 'Improve fine motor control, hand-eye coordination and spatial awareness through block stacking.',
    conditionTypes: ['Cerebral Palsy', 'Motor Delay'],
    ageRange: '2-7',
    skillCategory: 'Motor Skills',
    difficultyLevel: 1,
    materials: ['Large blocks (soft or wooden)', 'Flat surface'],
    instructions: [
      'Start with 2 large blocks',
      'Demonstrate stacking slowly',
      'Guide the child\'s hand if needed',
      'Gradually add more blocks',
      'Celebrate each small success',
    ],
    durationMinutes: 10,
    safetyNotes: 'Use soft blocks for children with limited grip. Supervise closely.',
  ),
  TherapyModuleModel(
    id: '4',
    title: 'Emotion Matching Game',
    objective: 'Help children recognize and label different emotions through a fun matching activity.',
    conditionTypes: ['ASD', 'ADHD', 'Learning Disability'],
    ageRange: '4-10',
    skillCategory: 'Social Skills',
    difficultyLevel: 2,
    materials: ['Emotion flashcards', 'Mirror (optional)'],
    instructions: [
      'Show an emotion face card (happy, sad, angry)',
      'Name the emotion clearly',
      'Ask: "Can you make this face?"',
      'Use a mirror for the child to see their own expression',
      'Match emotions to situations: "When do you feel happy?"',
    ],
    durationMinutes: 12,
    safetyNotes: 'Keep it playful. Don\'t push if the child becomes frustrated.',
  ),
  TherapyModuleModel(
    id: '5',
    title: 'Sound Identification Activity',
    objective: 'Enhance auditory processing and attention by identifying common environmental sounds.',
    conditionTypes: ['ASD', 'ADHD', 'Hearing Processing'],
    ageRange: '3-9',
    skillCategory: 'Cognitive',
    difficultyLevel: 2,
    materials: ['Audio recordings of sounds', 'Picture cards of sound sources'],
    instructions: [
      'Play a familiar sound (dog barking, doorbell)',
      'Ask: "What makes this sound?"',
      'Show matching picture cards',
      'Let the child point to the correct one',
      'Increase complexity with similar sounds',
    ],
    durationMinutes: 10,
    safetyNotes: 'Keep volume comfortable. Watch for sensory overload signs.',
  ),
  TherapyModuleModel(
    id: '6',
    title: 'Turn-Taking Board Game',
    objective: 'Practice taking turns, waiting, and following rules through structured board game play.',
    conditionTypes: ['ASD', 'ADHD'],
    ageRange: '5-12',
    skillCategory: 'Behavioral',
    difficultyLevel: 3,
    materials: ['Simple board game', 'Timer (optional)'],
    instructions: [
      'Choose a simple game with clear turns',
      'Explain the rules with visuals',
      'Use a timer or token to signal "your turn"',
      'Model waiting calmly while others play',
      'Praise good waiting and turn-taking',
    ],
    durationMinutes: 20,
    safetyNotes: 'Adapt rules to child\'s level. Keep games short initially.',
  ),
  TherapyModuleModel(
    id: '7',
    title: 'Breathing Butterfly Exercise',
    objective: 'Teach calming deep breathing techniques using a visual butterfly metaphor.',
    conditionTypes: ['ASD', 'ADHD', 'Anxiety'],
    ageRange: '3-12',
    skillCategory: 'Behavioral',
    difficultyLevel: 1,
    materials: ['Butterfly cutout (optional)'],
    instructions: [
      'Hold hands up like butterfly wings',
      'Breathe in slowly — open "wings" wide',
      'Breathe out slowly — close "wings" gently',
      'Repeat 5 times with the child',
      'Use during calm moments first, then during mild stress',
    ],
    durationMinutes: 5,
    safetyNotes: 'Never force breathing exercises. Make it playful.',
  ),
  TherapyModuleModel(
    id: '8',
    title: 'Finger Painting Expression',
    objective: 'Develop fine motor skills and creative expression through guided finger painting.',
    conditionTypes: ['Motor Delay', 'ASD', 'Down Syndrome'],
    ageRange: '2-8',
    skillCategory: 'Motor Skills',
    difficultyLevel: 1,
    materials: ['Non-toxic finger paints', 'Large paper', 'Apron/old clothes'],
    instructions: [
      'Set up a protected painting area',
      'Demonstrate finger painting strokes',
      'Let the child explore freely',
      'Name colors and shapes they make',
      'Display their artwork proudly',
    ],
    durationMinutes: 15,
    safetyNotes: 'Use non-toxic, washable paints only. Supervise young children closely.',
  ),
];
