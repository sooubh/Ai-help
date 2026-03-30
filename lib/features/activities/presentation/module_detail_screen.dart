import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/therapy_module_model.dart';
import 'activity_timer_screen.dart';

/// Full detail view for a single therapy module.
/// Shows objective, materials, step-by-step instructions,
/// duration, safety notes, and a start/complete action.
class ModuleDetailScreen extends StatelessWidget {
  final TherapyModuleModel module;

  const ModuleDetailScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                module.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCategoryColor(module.skillCategory),
                      _getCategoryColor(
                        module.skillCategory,
                      ).withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(module.skillCategory),
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),

          // ─── Content ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Tags ──────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.timer_outlined,
                        label: '${module.durationMinutes} min',
                      ),
                      _InfoChip(
                        icon: Icons.speed_rounded,
                        label: module.difficultyLabel,
                      ),
                      _InfoChip(
                        icon: Icons.calendar_today_outlined,
                        label: 'Ages ${module.ageRange}',
                      ),
                      _InfoChip(
                        icon: Icons.category_rounded,
                        label: module.skillCategory,
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 20),

                  // ─── Objective ──────────────────────────
                  _SectionHeader(title: 'Objective', icon: Icons.flag_rounded),
                  const SizedBox(height: 8),
                  Text(
                    module.objective,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.6),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // ─── Conditions ─────────────────────────
                  _SectionHeader(
                    title: 'Suitable For',
                    icon: Icons.medical_information_rounded,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        module.conditionTypes.map((c) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              c,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // ─── Materials ──────────────────────────
                  _SectionHeader(
                    title: 'Materials Needed',
                    icon: Icons.inventory_2_rounded,
                  ),
                  const SizedBox(height: 8),
                  ...module.materials.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(
                      delay: Duration(milliseconds: 400 + (entry.key * 50)),
                      duration: 300.ms,
                    );
                  }),

                  const SizedBox(height: 24),

                  // ─── Instructions ───────────────────────
                  _SectionHeader(
                    title: 'Step-by-Step Instructions',
                    icon: Icons.format_list_numbered_rounded,
                  ),
                  const SizedBox(height: 12),
                  ...module.instructions.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                entry.value,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(height: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(
                      delay: Duration(milliseconds: 500 + (entry.key * 80)),
                      duration: 400.ms,
                    );
                  }),

                  const SizedBox(height: 24),

                  // ─── Safety Notes ───────────────────────
                  if (module.safetyNotes != null &&
                      module.safetyNotes!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? AppColors.error.withValues(alpha: 0.1)
                                : AppColors.emergencyLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.health_and_safety_rounded,
                                color: AppColors.error,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Safety Notes',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            module.safetyNotes!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
                  ],

                  const SizedBox(height: 32),

                  // ─── Action Button ──────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ActivityTimerScreen(module: module),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_circle_rounded),
                      label: const Text(
                        'Start Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getCategoryColor(
                          module.skillCategory,
                        ),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 900.ms, duration: 400.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
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
}

// ─── Helper Widgets ──────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
