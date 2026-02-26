import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Daily Plan screen — personalized timeline of today's activities.
/// Shows activities with status (pending/done/skipped), timing, and actions.
class DailyPlanScreen extends StatefulWidget {
  const DailyPlanScreen({super.key});

  @override
  State<DailyPlanScreen> createState() => _DailyPlanScreenState();
}

class _DailyPlanScreenState extends State<DailyPlanScreen> {
  final List<_PlanActivity> _activities = _sampleActivities();

  int get _completedCount =>
      _activities.where((a) => a.status == _Status.completed).length;
  double get _adherencePercent =>
      _activities.isEmpty ? 0 : _completedCount / _activities.length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Plan'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('AI plan regeneration — coming soon!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Regenerate Plan',
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Adherence Card ──────────────────────────
          _buildAdherenceCard(isDark),

          // ─── Timeline ────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                return _ActivityTimelineCard(
                  activity: _activities[index],
                  isFirst: index == 0,
                  isLast: index == _activities.length - 1,
                  onStart: () => _updateStatus(index, _Status.inProgress),
                  onComplete: () => _updateStatus(index, _Status.completed),
                  onSkip: () => _updateStatus(index, _Status.skipped),
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(int index, _Status status) {
    setState(() => _activities[index].status = status);
  }

  Widget _buildAdherenceCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
            AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _adherencePercent,
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.surfaceVariant,
                  color: AppColors.accent,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '${(_adherencePercent * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_completedCount of ${_activities.length} activities done',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _adherencePercent >= 0.8
                      ? 'Amazing progress today! 🌟'
                      : _adherencePercent >= 0.5
                          ? 'Keep going, you\'re doing great! 💪'
                          : 'Every small step counts! ❤️',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ═══════════════════════════════════════════════════════════════
// TIMELINE ACTIVITY CARD
// ═══════════════════════════════════════════════════════════════

class _ActivityTimelineCard extends StatelessWidget {
  final _PlanActivity activity;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final int index;

  const _ActivityTimelineCard({
    required this.activity,
    required this.isFirst,
    required this.isLast,
    required this.onStart,
    required this.onComplete,
    required this.onSkip,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 8,
                    color: _statusColor.withValues(alpha: 0.3),
                  ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: activity.status == _Status.completed
                        ? _statusColor
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _statusColor,
                      width: 2.5,
                    ),
                  ),
                  child: activity.status == _Status.completed
                      ? const Icon(Icons.check, color: Colors.white, size: 8)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _statusColor.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),

          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardBackground
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: activity.status == _Status.inProgress
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : (isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.2)
                          : AppColors.divider.withValues(alpha: 0.5)),
                  width: activity.status == _Status.inProgress ? 1.5 : 1,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: activity.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(activity.icon,
                            color: activity.color, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration:
                                        activity.status == _Status.skipped
                                            ? TextDecoration.lineThrough
                                            : null,
                                  ),
                            ),
                            Text(
                              '${activity.time} · ${activity.duration} min',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(status: activity.status),
                    ],
                  ),

                  // Actions
                  if (activity.status == _Status.pending ||
                      activity.status == _Status.inProgress) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (activity.status == _Status.pending)
                          _ActionButton(
                            label: 'Start',
                            icon: Icons.play_arrow_rounded,
                            color: AppColors.primary,
                            onTap: onStart,
                          ),
                        if (activity.status == _Status.inProgress)
                          _ActionButton(
                            label: 'Complete',
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                            onTap: onComplete,
                          ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          label: 'Skip',
                          icon: Icons.skip_next_rounded,
                          color: AppColors.textTertiary,
                          onTap: onSkip,
                          outlined: true,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 80 * index),
          duration: 400.ms,
        );
  }

  Color get _statusColor {
    switch (activity.status) {
      case _Status.completed:
        return AppColors.success;
      case _Status.inProgress:
        return AppColors.primary;
      case _Status.skipped:
        return AppColors.textTertiary;
      case _Status.pending:
        return AppColors.divider;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _Status status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bgColor) = switch (status) {
      _Status.completed => ('Done', AppColors.success, AppColors.successLight),
      _Status.inProgress => ('Active', AppColors.primary, AppColors.primarySurface),
      _Status.skipped => ('Skipped', AppColors.textTertiary, AppColors.surfaceVariant),
      _Status.pending => ('Pending', AppColors.textTertiary, AppColors.surfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
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

// ─── Data ──────────────────────────────────────────

enum _Status { pending, inProgress, completed, skipped }

class _PlanActivity {
  final String title;
  final String time;
  final int duration;
  final IconData icon;
  final Color color;
  _Status status;

  _PlanActivity({
    required this.title,
    required this.time,
    required this.duration,
    required this.icon,
    required this.color,
    this.status = _Status.pending,
  });
}

List<_PlanActivity> _sampleActivities() => [
      _PlanActivity(
        title: 'Morning Greeting Practice',
        time: '9:00 AM',
        duration: 10,
        icon: Icons.chat_bubble_rounded,
        color: AppColors.primary,
        status: _Status.completed,
      ),
      _PlanActivity(
        title: 'Texture Exploration Box',
        time: '9:30 AM',
        duration: 15,
        icon: Icons.sensors_rounded,
        color: AppColors.purple,
        status: _Status.completed,
      ),
      _PlanActivity(
        title: 'Block Stacking Challenge',
        time: '10:00 AM',
        duration: 10,
        icon: Icons.accessibility_new_rounded,
        color: AppColors.accent,
        status: _Status.inProgress,
      ),
      _PlanActivity(
        title: 'Rest & Free Play',
        time: '10:30 AM',
        duration: 20,
        icon: Icons.self_improvement_rounded,
        color: const Color(0xFF10B981),
      ),
      _PlanActivity(
        title: 'Memory Match Game',
        time: '11:00 AM',
        duration: 10,
        icon: Icons.extension_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _PlanActivity(
        title: 'Emotion Matching Activity',
        time: '11:30 AM',
        duration: 12,
        icon: Icons.emoji_emotions_rounded,
        color: AppColors.secondary,
      ),
      _PlanActivity(
        title: 'Breathing Butterfly Exercise',
        time: '12:00 PM',
        duration: 5,
        icon: Icons.spa_rounded,
        color: const Color(0xFFEC4899),
      ),
    ];
