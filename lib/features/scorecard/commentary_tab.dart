import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/score_badge.dart';
import 'scorecard_provider.dart';

class CommentaryTab extends StatelessWidget {
  final ScorecardProvider provider;

  const CommentaryTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balls = provider.currentBalls.reversed.toList(); // Newest first

    if (balls.isEmpty) {
      return const EmptyState(
        title: 'No commentary yet',
        message: 'Ball by ball commentary updates will appear here as deliveries are bowled.',
        icon: Icons.comment_bank_outlined,
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: balls.length,
      itemBuilder: (context, index) {
        final b = balls[index];

        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Over Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  b.overDisplay,
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Ball outcome badge
              ScoreBadge.fromBall(
                runs: b.runsBat,
                extraType: b.extraType,
                isWicket: b.isWicket,
                size: 28,
              ),
              const SizedBox(width: 12),

              // Commentary String
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.commentary.isNotEmpty ? b.commentary : '${b.runsBat} run(s) recorded',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: b.isWicket || b.runsBat == 4 || b.runsBat == 6
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: b.isWicket
                            ? AppColors.wicket
                            : (b.runsBat >= 4
                                ? AppColors.primaryLight
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
