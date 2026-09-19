import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class PlayerAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final int jerseyNumber;
  final double size;
  final int? colorValue;
  final VoidCallback? onTap;
  final bool showCameraBadge;
  final VoidCallback? onCameraTap;

  const PlayerAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.jerseyNumber = 0,
    this.size = 52.0,
    this.colorValue,
    this.onTap,
    this.showCameraBadge = false,
    this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = colorValue != null ? Color(colorValue!) : AppColors.primary;
    final hasLocalPhoto = photoUrl != null &&
        photoUrl!.isNotEmpty &&
        File(photoUrl!).existsSync();
    final hasRemotePhoto = photoUrl != null &&
        photoUrl!.isNotEmpty &&
        (photoUrl!.startsWith('http://') || photoUrl!.startsWith('https://'));

    Widget avatarCore;
    if (hasLocalPhoto) {
      avatarCore = ClipOval(
        child: Image.file(
          File(photoUrl!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _buildFallback(themeColor),
        ),
      );
    } else if (hasRemotePhoto) {
      avatarCore = ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _buildFallback(themeColor),
        ),
      );
    } else {
      avatarCore = _buildFallback(themeColor);
    }

    Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: themeColor, width: size > 50 ? 2.0 : 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: avatarCore,
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    if (showCameraBadge) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            bottom: -2,
            right: -2,
            child: GestureDetector(
              onTap: onCameraTap ?? onTap,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return content;
  }

  Widget _buildFallback(Color themeColor) {
    String display;
    if (jerseyNumber > 0) {
      display = '$jerseyNumber';
    } else if (name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        display = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        display = name.substring(0, 1).toUpperCase();
      }
    } else {
      display = '?';
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            themeColor.withValues(alpha: 0.25),
            themeColor.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        display,
        style: AppTextStyles.scoreMedium.copyWith(
          color: themeColor,
          fontSize: size * 0.40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
