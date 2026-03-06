import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// Beautiful onboarding carousel with animated illustrations.
/// Shown to first-time users before login/signup.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: AppStrings.onboardingTitle1,
      description: AppStrings.onboardingDesc1,
      icon: Icons.school_rounded,
      gradient: const [Color(0xFF5B6EF5), Color(0xFF8B5CF6)],
    ),
    _OnboardingData(
      title: AppStrings.onboardingTitle2,
      description: AppStrings.onboardingDesc2,
      icon: Icons.smart_toy_rounded,
      gradient: const [Color(0xFF2DD4A8), Color(0xFF5B6EF5)],
    ),
    _OnboardingData(
      title: AppStrings.onboardingTitle3,
      description: AppStrings.onboardingDesc3,
      icon: Icons.insights_rounded,
      gradient: const [Color(0xFFFF7B6B), Color(0xFFFFB938)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed:
                      () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text(
                    AppStrings.skip,
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated icon
                        Container(
                              width: size.width * 0.45,
                              height: size.width * 0.45,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: page.gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: page.gradient[0].withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 40,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Icon(
                                page.icon,
                                size: size.width * 0.2,
                                color: Colors.white,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            ),

                        const SizedBox(height: 48),

                        // Title
                        Text(
                              page.title,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 500.ms)
                            .slideY(begin: 0.2, duration: 500.ms),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                              page.description,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color:
                                    isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 500.ms)
                            .slideY(begin: 0.2, duration: 500.ms),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page indicator + button
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor:
                          isDark ? AppColors.darkDivider : AppColors.divider,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),

                  // Next / Get Started button
                  GestureDetector(
                    onTap: _nextPage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentPage == _pages.length - 1 ? 160 : 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child:
                            _currentPage == _pages.length - 1
                                ? const Text(
                                  'Get Started',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                                : const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data model for onboarding pages.
class _OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  const _OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
