import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// About & Help screen — app info, FAQ, legal links, disclaimer.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('About & Help')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── App Info Card ─────────────────────────
            _buildAppInfoCard(context, isDark),
            const SizedBox(height: 24),

            // ─── FAQ ──────────────────────────────────
            _sectionTitle(context, 'Frequently Asked Questions'),
            const SizedBox(height: 12),
            _buildFAQ(context, isDark),
            const SizedBox(height: 24),

            // ─── Safety Disclaimer ────────────────────
            _sectionTitle(context, 'Safety Disclaimer'),
            const SizedBox(height: 12),
            _buildDisclaimer(context, isDark),
            const SizedBox(height: 24),

            // ─── Legal & Links ────────────────────────
            _sectionTitle(context, 'Legal & Support'),
            const SizedBox(height: 12),
            _buildLegalLinks(context, isDark),
          ],
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

  Widget _buildAppInfoCard(BuildContext context, bool isDark) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5B6EF5), Color(0xFF8B5CF6), Color(0xFFA855F7)],
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
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.tagline,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Built with Flutter & Gemini AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildFAQ(BuildContext context, bool isDark) {
    final faqs = [
      {
        'q': 'Is CARE-AI a replacement for therapy?',
        'a':
            'No. CARE-AI provides supplementary guidance and activities. It does not replace professional medical advice, diagnosis, or treatment. Always consult qualified healthcare providers.',
      },
      {
        'q': 'How does the AI personalize responses?',
        'a':
            'When you set up your child\'s profile (conditions, communication level, goals), the AI uses this context to tailor every response and activity recommendation.',
      },
      {
        'q': 'Is my data secure?',
        'a':
            'Yes. All data is stored securely in Firebase with encryption in transit and at rest. Your data is never shared with third parties. You can export or delete your data anytime from Settings.',
      },
      {
        'q': 'Which conditions does CARE-AI support?',
        'a':
            'CARE-AI supports a wide range including Autism (ASD), ADHD, cerebral palsy, Down syndrome, speech delays, sensory processing disorders, and more. Activities are designed to be adaptable.',
      },
      {
        'q': 'Can I use CARE-AI offline?',
        'a':
            'Most screens work offline. However, AI Chat requires internet to communicate with the Gemini API. Activities, games, and progress tracking work without connection.',
      },
      {
        'q': 'How do I share reports with my doctor?',
        'a':
            'Go to Settings → Generate Doctor Report. This creates a professional summary you can copy and share with your healthcare provider via text, email, or print.',
      },
    ];

    return Column(
      children:
          faqs.asMap().entries.map((entry) {
            final index = entry.key;
            final faq = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
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
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Text(
                  faq['q']!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                children: [
                  Text(
                    faq['a']!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ).animate().fadeIn(
              delay: Duration(milliseconds: 80 * index),
              duration: 300.ms,
            );
          }).toList(),
    );
  }

  Widget _buildDisclaimer(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkSurfaceVariant.withValues(alpha: 0.5)
                : AppColors.warningLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Text(
                'Important Notice',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'CARE-AI is an AI-powered parenting companion designed to support caregivers of children with developmental or physical disabilities.\n\n'
            '• This app does NOT provide medical diagnoses\n'
            '• It does NOT prescribe treatments or medications\n'
            '• All guidance is supplementary to professional care\n'
            '• Always consult qualified healthcare providers for medical concerns\n'
            '• In case of emergency, call your local emergency services immediately\n\n'
            'The AI responses are generated using Google Gemini and may occasionally contain inaccuracies. Always verify important information with your healthcare team.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildLegalLinks(BuildContext context, bool isDark) {
    final links = [
      {
        'icon': Icons.privacy_tip_rounded,
        'title': 'Privacy Policy',
        'subtitle': 'How we handle your data',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.description_rounded,
        'title': 'Terms of Service',
        'subtitle': 'Usage terms and conditions',
        'color': AppColors.accent,
      },
      {
        'icon': Icons.email_rounded,
        'title': 'Contact Support',
        'subtitle': 'support@care-ai.app',
        'color': AppColors.secondary,
      },
      {
        'icon': Icons.star_rounded,
        'title': 'Rate the App',
        'subtitle': 'Help us improve CARE-AI',
        'color': AppColors.gold,
      },
      {
        'icon': Icons.code_rounded,
        'title': 'Open Source Licenses',
        'subtitle': 'Third-party packages used',
        'color': AppColors.purple,
      },
    ];

    return Column(
      children:
          links.asMap().entries.map((entry) {
            final index = entry.key;
            final link = entry.value;
            final color = link['color'] as Color;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(link['icon'] as IconData, color: color, size: 20),
                ),
                title: Text(
                  link['title'] as String,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  link['subtitle'] as String,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color:
                      isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${link['title']} — opening soon'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(
              delay: Duration(milliseconds: 80 * index),
              duration: 300.ms,
            );
          }).toList(),
    );
  }
}
