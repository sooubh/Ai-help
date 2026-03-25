import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/data/therapy_modules_registry.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../services/firebase_service.dart';
import '../../../models/child_profile_model.dart';
import '../../activities/presentation/modules_library_screen.dart';
import '../../activities/presentation/therapy_activity_screen.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'package:provider/provider.dart';
import '../../../services/cache/smart_data_repository.dart';
import '../../../services/cache/sync_manager.dart';
import '../../../services/cache/local_cache_service.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/recommendation_model.dart';
import '../../../models/guidance_note_model.dart';
import '../../../services/ai_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/permission_service.dart';
import '../../../models/therapy_module_model.dart';

/// Premium Smart Dashboard — central hub of the CARE-AI user app.
/// Shows greeting, child summary, quick actions, today's plan,
/// emergency button, and bottom navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firebaseService = FirebaseService();
  int _currentNavIndex = 0;
  ChildProfileModel? _childProfile;
  List<ChildProfileModel> _allChildren = [];
  bool _isLoadingProfile = true;
  Map<String, dynamic> _weeklyStats = {'count': 0, 'minutes': 0, 'streak': 0};
  Map<String, double> _skillProgress = {};

  List<RecommendationModel>? _recommendations;
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadChildProfile();
    PermissionService().requestEssentialPermissions();
  }

  Future<void> _loadChildProfile() async {
    try {
      final repository = context.read<SmartDataRepository>();
      final uid = _firebaseService.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _isLoadingProfile = false);
        return;
      }
      
      final profiles = await repository.getChildProfiles(uid);
      final selected = profiles.isNotEmpty ? profiles.first : null;
      final dashboard = await repository.getDashboardData(uid);
      
      if (mounted) {
        setState(() {
          _allChildren = profiles;
          _childProfile = selected;
          _weeklyStats = dashboard['weeklyStats'] ?? {'count': 0, 'minutes': 0, 'streak': 0};
          _skillProgress = Map<String, double>.from(dashboard['skillProgress'] ?? {});
          _isLoadingProfile = false;
        });
        if (selected != null) {
          _checkStreakWarning();
          _fetchRecommendations(selected);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  /// Shows a streak-at-risk notification after 6 PM if the user has an
  /// active streak but has not logged any activity today (FIX 8).
  Future<void> _checkStreakWarning() async {
    if (DateTime.now().hour < 18) return;
    final streak = _weeklyStats['streak'] as int? ?? 0;
    if (streak <= 0) return;
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final dailyCounts = _weeklyStats['dailyCounts'];
    final todayCount =
        (dailyCounts is Map ? dailyCounts[todayKey] as int? : null) ?? 0;
    if (todayCount > 0) return;
    await NotificationService().showStreakWarning(streakDays: streak);
  }

  void _switchChild(ChildProfileModel child) {
    setState(() {
      _childProfile = child;
      _recommendations = null;
    });
    _fetchRecommendations(child);
  }

  Future<void> _fetchRecommendations(ChildProfileModel profile) async {
    final childId = profile.id;
    if (childId == null) return;

    setState(() => _isLoadingRecommendations = true);

    try {
      final cached = await _firebaseService.getDailyRecommendations(childId);
      if (cached != null && cached.isNotEmpty) {
        if (mounted) {
          setState(() {
            _recommendations = cached;
            _isLoadingRecommendations = false;
          });
        }
        return;
      }

      if (!mounted) return;
      final aiService = context.read<AiService>();
      final newRecs = await aiService.getRecommendations(profile);
      await _firebaseService.saveRecommendations(childId, newRecs);

      if (mounted) {
        setState(() {
          _recommendations = newRecs;
          _isLoadingRecommendations = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRecommendations = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _DashboardTab(
            childProfile: _childProfile,
            allChildren: _allChildren,
            isLoading: _isLoadingProfile,
            onRefresh: _loadChildProfile,
            onSwitchChild: _switchChild,
            weeklyStats: _weeklyStats,
            skillProgress: _skillProgress,
            recommendations: _recommendations,
            isLoadingRecommendations: _isLoadingRecommendations,
          ),
          const ModulesLibraryScreen(),
          const ProgressScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
      floatingActionButton:
          _currentNavIndex == 0 ? _buildEmergencyFAB(context) : null,
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: AppStrings.home,
                isSelected: _currentNavIndex == 0,
                onTap: () => setState(() => _currentNavIndex = 0),
              ),
              _NavItem(
                icon: Icons.extension_rounded,
                label: AppStrings.activities,
                isSelected: _currentNavIndex == 1,
                onTap: () => setState(() => _currentNavIndex = 1),
              ),
              _NavItem(
                icon: Icons.insights_rounded,
                label: AppStrings.progress,
                isSelected: _currentNavIndex == 2,
                onTap: () => setState(() => _currentNavIndex = 2),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: AppStrings.profile,
                isSelected: _currentNavIndex == 3,
                onTap: () => setState(() => _currentNavIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, '/emergency'),
      backgroundColor: AppColors.emergency,
      child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 28),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DASHBOARD TAB
// ═══════════════════════════════════════════════════════════════
class _DashboardTab extends StatelessWidget {
  final ChildProfileModel? childProfile;
  final List<ChildProfileModel> allChildren;
  final bool isLoading;
  final VoidCallback onRefresh;
  final ValueChanged<ChildProfileModel> onSwitchChild;
  final Map<String, dynamic> weeklyStats;
  final Map<String, double> skillProgress;
  final List<RecommendationModel>? recommendations;
  final bool isLoadingRecommendations;

  const _DashboardTab({
    required this.childProfile,
    required this.allChildren,
    required this.isLoading,
    required this.onRefresh,
    required this.onSwitchChild,
    required this.weeklyStats,
    required this.skillProgress,
    required this.recommendations,
    required this.isLoadingRecommendations,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseService().currentUser;
    final greeting = _getGreeting();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Top Bar ─────────────────────────────────
              _buildTopBar(context, greeting, user, isDark),

              // Multi-child selector
              _buildChildSelector(context, isDark),

              const SizedBox(height: 20),

              // ─── Hero Card ───────────────────────────────
              _buildHeroCard(context),

              const SizedBox(height: 24),

              // ─── Quick Actions ───────────────────────────
              Text(
                AppStrings.quickActions,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),

              _buildQuickActions(context, isDark),

              const SizedBox(height: 24),

              // ─── Guidance Notes ──────────────────────────
              if (childProfile != null)
                _buildGuidanceNotesSection(context, childProfile!.id!),

              if (childProfile != null) const SizedBox(height: 12),

              // ─── Child Summary or Setup ──────────────────
              if (isLoading)
                _buildLoadingCard(isDark)
              else if (childProfile != null)
                _buildChildSummary(context, isDark)
              else
                _buildSetupPrompt(context, isDark),

              const SizedBox(height: 24),

              // ─── AI Therapy Suggestions ────────────────
              _buildAiTherapySuggestions(context, isDark),

              const SizedBox(height: 24),

              // ─── Skill Progress Snapshot ───────────────
              _buildSkillProgressSnapshot(context, isDark),

              const SizedBox(height: 24),

              // ─── Today's Recommendations ─────────────────
              _buildRecommendationsSection(context, isDark),

              const SizedBox(height: 20),

              // ─── Disclaimer ──────────────────────────────
              _buildDisclaimer(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    String greeting,
    dynamic user,
    bool isDark,
  ) {
    final themeProvider = context.read<ThemeProvider>();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.displayName ?? user?.email ?? 'Parent',
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Dark mode toggle
        IconButton(
          onPressed: () => themeProvider.toggleTheme(),
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 22,
          ),
          style: IconButton.styleFrom(
            backgroundColor:
                isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.surfaceVariant,
          ),
        ),
        const SizedBox(width: 8),

        // Logout
        IconButton(
          onPressed: () async {
            await context.read<SyncManager>().stopSync();
            await LocalCacheService.instance.clearUserData();
            await FirebaseService().signOut();
            if (!context.mounted) return;
            Navigator.pushReplacementNamed(context, '/login');
          },
          icon: const Icon(Icons.logout_rounded, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.error.withValues(
              alpha: isDark ? 0.2 : 0.08,
            ),
            foregroundColor: AppColors.error,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  /// Multi-child selector row shown below greeting when multiple children exist.
  Widget _buildChildSelector(BuildContext context, bool isDark) {
    if (allChildren.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: allChildren.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final child = allChildren[index];
            final isSelected = child.name == childProfile?.name;

            return GestureDetector(
              onTap: () => onSwitchChild(child),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.child_care_rounded,
                      size: 16,
                      color:
                          isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      child.name,
                      style: TextStyle(
                        color:
                            isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppGradients.hero,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.primaryGlow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                weeklyStats['count'] > 0
                    ? '${weeklyStats['count']} activities this week · ${weeklyStats['minutes']} min · ${weeklyStats['streak']} day streak 🔥'
                    : AppStrings.tagline,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // AI Chat button inside hero
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/chat'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Chat with AI Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 100.ms, duration: 500.ms)
        .slideY(begin: 0.08, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildQuickActions(BuildContext context, bool isDark) {
    final actions = [
      _QuickAction(
        title: AppStrings.askAi,
        icon: Icons.smart_toy_rounded,
        gradient: AppGradients.primary,
        onTap: () => Navigator.pushNamed(context, '/chat'),
      ),
      _QuickAction(
        title: 'Voice',
        icon: Icons.mic_rounded,
        gradient: AppGradients.hero,
        onTap: () => Navigator.pushNamed(context, '/voice-assistant'),
      ),
      _QuickAction(
        title: AppStrings.games,
        icon: Icons.sports_esports_rounded,
        gradient: AppGradients.cardWarm,
        onTap: () => Navigator.pushNamed(context, '/games'),
      ),
      _QuickAction(
        title: AppStrings.dailyPlan,
        icon: Icons.calendar_today_rounded,
        gradient: AppGradients.accent,
        onTap: () => Navigator.pushNamed(context, '/daily-plan'),
      ),
      _QuickAction(
        title: AppStrings.emergency,
        icon: Icons.emergency_rounded,
        gradient: AppGradients.emergency,
        onTap: () => Navigator.pushNamed(context, '/emergency'),
      ),
      _QuickAction(
        title: 'Wellness',
        icon: Icons.spa_rounded,
        gradient: AppGradients.cardCool,
        onTap: () => Navigator.pushNamed(context, '/wellness'),
      ),
      _QuickAction(
        title: 'Community',
        icon: Icons.groups_rounded,
        gradient: AppGradients.cardWarm,
        onTap: () => Navigator.pushNamed(context, '/community'),
      ),
      _QuickAction(
        title: 'Achievements',
        icon: Icons.emoji_events_rounded,
        gradient: AppGradients.cardPurple,
        onTap: () => Navigator.pushNamed(context, '/achievements'),
      ),
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final action = actions[index];
          return GestureDetector(
            onTap: action.onTap,
            child: Container(
              width: 90,
              decoration: BoxDecoration(
                gradient: action.gradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (action.gradient as LinearGradient).colors[0]
                        .withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon, color: Colors.white, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    action.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 400 + (index * 80)),
            duration: 400.ms,
          );
        },
      ),
    );
  }

  Widget _buildChildSummary(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : AppShadows.soft,
        border:
            isDark
                ? Border.all(color: AppColors.darkBorder.withValues(alpha: 0.3))
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.purpleSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  color: AppColors.purple,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childProfile!.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${childProfile!.age} years old • ${childProfile!.communicationLevel}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed:
                    () => Navigator.pushNamed(
                      context,
                      '/profile-setup',
                      arguments: childProfile,
                    ),
                icon: const Icon(Icons.edit_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor:
                      isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.surfaceVariant,
                ),
              ),
            ],
          ),
          if (childProfile!.conditions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  childProfile!.conditions.take(3).map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 400.ms);
  }

  Widget _buildSetupPrompt(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile-setup'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppGradients.heroSubtle,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.child_care_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Up Child Profile',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add your child\'s details for personalized AI guidance',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 400.ms);
  }

  // ─── AI Therapy Suggestions ──────────────────────────────────
  Widget _buildAiTherapySuggestions(BuildContext context, bool isDark) {
    // Get condition-matched modules from the registry
    final conditions = childProfile?.conditions ?? [];
    List<dynamic> suggested = [];
    for (final condition in conditions) {
      suggested.addAll(TherapyModulesRegistry.forCondition(condition));
    }
    // Remove duplicates and limit
    final seen = <String>{};
    suggested = suggested.where((m) => seen.add(m.id)).toList();
    if (suggested.isEmpty) {
      suggested = TherapyModulesRegistry.allModules.take(6).toList();
    }
    suggested = suggested.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'AI Therapy Suggestions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 4),
        Text(
          'Personalized modules based on your child\'s profile',
          style: Theme.of(context).textTheme.bodySmall,
        ).animate().fadeIn(delay: 550.ms),
        const SizedBox(height: 12),
        SizedBox(
          height: 165,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggested.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final module = suggested[index];
              final catColor = _getCategoryColor(module.skillCategory);
              return GestureDetector(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => TherapyActivityScreen(
                              module: module,
                              childProfile: childProfile,
                            ),
                      ),
                    ),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        catColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        catColor.withValues(alpha: isDark ? 0.08 : 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: catColor.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getCategoryIcon(module.skillCategory),
                          color: catColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        module.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              module.skillCategory,
                              style: TextStyle(
                                color: catColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${module.durationMinutes}m',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(
                delay: Duration(milliseconds: 550 + (index * 80)),
                duration: 400.ms,
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Skill Progress Snapshot ────────────────────────────────
  Widget _buildSkillProgressSnapshot(BuildContext context, bool isDark) {
    final skillData = <String, double>{
      'Communication': 0.0,
      'Cognitive': 0.0,
      'Memory': 0.0,
      'Attention': 0.0,
      'Social': 0.0,
      'Sensory': 0.0,
    };

    // Use cached dashboard skill progress instead of direct Firebase call
    for (final entry in skillProgress.entries) {
      final key = entry.key.length > 12 ? entry.key.substring(0, 12) : entry.key;
      skillData[key] = entry.value;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : AppShadows.soft,
        border:
            isDark
                ? Border.all(
                  color: AppColors.darkBorder.withValues(alpha: 0.3),
                )
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Skill Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...skillData.entries.map((entry) {
            final color = _getCategoryColor(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${(entry.value * 100).toInt()}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: entry.value,
                      backgroundColor: color.withValues(
                        alpha: isDark ? 0.1 : 0.08,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 650.ms, duration: 400.ms);
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
      case 'Social Interaction':
        return Icons.groups_rounded;
      case 'Behavioral':
        return Icons.emoji_emotions_rounded;
      case 'Emotional Recognition':
        return Icons.mood_rounded;
      case 'Memory':
        return Icons.grid_view_rounded;
      case 'Attention':
        return Icons.center_focus_strong_rounded;
      case 'Speech & Language':
        return Icons.record_voice_over_rounded;
      case 'Problem Solving':
        return Icons.lightbulb_rounded;
      default:
        return Icons.extension_rounded;
    }
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
      case 'Social Interaction':
      case 'Social':
        return const Color(0xFF10B981);
      case 'Behavioral':
        return AppColors.secondary;
      case 'Emotional Recognition':
        return const Color(0xFFEC4899);
      case 'Memory':
        return const Color(0xFF8B5CF6);
      case 'Attention':
        return const Color(0xFFEF4444);
      case 'Speech & Language':
        return const Color(0xFF06B6D4);
      case 'Problem Solving':
        return const Color(0xFFF97316);
      default:
        return AppColors.primary;
    }
  }

  Widget _buildRecommendationsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.recommendations,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (isLoadingRecommendations)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ).animate().fadeIn(delay: 700.ms),
        const SizedBox(height: 12),

        if (isLoadingRecommendations &&
            (recommendations == null || recommendations!.isEmpty))
          ...List.generate(3, (index) => _buildShimmerRecommendation(isDark))
        else if (recommendations != null && recommendations!.isNotEmpty)
          ...recommendations!.map(
            (rec) => _buildDynamicRecommendation(context, rec, isDark),
          )
        else
          // Fallback
          ..._buildSampleRecommendations(context, isDark),
      ],
    );
  }

  Widget _buildDynamicRecommendation(
    BuildContext context,
    RecommendationModel item,
    bool isDark,
  ) {
    IconData icon = Icons.check_circle_outline_rounded;
    Color color = AppColors.primary;

    final lowerTitle = item.title.toLowerCase();
    final lowerReason = item.reason.toLowerCase();
    if (lowerTitle.contains('sensory') ||
        lowerTitle.contains('play') ||
        lowerReason.contains('sensory')) {
      icon = Icons.touch_app_rounded;
      color = AppColors.accent;
    } else if (lowerTitle.contains('communication') ||
        lowerTitle.contains('speech') ||
        lowerReason.contains('speech')) {
      icon = Icons.chat_bubble_rounded;
      color = AppColors.primary;
    } else if (lowerTitle.contains('motor') ||
        lowerTitle.contains('move') ||
        lowerReason.contains('motor')) {
      icon = Icons.sports_handball_rounded;
      color = AppColors.secondary;
    } else if (lowerTitle.contains('focus') ||
        lowerTitle.contains('attention')) {
      icon = Icons.psychology_rounded;
      color = AppColors.purple;
    } else if (lowerTitle.contains('calm') || lowerTitle.contains('breath')) {
      icon = Icons.spa_rounded;
      color = const Color(0xFF10B981);
    }

        return GestureDetector(
          onTap: () => _openRecommendation(context, item),
          child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.darkCardBackground
                      : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark ? [] : AppShadows.subtle,
              border:
                  isDark
                      ? Border.all(
                        color: AppColors.darkBorder.withValues(alpha: 0.3),
                      )
                      : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.duration,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.reason,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.play_circle_rounded,
                  size: 28,
                  color: color,
                ),
              ],
            ),
          ),
        ))
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOut);
  }

  Future<void> _openRecommendation(
    BuildContext context,
    RecommendationModel recommendation,
  ) async {
    final matchedModule = _findModuleForRecommendation(recommendation);
    final moduleToOpen = matchedModule ?? _bestFallbackModule();

    if (moduleToOpen == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No module available right now. Please try again.'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => TherapyActivityScreen(
              module: moduleToOpen,
              childProfile: childProfile,
            ),
      ),
    );
  }

  TherapyModuleModel? _bestFallbackModule() {
    final ranked = _rankedFallbackModules(limit: 1);
    return ranked.isNotEmpty ? ranked.first : null;
  }

  TherapyModuleModel? _findModuleForRecommendation(RecommendationModel item) {
    final title = item.title.trim().toLowerCase();
    final objective = item.objective.trim().toLowerCase();
    final reason = item.reason.trim().toLowerCase();

    if (title.isEmpty && objective.isEmpty && reason.isEmpty) return null;

    final exact = TherapyModulesRegistry.allModules
        .where((m) => m.title.trim().toLowerCase() == title)
        .toList();
    if (exact.isNotEmpty) return exact.first;

    final contains = TherapyModulesRegistry.allModules.where((m) {
      final moduleTitle = m.title.toLowerCase();
      return moduleTitle.contains(title) || title.contains(moduleTitle);
    }).toList();
    if (contains.isNotEmpty) return contains.first;

    // Fuzzy fallback: choose the module with highest token overlap
    final queryTokens = <String>{
      ...title.split(RegExp(r'[^a-z0-9]+')),
      ...objective.split(RegExp(r'[^a-z0-9]+')),
      ...reason.split(RegExp(r'[^a-z0-9]+')),
    }.where((t) => t.length > 2).toSet();

    if (queryTokens.isEmpty) return null;

    TherapyModuleModel? best;
    var bestScore = 0;
    for (final module in TherapyModulesRegistry.allModules) {
      final moduleText =
          '${module.title} ${module.objective} ${module.skillCategory}'.toLowerCase();
      final moduleTokens = moduleText
          .split(RegExp(r'[^a-z0-9]+'))
          .where((t) => t.length > 2)
          .toSet();
      final overlap = queryTokens.intersection(moduleTokens).length;
      if (overlap > bestScore) {
        bestScore = overlap;
        best = module;
      }
    }

    if (best != null && bestScore > 0) return best;

    return null;
  }

  Widget _buildShimmerRecommendation(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.white10 : Colors.grey[200]!,
        highlightColor: isDark ? Colors.white24 : Colors.grey[100]!,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSampleRecommendations(BuildContext context, bool isDark) {
    final modules = _rankedFallbackModules(limit: 5);
    if (modules.isEmpty) return <Widget>[];

    return modules.asMap().entries.map((entry) {
      final index = entry.key;
      final module = entry.value;
      final color = _getCategoryColor(module.skillCategory);
      return GestureDetector(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => TherapyActivityScreen(
                      module: module,
                      childProfile: childProfile,
                    ),
              ),
            ),
        child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isDark
                    ? AppColors.darkCardBackground
                    : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark ? [] : AppShadows.subtle,
            border:
                isDark
                    ? Border.all(
                      color: AppColors.darkBorder.withValues(alpha: 0.3),
                    )
                    : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(module.skillCategory),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${module.durationMinutes} min • ${_buildFallbackReason(module)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_rounded, color: color, size: 32),
            ],
          ),
        ),
      )).animate().fadeIn(
        delay: Duration(milliseconds: 800 + (index * 100)),
        duration: 400.ms,
      );
    }).toList();
  }

  List<TherapyModuleModel> _rankedFallbackModules({int limit = 5}) {
    final profile = childProfile;
    final all = TherapyModulesRegistry.allModules;
    if (profile == null) return all.take(limit).toList();

    final completed = profile.completedModuleIds.toSet();
    final weakestSkills = skillProgress.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final weakest = weakestSkills.take(2).map((e) => e.key.toLowerCase()).toSet();

    int score(TherapyModuleModel module) {
      var value = 0;
      final moduleConditions = module.conditionTypes
          .map((e) => e.toLowerCase())
          .toList();
      final profileConditions = profile.conditions.map((e) => e.toLowerCase()).toList();

      for (final condition in profileConditions) {
        final matched = moduleConditions.any(
          (m) => m.contains(condition) || condition.contains(m),
        );
        if (matched) value += 4;
      }

      if (_isAgeInRange(profile.age, module.ageRange)) value += 2;

      final categoryLower = module.skillCategory.toLowerCase();
      if (weakest.any((skill) => categoryLower.contains(skill))) {
        value += 2;
      }

      if (completed.contains(module.id)) value -= 5;
      return value;
    }

    final ranked = [...all]
      ..sort((a, b) {
        final scoreCompare = score(b).compareTo(score(a));
        if (scoreCompare != 0) return scoreCompare;
        return a.durationMinutes.compareTo(b.durationMinutes);
      });

    return ranked.where((m) => !completed.contains(m.id)).take(limit).toList();
  }

  bool _isAgeInRange(int age, String range) {
    final parts = range.split('-');
    if (parts.length != 2) return true;
    final min = int.tryParse(parts[0].trim());
    final max = int.tryParse(parts[1].trim());
    if (min == null || max == null) return true;
    return age >= min && age <= max;
  }

  String _buildFallbackReason(TherapyModuleModel module) {
    final profile = childProfile;
    if (profile == null) {
      return module.objective;
    }

    final moduleConditions = module.conditionTypes.map((e) => e.toLowerCase());
    final matchingCondition = profile.conditions.firstWhere(
      (c) {
        final condition = c.toLowerCase();
        return moduleConditions.any(
          (m) => m.contains(condition) || condition.contains(m),
        );
      },
      orElse: () => '',
    );

    if (matchingCondition.isNotEmpty) {
      return 'Recommended for ${matchingCondition.toLowerCase()} support';
    }

    if (_isAgeInRange(profile.age, module.ageRange)) {
      return 'Well-suited for age ${profile.age}';
    }

    return module.objective;
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildDisclaimer(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkSurfaceVariant.withValues(alpha: 0.5)
                : AppColors.warningLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.disclaimerShort,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1000.ms, duration: 400.ms);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildGuidanceNotesSection(BuildContext context, String childId) {
    return StreamBuilder<List<GuidanceNoteModel>>(
      stream: context.read<SmartDataRepository>().watchGuidanceNotes(childId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final notes = snapshot.data!;
        final unreadNotes = notes.where((note) => !note.isRead).toList();

        if (unreadNotes.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor Notes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...unreadNotes.map(
              (note) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: AppColors.infoLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.info),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.mark_email_unread,
                    color: AppColors.info,
                  ),
                  title: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('From: ${note.doctorName}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () {
                      FirebaseService().markGuidanceNoteRead(note.id);
                    },
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: Text(note.title),
                            content: SingleChildScrollView(
                              child: Text(note.content),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Close'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  FirebaseService().markGuidanceNoteRead(
                                    note.id,
                                  );
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Mark as Read'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ),
            ),
          ],
        ).animate().fadeIn();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HELPER WIDGETS & DATA
// ═══════════════════════════════════════════════════════════════

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}
