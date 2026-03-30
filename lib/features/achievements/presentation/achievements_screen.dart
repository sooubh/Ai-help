import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/firebase_service.dart';
import '../../../services/cache/smart_data_repository.dart';
import 'package:provider/provider.dart';
import '../../../models/activity_log_model.dart';

/// Achievements & Badges screen — shows unlockable badges
/// based on real activity log data from Firestore.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _firebaseService = FirebaseService();
  bool _isLoading = true;
  List<ActivityLogModel> _logs = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repository = context.read<SmartDataRepository>();
      final uid = _firebaseService.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");

      final logs = await _firebaseService.getActivityLogs(limit: 200);
      final dashboard = await repository.getDashboardData(uid);
      final stats = dashboard['weeklyStats'] ?? {'count': 0, 'minutes': 0, 'streak': 0};
      
      if (mounted) {
        setState(() {
          _logs = logs;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_Badge> _buildBadges() {
    final totalActivities = _logs.length;
    final streak = _stats['streak'] ?? 0;

    // Unique categories completed
    final categories = <String>{};
    for (final log in _logs) {
      categories.add(log.category);
    }

    // Total minutes
    int totalSeconds = 0;
    for (final log in _logs) {
      totalSeconds += log.durationSeconds;
    }
    final totalMinutes = totalSeconds ~/ 60;

    return [
      _Badge(
        title: 'First Steps',
        description: 'Complete your first activity',
        icon: Icons.baby_changing_station_rounded,
        color: AppColors.primary,
        isUnlocked: totalActivities >= 1,
        progress: totalActivities >= 1 ? 1.0 : 0.0,
      ),
      _Badge(
        title: 'Getting Started',
        description: 'Complete 5 activities',
        icon: Icons.rocket_launch_rounded,
        color: AppColors.accent,
        isUnlocked: totalActivities >= 5,
        progress: (totalActivities / 5).clamp(0.0, 1.0),
      ),
      _Badge(
        title: 'Activity Star',
        description: 'Complete 10 activities',
        icon: Icons.star_rounded,
        color: AppColors.gold,
        isUnlocked: totalActivities >= 10,
        progress: (totalActivities / 10).clamp(0.0, 1.0),
      ),
      _Badge(
        title: 'Superstar',
        description: 'Complete 25 activities',
        icon: Icons.auto_awesome_rounded,
        color: AppColors.purple,
        isUnlocked: totalActivities >= 25,
        progress: (totalActivities / 25).clamp(0.0, 1.0),
      ),
      _Badge(
        title: 'Consistent!',
        description: '3-day streak',
        icon: Icons.local_fire_department_rounded,
        color: AppColors.secondary,
        isUnlocked: streak >= 3,
        progress: (streak / 3).clamp(0.0, 1.0),
      ),
      _Badge(
        title: 'On Fire!',
        description: '7-day streak',
        icon: Icons.whatshot_rounded,
        color: const Color(0xFFF59E0B),
        isUnlocked: streak >= 7,
        progress: (streak / 7).clamp(0.0, 1.0),
      ),
      _Badge(
        title: 'Explorer',
        description: 'Try 3 different skill categories',
        icon: Icons.explore_rounded,
        color: const Color(0xFF0EA5E9),
        isUnlocked: categories.length >= 3,
        progress: (categories.length / 3).clamp(0.0, 1.0),
      ),
      _Badge(
        title: 'Well-Rounded',
        description: 'Try all 5 skill categories',
        icon: Icons.circle_rounded,
        color: const Color(0xFF10B981),
        isUnlocked: categories.length >= 5,
        progress: (categories.length / 5).clamp(0.0, 1.0),
      ),
      _Badge(
        title: 'Dedicated',
        description: 'Spend 30+ minutes on activities',
        icon: Icons.timer_rounded,
        color: AppColors.primary,
        isUnlocked: totalMinutes >= 30,
        progress: (totalMinutes / 30).clamp(0.0, 1.0),
      ),
      _Badge(
        title: 'Marathon',
        description: 'Spend 120+ minutes on activities',
        icon: Icons.emoji_events_rounded,
        color: AppColors.gold,
        isUnlocked: totalMinutes >= 120,
        progress: (totalMinutes / 120).clamp(0.0, 1.0),
      ),
      _Badge(
        title: 'Champion',
        description: 'Complete 50 activities',
        icon: Icons.military_tech_rounded,
        color: const Color(0xFFEF4444),
        isUnlocked: totalActivities >= 50,
        progress: (totalActivities / 50).clamp(0.0, 1.0),
      ),
      _Badge(
        title: 'Legend',
        description: '14-day streak',
        icon: Icons.workspace_premium_rounded,
        color: AppColors.purple,
        isUnlocked: streak >= 14,
        progress: (streak / 14).clamp(0.0, 1.0),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress summary
                    _buildSummaryCard(context, isDark),
                    const SizedBox(height: 24),

                    // Badges grid
                    Text(
                      'Badges',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 12),
                    _buildBadgeGrid(context, isDark),
                  ],
                ),
              ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, bool isDark) {
    final badges = _buildBadges();
    final unlocked = badges.where((b) => b.isUnlocked).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked / ${badges.length} Unlocked',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_logs.length} activities completed · '
                  '${_stats['streak'] ?? 0} day streak',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: badges.isEmpty ? 0 : unlocked / badges.length,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildBadgeGrid(BuildContext context, bool isDark) {
    final badges = _buildBadges();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.78,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeCard(context, badge, isDark, index);
      },
    );
  }

  Widget _buildBadgeCard(
    BuildContext context,
    _Badge badge,
    bool isDark,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: Row(
                  children: [
                    Icon(badge.icon, color: badge.color, size: 24),
                    const SizedBox(width: 8),
                    Expanded(child: Text(badge.title)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(badge.description),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: badge.progress,
                        minHeight: 8,
                        backgroundColor:
                            isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant,
                        color: badge.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge.isUnlocked
                          ? '✅ Unlocked!'
                          : '${(badge.progress * 100).toInt()}% complete',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color:
              isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border:
              badge.isUnlocked
                  ? Border.all(
                    color: badge.color.withValues(alpha: 0.4),
                    width: 2,
                  )
                  : (isDark
                      ? Border.all(
                        color: AppColors.darkBorder.withValues(alpha: 0.2),
                      )
                      : null),
          boxShadow:
              badge.isUnlocked
                  ? [
                    BoxShadow(
                      color: badge.color.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    badge.isUnlocked
                        ? badge.color.withValues(alpha: 0.15)
                        : (isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant),
                shape: BoxShape.circle,
              ),
              child: Icon(
                badge.icon,
                color:
                    badge.isUnlocked
                        ? badge.color
                        : (isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary),
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color:
                    badge.isUnlocked
                        ? null
                        : (isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Mini progress bar
            SizedBox(
              width: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: badge.progress,
                  minHeight: 3,
                  backgroundColor:
                      isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.surfaceVariant,
                  color:
                      badge.isUnlocked
                          ? badge.color
                          : (isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 60 * index),
      duration: 300.ms,
    );
  }
}

class _Badge {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final double progress;

  const _Badge({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.progress,
  });
}
