import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../models/guidance_note_model.dart';
import '../../../services/firebase_service.dart';

/// Screen for doctors to write and send secure guidance notes to parents.
class ComposeGuidanceNoteScreen extends StatefulWidget {
  final String childId;

  const ComposeGuidanceNoteScreen({super.key, required this.childId});

  @override
  State<ComposeGuidanceNoteScreen> createState() =>
      _ComposeGuidanceNoteScreenState();
}

class _ComposeGuidanceNoteScreenState extends State<ComposeGuidanceNoteScreen> {
  final _firebaseService = FirebaseService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;

  final List<String> _categories = [
    'Progress Update',
    'Routine Change',
    'General Advice',
    'Behavior Management',
    'Therapy Adjustments',
  ];
  String? _selectedCategory;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _sendNote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a note category.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _firebaseService.currentUser;
      if (user == null) throw Exception('Doctor not signed in');

      final note = GuidanceNoteModel(
        id: const Uuid().v4(),
        doctorId: user.uid,
        doctorName: user.displayName ?? 'Doctor',
        childId: widget.childId,
        title: '[$_selectedCategory] ${_titleController.text.trim()}',
        content: _contentController.text.trim(),
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _firebaseService.sendGuidanceNote(note);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guidance note sent!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context); // Go back
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending note: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Compose Note'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor:
            isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header Info ─────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.doctorPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.doctorPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        color: AppColors.doctorPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Notes are sent securely to the parents and remain attached to the patient profile.',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                // ─── Category ────────────────────────────────
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      _categories.map((c) {
                        final isSelected = _selectedCategory == c;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.doctorPrimary
                                      : (isDark
                                          ? AppColors.darkSurface
                                          : Colors.white),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.doctorPrimary
                                        : (isDark
                                            ? AppColors.darkDivider
                                            : AppColors.divider),
                              ),
                            ),
                            child: Text(
                              c,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                const SizedBox(height: 28),

                // ─── Title ───────────────────────────────────
                Text(
                  'Subject',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  validator:
                      (val) =>
                          val == null || val.isEmpty
                              ? 'Please enter a subject'
                              : null,
                  style: TextStyle(
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Behavioral Progress Last Week',
                    hintStyle: TextStyle(
                      color:
                          isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            isDark ? AppColors.darkDivider : AppColors.divider,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color:
                            isDark ? AppColors.darkDivider : AppColors.divider,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.doctorPrimary,
                        width: 2,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 28),

                // ─── Content ─────────────────────────────────
                Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentController,
                  validator:
                      (val) =>
                          val == null || val.isEmpty
                              ? 'Please enter your message'
                              : null,
                  maxLines: 10,
                  style: TextStyle(
                    color:
                        isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Type your guidance, feedback, or instructions here...',
                    hintStyle: TextStyle(
                      color:
                          isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color:
                            isDark ? AppColors.darkDivider : AppColors.divider,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color:
                            isDark ? AppColors.darkDivider : AppColors.divider,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.doctorPrimary,
                        width: 2,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                const SizedBox(height: 32),

                // ─── Submit Button ─────────────────────────
                SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _sendNote,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient:
                                _isSubmitting ? null : AppGradients.doctor,
                            color:
                                _isSubmitting
                                    ? (isDark
                                        ? AppColors.darkSurfaceVariant
                                        : AppColors.surfaceVariant)
                                    : null,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child:
                                _isSubmitting
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                    : const Text(
                                      'Send Note',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms)
                    .slideY(begin: 0.1),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
