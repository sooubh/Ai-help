import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/therapy_module_model.dart';
import '../../../models/therapy_session_model.dart';
import '../../../models/child_profile_model.dart';
import '../../../services/firebase_service.dart';
import '../../../services/therapy_ai_service.dart';

/// Generic, reusable therapy activity screen that renders any TherapyModuleModel.
/// Tracks time, score, engagement, and shows AI feedback on completion.
class TherapyActivityScreen extends StatefulWidget {
  final TherapyModuleModel module;
  final ChildProfileModel? childProfile;
  final int? overrideDifficulty;

  const TherapyActivityScreen({
    super.key,
    required this.module,
    this.childProfile,
    this.overrideDifficulty,
  });

  @override
  State<TherapyActivityScreen> createState() => _TherapyActivityScreenState();
}

class _TherapyActivityScreenState extends State<TherapyActivityScreen> {
  int _currentStep = 0;
  int _score = 0;
  int _maxScore = 0;
  bool _isCompleted = false;
  bool _showingFeedback = false;
  Map<String, dynamic>? _aiFeedback;
  late Stopwatch _stopwatch;
  late int _effectiveDifficulty;
  final _firebase = FirebaseService();
  final _therapyAi = TherapyAiService();

  List<String> get _instructions => widget.module.instructions;
  int get _totalSteps => _instructions.length;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _effectiveDifficulty =
        widget.overrideDifficulty ?? widget.module.difficultyLevel;
    _maxScore = _totalSteps * 10; // 10 points per step
    _therapyAi.initialize();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  void _completeStep({bool correct = true}) {
    if (correct) _score += 10;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _finishModule();
    }
  }

  Future<void> _finishModule() async {
    _stopwatch.stop();
    setState(() => _isCompleted = true);

    final accuracy =
        _maxScore > 0 ? (_score / _maxScore * 100) : 0.0;

    final session = TherapySessionModel(
      moduleId: widget.module.id,
      moduleTitle: widget.module.title,
      skillCategory: widget.module.skillCategory,
      difficultyLevel: _effectiveDifficulty,
      score: _score,
      maxScore: _maxScore,
      accuracyPercent: accuracy,
      timeSpentSeconds: _stopwatch.elapsed.inSeconds,
      stepsCompleted: _currentStep + 1,
      totalSteps: _totalSteps,
      engagementRating: _calculateEngagement(),
      completedAt: DateTime.now(),
    );

    // Save session
    try {
      await _firebase.saveTherapySession(
          session, widget.childProfile?.id);
    } catch (_) {}

    // Get AI feedback
    if (widget.childProfile != null) {
      setState(() => _showingFeedback = true);
      try {
        final feedback = await _therapyAi.getPostCompletionFeedback(
          session: session,
          profile: widget.childProfile!,
        );
        setState(() => _aiFeedback = feedback);
      } catch (_) {
        setState(() => _aiFeedback = null);
      }
    }
  }

  int _calculateEngagement() {
    final timePerStep =
        _stopwatch.elapsed.inSeconds / (_currentStep + 1);
    // If completing each step takes a reasonable time (5-60s), engagement is good
    if (timePerStep >= 5 && timePerStep <= 60) return 5;
    if (timePerStep >= 3 && timePerStep <= 90) return 4;
    if (timePerStep >= 2 && timePerStep <= 120) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$_score pts',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isCompleted ? _buildCompletionView(isDark, theme) : _buildActivityView(isDark, theme),
    );
  }

  // ─── ACTIVITY VIEW ──────────────────────────────────────────

  Widget _buildActivityView(bool isDark, ThemeData theme) {
    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: (_currentStep + 1) / _totalSteps,
          backgroundColor:
              isDark ? Colors.white10 : Colors.grey.shade200,
          valueColor:
              AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 4,
        ),

        // Module info header
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.12),
                AppColors.accent.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.module.skillCategory,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _difficultyColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Level $_effectiveDifficulty',
                      style: TextStyle(
                        color: _difficultyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.timer_outlined,
                      size: 16,
                      color: isDark ? Colors.white54 : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.module.durationMinutes} min',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.module.objective,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        // Step counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                    widget.module.difficultyLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _difficultyColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Current instruction
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _instructions[_currentStep],
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.module.materials.isNotEmpty &&
                      _currentStep == 0) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Materials needed:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.module.materials.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(m)),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _currentStep--),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _completeStep(),
                  icon: Icon(_currentStep == _totalSteps - 1
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_rounded),
                  label: Text(_currentStep == _totalSteps - 1
                      ? 'Complete!'
                      : 'Done — Next Step'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── COMPLETION VIEW ────────────────────────────────────────

  Widget _buildCompletionView(bool isDark, ThemeData theme) {
    final accuracy =
        _maxScore > 0 ? (_score / _maxScore * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Celebration icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              accuracy >= 80
                  ? Icons.rocket_launch_rounded
                  : accuracy >= 50
                      ? Icons.emoji_events_rounded
                      : Icons.star_rounded,
              color: Colors.white,
              size: 48,
            ),
          )
              .animate()
              .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut),

          const SizedBox(height: 16),
          Text(
            'Activity Complete! 🎉',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.module.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              _StatCard(
                icon: Icons.stars_rounded,
                label: 'Score',
                value: '$_score/$_maxScore',
                color: AppColors.primary,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.percent_rounded,
                label: 'Accuracy',
                value: '${accuracy.toStringAsFixed(0)}%',
                color: AppColors.accent,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icon: Icons.timer_rounded,
                label: 'Time',
                value: _formatDuration(_stopwatch.elapsed),
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ],
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms),

          const SizedBox(height: 24),

          // AI Feedback section
          if (_showingFeedback && _aiFeedback == null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 12),
                  Text('AI is analyzing your performance...',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),

          if (_aiFeedback != null) _buildAiFeedbackCard(isDark, theme),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Library'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Reset and retry
                    setState(() {
                      _currentStep = 0;
                      _score = 0;
                      _isCompleted = false;
                      _showingFeedback = false;
                      _aiFeedback = null;
                      _stopwatch.reset();
                      _stopwatch.start();
                    });
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiFeedbackCard(bool isDark, ThemeData theme) {
    final feedback = _aiFeedback!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
            AppColors.accent.withValues(alpha: isDark ? 0.1 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Therapy Feedback',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback['feedbackMessage'] ?? 'Great job completing this activity!',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (feedback['strengthsObserved'] != null) ...[
            const SizedBox(height: 12),
            Text('💪 Strengths:',
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            ...(feedback['strengthsObserved'] as List)
                .map((s) => Text('  • $s',
                    style: theme.textTheme.bodySmall)),
          ],
          if (feedback['areasToImprove'] != null) ...[
            const SizedBox(height: 8),
            Text('🌱 Keep working on:',
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            ...(feedback['areasToImprove'] as List)
                .map((s) => Text('  • $s',
                    style: theme.textTheme.bodySmall)),
          ],
          if (feedback['nextActivitySuggestion'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feedback['nextActivitySuggestion'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1);
  }

  Color get _difficultyColor {
    switch (_effectiveDifficulty) {
      case 1:
        return const Color(0xFF10B981);
      case 2:
        return const Color(0xFF3B82F6);
      case 3:
        return const Color(0xFFF59E0B);
      case 4:
        return const Color(0xFFF97316);
      case 5:
        return const Color(0xFFEF4444);
      default:
        return AppColors.primary;
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s}s';
  }
}

// ═══════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
