import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'doctor_home_tab.dart';
import 'doctor_requests_tab.dart';
import 'doctor_patients_tab.dart';
import 'doctor_profile_tab.dart';

/// Doctor portal shell with bottom navigation.
/// Houses 4 tabs: Dashboard, Requests, Patients, Profile.
class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    DoctorHomeTab(),
    DoctorRequestsTab(),
    DoctorPatientsTab(),
    DoctorProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.dashboard_rounded, 'Dashboard', 0, isDark),
                _navItem(Icons.notifications_rounded, 'Requests', 1, isDark),
                _navItem(Icons.people_rounded, 'Patients', 2, isDark),
                _navItem(Icons.person_rounded, 'Profile', 3, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, bool isDark) {
    final isSelected = _currentIndex == index;
    final activeColor = AppColors.doctorPrimary;
    final inactiveColor =
        isDark ? AppColors.darkTextTertiary : AppColors.textTertiary;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? activeColor.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
