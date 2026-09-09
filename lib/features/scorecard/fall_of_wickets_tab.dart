import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import 'scorecard_provider.dart';

class FallOfWicketsTab extends StatelessWidget {
  final ScorecardProvider provider;

  const FallOfWicketsTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fows = provider.currentFallOfWickets;

    if (fows.isEmpty) {
      return const EmptyState(
        title: 'No wickets fallen',
        message: 'Fall of wickets progression will appear here as wickets are recorded.',
        icon: Icons.sports_cricket,
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: fows.length,
      itemBuilder: (context, index) {
        final fow = fows[index];

        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Wicket Number Chip
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.wicket.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${fow.wicketNumber}',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.wicket,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Player & Over Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fow.playerName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dismissed at ${fow.overDisplay} Overs',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Score at dismissal
              Text(
                '${fow.score} Runs',
                style: AppTextStyles.scoreSmall.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
