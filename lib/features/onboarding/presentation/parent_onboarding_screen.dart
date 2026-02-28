import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../services/firebase_service.dart';
import '../../../widgets/custom_text_field.dart';

class ParentOnboardingScreen extends StatefulWidget {
  const ParentOnboardingScreen({super.key});

  @override
  State<ParentOnboardingScreen> createState() => _ParentOnboardingScreenState();
}

class _ParentOnboardingScreenState extends State<ParentOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();

  final _relationshipController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileSize = await file.length();

      // Check 5MB limit
      if (fileSize > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an image smaller than 5MB.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _imageFile = file;
      });
    }
  }

  Future<void> _saveParentDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uid = _firebaseService.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await _firebaseService.uploadFile(
          _imageFile!,
          'users/$uid/profile.jpg',
        );
      }

      final profile = await _firebaseService.getUserProfile();
      if (profile != null) {
        await _firebaseService.updateUserProfile({
          'photoUrl': photoUrl,
          // Currently user models don't have relationship fields,
          // usually relationship is stored per child or on the parent doc.
          // For simplicity in this demo, parent relationship is just logged
          // or you could add it to parent user model.
          'relationship': _relationshipController.text.trim(),
        });
      }

      if (!mounted) return;

      // Proceed to child profile setup
      Navigator.pushReplacementNamed(context, '/profile-setup');
    } catch (e) {
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
      appBar: AppBar(title: const Text('Parent Profile'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Let\'s build your profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 8),
                Text(
                  'Upload a photo so your child recognizes you.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 32),

                // Profile Image Picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                      image:
                          _imageFile != null
                              ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                              : null,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child:
                        _imageFile == null
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  size: 32,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Upload',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                            : null,
                  ),
                ).animate().scale(
                  delay: 400.ms,
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                ),

                const SizedBox(height: 12),
                const Text(
                  'Max size: 5MB',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 40),

                // Relationship
                CustomTextField(
                  label: 'Relationship to Child (e.g. Mother, Guardian)',
                  controller: _relationshipController,
                  prefixIcon: Icons.family_restroom_rounded,
                  validator: (v) => Validators.required(v, 'Relationship'),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _saveParentDetails(),
                ).animate().slideY(delay: 600.ms, duration: 400.ms, begin: 0.2),

                const SizedBox(height: 48),

                // Next Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveParentDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Continue to Child Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
