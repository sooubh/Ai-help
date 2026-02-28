import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/firebase_service.dart';

/// Patients list tab — shows all patients assigned to the doctor.
/// Tapping a patient navigates to the PatientDetailScreen.
class DoctorPatientsTab extends StatefulWidget {
  const DoctorPatientsTab({super.key});

  @override
  State<DoctorPatientsTab> createState() => _DoctorPatientsTabState();
}

class _DoctorPatientsTabState extends State<DoctorPatientsTab> {
  final _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final patients = await _firebaseService.getDoctorPatients();
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _filtered = patients;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filtered = _patients;
      } else {
        _filtered =
            _patients.where((p) {
              final name = (p['childName'] as String).toLowerCase();
              final parent = (p['parentName'] as String).toLowerCase();
              final q = query.toLowerCase();
              return name.contains(q) || parent.contains(q);
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        foregroundColor:
            isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.doctorPrimary,
                ),
              )
              : Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isDark
                                  ? AppColors.darkDivider
                                  : AppColors.divider,
                        ),
                      ),
                      child: TextField(
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          hintText: 'Search by child or parent name…',
                          hintStyle: TextStyle(
                            color:
                                isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.textTertiary,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.doctorPrimary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  // Count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          '${_filtered.length} patient${_filtered.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // List
                  Expanded(
                    child:
                        _filtered.isEmpty
                            ? Center(
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? 'No patients matching "$_searchQuery"'
                                    : 'No patients yet',
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                ),
                              ),
                            )
                            : RefreshIndicator(
                              color: AppColors.doctorPrimary,
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  4,
                                  20,
                                  32,
                                ),
                                itemCount: _filtered.length,
                                itemBuilder:
                                    (context, i) => _buildPatientTile(
                                      _filtered[i],
                                      isDark,
                                      i,
                                    ),
                              ),
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildPatientTile(
    Map<String, dynamic> patient,
    bool isDark,
    int index,
  ) {
    final childName = patient['childName'] as String;
    final parentName = patient['parentName'] as String;
    final conditions = patient['conditions'] as List<String>;
    final age = patient['childAge'];
    final status = patient['currentTherapyStatus'] as String;
    final statusColor =
        status == 'Active'
            ? AppColors.success
            : status == 'Paused'
            ? AppColors.warning
            : AppColors.textTertiary;

    return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/patient-detail',
              arguments: {
                'childId': patient['childId'],
                'childName': childName,
                'parentUid': patient['parentUid'],
              },
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isDark
                        ? AppColors.darkDivider.withValues(alpha: 0.3)
                        : AppColors.divider,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : AppColors.primary).withValues(
                    alpha: 0.04,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.doctorPrimary.withValues(alpha: 0.15),
                        AppColors.doctorPrimary.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      childName.isNotEmpty ? childName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.doctorPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Age $age  •  $parentName',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                        ),
                      ),
                      if (conditions.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children:
                              conditions
                                  .take(2)
                                  .map(
                                    (c) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.doctorPrimary
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        c,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.doctorPrimary,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color:
                          isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (200 + index * 60).ms, duration: 400.ms)
        .slideX(begin: 0.04);
  }
}
