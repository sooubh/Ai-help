import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../models/doctor_model.dart';
import '../../../models/child_profile_model.dart';
import '../../../services/firebase_service.dart';
import '../../../services/cache/smart_data_repository.dart';
import 'package:provider/provider.dart';

class FullProfileScreen extends StatefulWidget {
  const FullProfileScreen({super.key});

  @override
  State<FullProfileScreen> createState() => _FullProfileScreenState();
}

class _FullProfileScreenState extends State<FullProfileScreen> {
  final _firebaseService = FirebaseService();

  bool _isLoading = true;
  UserModel? _userProfile;
  DoctorModel? _doctorProfile;
  List<ChildProfileModel> _childrenProfiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final repository = context.read<SmartDataRepository>();
      final uid = _firebaseService.currentUser?.uid;
      if (uid == null) return;

      final user = await repository.getUserProfile(uid);
      if (user != null) {
        _userProfile = user;
        if (user.role == 'doctor') {
          _doctorProfile = await _firebaseService.getDoctorProfile();
        } else {
          _childrenProfiles = await repository.getChildProfiles(uid);
        }
      }
    } catch (e) {
      debugPrint('Error loading profiles: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Full Profile View'), elevation: 0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userProfile == null
              ? const Center(child: Text('Failed to load profile details.'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserHeader(
                      context,
                      isDark,
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 24),

                    if (_userProfile!.role == 'doctor' &&
                        _doctorProfile != null) ...[
                      _sectionTitle(
                        context,
                        'Professional Details',
                      ).animate().slideX(begin: 0.1).fadeIn(),
                      const SizedBox(height: 12),
                      _buildDoctorDetailsCard(
                        context,
                        isDark,
                      ).animate().fadeIn(delay: 100.ms),
                    ] else if (_userProfile!.role == 'parent' &&
                        _childrenProfiles.isNotEmpty) ...[
                      _sectionTitle(
                        context,
                        'Children Profiles',
                      ).animate().slideX(begin: 0.1).fadeIn(),
                      const SizedBox(height: 12),
                      ..._childrenProfiles.map(
                        (child) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildChildDetailsCard(context, child, isDark),
                        ).animate().fadeIn(delay: 200.ms),
                      ),
                    ] else if (_userProfile!.role == 'parent' &&
                        _childrenProfiles.isEmpty)
                      const Text(
                        'No child profiles found.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      const Text(
                        'Profile details missing.',
                        style: TextStyle(color: Colors.grey),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }

  Widget _buildUserHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primarySurface,
            backgroundImage:
                _userProfile?.photoUrl != null
                    ? NetworkImage(_userProfile!.photoUrl!)
                    : null,
            child:
                _userProfile?.photoUrl == null
                    ? Text(
                      _userProfile?.displayName?.isNotEmpty == true
                          ? _userProfile!.displayName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile?.displayName ?? 'Unknown User',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _userProfile?.email ?? 'No email',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (_userProfile?.role ?? 'Participant').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorDetailsCard(BuildContext context, bool isDark) {
    final doc = _doctorProfile!;
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDetailRow(
              Icons.local_hospital_rounded,
              'Clinic',
              doc.clinicName,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              Icons.medical_services_rounded,
              'Specialization',
              doc.specialization,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              Icons.phone_rounded,
              'Phone',
              (doc.phone == null || doc.phone!.isEmpty)
                  ? 'Not provided'
                  : doc.phone!,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              Icons.short_text_rounded,
              'Bio',
              (doc.bio == null || doc.bio!.isEmpty) ? 'Not provided' : doc.bio!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildDetailsCard(
    BuildContext context,
    ChildProfileModel child,
    bool isDark,
  ) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Child Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  backgroundImage:
                      child.photoUrl != null
                          ? NetworkImage(child.photoUrl!)
                          : null,
                  child:
                      child.photoUrl == null
                          ? Icon(
                            Icons.child_care_rounded,
                            color: AppColors.primary,
                          )
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${child.age} yrs • ${_capitalize(child.gender ?? 'Unknown')}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (child.relationship != null &&
                    child.relationship!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      child.relationship!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTagList('Medical Conditions', child.conditions),
                const SizedBox(height: 16),
                _buildDetailRow(
                  Icons.record_voice_over_rounded,
                  'Communication',
                  _capitalize(child.communicationLevel),
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  Icons.directions_run_rounded,
                  'Motor Skills',
                  _capitalize(child.motorSkillLevel),
                ),
                const Divider(height: 24),
                _buildTagList('Key Behaviors', child.behavioralConcerns),
                const SizedBox(height: 16),
                _buildTagList('Sensory Issues', child.sensoryIssues),
                const SizedBox(height: 16),
                _buildTagList('Parent Goals', child.parentGoals),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagList(String label, List<String> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              tags
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
    );
  }
}
