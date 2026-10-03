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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Team Crest / Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.15),
              borderRadius: AppRadius.roundedSm,
              border: Border.all(color: teamColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              team.shortName,
              style: AppTextStyles.scoreSmall.copyWith(
                color: teamColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Team Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: AppTextStyles.h3.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  captainName != null
                      ? '$playerCount Players • Capt: $captainName'
                      : '$playerCount Players Registered',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          ?trailing,
        ],
      ),
    );
  }
}
