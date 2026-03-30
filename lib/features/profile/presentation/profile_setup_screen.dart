import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../models/child_profile_model.dart';
import '../../../services/firebase_service.dart';
import '../../../widgets/custom_text_field.dart';

/// Multi-step child profile setup wizard.
/// Collects all PRD-required fields for AI personalization.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();

  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  // Selections
  String? _selectedGender;
  String? _selectedCommunicationLevel;
  String? _selectedMotorSkillLevel;
  String? _selectedTherapyStatus;

  // Multi-select lists
  final List<String> _selectedConditions = [];
  final List<String> _selectedBehaviors = [];
  final List<String> _selectedSensory = [];
  final List<String> _selectedGoals = [];

  File? _imageFile;
  ChildProfileModel? _editingProfile;
  bool _didLoadInitialProfile = false;
  bool _isPrefillingProfile = true;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitialProfile) return;
    _didLoadInitialProfile = true;
    _loadExistingProfileForEdit();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedConditions.isEmpty) {
      _showError('Please select at least one condition');
      return;
    }
    if (_selectedCommunicationLevel == null) {
      _showError('Please select communication level');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final uid = _firebaseService.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      String? photoUrl;
      // Only upload if an image was selected
      if (_imageFile != null) {
        // use a random id or naming convention for the child's image
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        photoUrl = await _firebaseService.uploadFile(
          _imageFile!,
          'users/$uid/children/$timestamp.jpg',
        );
      }

      final profile =
          _editingProfile?.copyWith(
            name: _nameController.text.trim(),
            age: int.parse(_ageController.text.trim()),
            gender: _selectedGender,
            conditions: List<String>.from(_selectedConditions),
            communicationLevel: _selectedCommunicationLevel!,
            behavioralConcerns: List<String>.from(_selectedBehaviors),
            sensoryIssues: List<String>.from(_selectedSensory),
            motorSkillLevel: _selectedMotorSkillLevel ?? 'Unknown',
            parentGoals: List<String>.from(_selectedGoals),
            currentTherapyStatus:
                _selectedTherapyStatus ?? 'Not currently in therapy',
            photoUrl: photoUrl ?? _editingProfile?.photoUrl,
          ) ??
          ChildProfileModel(
            name: _nameController.text.trim(),
            age: int.parse(_ageController.text.trim()),
            gender: _selectedGender,
            conditions: List<String>.from(_selectedConditions),
            communicationLevel: _selectedCommunicationLevel!,
            behavioralConcerns: List<String>.from(_selectedBehaviors),
            sensoryIssues: List<String>.from(_selectedSensory),
            motorSkillLevel: _selectedMotorSkillLevel ?? 'Unknown',
            learningAbilities: const [],
            parentGoals: List<String>.from(_selectedGoals),
            currentTherapyStatus:
                _selectedTherapyStatus ?? 'Not currently in therapy',
            photoUrl: photoUrl,
          );

      await _firebaseService.saveChildProfile(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on Exception catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> _loadExistingProfileForEdit() async {
    try {
      ChildProfileModel? profile;
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is ChildProfileModel) {
        profile = args;
      } else if (args is Map<String, dynamic>) {
        final childId = args['childId'] as String?;
        if (childId != null && childId.isNotEmpty) {
          profile = await _firebaseService.getChildProfile(childId);
        }
      }

      profile ??= await _firebaseService.getChildProfile();
      if (!mounted) return;

      if (profile != null) {
        _applyProfileToForm(profile);
      }
    } catch (_) {
      // Keep form in create mode if prefill fails.
    } finally {
      if (mounted) {
        setState(() => _isPrefillingProfile = false);
      }
    }
  }

  void _applyProfileToForm(ChildProfileModel profile) {
    _editingProfile = profile;
    _nameController.text = profile.name;
    _ageController.text = profile.age.toString();

    _selectedGender = _pickIfInOptions(profile.gender, AppStrings.genders);
    _selectedCommunicationLevel = _pickIfInOptions(
      profile.communicationLevel,
      AppStrings.communicationLevels,
    );
    _selectedMotorSkillLevel = _pickIfInOptions(
      profile.motorSkillLevel,
      AppStrings.motorSkillLevels,
    );
    _selectedTherapyStatus = _pickIfInOptions(
      profile.currentTherapyStatus,
      AppStrings.therapyStatuses,
    );

    _selectedConditions
      ..clear()
      ..addAll(
        profile.conditions.where((e) => AppStrings.commonConditions.contains(e)),
      );
    _selectedBehaviors
      ..clear()
      ..addAll(
        profile.behavioralConcerns.where(
          (e) => AppStrings.commonBehavioralConcerns.contains(e),
        ),
      );
    _selectedSensory
      ..clear()
      ..addAll(
        profile.sensoryIssues.where((e) => AppStrings.commonSensoryIssues.contains(e)),
      );
    _selectedGoals
      ..clear()
      ..addAll(profile.parentGoals.where((e) => AppStrings.commonParentGoals.contains(e)));
  }

  String? _pickIfInOptions(String? value, List<String> options) {
    if (value == null) return null;
    return options.contains(value) ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isPrefillingProfile) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.profileSetup)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileSetup),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  _editingProfile == null
                      ? 'Tell us about your child'
                      : 'Update your child profile',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 4),
                Text(
                  'This helps us personalize guidance and activities.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                const SizedBox(height: 24),

                // ── Profile Photo ─────────────────────────────
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
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
                                    : (_editingProfile?.photoUrl != null &&
                                        _editingProfile!.photoUrl!.isNotEmpty)
                                    ? DecorationImage(
                                      image: NetworkImage(_editingProfile!.photoUrl!),
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
                                        Icons.add_a_photo_rounded,
                                        size: 28,
                                        color: AppColors.primary.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Photo',
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
                        delay: 200.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Max size: 5MB',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Basic Info ────────────────────────────────
                _sectionTitle('Basic Information', Icons.person_rounded),
                const SizedBox(height: 12),

                CustomTextField(
                  label: AppStrings.childName,
                  controller: _nameController,
                  prefixIcon: Icons.person_outlined,
                  validator: (v) => Validators.required(v, "Child's name"),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 4),

                CustomTextField(
                  label: AppStrings.childAge,
                  controller: _ageController,
                  prefixIcon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  validator: Validators.age,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 4),

                _buildDropdown(
                  label: AppStrings.childGender,
                  value: _selectedGender,
                  items: AppStrings.genders,
                  icon: Icons.wc_outlined,
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),

                const SizedBox(height: 20),

                // ── Conditions ────────────────────────────────
                _sectionTitle('Conditions', Icons.medical_information_rounded),
                const SizedBox(height: 8),
                _buildMultiSelect(
                  label: 'Select all that apply:',
                  options: AppStrings.commonConditions,
                  selected: _selectedConditions,
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                // ── Communication ─────────────────────────────
                _sectionTitle('Communication', Icons.chat_rounded),
                const SizedBox(height: 12),
                _buildDropdown(
                  label: AppStrings.communicationLevel,
                  value: _selectedCommunicationLevel,
                  items: AppStrings.communicationLevels,
                  icon: Icons.record_voice_over_outlined,
                  onChanged:
                      (v) => setState(() => _selectedCommunicationLevel = v),
                  isRequired: true,
                ),

                const SizedBox(height: 20),

                // ── Behavioral Concerns ───────────────────────
                _sectionTitle('Behavioral Concerns', Icons.psychology_rounded),
                const SizedBox(height: 8),
                _buildMultiSelect(
                  label: 'Select any concerns:',
                  options: AppStrings.commonBehavioralConcerns,
                  selected: _selectedBehaviors,
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                // ── Sensory Issues ────────────────────────────
                _sectionTitle('Sensory Sensitivities', Icons.sensors_rounded),
                const SizedBox(height: 8),
                _buildMultiSelect(
                  label: 'Select any sensitivities:',
                  options: AppStrings.commonSensoryIssues,
                  selected: _selectedSensory,
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                // ── Motor Skills ──────────────────────────────
                _sectionTitle('Motor Skills', Icons.accessibility_new_rounded),
                const SizedBox(height: 12),
                _buildDropdown(
                  label: AppStrings.motorSkills,
                  value: _selectedMotorSkillLevel,
                  items: AppStrings.motorSkillLevels,
                  icon: Icons.accessibility_new_outlined,
                  onChanged:
                      (v) => setState(() => _selectedMotorSkillLevel = v),
                ),

                const SizedBox(height: 20),

                // ── Parent Goals ──────────────────────────────
                _sectionTitle('Your Goals', Icons.flag_rounded),
                const SizedBox(height: 8),
                _buildMultiSelect(
                  label: 'What do you want to focus on?',
                  options: AppStrings.commonParentGoals,
                  selected: _selectedGoals,
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                // ── Therapy Status ────────────────────────────
                _sectionTitle(
                  'Current Therapy',
                  Icons.health_and_safety_rounded,
                ),
                const SizedBox(height: 12),
                _buildDropdown(
                  label: AppStrings.currentTherapy,
                  value: _selectedTherapyStatus,
                  items: AppStrings.therapyStatuses,
                  icon: Icons.local_hospital_outlined,
                  onChanged: (v) => setState(() => _selectedTherapyStatus = v),
                ),

                const SizedBox(height: 32),

                // ── Save Button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveProfile,
                    icon:
                        _isLoading
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.check_circle_rounded),
                    label: Text(
                      _isLoading
                          ? 'Saving...'
                          : (_editingProfile == null
                              ? AppStrings.saveProfile
                              : 'Update Profile'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helper Widgets ──────────────────────────────────────────

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        items:
            items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: onChanged,
        validator:
            isRequired
                ? (v) => v == null ? 'Please select $label' : null
                : null,
      ),
    );
  }

  Widget _buildMultiSelect({
    required String label,
    required List<String> options,
    required List<String> selected,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              options.map((option) {
                final isSelected = selected.contains(option);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selected.remove(option);
                      } else {
                        selected.add(option);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : (isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.surfaceVariant),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        Text(
                          option,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary),
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
