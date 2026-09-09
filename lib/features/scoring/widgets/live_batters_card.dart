import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/batting_stat.dart';
import '../../../data/models/partnership.dart';
import '../../../data/models/player.dart';

class LiveBattersCard extends StatelessWidget {
  final Player? striker;
  final BattingStat? strikerStat;
  final Player? nonStriker;
  final BattingStat? nonStrikerStat;
  final Partnership? partnership;
  final VoidCallback onSwapStrike;
  final VoidCallback? onChangeStriker;
  final VoidCallback? onChangeNonStriker;

  const LiveBattersCard({
    super.key,
    required this.striker,
    required this.strikerStat,
    required this.nonStriker,
    required this.nonStrikerStat,
    this.partnership,
    required this.onSwapStrike,
    this.onChangeStriker,
    this.onChangeNonStriker,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BATTERS',
                style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              InkWell(
                onTap: onSwapStrike,
                borderRadius: AppRadius.roundedSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_vert, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Swap Strike',
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

          // Striker Row (On Strike)
          if (striker != null)
            _buildBatterRow(
              context,
              name: striker!.name,
              runs: strikerStat?.runs ?? 0,
              balls: strikerStat?.balls ?? 0,
              fours: strikerStat?.fours ?? 0,
              sixes: strikerStat?.sixes ?? 0,
              strikeRate: strikerStat?.strikeRate ?? 0.0,
              isOnStrike: true,
              isDark: isDark,
              onTap: onChangeStriker,
            )
          else
            _buildEmptyBatterRow(
              context,
              label: 'No Striker — Tap to Add / Select Striker (*)',
              isOnStrike: true,
              isDark: isDark,
              onTap: onChangeStriker,
            ),

          const SizedBox(height: 8),

          // Non-Striker Row
          if (nonStriker != null)
            _buildBatterRow(
              context,
              name: nonStriker!.name,
              runs: nonStrikerStat?.runs ?? 0,
              balls: nonStrikerStat?.balls ?? 0,
              fours: nonStrikerStat?.fours ?? 0,
              sixes: nonStrikerStat?.sixes ?? 0,
              strikeRate: nonStrikerStat?.strikeRate ?? 0.0,
              isOnStrike: false,
              isDark: isDark,
              onTap: onChangeNonStriker,
            )
          else
            _buildEmptyBatterRow(
              context,
              label: 'No Non-Striker — Tap to Add / Select Non-Striker',
              isOnStrike: false,
              isDark: isDark,
              onTap: onChangeNonStriker,
            ),

          if (partnership != null) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.handshake_outlined, size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Partnership: ${partnership!.totalRuns} (${partnership!.totalBalls})',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyBatterRow(
    BuildContext context, {
    required String label,
    required bool isOnStrike,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.roundedSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isOnStrike
              ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
              : (isDark ? AppColors.darkSurfaceElevated.withValues(alpha: 0.3) : AppColors.lightSurfaceElevated.withValues(alpha: 0.5)),
          borderRadius: AppRadius.roundedSm,
          border: Border.all(
            color: isOnStrike
                ? AppColors.primary.withValues(alpha: 0.45)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isOnStrike ? Icons.sports_cricket : Icons.person_add_outlined,
              size: 18,
              color: isOnStrike ? AppColors.primary : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isOnStrike
                      ? AppColors.primary
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.add_circle_outline,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatterRow(
    BuildContext context, {
    required String name,
    required int runs,
    required int balls,
    required int fours,
    required int sixes,
    required double strikeRate,
    required bool isOnStrike,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.roundedSm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isOnStrike
              ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08)
              : Colors.transparent,
          borderRadius: AppRadius.roundedSm,
          border: isOnStrike
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          children: [
            // On Strike Indicator Ball / Dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnStrike ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),

            // Name
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      isOnStrike ? '$name *' : name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: isOnStrike ? FontWeight.bold : FontWeight.w500,
                        color: isOnStrike
                            ? AppColors.primary
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ],
              ),
            ),

            // Runs (Balls)
            Text(
              '$runs ($balls)',
              style: AppTextStyles.scoreSmall.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 14),

            // 4s & 6s
            Text(
              '4s: $fours  6s: $sixes',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 12),

            // Strike Rate
            SizedBox(
              width: 44,
              child: Text(
                strikeRate.toStringAsFixed(1),
                textAlign: TextAlign.end,
                style: AppTextStyles.scoreSmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
