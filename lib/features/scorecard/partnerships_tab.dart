import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import 'scorecard_provider.dart';

class PartnershipsTab extends StatelessWidget {
  final ScorecardProvider provider;

  const PartnershipsTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final partnerships = provider.currentPartnerships;

    if (partnerships.isEmpty) {
      return const EmptyState(
        title: 'No partnerships recorded',
        message: 'Partnerships will appear here as batting stands develop.',
        icon: Icons.handshake_outlined,
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: partnerships.length,
      itemBuilder: (context, index) {
        final p = partnerships[index];

        final batter1Ratio = p.totalRuns > 0 ? (p.batter1Runs / p.totalRuns) : 0.5;

        return AppCard(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${p.wicketNumber}${_getOrdinal(p.wicketNumber)} Wicket Stand',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${p.totalRuns} Runs (${p.totalBalls} balls)',
                    style: AppTextStyles.scoreSmall.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Visual Progress Bar
              ClipRRect(
                borderRadius: AppRadius.roundedSm,
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (batter1Ratio * 100).toInt().clamp(1, 99),
                        child: Container(color: AppColors.primary),
                      ),
                      Expanded(
                        flex: ((1 - batter1Ratio) * 100).toInt().clamp(1, 99),
                        child: Container(color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Batters Breakdown Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Batter 1
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.batter1Name,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${p.batter1Runs} (${p.batter1Balls})',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Batter 2
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        p.batter2Name,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${p.batter2Runs} (${p.batter2Balls})',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getOrdinal(int number) {
    if (number == 1) return 'st';
    if (number == 2) return 'nd';
    if (number == 3) return 'rd';
    return 'th';
  }
}
