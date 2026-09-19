import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, danger, text, pill }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 48,
    this.width,
  });

  /// Convenience constructor for the signature pill-shaped button
  const AppButton.pill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 34,
    this.width,
  }) : variant = AppButtonVariant.pill;

  @override
  Widget build(BuildContext context) {
    if (variant == AppButtonVariant.pill) {
      final pillButton = FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          minimumSize: Size(width ?? (isFullWidth ? double.infinity : 0), height ?? 34),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedFull),
          elevation: 0,
        ),
        icon: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon ?? Icons.add_rounded, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );

      if (isFullWidth) {
        return SizedBox(width: double.infinity, child: pillButton);
      }
      return pillButton;
    }

    Widget buttonChild;
    if (isLoading) {
      buttonChild = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.button,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    } else {
      buttonChild = Text(
        label,
        style: AppTextStyles.button,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      );
    }

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
            minimumSize: Size(width ?? (isFullWidth ? double.infinity : 64), height ?? 48),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurfaceElevated,
            foregroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
            minimumSize: Size(width ?? (isFullWidth ? double.infinity : 64), height ?? 48),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            side: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
            ),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
            minimumSize: Size(width ?? (isFullWidth ? double.infinity : 64), height ?? 48),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
            minimumSize: Size(width ?? (isFullWidth ? double.infinity : 64), height ?? 48),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
            minimumSize: Size(width ?? 48, height ?? 40),
          ),
          child: buttonChild,
        );
        break;

      case AppButtonVariant.pill:
        // Handled at start of build method
        button = const SizedBox.shrink();
        break;
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Signature header action button following the unified Dashboard 'New Match' design system:
/// - Pill shape (AppRadius.roundedFull)
/// - Height: 34px (minimumSize: Size(0, 34))
/// - Background: AppColors.primary
/// - Foreground: Colors.white
/// - Rounded icon: 18px (default Icons.add_rounded)
/// - Compact bold typography: 12.5px, w700, letterSpacing: 0.2
/// - Padding: symmetric(horizontal: 12, vertical: 0)
/// - Configurable [margin] (defaults to null or outer padding)
class AppHeaderActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool isLoading;
  final EdgeInsetsGeometry? margin;

  const AppHeaderActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.isLoading = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(0, 34),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedFull),
        elevation: 0,
      ),
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    );

    if (margin != null) {
      return Padding(padding: margin!, child: button);
    }
    return button;
  }
}
