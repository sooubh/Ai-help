import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/activity_log_model.dart';
import '../../../services/firebase_service.dart';
import 'package:intl/intl.dart';

/// Detailed patient view showing child profile data, conditions,
/// activity timeline, and quick actions for the doctor.
class PatientDetailScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final String parentUid;

  const PatientDetailScreen({
    super.key,
    required this.childId,
    required this.childName,
    this.parentUid = '',
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final _firebaseService = FirebaseService();

  Map<String, dynamic>? _childData;
  List<ActivityLogModel> _activityLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    try {
      // Load the patient list and find this child
      final patients = await _firebaseService.getDoctorPatients();
      final match =
          patients.where((p) => p['childId'] == widget.childId).toList();
      final parentUid =
          match.isNotEmpty
              ? match.first['parentUid'] as String
              : widget.parentUid;

      List<ActivityLogModel> logs = [];
      if (parentUid.isNotEmpty) {
        logs = await _firebaseService.getPatientActivityLogs(
          parentUid,
          limit: 10,
        );
      }

      if (!mounted) return;
      setState(() {
        _childData = match.isNotEmpty ? match.first : null;
        _activityLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Error loading patient data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(widget.childName),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Profile Card ────────────────────────────
                    _buildProfileCard(isDark),
                    const SizedBox(height: 20),

                    // ─── Conditions ──────────────────────────────
                    if (_childData != null) _buildConditionsSection(isDark),
                    const SizedBox(height: 20),

                    // ─── Activity Timeline ───────────────────────
                    _buildActivityTimeline(isDark),
                    const SizedBox(height: 28),

                    // ─── Action Buttons ──────────────────────────
                    _buildActionButtons(isDark),
                  ],
                ),
              ),
    );
  }

  // ─── Profile Card ─────────────────────────────────────────

  Widget _buildProfileCard(bool isDark) {
    final age = _childData?['childAge'] ?? 'N/A';
    final gender = _childData?['childGender'] ?? 'N/A';
    final commLevel = _childData?['communicationLevel'] ?? 'Unknown';
    final therapyStatus = _childData?['currentTherapyStatus'] ?? 'Unknown';
    final parentName = _childData?['parentName'] ?? 'Unknown';

    final statusColor =
        therapyStatus == 'Active'
            ? AppColors.success
            : therapyStatus == 'Paused'
            ? AppColors.warning
            : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.doctorPrimary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.doctorPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.doctorPrimary.withValues(alpha: 0.2),
                      AppColors.doctorPrimary.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.childName.isNotEmpty
                        ? widget.childName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.doctorPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.childName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Parent: $parentName',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  therapyStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Info grid
          Row(
            children: [
              _infoChip(Icons.cake_rounded, 'Age $age', isDark),
              const SizedBox(width: 10),
              _infoChip(Icons.person_rounded, gender, isDark),
              const SizedBox(width: 10),
              _infoChip(Icons.record_voice_over_rounded, commLevel, isDark),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05);
  }

  Widget _infoChip(IconData icon, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color:
              isDark
                  ? AppColors.darkSurfaceVariant.withValues(alpha: 0.5)
                  : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.doctorPrimary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Conditions Section ───────────────────────────────────

  Widget _buildConditionsSection(bool isDark) {
    final conditions = (_childData?['conditions'] as List<String>?) ?? [];
    if (conditions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.health_and_safety_rounded,
              color: AppColors.doctorPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Conditions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              conditions.map((c) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppColors.doctorPrimary.withValues(alpha: 0.12)
                            : AppColors.doctorSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.doctorPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark
                              ? AppColors.doctorPrimary
                              : AppColors.doctorPrimaryDark,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  // ─── Activity Timeline ────────────────────────────────────

  Widget _buildActivityTimeline(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.timeline_rounded,
              color: AppColors.doctorPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${_activityLogs.length} records',
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_activityLogs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_rounded,
                  size: 36,
                  color: AppColors.textTertiary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'No activity logs yet',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_activityLogs.length, (i) {
            final log = _activityLogs[i];
            final dateStr = DateFormat('MMM d, h:mm a').format(log.completedAt);
            final durationMin = (log.durationSeconds / 60).round();
            final categoryColor = _categoryColor(log.category);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _categoryIcon(log.category),
                      size: 18,
                      color: categoryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.activityTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$dateStr  •  ${durationMin}min',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (300 + i * 60).ms, duration: 350.ms);
          }),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  // ─── Action Buttons ───────────────────────────────────────

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.doctorPrimary, Color(0xFF38BDF8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.doctorPrimary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_task_rounded, size: 20),
              label: const Text('Assign Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/assign-plan',
                  arguments: {'childId': widget.childId},
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.note_add_rounded, size: 20),
              label: const Text('Send Note'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.doctorPrimary,
                side: const BorderSide(
                  color: AppColors.doctorPrimary,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/compose-note',
                  arguments: {'childId': widget.childId},
                );
              },
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1);
  }

  // ─── Helpers ──────────────────────────────────────────────

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'speech':
        return AppColors.doctorPrimary;
      case 'motor':
        return AppColors.accent;
      case 'cognitive':
        return AppColors.purple;
      case 'social':
        return AppColors.secondary;
      case 'sensory':
        return AppColors.gold;
      default:
        return AppColors.primary;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'speech':
        return Icons.record_voice_over_rounded;
      case 'motor':
        return Icons.directions_run_rounded;
      case 'cognitive':
        return Icons.psychology_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'sensory':
        return Icons.touch_app_rounded;
      default:
        return Icons.assignment_rounded;
    }
  }
}
