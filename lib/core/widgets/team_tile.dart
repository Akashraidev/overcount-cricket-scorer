import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_text_styles.dart';
import '../../data/models/team.dart';
import 'app_card.dart';

class TeamTile extends StatelessWidget {
  final Team team;
  final int playerCount;
  final String? captainName;
  final VoidCallback? onTap;
  final Widget? trailing;

  const TeamTile({
    super.key,
    required this.team,
    this.playerCount = 0,
    this.captainName,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teamColor = Color(team.colorValue);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Team Crest / Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.15),
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: teamColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              team.shortName,
              style: AppTextStyles.scoreSmall.copyWith(
                color: teamColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Team Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: AppTextStyles.h3.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  captainName != null
                      ? '$playerCount Players • Capt: $captainName'
                      : '$playerCount Players Registered',
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
