import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'app_button.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final List<Widget>? actions;

  // Visual polish & customization parameters
  final Widget? icon;
  final String? subtitle;
  final TextAlign titleAlignment;
  final bool? centerContent;
  final double? maxWidth;
  final EdgeInsets? insetPadding;
  final EdgeInsets? padding;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.actions,
    this.icon,
    this.subtitle,
    this.titleAlignment = TextAlign.center,
    this.centerContent,
    this.maxWidth,
    this.insetPadding,
    this.padding,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDestructive = false,
    List<Widget>? actions,
    Widget? icon,
    String? subtitle,
    TextAlign titleAlignment = TextAlign.center,
    bool? centerContent,
    double? maxWidth,
    EdgeInsets? insetPadding,
    EdgeInsets? padding,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
        actions: actions,
        icon: icon,
        subtitle: subtitle,
        titleAlignment: titleAlignment,
        centerContent: centerContent,
        maxWidth: maxWidth,
        insetPadding: insetPadding,
        padding: padding,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // Responsive breakpoints
    final isSmallMobile = screenWidth < 360;
    final isMobile = screenWidth < 600;
    final isTabletOrDesktop = screenWidth >= 600;

    // Sizing & constraints
    final effectiveMaxWidth = maxWidth ??
        (isTabletOrDesktop
            ? 480.0
            : math.min(screenWidth - (isSmallMobile ? 24.0 : 36.0), 440.0));
    final effectiveInsetPadding = insetPadding ??
        EdgeInsets.symmetric(
          horizontal: isSmallMobile ? 12.0 : (isMobile ? 18.0 : 32.0),
          vertical: 24.0,
        );
    final effectivePadding = padding ??
        (isSmallMobile
            ? const EdgeInsets.fromLTRB(16, 20, 16, 16)
            : (isMobile
                ? const EdgeInsets.fromLTRB(20, 24, 20, 20)
                : const EdgeInsets.fromLTRB(28, 28, 28, 24)));

    // Typography for heading - adapts gracefully and centers multi-line text cleanly
    final titleStyle = (isMobile ? AppTextStyles.h3 : AppTextStyles.h2).copyWith(
      fontSize: isSmallMobile ? 17 : (isMobile ? 18.5 : 20.5),
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.3,
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    );

    // Auto-detect whether content should be centered (default to true for simple Text messages)
    final shouldCenter = centerContent ?? (content is Text);

    Widget contentWidget;
    if (shouldCenter) {
      contentWidget = Center(
        child: DefaultTextStyle.merge(
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            height: 1.45,
          ),
          child: content,
        ),
      );
    } else {
      contentWidget = DefaultTextStyle.merge(
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          height: 1.45,
        ),
        child: content,
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: effectiveInsetPadding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: effectiveMaxWidth,
            minWidth: isSmallMobile ? (screenWidth - 24) : 280.0,
          ),
          child: Material(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.0,
              ),
            ),
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.18),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: effectivePadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Optional top icon badge
                  if (icon != null) ...[
                    Center(child: icon!),
                    const SizedBox(height: 14),
                  ],

                  // Centered multi-line Heading
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      title,
                      textAlign: titleAlignment,
                      style: titleStyle,
                      softWrap: true,
                    ),
                  ),

                  // Optional subtitle
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Content Area (properly balanced & flexible)
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: double.infinity,
                        child: contentWidget,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons (balanced, symmetrical layout)
                  _buildActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (actions != null) {
      if (actions!.isEmpty) return const SizedBox.shrink();

      if (actions!.length == 1) {
        final single = actions!.first;
        if (single is AppButton && !single.isFullWidth) {
          return SizedBox(width: double.infinity, child: single);
        }
        return SizedBox(width: double.infinity, child: single);
      }

      // Check if actions list is [AppButton, SizedBox, AppButton] pattern
      if (actions!.length == 3 &&
          actions![0] is AppButton &&
          actions![1] is SizedBox &&
          actions![2] is AppButton) {
        return Row(
          children: [
            Expanded(child: actions![0]),
            const SizedBox(width: 12),
            Expanded(child: actions![2]),
          ],
        );
      }

      final hasFullWidth = actions!.any((a) => a is AppButton && a.isFullWidth);
      if (hasFullWidth) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: actions!.map((action) {
            if (action is AppButton) {
              return SizedBox(width: double.infinity, child: action);
            }
            return action;
          }).toList(),
        );
      }

      final allAppButtons = actions!.every((a) => a is AppButton);
      if (allAppButtons && actions!.length == 2) {
        return Row(
          children: [
            Expanded(child: actions![0]),
            const SizedBox(width: 12),
            Expanded(child: actions![1]),
          ],
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: actions!.map((action) {
          if (action is AppButton && action.isFullWidth) {
            return Expanded(child: action);
          }
          return action;
        }).toList(),
      );
    }

    // Default confirm/cancel buttons
    if (cancelLabel != null && confirmLabel != null) {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              label: cancelLabel!,
              variant: AppButtonVariant.outline,
              height: 42,
              onPressed: onCancel ?? () => Navigator.of(context).pop(false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: confirmLabel!,
              variant: isDestructive ? AppButtonVariant.danger : AppButtonVariant.primary,
              height: 42,
              onPressed: onConfirm,
            ),
          ),
        ],
      );
    } else if (confirmLabel != null) {
      return SizedBox(
        width: double.infinity,
        child: AppButton(
          label: confirmLabel!,
          variant: isDestructive ? AppButtonVariant.danger : AppButtonVariant.primary,
          height: 44,
          isFullWidth: true,
          onPressed: onConfirm,
        ),
      );
    } else if (cancelLabel != null) {
      return SizedBox(
        width: double.infinity,
        child: AppButton(
          label: cancelLabel!,
          variant: AppButtonVariant.outline,
          height: 44,
          isFullWidth: true,
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
