import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';

/// Role selection screen shown after login.
/// Lets the user choose between Parent and Doctor interfaces.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppGradients.darkHero : AppGradients.heroSubtle,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo
                Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: AppGradients.hero,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 24),

                Text(
                  'CARE-AI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                const SizedBox(height: 8),

                Text(
                  'How would you like to continue?',
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                const Spacer(flex: 2),

                // Parent / User Card
                _buildRoleCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.family_restroom_rounded,
                  title: 'Parent / Caregiver',
                  subtitle:
                      'Track progress, get AI guidance,\nmanage therapy activities',
                  gradient: AppGradients.hero,
                  delay: 400,
                  onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                ),

                const SizedBox(height: 16),

                // Doctor Card
                _buildRoleCard(
                  context: context,
                  isDark: isDark,
                  icon: Icons.medical_services_rounded,
                  title: 'Doctor / Therapist',
                  subtitle: 'View patients, assign plans,\nsend guidance notes',
                  gradient: AppGradients.doctor,
                  delay: 550,
                  onTap:
                      () => Navigator.pushReplacementNamed(
                        context,
                        '/doctor-dashboard',
                      ),
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required int delay,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isDark
                    ? AppColors.darkBorder.withValues(alpha: 0.3)
                    : AppColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.primary).withValues(
                alpha: 0.06,
              ),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with gradient background
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 18),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              color:
                  isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 500.ms).slideY(begin: 0.08);
  }
}
