import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../services/firebase_service.dart';
import '../../../services/notification_service.dart';

/// Settings screen — profile, theme, voice, notifications, privacy, logout.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  bool _dailyReminderEnabled = true;
  bool _progressNotifEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final enabled = await _notificationService.isEnabled();
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('reminder_hour') ?? 9;
    final minute = prefs.getInt('reminder_minute') ?? 0;
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
        _dailyReminderEnabled =
            prefs.getBool('daily_reminder_enabled') ?? true;
        _progressNotifEnabled =
            prefs.getBool('progress_notifications_enabled') ?? true;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _notificationService.setEnabled(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Notifications scheduled for ${_reminderTime.format(context)}'
              : 'Notifications disabled',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() => _reminderTime = picked);
      await _notificationService.scheduleDailyReminder(
        hour: picked.hour,
        minute: picked.minute,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder set for ${picked.format(context)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleDailyReminder(bool value) async {
    setState(() => _dailyReminderEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_reminder_enabled', value);
    if (value) {
      await _notificationService.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
    } else {
      await _notificationService.cancel(NotificationService.dailyReminderId);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Daily reminder enabled' : 'Daily reminder disabled',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleProgressNotif(bool value) async {
    setState(() => _progressNotifEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('progress_notifications_enabled', value);
    if (value) {
      await _notificationService.scheduleProgressUpdateNotifications();
    } else {
      await Workmanager().cancelByUniqueName('care_ai_progress_update');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Progress reminders enabled (every 3 hours)'
              : 'Progress reminders disabled',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final firebase = FirebaseService();
      final userProfile = await firebase.getUserProfile();
      final childProfiles = await firebase.getChildProfiles();

      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'user': userProfile?.toMap(),
        'children': childProfiles.map((c) => c.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      await Clipboard.setData(ClipboardData(text: jsonString));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data copied to clipboard! 📋'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final user = FirebaseService().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Profile Card ──────────────────────────
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/full-profile'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.darkCardBackground
                          : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow:
                      isDark
                          ? []
                          : [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        (user?.displayName?.isNotEmpty == true)
                            ? user!.displayName![0].toUpperCase()
                            : (user?.email?[0].toUpperCase() ?? 'U'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Parent',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            // ─── Appearance ────────────────────────────
            _sectionTitle(context, 'Appearance'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.dark_mode_rounded,
              title: 'Dark Mode',
              trailing: Switch.adaptive(
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeTrackColor: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            // ─── Child Profile ─────────────────────────
            _sectionTitle(context, 'Child Profile'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.child_care_rounded,
              title: 'Edit Child Profile',
              subtitle: 'Update your child\'s information',
              onTap: () => Navigator.pushNamed(context, '/profile-setup'),
            ),

            const SizedBox(height: 20),

            // ─── Notifications ─────────────────────────
            _sectionTitle(context, 'Notifications'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.notifications_rounded,
              title: 'Push Notifications',
              subtitle: 'Daily reminders, progress updates',
              trailing: Switch.adaptive(
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                activeTrackColor: AppColors.primary,
              ),
            ),
            if (_notificationsEnabled)
              _SettingsTile(
                icon: Icons.alarm_rounded,
                title: 'Daily Reminder',
                subtitle: 'Morning check-in notification at saved time',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap:
                          _dailyReminderEnabled ? _selectReminderTime : null,
                      child: Chip(
                        label: Text(
                          _reminderTime.format(context),
                          style: TextStyle(
                            color:
                                _dailyReminderEnabled
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        backgroundColor:
                            _dailyReminderEnabled
                                ? AppColors.primarySurface
                                : Colors.grey.withValues(alpha: 0.1),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch.adaptive(
                      value: _dailyReminderEnabled,
                      onChanged: _toggleDailyReminder,
                      activeTrackColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            if (_notificationsEnabled)
              _SettingsTile(
                icon: Icons.bar_chart_rounded,
                title: 'Progress Reminders (every 3 hours)',
                subtitle: 'Background updates on activities and streaks',
                trailing: Switch.adaptive(
                  value: _progressNotifEnabled,
                  onChanged: _toggleProgressNotif,
                  activeTrackColor: AppColors.primary,
                ),
              ),

            const SizedBox(height: 20),

            // ─── Safety & Privacy ──────────────────────
            _sectionTitle(context, 'Safety & Privacy'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.shield_rounded,
              title: 'Safety Disclaimer',
              subtitle: AppStrings.disclaimerShort,
            ),
            _SettingsTile(
              icon: Icons.download_rounded,
              title: 'Export My Data',
              subtitle: 'Download a copy of your data to clipboard',
              trailing:
                  _isExporting
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : null,
              onTap: _isExporting ? null : _exportData,
            ),
            _SettingsTile(
              icon: Icons.medical_information_rounded,
              title: 'Generate Doctor Report',
              subtitle: 'Professional summary for your healthcare provider',
              onTap: () => Navigator.pushNamed(context, '/doctor-report'),
            ),

            const SizedBox(height: 20),

            // ─── Help & Info ────────────────────────────
            _sectionTitle(context, 'Help & Info'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.help_outline_rounded,
              title: 'About & Help',
              subtitle: 'FAQ, legal, support, app info',
              onTap: () => Navigator.pushNamed(context, '/about'),
            ),

            const SizedBox(height: 20),

            // ─── Account ───────────────────────────────
            _sectionTitle(context, 'Account'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              iconColor: AppColors.warning,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text(
                          'Are you sure you want to sign out?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                );
                if (confirm != true || !context.mounted) return;
                await FirebaseService().signOut();
                await Workmanager().cancelByUniqueName('care_ai_progress_update');
                await NotificationService().cancelAll();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
            _SettingsTile(
              icon: Icons.delete_forever_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and data',
              iconColor: AppColors.error,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text('Delete Account'),
                        content: const Text(
                          'This will permanently delete your account and all associated data. This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                );
                if (confirm != true || !context.mounted) return;
                try {
                  await FirebaseService().deleteAccount();
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 32),

            // ─── App Info ──────────────────────────────
            Center(
              child: Column(
                children: [
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
              : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color:
                    isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
              )
              : null),
    );
  }
}
