import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum MediaSourceType { camera, gallery, video }

class MediaPickerBottomSheet extends StatelessWidget {
  final Function(MediaSourceType) onMediaSelected;

  const MediaPickerBottomSheet({super.key, required this.onMediaSelected});

  static void show(BuildContext context, {required Function(MediaSourceType) onSelected}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? AppColors.darkBackground 
          : AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MediaPickerBottomSheet(onMediaSelected: onSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final iconColor = AppColors.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Attach Media',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt_rounded, color: iconColor),
              ),
              title: Text('Camera', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
              subtitle: Text('Take a photo', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                onMediaSelected(MediaSourceType.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library_rounded, color: iconColor),
              ),
              title: Text('Photo Gallery', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
              subtitle: Text('Choose a photo from gallery', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                onMediaSelected(MediaSourceType.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.videocam_rounded, color: iconColor),
              ),
              title: Text('Video', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
              subtitle: Text('Choose a video from gallery', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                onMediaSelected(MediaSourceType.video);
              },
            ),
          ],
        ),
      ),
    );
  }
}
