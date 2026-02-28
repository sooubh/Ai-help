import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/firebase_service.dart';

/// Password reset screen — enter email to receive reset link.
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _firebaseService = FirebaseService();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _firebaseService.resetPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _emailSent = true);
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child:
              _emailSent ? _buildSuccessView(isDark) : _buildFormView(isDark),
        ),
      ),
    );
  }

  Widget _buildFormView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Icon
        Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              duration: 400.ms,
              curve: Curves.easeOutBack,
            ),

        const SizedBox(height: 24),

        Text(
          AppStrings.resetPassword,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

        const SizedBox(height: 8),

        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 32),

        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _sendResetEmail(),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(
                    r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(v.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: AppStrings.email,
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetEmail,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'Send Reset Link',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildSuccessView(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 60),

        Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.success,
                size: 52,
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.5, 0.5),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),

        const SizedBox(height: 32),

        Text(
          'Check Your Email',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 12),

        Text(
          'We\'ve sent a password reset link to\n${_emailController.text.trim()}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Login'),
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

        const SizedBox(height: 16),

        TextButton(
          onPressed: () {
            setState(() => _emailSent = false);
          },
          child: const Text('Didn\'t receive it? Try again'),
        ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
      ],
    );
  }
}
