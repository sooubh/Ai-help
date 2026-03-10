import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../services/firebase_service.dart';
import '../../../services/cache/sync_manager.dart';
import '../../../widgets/custom_text_field.dart';

/// Signup screen matching the premium login design.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firebaseService = FirebaseService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isDoctor = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _firebaseService.signUp(
        _emailController.text,
        _passwordController.text,
        displayName: _nameController.text.trim(),
        role: _isDoctor ? 'doctor' : 'parent',
      );
      if (!mounted) return;

      // Start cache sync after successful signup
      final userId = _firebaseService.currentUser?.uid;
      if (userId != null && mounted) {
        final syncManager = context.read<SyncManager>();
        await syncManager.startSync(userId);
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.signUpSuccess),
          backgroundColor: AppColors.success,
        ),
      );

      if (_isDoctor) {
        Navigator.pushReplacementNamed(context, '/doctor-onboarding');
      } else {
        Navigator.pushReplacementNamed(context, '/parent-onboarding');
      }
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
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
        // Start cache sync after successful Google signup
        final userId = _firebaseService.currentUser?.uid;
        if (userId != null && mounted) {
          final syncManager = context.read<SyncManager>();
          await syncManager.startSync(userId);
        }
        if (!mounted) return;

        if (_isDoctor) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                const SizedBox(height: 32),

                // ─── Header ───────────────────────────────────
                _buildHeader(context, isDark),

                const SizedBox(height: 24),

                // ─── Role Toggle ──────────────────────────────
                _buildRoleToggle(context, isDark),

                const SizedBox(height: 24),

                // ─── Signup Card ──────────────────────────────
                _buildSignupCard(context, isDark),

                const SizedBox(height: 24),

                // ─── Login Link ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.hasAccount,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap:
                          () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text(
                        AppStrings.login,
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
        Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2DD4A8), Color(0xFF5B6EF5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2DD4A8).withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_add_rounded,
                size: 36,
                color: Colors.white,
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.5, 0.5),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: 16),
        Text(
          'Create Account',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        const SizedBox(height: 4),
        Text(
          'Join the CARE-AI family',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
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
    ).animate().fadeIn(delay: 350.ms, duration: 400.ms);
  }

  Widget _buildSignupCard(BuildContext context, bool isDark) {
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
              children: [
                // Name
                CustomTextField(
                  label: AppStrings.fullName,
                  controller: _nameController,
                  prefixIcon: Icons.person_outlined,
                  validator: (v) => Validators.required(v, 'Name'),
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 4),

                // Email
                CustomTextField(
                  label: AppStrings.email,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 4),

                // Password
                CustomTextField(
                  label: AppStrings.password,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outlined,
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
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

                const SizedBox(height: 4),

                // Confirm Password
                CustomTextField(
                  label: AppStrings.confirmPassword,
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  prefixIcon: Icons.lock_outlined,
                  validator:
                      (v) => Validators.confirmPassword(
                        v,
                        _passwordController.text,
                      ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signUp(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed:
                        () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Up button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
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
                              AppStrings.signUp,
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
                        'or sign up with',
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
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideY(begin: 0.1, duration: 600.ms, curve: Curves.easeOutCubic);
  }
}
