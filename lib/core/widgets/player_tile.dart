import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_text_styles.dart';
import '../../data/models/player.dart';
import 'app_card.dart';

class PlayerTile extends StatelessWidget {
  final Player player;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;

  const PlayerTile({
    super.key,
    required this.player,
    this.onTap,
    this.trailing,
    this.isSelected = false,
    this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      borderColor: isSelected ? AppColors.primary : null,
      backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
      child: Row(
        children: [
          if (onSelectChanged != null) ...[
            Checkbox(
              value: isSelected,
              onChanged: onSelectChanged,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 4),
          ],

          // Jersey / Avatar Circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              borderRadius: AppRadius.roundedFull,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              player.jerseyNumber > 0 ? '${player.jerseyNumber}' : player.name.substring(0, 1).toUpperCase(),
              style: AppTextStyles.scoreSmall.copyWith(
                color: AppColors.primary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (player.isCaptain) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.accent, width: 0.8),
                        ),
                        child: Text(
                          'C',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (player.isWicketKeeper) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.info, width: 0.8),
                        ),
                        child: Text(
                          'WK',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.info,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${player.role} • ${player.battingStyle}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
