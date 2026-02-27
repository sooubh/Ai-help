import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Community Resources Screen — curated list of support groups,
/// forums, and online communities organized by category.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Community & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            _buildHeroCard(context),
            const SizedBox(height: 24),

            // Categories
            _buildCategory(
              context,
              isDark,
              title: 'Autism Spectrum (ASD)',
              icon: Icons.emoji_people_rounded,
              color: AppColors.primary,
              resources: [
                _Resource(
                  'Autism Speaks Community',
                  'autismspeaks.org',
                  'Connect with families, share stories, find local events',
                ),
                _Resource(
                  'r/Autism Parenting (Reddit)',
                  'reddit.com/r/AutismParenting',
                  'Active online community of parents sharing daily experiences',
                ),
                _Resource(
                  'Wrong Planet',
                  'wrongplanet.net',
                  'Forum for individuals on the spectrum and their families',
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildCategory(
              context,
              isDark,
              title: 'ADHD & Attention',
              icon: Icons.psychology_rounded,
              color: AppColors.accent,
              resources: [
                _Resource(
                  'CHADD',
                  'chadd.org',
                  'National resource on ADHD with parent support groups',
                ),
                _Resource(
                  'ADDitude Magazine Community',
                  'additudemag.com',
                  'Expert advice, webinars, and support forums',
                ),
                _Resource(
                  'ADHD Foundation',
                  'adhdfoundation.org.uk',
                  'Resources, training, and neurodiversity support',
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildCategory(
              context,
              isDark,
              title: 'Motor & Physical',
              icon: Icons.accessibility_new_rounded,
              color: AppColors.secondary,
              resources: [
                _Resource(
                  'United Cerebral Palsy',
                  'ucp.org',
                  'Support services, programs, and advocacy',
                ),
                _Resource(
                  'National Down Syndrome Society',
                  'ndss.org',
                  'Family support, resources, and community events',
                ),
                _Resource(
                  'Easter Seals',
                  'easterseals.com',
                  'Disability services and community support',
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildCategory(
              context,
              isDark,
              title: 'General Parenting Support',
              icon: Icons.groups_rounded,
              color: AppColors.purple,
              resources: [
                _Resource(
                  'Parent to Parent USA',
                  'p2pusa.org',
                  'Nationwide network of parent-to-parent support',
                ),
                _Resource(
                  'Family Voices',
                  'familyvoices.org',
                  'Advocacy for families of children with special needs',
                ),
                _Resource(
                  'The Arc',
                  'thearc.org',
                  'Advocacy for people with intellectual & developmental disabilities',
                ),
                _Resource(
                  'NAMI Family Support',
                  'nami.org',
                  'Free peer-led support groups for families',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFF5B6EF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.people_rounded,
              color: Colors.white, size: 40),
          const SizedBox(height: 12),
          const Text(
            'You Are Not Alone',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with other parents, find local support groups, and access resources from organizations that understand your journey.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(
          begin: 0.05,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildCategory(
    BuildContext context,
    bool isDark, {
    required String title,
    required IconData icon,
    required Color color,
    required List<_Resource> resources,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 10),
        ...resources.asMap().entries.map((entry) {
          final index = entry.key;
          final res = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardBackground
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: isDark
                  ? Border.all(
                      color: AppColors.darkBorder.withValues(alpha: 0.2))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  res.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  res.url,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  res.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ).animate().fadeIn(
                delay: Duration(milliseconds: 80 * index),
                duration: 300.ms,
              );
        }),
      ],
    );
  }
}

class _Resource {
  final String name;
  final String url;
  final String description;

  const _Resource(this.name, this.url, this.description);
}
