import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/firebase_service.dart';
import '../../../../widgets/custom_text_field.dart';

class AssignPlanScreen extends StatefulWidget {
  final String childId;

  const AssignPlanScreen({super.key, required this.childId});

  @override
  State<AssignPlanScreen> createState() => _AssignPlanScreenState();
}

class _AssignPlanScreenState extends State<AssignPlanScreen> {
  final _firebaseService = FirebaseService();
  final _titleController = TextEditingController();
  final _timeController = TextEditingController();
  final _durationController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submitPlan() async {
    if (_titleController.text.trim().isEmpty || _timeController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    
    try {
      final duration = int.tryParse(_durationController.text.trim()) ?? 15;
      final activity = {
        'title': _titleController.text.trim(),
        'time': _timeController.text.trim(),
        'duration': duration,
        'status': 'pending', // default status
      };

      // Mocking the parent ID for MVP purposes as child-to-parent mappings require deeper query logic.
      await _firebaseService.assignActivityToChild(
        _firebaseService.currentUser!.uid, 
        widget.childId, 
        activity,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Therapy task assigned!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Assign Therapy Task'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CustomTextField(
              label: 'Task Title',
              controller: _titleController,
              prefixIcon: Icons.title,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Time (e.g., 9:00 AM)',
              controller: _timeController,
              prefixIcon: Icons.access_time,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Duration (minutes)',
              controller: _durationController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.timer,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send to Patient'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
