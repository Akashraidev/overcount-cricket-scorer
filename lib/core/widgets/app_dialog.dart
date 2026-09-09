import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';
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
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AppDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isDestructive: isDestructive,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedXl),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: AppSpacing.dialogPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: content)),
              const SizedBox(height: 24),
              if (actions != null)
                Builder(
                  builder: (context) {
                    if (actions!.length == 1) {
                      final single = actions!.first;
                      if (single is AppButton && !single.isFullWidth) {
                        return Align(alignment: Alignment.centerRight, child: single);
                      }
                      return SizedBox(width: double.infinity, child: single);
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
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions!.map((action) {
                        if (action is AppButton && action.isFullWidth) {
                          return Expanded(child: action);
                        }
                        return action;
                      }).toList(),
                    );
                  },
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (cancelLabel != null)
                      AppButton(
                        label: cancelLabel!,
                        variant: AppButtonVariant.outline,
                        height: 40,
                        onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                      ),
                    if (cancelLabel != null && confirmLabel != null)
                      const SizedBox(width: 12),
                    if (confirmLabel != null)
                      AppButton(
                        label: confirmLabel!,
                        variant: isDestructive ? AppButtonVariant.danger : AppButtonVariant.primary,
                        height: 40,
                        onPressed: onConfirm,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
