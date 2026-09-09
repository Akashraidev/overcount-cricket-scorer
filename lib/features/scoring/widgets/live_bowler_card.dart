import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/bowling_stat.dart';
import '../../../data/models/player.dart';

class LiveBowlerCard extends StatelessWidget {
  final Player? bowler;
  final BowlingStat? bowlerStat;
  final VoidCallback onChangeBowler;

  const LiveBowlerCard({
    super.key,
    required this.bowler,
    required this.bowlerStat,
    required this.onChangeBowler,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasBowler = bowler != null;

    final overs = bowlerStat?.oversDisplay ?? '0.0';
    final maidens = bowlerStat?.maidens ?? 0;
    final runs = bowlerStat?.runsConceded ?? 0;
    final wickets = bowlerStat?.wickets ?? 0;
    final eco = bowlerStat?.economy.toStringAsFixed(2) ?? '0.00';

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURRENT BOWLER',
                style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              InkWell(
                onTap: onChangeBowler,
                borderRadius: AppRadius.roundedSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        hasBowler ? Icons.change_circle_outlined : Icons.person_add_alt_1,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasBowler ? 'Change Bowler' : '+ Add Bowler',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (hasBowler)
            InkWell(
              onTap: onChangeBowler,
              borderRadius: AppRadius.roundedSm,
              child: Row(
                children: [
                  const Icon(Icons.sports_baseball, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bowler!.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Figures
                  Text(
                    '$overs - $maidens - $runs - $wickets',
                    style: AppTextStyles.scoreSmall.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Economy
                  Text(
                    'Eco: $eco',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: onChangeBowler,
              borderRadius: AppRadius.roundedSm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: AppRadius.roundedSm,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add_alt_1, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Tap to Add / Select Bowler',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
