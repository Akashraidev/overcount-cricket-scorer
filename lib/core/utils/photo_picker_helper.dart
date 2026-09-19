import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_text_styles.dart';

class PhotoPickerHelper {
  PhotoPickerHelper._();

  static final ImagePicker _picker = ImagePicker();

  /// Shows a modal bottom sheet allowing the user to choose between Camera, Gallery, or Remove Photo.
  /// Returns the saved local image file path, or empty string if removed, or null if cancelled.
  static Future<String?> showPhotoSourceSheet({
    required BuildContext context,
    required String playerId,
    String? currentPhotoUrl,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sheet drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Profile Photo',
                  style: AppTextStyles.h3.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Capture a new photo or select one from your gallery',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Option 1: Camera
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22),
                  ),
                  title: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Take a new photo using device camera', style: TextStyle(fontSize: 12)),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                  onTap: () => Navigator.of(ctx).pop('camera'),
                ),
                const SizedBox(height: 8),

                // Option 2: Gallery
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.info, size: 22),
                  ),
                  title: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Choose an existing photo from library', style: TextStyle(fontSize: 12)),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                  onTap: () => Navigator.of(ctx).pop('gallery'),
                ),

                // Option 3: Remove Photo (if existing)
                if (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                    ),
                    title: const Text('Remove Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.error)),
                    subtitle: const Text('Revert to default jersey/initial avatar', style: TextStyle(fontSize: 12)),
                    shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                    onTap: () => Navigator.of(ctx).pop('remove'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return null;

    if (action == 'remove') {
      return ''; // Empty string indicates removed photo
    }

    try {
      final source = action == 'camera' ? ImageSource.camera : ImageSource.gallery;
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 88,
      );

      if (pickedFile == null) return null;

      // Save permanently in app documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDocDir.path, 'player_photos'));
      if (!photosDir.existsSync()) {
        photosDir.createSync(recursive: true);
      }

      final ext = p.extension(pickedFile.path).isNotEmpty ? p.extension(pickedFile.path) : '.jpg';
      final fileName = 'player_${playerId}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final targetPath = p.join(photosDir.path, fileName);

      final savedFile = await File(pickedFile.path).copy(targetPath);
      return savedFile.path;
    } catch (e) {
      if (context.mounted) {
        String errorMsg = 'Failed to pick photo: $e';
        if (e is PlatformException) {
          if (e.code == 'channel-error' || (e.message != null && e.message!.contains('channel'))) {
            errorMsg = 'Full App Restart Required: Please stop the app (click Red Stop button in Android Studio) and run it again so the native camera/gallery plugin is compiled into the APK.';
          } else if (e.code == 'camera_access_denied' || e.code == 'photo_access_denied') {
            errorMsg = 'Permission denied: Please grant camera and gallery permissions in device App Settings.';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return null;
    }
  }
}
