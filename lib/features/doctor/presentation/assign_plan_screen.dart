import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../models/therapy_module_model.dart';
import '../../../services/firebase_service.dart';

/// Screen for doctors to assign a specific therapy module to a child's daily plan.
class AssignPlanScreen extends StatefulWidget {
  final String childId;
  final String parentUid;

  const AssignPlanScreen({
    super.key,
    required this.childId,
    required this.parentUid,
  });

  @override
  State<AssignPlanScreen> createState() => _AssignPlanScreenState();
}

class _AssignPlanScreenState extends State<AssignPlanScreen> {
  final _firebaseService = FirebaseService();
  final _notesController = TextEditingController();

  final List<TherapyModuleModel> _modules = _sampleModules;
  bool _isSubmitting = false;

  TherapyModuleModel? _selectedModule;
  int _frequencyDays = 3;

  Future<void> _submitAssignment() async {
    if (_selectedModule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a module first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final assignmentData = {
        'moduleId': _selectedModule!.id,
        'assignedAt': DateTime.now().toIso8601String(),
        'frequencyDays': _frequencyDays,
        'doctorNotes': _notesController.text.trim(),
        'completed': false,
      };

      await _firebaseService.assignActivityToChild(
        widget.parentUid,
        widget.childId,
        assignmentData,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan assigned successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context); // Go back to PatientDetailScreen
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning plan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Assign Therapy Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor:
            isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Module Selection ────────────────────────
            Text(
              '1. Select Module',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TherapyModuleModel>(
                  isExpanded: true,
                  value: _selectedModule,
                  hint: Text(
                    'Choose a therapy module...',
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                    ),
                  ),
                  dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                  items:
                      _modules.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(
                            m.title,
                            style: TextStyle(
                              color:
                                  isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedModule = val);
                  },
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),

            if (_selectedModule != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.doctorPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.doctorPrimary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.doctorPrimary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedModule!.objective,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.doctorPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _tag(_selectedModule!.skillCategory, isDark),
                        const SizedBox(width: 8),
                        _tag('${_selectedModule!.durationMinutes} min', isDark),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1),
            ],

            const SizedBox(height: 32),

            // ─── Frequency ─────────────────────────────
            Text(
              '2. Frequency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'How many days a week should this be practiced?',
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  [1, 2, 3, 4, 5, 6, 7].map((days) {
                    final isSelected = _frequencyDays == days;
                    return GestureDetector(
                      onTap: () => setState(() => _frequencyDays = days),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppGradients.doctor : null,
                          color:
                              isSelected
                                  ? null
                                  : (isDark
                                      ? AppColors.darkSurfaceVariant
                                      : Colors.white),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected
                                    ? Colors.transparent
                                    : (isDark
                                        ? AppColors.darkDivider
                                        : AppColors.divider),
                          ),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: AppColors.doctorPrimary.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                  : [],
                        ),
                        child: Center(
                          child: Text(
                            '$days',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 32),

            // ─── Instructions ──────────────────────────
            Text(
              '3. Special Instructions (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                ),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 4,
                style: TextStyle(
                  color:
                      isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText:
                      'e.g., "Make sure to take breaks if they get overwhelmed..."',
                  hintStyle: TextStyle(
                    color:
                        isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

            const SizedBox(height: 40),

            // ─── Submit Button ─────────────────────────
            SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAssignment,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: _isSubmitting ? null : AppGradients.doctor,
                        color:
                            _isSubmitting
                                ? (isDark
                                    ? AppColors.darkSurfaceVariant
                                    : AppColors.surfaceVariant)
                                : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                                : const Text(
                                  'Assign Plan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 500.ms, duration: 400.ms)
                .slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.doctorPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.doctorPrimary,
        ),
      ),
    );
  }
}

final _sampleModules = [
  TherapyModuleModel(
    id: '1',
    title: 'Picture Card Communication',
    objective:
        'Help your child express needs and feelings using picture cards for visual communication support.',
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
    safetyNotes:
        'Use age-appropriate images. Avoid scolding for wrong choices.',
  ),
  TherapyModuleModel(
    id: '2',
    title: 'Texture Exploration Box',
    objective:
        'Develop sensory tolerance and awareness through guided texture exploration activities.',
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
    safetyNotes:
        'Watch for signs of distress. Stop if overwhelmed. Non-toxic materials only.',
  ),
  TherapyModuleModel(
    id: '3',
    title: 'Block Stacking Challenge',
    objective:
        'Improve fine motor control, hand-eye coordination and spatial awareness through block stacking.',
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
    safetyNotes:
        'Use soft blocks for children with limited grip. Supervise closely.',
  ),
  TherapyModuleModel(
    id: '4',
    title: 'Emotion Matching Game',
    objective:
        'Help children recognize and label different emotions through a fun matching activity.',
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
    safetyNotes:
        'Keep it playful. Don\'t push if the child becomes frustrated.',
  ),
];
