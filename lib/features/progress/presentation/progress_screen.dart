import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/firebase_service.dart';
import '../../../services/cache/smart_data_repository.dart';
import 'package:provider/provider.dart';
import '../../../models/activity_log_model.dart';

/// Progress tracking screen — real-time data from Firestore.
/// Shows weekly stats, skill progress, activity history, milestones, weekly trend.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _firebaseService = FirebaseService();
  bool _isLoading = true;

  // Real data from Firestore
  Map<String, dynamic> _weeklyStats = {'count': 0, 'minutes': 0, 'streak': 0};
  Map<String, double> _skillProgress = {};
  List<ActivityLogModel> _activityLogs = [];
  List<Map<String, dynamic>> _milestones = [];
  List<int> _dailyCounts = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repository = context.read<SmartDataRepository>();
      final uid = _firebaseService.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      
      final dashboard = await repository.getDashboardData(uid);
      final logs = await _firebaseService.getActivityLogs(limit: 5);
      final milestones = await _firebaseService.getMilestones();

      if (mounted) {
        setState(() {
          _weeklyStats = dashboard['weeklyStats'] ?? {'count': 0, 'minutes': 0, 'streak': 0};
          _skillProgress = Map<String, double>.from(dashboard['skillProgress'] ?? {});
          _activityLogs = logs;
          _milestones = milestones;
          _dailyCounts = List<int>.from(dashboard['dailyActivityCounts'] ?? List.filled(7, 0));
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            onPressed: () {
              final report = _generateReport();
              Clipboard.setData(ClipboardData(text: report));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Progress report copied to clipboard! 📊'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.share_rounded, size: 22),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Weekly Summary Card ───────────────────
                      _buildWeeklySummary(context, isDark),
                      const SizedBox(height: 20),

                      // ─── Skill Progress Rings ──────────────────
                      _sectionTitle(context, 'Skill Progress'),
                      const SizedBox(height: 12),
                      _buildSkillRings(context, isDark),
                      const SizedBox(height: 24),

                      // ─── Activity History ──────────────────────
                      _sectionTitle(context, 'Recent Activities'),
                      const SizedBox(height: 12),
                      _buildActivityHistory(context, isDark),
                      const SizedBox(height: 24),

                      // ─── Milestones ────────────────────────────
                      _sectionTitle(context, 'Milestones Achieved'),
                      const SizedBox(height: 12),
                      _buildMilestones(context, isDark),
                      const SizedBox(height: 24),

                      // ─── Weekly Trend ──────────────────────────
                      _sectionTitle(context, 'Weekly Activity Trend'),
                      const SizedBox(height: 12),
                      _buildWeeklyTrend(context, isDark),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ).animate().fadeIn(duration: 300.ms);
  }

  String _generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('📊 CARE-AI Progress Report');
    buffer.writeln(
      'Generated: ${DateTime.now().toIso8601String().substring(0, 10)}',
    );
    buffer.writeln('─────────────────────────');
    buffer.writeln();
    buffer.writeln('📈 Weekly Summary');
    buffer.writeln('  Activities Completed: ${_weeklyStats['count']}');
    buffer.writeln('  Total Minutes: ${_weeklyStats['minutes']}');
    buffer.writeln('  Current Streak: ${_weeklyStats['streak']} days');
    buffer.writeln();
    buffer.writeln('🎯 Skill Progress');
    if (_skillProgress.isEmpty) {
      buffer.writeln('  No activities logged yet.');
    }
    for (final entry in _skillProgress.entries) {
      buffer.writeln('  ${entry.key}: ${(entry.value * 100).toInt()}%');
    }
    buffer.writeln();
    buffer.writeln('🏆 Milestones');
    if (_milestones.isEmpty) {
      buffer.writeln('  No milestones yet.');
    }
    for (final m in _milestones) {
      buffer.writeln('  ${m['emoji'] ?? '⭐'} ${m['title'] ?? 'Milestone'}');
    }
    buffer.writeln();
    buffer.writeln('✅ Recent Activities');
    if (_activityLogs.isEmpty) {
      buffer.writeln('  No activities logged yet.');
    }
    for (final log in _activityLogs) {
      final mins = (log.durationSeconds / 60).round();
      buffer.writeln('  ✓ ${log.activityTitle} ($mins min)');
    }
    buffer.writeln();
    buffer.writeln('─────────────────────────');
    buffer.writeln('Generated by CARE-AI • AI Parenting Companion');
    return buffer.toString();
  }

  Widget _buildWeeklySummary(BuildContext context, bool isDark) {
    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5B6EF5), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B6EF5).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'This Week',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    label: 'Activities',
                    value: '${_weeklyStats['count']}',
                    icon: Icons.extension_rounded,
                  ),
                  _SummaryItem(
                    label: 'Minutes',
                    value: '${_weeklyStats['minutes']}',
                    icon: Icons.timer_rounded,
                  ),
                  _SummaryItem(
                    label: 'Streak',
                    value: '${_weeklyStats['streak']} d',
                    icon: Icons.local_fire_department_rounded,
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildSkillRings(BuildContext context, bool isDark) {
    if (_skillProgress.isEmpty) {
      return _buildEmptyState(
        context,
        isDark,
        'Complete activities to see skill progress.',
      );
    }

    final colors = [
      AppColors.primary,
      AppColors.accent,
      const Color(0xFF10B981),
      AppColors.purple,
      const Color(0xFFF59E0B),
    ];

    final entries = _skillProgress.entries.toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children:
          entries.asMap().entries.map((entry) {
            final skill = entry.value;
            final color = colors[entry.key % colors.length];
            return Column(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: skill.value,
                        backgroundColor:
                            isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant,
                        color: color,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                      ),
                      Text(
                        '${(skill.value * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  skill.key.length > 10
                      ? '${skill.key.substring(0, 10)}…'
                      : skill.key,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ).animate().fadeIn(
              delay: Duration(milliseconds: 200 + (entry.key * 100)),
              duration: 400.ms,
            );
          }).toList(),
    );
  }

  Widget _buildActivityHistory(BuildContext context, bool isDark) {
    if (_activityLogs.isEmpty) {
      return _buildEmptyState(
        context,
        isDark,
        'No activities completed yet. Start your first!',
      );
    }

    return Column(
      children:
          _activityLogs.asMap().entries.map((entry) {
            final log = entry.value;
            final mins = (log.durationSeconds / 60).round();
            final ago = _timeAgo(log.completedAt);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.darkCardBackground
                        : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border:
                    isDark
                        ? Border.all(
                          color: AppColors.darkBorder.withValues(alpha: 0.2),
                        )
                        : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.activityTitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Completed • $mins min • $ago',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(
              delay: Duration(milliseconds: 100 * entry.key),
              duration: 300.ms,
            );
          }).toList(),
    );
  }

  Widget _buildMilestones(BuildContext context, bool isDark) {
    if (_milestones.isEmpty) {
      return _buildEmptyState(
        context,
        isDark,
        'Milestones will appear as your child progresses.',
      );
    }

    return Column(
      children:
          _milestones.asMap().entries.map((entry) {
            final milestone = entry.value;
            final title = milestone['title'] ?? 'Milestone';
            final category = milestone['category'] ?? '';
            final emoji = milestone['emoji'] ?? '⭐';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.08),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (category.isNotEmpty)
                          Text(
                            category,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ],
              ),
            ).animate().fadeIn(
              delay: Duration(milliseconds: 200 + (entry.key * 100)),
              duration: 400.ms,
            );
          }).toList(),
    );
  }

  Widget _buildWeeklyTrend(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
    });

    final maxCount =
        _dailyCounts.isEmpty ? 1 : _dailyCounts.reduce((a, b) => a > b ? a : b);
    final maxVal = maxCount == 0 ? 1 : maxCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border:
            isDark
                ? Border.all(color: AppColors.darkBorder.withValues(alpha: 0.2))
                : null,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  days.asMap().entries.map((entry) {
                    final index = entry.key;
                    final value =
                        _dailyCounts.length > index ? _dailyCounts[index] : 0;
                    final normalized = value / maxVal;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (value > 0)
                          Text(
                            '$value',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Container(
                          width: 28,
                          height: (100 * normalized).clamp(4, 100).toDouble(),
                          decoration: BoxDecoration(
                            gradient:
                                value > 0
                                    ? LinearGradient(
                                      colors: [
                                        AppColors.primary.withValues(
                                          alpha: 0.7,
                                        ),
                                        AppColors.primary,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    )
                                    : null,
                            color:
                                value == 0
                                    ? (isDark
                                        ? AppColors.darkSurfaceVariant
                                        : AppColors.surfaceVariant)
                                    : null,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ).animate().fadeIn(
                          delay: Duration(milliseconds: 300 + (index * 60)),
                          duration: 400.ms,
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                days.map((d) {
                  return Text(
                    d,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 11),
                  );
                }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border:
            isDark
                ? Border.all(color: AppColors.darkBorder.withValues(alpha: 0.2))
                : null,
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 36,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }
}

// ─── Data Classes ──────────────────────────────────────────

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
