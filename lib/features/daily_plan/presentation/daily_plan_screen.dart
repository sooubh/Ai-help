import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/firebase_service.dart';
import '../../../services/cloud_functions_service.dart';
import '../../../services/cache/smart_data_repository.dart';
import 'package:provider/provider.dart';
import '../../../models/child_profile_model.dart';
import 'package:intl/intl.dart';

/// Daily Plan screen — loads plans for any day with full CRUD capabilities.
/// Features: day picker, add/edit/delete activities, future scheduling.
class DailyPlanScreen extends StatefulWidget {
  const DailyPlanScreen({super.key});

  @override
  State<DailyPlanScreen> createState() => _DailyPlanScreenState();
}

class _DailyPlanScreenState extends State<DailyPlanScreen> {
  final _firebaseService = FirebaseService();
  final _cloudFunctionsService = CloudFunctionsService();
  List<_PlanActivity> _activities = [];
  bool _isLoading = true;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadPlan();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String get _todayKey => _dateKey(_selectedDate);

  int get _completedCount =>
      _activities.where((a) => a.status == _Status.completed).length;
  double get _adherencePercent =>
      _activities.isEmpty ? 0 : _completedCount / _activities.length;

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _isLoading = true;
    });
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final repository = context.read<SmartDataRepository>();
      final uid = _firebaseService.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");

      final saved = await repository.getDailyPlan(uid, _todayKey);
      if (saved != null && saved.isNotEmpty) {
        // Load from Firestore
        if (mounted) {
          setState(() {
            _activities = saved.map((a) => _PlanActivity.fromMap(a)).toList();
            _isLoading = false;
          });
        }
      } else {
        // Auto-generate only for today, empty for future dates
        if (_dateKey(_selectedDate) == _dateKey(DateTime.now())) {
          await _generatePlan();
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (_dateKey(_selectedDate) == _dateKey(DateTime.now())) {
        await _generatePlan();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generatePlan() async {
    final repository = context.read<SmartDataRepository>();
    final uid = _firebaseService.currentUser?.uid;
    ChildProfileModel? profile;
    if (uid != null) {
      final profiles = await repository.getChildProfiles(uid);
      if (profiles.isNotEmpty) profile = profiles.first;
    }
    
    final childId = profile?.id;

    if (childId != null) {
      try {
        // Attempt generation via Cloud Function Backend
        final backendPlan = await _cloudFunctionsService.generateDailyPlan(
          childId,
        );

        if (backendPlan != null && backendPlan.isNotEmpty) {
          if (mounted) {
            setState(() {
              _activities =
                  backendPlan
                      .map(
                        (data) => _PlanActivity(
                          title: data['title'] ?? 'Therapy Activity',
                          time: data['time'] ?? 'Flexible',
                          duration: data['duration'] ?? 15,
                          icon: Icons.star_rounded,
                          color: AppColors.primary,
                        ),
                      )
                      .toList();
              _isLoading = false;
            });
          }
          await _savePlan();
          return;
        }
      } catch (_) {
        // If Cloud Function fails, fall through to local generation
      }
    }

    // Generate activities based on child profile (fallback)
    final conditions = profile?.conditions ?? [];

    final generated = <_PlanActivity>[];
    var hour = 9;

    // Communication activity
    generated.add(
      _PlanActivity(
        title: 'Morning Greeting Practice',
        time: '$hour:00 AM',
        duration: 10,
        icon: Icons.chat_bubble_rounded,
        color: AppColors.primary,
      ),
    );
    hour++;

    // Condition-specific activities
    if (conditions.any(
      (c) =>
          c.toLowerCase().contains('asd') || c.toLowerCase().contains('autism'),
    )) {
      generated.add(
        _PlanActivity(
          title: 'Sensory Exploration Box',
          time:
              '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? 'PM' : 'AM'}',
          duration: 15,
          icon: Icons.sensors_rounded,
          color: AppColors.purple,
        ),
      );
      hour++;
    }

    if (conditions.any((c) => c.toLowerCase().contains('adhd'))) {
      generated.add(
        _PlanActivity(
          title: 'Focus & Attention Exercise',
          time:
              '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? 'PM' : 'AM'}',
          duration: 10,
          icon: Icons.psychology_rounded,
          color: const Color(0xFFF59E0B),
        ),
      );
      hour++;
    }

    // Motor skills
    generated.add(
      _PlanActivity(
        title: 'Block Stacking Challenge',
        time: '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? 'PM' : 'AM'}',
        duration: 10,
        icon: Icons.accessibility_new_rounded,
        color: AppColors.accent,
      ),
    );
    hour++;

    // Rest
    generated.add(
      _PlanActivity(
        title: 'Rest & Free Play',
        time: '${hour > 12 ? hour - 12 : hour}:30 ${hour >= 12 ? 'PM' : 'AM'}',
        duration: 20,
        icon: Icons.self_improvement_rounded,
        color: const Color(0xFF10B981),
      ),
    );
    hour++;

    // Game
    generated.add(
      _PlanActivity(
        title: 'Memory Match Game',
        time: '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? 'PM' : 'AM'}',
        duration: 10,
        icon: Icons.extension_rounded,
        color: const Color(0xFFF59E0B),
      ),
    );
    hour++;

    // Emotion
    generated.add(
      _PlanActivity(
        title: 'Emotion Matching Activity',
        time: '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? 'PM' : 'AM'}',
        duration: 12,
        icon: Icons.emoji_emotions_rounded,
        color: AppColors.secondary,
      ),
    );
    hour++;

    // Calming
    generated.add(
      _PlanActivity(
        title: 'Breathing Butterfly Exercise',
        time: '${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? 'PM' : 'AM'}',
        duration: 5,
        icon: Icons.spa_rounded,
        color: const Color(0xFFEC4899),
      ),
    );

    setState(() {
      _activities = generated;
      _isLoading = false;
    });

    // Save to Firestore
    await _savePlan();
  }

  Future<void> _savePlan() async {
    final data = _activities.map((a) => a.toMap()).toList();
    await _firebaseService.saveDailyPlan(_todayKey, data);
  }

  void _updateStatus(int index, _Status status) {
    setState(() => _activities[index].status = status);
    _savePlan();
  }

  Future<void> _addActivity(_PlanActivity activity) async {
    setState(() => _activities.add(activity));
    await _savePlan();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity added! ✅'), backgroundColor: AppColors.success),
    );
  }

  Future<void> _updateActivity(int index, _PlanActivity activity) async {
    setState(() => _activities[index] = activity);
    await _savePlan();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity updated! ✏️'), backgroundColor: AppColors.primary),
    );
  }

  Future<void> _deleteActivity(int index) async {
    setState(() => _activities.removeAt(index));
    await _savePlan();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity removed! 🗑️'), backgroundColor: AppColors.textTertiary),
    );
  }

  void _showAddActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddActivityDialog(
        onAdd: _addActivity,
        selectedDate: _selectedDate,
      ),
    );
  }

  void _showEditActivityDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => _EditActivityDialog(
        activity: _activities[index],
        onUpdate: (activity) => _updateActivity(index, activity),
        onDelete: () {
          Navigator.pop(context);
          _deleteActivity(index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = _dateKey(_selectedDate) == _dateKey(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(isToday ? 'Today\'s Plan' : 'Plan for ${DateFormat('MMM dd').format(_selectedDate)}'),
        elevation: 0,
        actions: [
          if (isToday)
            IconButton(
              onPressed: () async {
                setState(() => _isLoading = true);
                await _generatePlan();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Plan regenerated! ✨'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Regenerate Plan',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
            children: [
              // ─── Day Picker ──────────────────────────────
              _buildDayPicker(isDark),

              // ─── Adherence Card ──────────────────────────
              _buildAdherenceCard(isDark),

              // ─── Timeline ────────────────────────────────
              Expanded(
                child: _activities.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 64,
                            color: AppColors.textTertiary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No activities planned for this day',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showAddActivityDialog,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Activity'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        return _ActivityTimelineCard(
                          activity: _activities[index],
                          isFirst: index == 0,
                          isLast: index == _activities.length - 1,
                          onStart:
                              () => _updateStatus(index, _Status.inProgress),
                          onComplete:
                              () => _updateStatus(index, _Status.completed),
                          onSkip: () => _updateStatus(index, _Status.skipped),
                          onEdit: () => _showEditActivityDialog(index),
                          index: index,
                        );
                      },
                    ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddActivityDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildDayPicker(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(
          14,
          (i) {
            final date = DateTime.now().add(Duration(days: i - (DateTime.now().weekday - 1)));
            final isSelected = _dateKey(date) == _dateKey(_selectedDate);
            final isToday = _dateKey(date) == _dateKey(DateTime.now());

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => _selectDate(date),
                child: Container(
                  width: 60,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkCardBackground
                            : AppColors.cardBackground),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0)
                          : (isDark
                              ? AppColors.darkBorder.withValues(alpha: 0.3)
                              : AppColors.divider.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('E').format(date),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d').format(date),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (isToday)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _adherencePercent,
                  backgroundColor:
                      isDark
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
  final VoidCallback onEdit;
  final int index;

  const _ActivityTimelineCard({
    required this.activity,
    required this.isFirst,
    required this.isLast,
    required this.onStart,
    required this.onComplete,
    required this.onSkip,
    required this.onEdit,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    color:
                        activity.status == _Status.completed
                            ? _statusColor
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: _statusColor, width: 2.5),
                  ),
                  child:
                      activity.status == _Status.completed
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 8,
                          )
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
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.darkCardBackground
                        : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      activity.status == _Status.inProgress
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : (isDark
                              ? AppColors.darkBorder.withValues(alpha: 0.2)
                              : AppColors.divider.withValues(alpha: 0.5)),
                  width: activity.status == _Status.inProgress ? 1.5 : 1,
                ),
                boxShadow:
                    isDark
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
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: activity.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          activity.icon,
                          color: activity.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
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
                        const SizedBox(width: 8),
                        _ActionButton(
                          label: 'Edit',
                          icon: Icons.edit_rounded,
                          color: AppColors.secondary,
                          onTap: onEdit,
                          outlined: true,
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ActionButton(
                          label: 'Edit',
                          icon: Icons.edit_rounded,
                          color: AppColors.secondary,
                          onTap: onEdit,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      _Status.inProgress => (
        'Active',
        AppColors.primary,
        AppColors.primarySurface,
      ),
      _Status.skipped => (
        'Skipped',
        AppColors.textTertiary,
        AppColors.surfaceVariant,
      ),
      _Status.pending => (
        'Pending',
        AppColors.textTertiary,
        AppColors.surfaceVariant,
      ),
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

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'time': time,
      'duration': duration,
      'iconCode': icon.codePoint,
      'colorValue': color.toARGB32(),
      'status': status.name,
    };
  }

  factory _PlanActivity.fromMap(Map<String, dynamic> map) {
    return _PlanActivity(
      title: map['title'] ?? '',
      time: map['time'] ?? '',
      duration: map['duration'] ?? 10,
      icon: _getIconFromCode(map['iconCode']),
      color: Color(map['colorValue'] ?? AppColors.primary.toARGB32()),
      status: _Status.values.firstWhere(
        (s) => s.name == (map['status'] ?? 'pending'),
        orElse: () => _Status.pending,
      ),
    );
  }

  static IconData _getIconFromCode(int? code) {
    if (code == null) return Icons.extension_rounded;

    // Mapping common icon code points to constant IconData for tree-shaking
    if (code == Icons.chat_bubble_rounded.codePoint) {
      return Icons.chat_bubble_rounded;
    }
    if (code == Icons.star_rounded.codePoint) {
      return Icons.star_rounded;
    }
    if (code == Icons.extension_rounded.codePoint) {
      return Icons.extension_rounded;
    }
    if (code == Icons.fitness_center_rounded.codePoint) {
      return Icons.fitness_center_rounded;
    }
    if (code == Icons.brush_rounded.codePoint) {
      return Icons.brush_rounded;
    }
    if (code == Icons.music_note_rounded.codePoint) {
      return Icons.music_note_rounded;
    }
    if (code == Icons.self_improvement_rounded.codePoint) {
      return Icons.self_improvement_rounded;
    }
    if (code == Icons.psychology_rounded.codePoint) {
      return Icons.psychology_rounded;
    }

    // If we can't find a constant match, we MUST return a constant default to support tree-shaking
    return Icons.extension_rounded;
  }
}

// ═══════════════════════════════════════════════════════════════
// ADD ACTIVITY DIALOG
// ═══════════════════════════════════════════════════════════════

class _AddActivityDialog extends StatefulWidget {
  final Function(_PlanActivity) onAdd;
  final DateTime selectedDate;

  const _AddActivityDialog({
    required this.onAdd,
    required this.selectedDate,
  });

  @override
  State<_AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<_AddActivityDialog> {
  late TextEditingController _titleController;
  late TextEditingController _timeController;
  int _duration = 15;
  late IconData _selectedIcon;
  late Color _selectedColor;

  final List<(IconData, String)> _availableIcons = [
    (Icons.chat_bubble_rounded, 'Communication'),
    (Icons.sensors_rounded, 'Sensory'),
    (Icons.psychology_rounded, 'Focus'),
    (Icons.accessibility_new_rounded, 'Motor'),
    (Icons.self_improvement_rounded, 'Rest'),
    (Icons.extension_rounded, 'Activity'),
    (Icons.emoji_emotions_rounded, 'Emotion'),
    (Icons.spa_rounded, 'Calm'),
  ];

  final List<(Color, String)> _availableColors = [
    (AppColors.primary, 'Blue'),
    (AppColors.secondary, 'Purple'),
    (AppColors.accent, 'Orange'),
    (const Color(0xFF10B981), 'Green'),
    (const Color(0xFFEC4899), 'Pink'),
    (AppColors.success, 'Green'),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    final now = DateTime.now();
    _timeController = TextEditingController(
      text: '${(now.hour + 1).toString().padLeft(2, '0')}:00 ${now.hour >= 11 ? 'PM' : 'AM'}',
    );
    _selectedIcon = Icons.star_rounded;
    _selectedColor = AppColors.primary;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _saveActivity() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter activity title')),
      );
      return;
    }

    final activity = _PlanActivity(
      title: _titleController.text,
      time: _timeController.text,
      duration: _duration,
      icon: _selectedIcon,
      color: _selectedColor,
    );

    Navigator.pop(context);
    widget.onAdd(activity);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Add New Activity'),
      contentPadding: const EdgeInsets.all(16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Activity Title',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g., Ball Play, Reading Time',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),

            // Time
            Text(
              'Time',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                hintText: '10:00 AM',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),

            // Duration
            Text(
              'Duration: $_duration minutes',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Slider(
              value: _duration.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              onChanged: (value) => setState(() => _duration = value.toInt()),
              label: '$_duration min',
            ),
            const SizedBox(height: 16),

            // Icon
            Text(
              'Icon',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableIcons.map((entry) {
                final (icon, label) = entry;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Tooltip(
                    message: label,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _selectedIcon == icon
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : (isDark
                                ? AppColors.darkCardBackground
                                : AppColors.surfaceVariant),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedIcon == icon
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(icon, color: AppColors.primary),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Color
            Text(
              'Color',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableColors.map((entry) {
                final (color, label) = entry;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Tooltip(
                    message: label,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color
                              ? Colors.white
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveActivity,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add Activity'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EDIT ACTIVITY DIALOG
// ═══════════════════════════════════════════════════════════════

class _EditActivityDialog extends StatefulWidget {
  final _PlanActivity activity;
  final Function(_PlanActivity) onUpdate;
  final VoidCallback onDelete;

  const _EditActivityDialog({
    required this.activity,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_EditActivityDialog> createState() => _EditActivityDialogState();
}

class _EditActivityDialogState extends State<_EditActivityDialog> {
  late TextEditingController _titleController;
  late TextEditingController _timeController;
  late int _duration;
  late IconData _selectedIcon;
  late Color _selectedColor;

  final List<(IconData, String)> _availableIcons = [
    (Icons.chat_bubble_rounded, 'Communication'),
    (Icons.sensors_rounded, 'Sensory'),
    (Icons.psychology_rounded, 'Focus'),
    (Icons.accessibility_new_rounded, 'Motor'),
    (Icons.self_improvement_rounded, 'Rest'),
    (Icons.extension_rounded, 'Activity'),
    (Icons.emoji_emotions_rounded, 'Emotion'),
    (Icons.spa_rounded, 'Calm'),
  ];

  final List<(Color, String)> _availableColors = [
    (AppColors.primary, 'Blue'),
    (AppColors.secondary, 'Purple'),
    (AppColors.accent, 'Orange'),
    (const Color(0xFF10B981), 'Green'),
    (const Color(0xFFEC4899), 'Pink'),
    (AppColors.success, 'Green'),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.activity.title);
    _timeController = TextEditingController(text: widget.activity.time);
    _duration = widget.activity.duration;
    _selectedIcon = widget.activity.icon;
    _selectedColor = widget.activity.color;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _updateActivity() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter activity title')),
      );
      return;
    }

    final activity = _PlanActivity(
      title: _titleController.text,
      time: _timeController.text,
      duration: _duration,
      icon: _selectedIcon,
      color: _selectedColor,
      status: widget.activity.status,
    );

    Navigator.pop(context);
    widget.onUpdate(activity);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Edit Activity'),
      contentPadding: const EdgeInsets.all(16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Activity Title',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),

            // Time
            Text(
              'Time',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),

            // Duration
            Text(
              'Duration: $_duration minutes',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Slider(
              value: _duration.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              onChanged: (value) => setState(() => _duration = value.toInt()),
              label: '$_duration min',
            ),
            const SizedBox(height: 16),

            // Icon
            Text(
              'Icon',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableIcons.map((entry) {
                final (icon, label) = entry;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Tooltip(
                    message: label,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _selectedIcon == icon
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : (isDark
                                ? AppColors.darkCardBackground
                                : AppColors.surfaceVariant),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedIcon == icon
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(icon, color: AppColors.primary),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Color
            Text(
              'Color',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableColors.map((entry) {
                final (color, label) = entry;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Tooltip(
                    message: label,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color
                              ? Colors.white
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onDelete();
          },
          child: const Text(
            'Delete',
            style: TextStyle(color: Colors.red),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _updateActivity,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Update'),
        ),
      ],
    );
  }
}
