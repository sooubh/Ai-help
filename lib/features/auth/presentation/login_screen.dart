import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../services/firebase_service.dart';
import '../../../services/cache/sync_manager.dart';
import '../../../services/cache/local_cache_service.dart';
import '../../../widgets/custom_text_field.dart';

/// Premium login screen with gradient background,
/// glassmorphism card, and animated elements.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firebaseService = FirebaseService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isDoctor = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _firebaseService.signIn(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;

      final profile = await _firebaseService.getUserProfile();
      if (!mounted) return;

      // Validate that the user's fetched role matches the selected role
      if (profile?.role == 'doctor' && !_isDoctor) {
        _showError('This account belongs to a Doctor. Please switch tabs.');
        await _firebaseService.signOut();
        return;
      } else if (profile?.role == 'parent' && _isDoctor) {
        _showError('This account belongs to a Parent. Please switch tabs.');
        await _firebaseService.signOut();
        return;
      }

      // Start cache sync after successful login
      final userId = _firebaseService.currentUser?.uid;
      if (userId != null && mounted) {
        final syncManager = context.read<SyncManager>();
        await syncManager.startSync(userId);
        final cache = LocalCacheService.instance;
        if (cache.lastBackupTime == null) {
          await cache.restoreFromBackup();
        }
      }
      if (!mounted) return;

      if (profile?.role == 'doctor') {
        final docProfile = await _firebaseService.getDoctorProfile();
        if (!mounted) return;
        if (docProfile == null ||
            docProfile.specialization.isEmpty ||
            docProfile.name == 'Dr. Unknown') {
          Navigator.pushReplacementNamed(context, '/doctor-onboarding');
        } else {
          Navigator.pushReplacementNamed(context, '/doctor-dashboard');
        }
      } else {
        final children = await _firebaseService.getChildProfiles();
        if (!mounted) return;
        if (children.isEmpty) {
          Navigator.pushReplacementNamed(context, '/parent-onboarding');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on Exception catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await _firebaseService.signInWithGoogle(
        role: _isDoctor ? 'doctor' : 'parent',
      );
      if (!mounted) return;
      if (user != null) {
        // Start cache sync after successful Google login
        final userId = _firebaseService.currentUser?.uid;
        if (userId != null && mounted) {
          final syncManager = context.read<SyncManager>();
          await syncManager.startSync(userId);
          final cache = LocalCacheService.instance;
          if (cache.lastBackupTime == null) {
            await cache.restoreFromBackup();
          }
        }
        if (!mounted) return;

        final profile = await _firebaseService.getUserProfile();
        if (!mounted) return;

        if (profile?.role == 'doctor') {
          final docProfile = await _firebaseService.getDoctorProfile();
          if (!mounted) return;
          if (docProfile == null ||
              docProfile.specialization.isEmpty ||
              docProfile.name == 'Dr. Unknown') {
            Navigator.pushReplacementNamed(context, '/doctor-onboarding');
          } else {
            Navigator.pushReplacementNamed(context, '/doctor-dashboard');
          }
        } else {
          final children = await _firebaseService.getChildProfiles();
          if (!mounted) return;
          if (children.isEmpty) {
            Navigator.pushReplacementNamed(context, '/parent-onboarding');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      }
    } on Exception catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    UiHelpers.showErrorSnackbar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? const LinearGradient(
                    colors: [AppColors.darkBackground, Color(0xFF1A1D35)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                  : const LinearGradient(
                    colors: [Color(0xFFEEF0FF), Color(0xFFF8F9FE)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(height: size.height * 0.06),

                // ─── Logo & Title ─────────────────────────────
                _buildHeader(context, isDark),

                const SizedBox(height: 32),

                // ─── Role Toggle ──────────────────────────────
                _buildRoleToggle(context, isDark),

                const SizedBox(height: 24),

                // ─── Login Card ───────────────────────────────
                _buildLoginCard(context, isDark),

                const SizedBox(height: 24),

                // ─── Sign Up Link ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.noAccount,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap:
                          () => Navigator.pushReplacementNamed(
                            context,
                            '/signup',
                          ),
                      child: const Text(
                        AppStrings.signUp,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 800.ms, duration: 500.ms),

                const SizedBox(height: 32),

                // ─── Disclaimer ───────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppColors.darkSurfaceVariant.withValues(
                              alpha: 0.5,
                            )
                            : AppColors.warningLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
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
                ).animate().fadeIn(delay: 900.ms, duration: 500.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Gradient app icon
        Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B6EF5), Color(0xFFA855F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B6EF5).withValues(alpha: 0.35),
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
            .scale(
              begin: const Offset(0.5, 0.5),
              duration: 600.ms,
              curve: Curves.easeOutBack,
            ),

        const SizedBox(height: 20),

        // App name
        Text(
          AppStrings.appName,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

        const SizedBox(height: 6),

        // Tagline
        Text(
          AppStrings.tagline,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildRoleToggle(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isDoctor = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isDoctor ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      !_isDoctor
                          ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : [],
                ),
                child: Center(
                  child: Text(
                    'Parent',
                    style: TextStyle(
                      color:
                          !_isDoctor
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary),
                      fontWeight:
                          !_isDoctor ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isDoctor = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isDoctor ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      _isDoctor
                          ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : [],
                ),
                child: Center(
                  child: Text(
                    'Doctor',
                    style: TextStyle(
                      color:
                          _isDoctor
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary),
                      fontWeight: _isDoctor ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _buildLoginCard(BuildContext context, bool isDark) {
    return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:
                isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  isDark
                      ? AppColors.darkBorder.withValues(alpha: 0.3)
                      : AppColors.divider.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : const Color(0xFF5B6EF5).withValues(alpha: 0.06),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to continue your journey',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),

                // Email field
                CustomTextField(
                  label: AppStrings.email,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 4),

                // Password field
                CustomTextField(
                  label: AppStrings.password,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outlined,
                  validator: Validators.password,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  ),
                ),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        () => Navigator.pushNamed(context, '/password-reset'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text(
                      AppStrings.forgotPassword,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              AppStrings.login,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 20),

                // ─── Divider ─────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color:
                            isDark ? AppColors.darkDivider : AppColors.divider,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.textTertiary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color:
                            isDark ? AppColors.darkDivider : AppColors.divider,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ─── Social Auth Buttons ─────────────────
                Row(
                  children: [
                    // Google button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        icon: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                        label: const Text('Google'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color:
                                isDark
                                    ? AppColors.darkBorder
                                    : AppColors.divider,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Phone OTP button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            () => Navigator.pushNamed(context, '/phone-otp'),
                        icon: const Icon(Icons.phone_rounded, size: 20),
                        label: const Text('Phone'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color:
                                isDark
                                    ? AppColors.darkBorder
                                    : AppColors.divider,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 500.ms, duration: 600.ms)
        .slideY(begin: 0.1, duration: 600.ms, curve: Curves.easeOutCubic);
  }
}
