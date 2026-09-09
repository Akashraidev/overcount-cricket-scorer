import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';

class MatchCompleteDialog extends StatelessWidget {
  final String title;
  final String summary;
  final VoidCallback onViewScorecard;
  final VoidCallback? onHome;

  const MatchCompleteDialog({
    super.key,
    required this.title,
    required this.summary,
    required this.onViewScorecard,
    this.onHome,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String summary,
    required VoidCallback onViewScorecard,
    VoidCallback? onHome,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MatchCompleteDialog(
        title: title,
        summary: summary,
        onViewScorecard: onViewScorecard,
        onHome: onHome,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: AppDialog(
        title: 'MATCH FINISHED! 🏆',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.25),
                    AppColors.primary.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 2),
              ),
              child: const Icon(Icons.emoji_events_rounded, size: 52, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                summary,
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          AppButton(
            label: 'View Complete Scorecard',
            icon: Icons.receipt_long_rounded,
            isFullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              onViewScorecard();
            },
          ),
          if (onHome != null) ...[
            const SizedBox(height: 8),
            AppButton(
              label: 'Back to Home Dashboard',
              icon: Icons.home_rounded,
              isFullWidth: true,
              variant: AppButtonVariant.outline,
              onPressed: () {
                Navigator.of(context).pop();
                onHome!();
              },
            ),
          ],
        ],
      ),
    );
  }
}
