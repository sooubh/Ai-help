import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../models/child_profile_model.dart';
import '../../../services/firebase_service.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

/// Profile setup screen — collects child details and saves to Firestore.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _challengesController = TextEditingController();
  final _goalsController = TextEditingController();

  String? _selectedCondition;
  String? _selectedCommunicationLevel;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _challengesController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCondition == null || _selectedCommunicationLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select condition and communication level'),
          backgroundColor: AppColors.alert,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Parse comma-separated challenges and goals into lists
      final challenges = _challengesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final goals = _goalsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final profile = ChildProfileModel(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        condition: _selectedCondition!,
        communicationLevel: _selectedCommunicationLevel!,
        challenges: challenges,
        goals: goals,
        updatedAt: DateTime.now(),
      );

      await _firebaseService.saveChildProfile(profile);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileSetup)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading
                Text(
                  'Tell us about your child',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'This helps us personalize guidance for you.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),

                // Child name
                CustomTextField(
                  label: AppStrings.childName,
                  controller: _nameController,
                  prefixIcon: Icons.person_outlined,
                  validator: (v) => Validators.required(v, 'Child\'s name'),
                  textInputAction: TextInputAction.next,
                ),

                // Age
                CustomTextField(
                  label: AppStrings.childAge,
                  controller: _ageController,
                  prefixIcon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  validator: Validators.age,
                  textInputAction: TextInputAction.next,
                ),

                // Condition dropdown
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCondition,
                    decoration: const InputDecoration(
                      labelText: AppStrings.condition,
                      prefixIcon: Icon(Icons.medical_information_outlined),
                    ),
                    items: AppStrings.commonConditions
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCondition = v),
                    validator: (v) =>
                        v == null ? 'Please select a condition' : null,
                  ),
                ),

                // Communication level dropdown
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCommunicationLevel,
                    decoration: const InputDecoration(
                      labelText: AppStrings.communicationLevel,
                      prefixIcon: Icon(Icons.chat_outlined),
                    ),
                    items: AppStrings.communicationLevels
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCommunicationLevel = v),
                    validator: (v) =>
                        v == null ? 'Please select communication level' : null,
                  ),
                ),

                // Challenges
                CustomTextField(
                  label: AppStrings.challenges,
                  hint: 'e.g., Tantrums, Sensory issues (comma separated)',
                  controller: _challengesController,
                  prefixIcon: Icons.warning_amber_outlined,
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                ),

                // Goals
                CustomTextField(
                  label: AppStrings.parentGoals,
                  hint: 'e.g., Better communication, Calmer routines',
                  controller: _goalsController,
                  prefixIcon: Icons.flag_outlined,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                ),

                const SizedBox(height: 16),

                // Save button
                CustomButton(
                  text: AppStrings.saveProfile,
                  onPressed: _saveProfile,
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
