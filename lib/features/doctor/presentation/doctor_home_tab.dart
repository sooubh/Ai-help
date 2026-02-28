import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../models/doctor_model.dart';
import '../../../services/firebase_service.dart';

/// Dashboard overview tab — stats, quick actions, summary.
class DoctorHomeTab extends StatefulWidget {
  const DoctorHomeTab({super.key});

  @override
  State<DoctorHomeTab> createState() => _DoctorHomeTabState();
}

class _DoctorHomeTabState extends State<DoctorHomeTab> {
  final _firebaseService = FirebaseService();

  DoctorModel? _doctor;
  int _patientCount = 0;
  int _notesCount = 0;
  int _activeCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _firebaseService.getDoctorProfile(),
        _firebaseService.getDoctorPatients(),
        _firebaseService.getDoctorNotesCount(),
      ]);
      if (!mounted) return;
      final patients = results[1] as List<Map<String, dynamic>>;
      setState(() {
        _doctor = results[0] as DoctorModel?;
        _patientCount = patients.length;
        _notesCount = results[2] as int;
        _activeCount =
            patients.where((p) => p['currentTherapyStatus'] == 'Active').length;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.doctorPrimary),
      );
    }

    return RefreshIndicator(
      color: AppColors.doctorPrimary,
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(isDark),
          const SizedBox(height: 24),
          _buildStatsRow(isDark),
          const SizedBox(height: 28),
          _buildQuickActions(isDark),
          const SizedBox(height: 28),
          _buildTipsCard(isDark),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    final name = _doctor?.name ?? 'Doctor';
    final specialization = _doctor?.specialization ?? 'Specialist';

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 20,
        24,
        28,
      ),
      decoration: BoxDecoration(
        gradient: AppGradients.doctor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.doctorPrimary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Online',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Good ${_greetingPeriod()},',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dr. $name',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.local_hospital_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                specialization,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1);
  }

  // ─── Stats Row ────────────────────────────────────────────

  Widget _buildStatsRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statCard(
            Icons.people_outline_rounded,
            '$_patientCount',
            'Patients',
            AppColors.doctorPrimary,
            isDark,
          ),
          const SizedBox(width: 12),
          _statCard(
            Icons.note_alt_outlined,
            '$_notesCount',
            'Notes Sent',
            AppColors.accent,
            isDark,
          ),
          const SizedBox(width: 12),
          _statCard(
            Icons.verified_rounded,
            '$_activeCount',
            'Active',
            AppColors.gold,
            isDark,
          ),
        ],
      ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1),
    );
  }

  Widget _statCard(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
    );
  }

  // ─── Quick Actions ────────────────────────────────────────

  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _actionTile(
                Icons.person_search_rounded,
                'View\nPatients',
                AppColors.doctorPrimary,
                isDark,
                () {
                  // Switch to patients tab — parent widget handles this
                  final state =
                      context.findAncestorStateOfType<_DoctorHomeTabState>();
                  state?._switchToTab?.call(2);
                },
              ),
              const SizedBox(width: 12),
              _actionTile(
                Icons.notifications_active_rounded,
                'Patient\nRequests',
                AppColors.secondary,
                isDark,
                () {
                  final state =
                      context.findAncestorStateOfType<_DoctorHomeTabState>();
                  state?._switchToTab?.call(1);
                },
              ),
              const SizedBox(width: 12),
              _actionTile(
                Icons.note_add_rounded,
                'Send\nNote',
                AppColors.accent,
                isDark,
                () {
                  Navigator.pushNamed(
                    context,
                    '/compose-note',
                    arguments: {'childId': ''},
                  );
                },
              ),
              const SizedBox(width: 12),
              _actionTile(
                Icons.assignment_rounded,
                'Assign\nPlan',
                AppColors.purple,
                isDark,
                () {
                  Navigator.pushNamed(
                    context,
                    '/assign-plan',
                    arguments: {'childId': ''},
                  );
                },
              ),
            ],
          ),
        ],
      ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
    );
  }

  // Callback to switch tabs (set by parent DoctorDashboardScreen)
  void Function(int)? _switchToTab;

  Widget _actionTile(
    IconData icon,
    String label,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
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
      ),
    );
  }

  // ─── Tips Card ────────────────────────────────────────────

  Widget _buildTipsCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.doctorPrimary.withValues(alpha: 0.08),
              AppColors.accent.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.doctorPrimary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.doctorPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                color: AppColors.doctorPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tip of the Day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review patient activity logs regularly to track therapy effectiveness and adjust plans.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color:
                          isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
    );
  }

  String _greetingPeriod() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}
