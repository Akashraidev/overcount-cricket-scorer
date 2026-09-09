import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/score_badge.dart';
import '../../../data/models/ball.dart';

class CurrentOverTrack extends StatelessWidget {
  final List<Ball> balls;
  final int overNumber;

  const CurrentOverTrack({
    super.key,
    required this.balls,
    required this.overNumber,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalRunsInOver = balls.fold<int>(0, (sum, b) => sum + b.totalRuns);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURRENT OVER (Ov ${overNumber + 1})',
                style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '$totalRunsInOver Runs',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (balls.isEmpty)
            Text(
              'Over just started • Awaiting first ball',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: balls.map((b) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ScoreBadge.fromBall(
                      runs: b.runsBat,
                      extraType: b.extraType,
                      isWicket: b.isWicket,
                      size: 34,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
