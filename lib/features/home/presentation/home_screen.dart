import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../services/firebase_service.dart';
import '../../../models/child_profile_model.dart';
import '../../activities/presentation/modules_library_screen.dart';
import '../../progress/presentation/progress_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    _loadChildProfile();
  }

  Future<void> _loadChildProfile() async {
    try {
      final profiles = await _firebaseService.getChildProfiles();
      final selected = profiles.isNotEmpty ? profiles.first : null;
      if (mounted) {
        setState(() {
          _allChildren = profiles;
          _childProfile = selected;
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _switchChild(ChildProfileModel child) {
    setState(() => _childProfile = child);
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
          ),
          const ModulesLibraryScreen(),
          const ProgressScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
      floatingActionButton: _currentNavIndex == 0
          ? _buildEmergencyFAB(context)
          : null,
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
      child: const Icon(
        Icons.emergency_rounded,
        color: Colors.white,
        size: 28,
      ),
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

  const _DashboardTab({
    required this.childProfile,
    required this.allChildren,
    required this.isLoading,
    required this.onRefresh,
    required this.onSwitchChild,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),

              _buildQuickActions(context, isDark),

              const SizedBox(height: 24),

              // ─── Child Summary or Setup ──────────────────
              if (isLoading)
                _buildLoadingCard(isDark)
              else if (childProfile != null)
                _buildChildSummary(context, isDark)
              else
                _buildSetupPrompt(context, isDark),

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
      BuildContext context, String greeting, dynamic user, bool isDark) {
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
            backgroundColor: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.surfaceVariant,
          ),
        ),
        const SizedBox(width: 8),

        // Logout
        IconButton(
          onPressed: () async {
            await FirebaseService().signOut();
            if (!context.mounted) return;
            Navigator.pushReplacementNamed(context, '/login');
          },
          icon: const Icon(Icons.logout_rounded, size: 22),
          style: IconButton.styleFrom(
            backgroundColor:
                AppColors.error.withValues(alpha: isDark ? 0.2 : 0.08),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
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
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      child.name,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
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
            AppStrings.tagline,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  Icon(Icons.smart_toy_rounded,
                      color: Colors.white, size: 20),
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
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(
          begin: 0.08,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
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
                    color: (action.gradient as LinearGradient)
                        .colors[0]
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
        border: isDark
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
                onPressed: () =>
                    Navigator.pushNamed(context, '/profile-setup'),
                icon: const Icon(Icons.edit_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
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
              children: childProfile!.conditions.take(3).map((c) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
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

  Widget _buildRecommendationsSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.recommendations,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ).animate().fadeIn(delay: 700.ms),
        const SizedBox(height: 12),

        // Sample recommendation cards
        ..._buildSampleRecommendations(context, isDark),
      ],
    );
  }

  List<Widget> _buildSampleRecommendations(BuildContext context, bool isDark) {
    final items = [
      _RecommendationItem(
        title: 'Communication Practice',
        subtitle: '10 min • Picture card activity',
        icon: Icons.chat_bubble_rounded,
        color: AppColors.primary,
      ),
      _RecommendationItem(
        title: 'Sensory Play Time',
        subtitle: '15 min • Texture exploration',
        icon: Icons.touch_app_rounded,
        color: AppColors.accent,
      ),
      _RecommendationItem(
        title: 'Motor Skills Exercise',
        subtitle: '10 min • Stacking blocks',
        icon: Icons.sports_handball_rounded,
        color: AppColors.secondary,
      ),
    ];

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCardBackground
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark ? [] : AppShadows.subtle,
            border: isDark
                ? Border.all(
                    color: AppColors.darkBorder.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
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
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_rounded,
                color: item.color,
                size: 32,
              ),
            ],
          ),
        ),
      ).animate().fadeIn(
            delay: Duration(milliseconds: 800 + (index * 100)),
            duration: 400.ms,
          );
    }).toList();
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildDisclaimer(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  ),
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
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
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
                color: isSelected
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

class _RecommendationItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _RecommendationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
