import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_text_styles.dart';
import '../utils/date_formatter.dart';
import '../../data/models/innings.dart';
import '../../data/models/match.dart';
import '../../data/models/team.dart';
import 'app_card.dart';

class MatchTile extends StatelessWidget {
  final CricketMatch match;
  final Team teamA;
  final Team teamB;
  final List<Innings>? inningsList;
  final VoidCallback? onTap;
  final VoidCallback? onContinueScoring;
  final VoidCallback? onViewScorecard;

  const MatchTile({
    super.key,
    required this.match,
    required this.teamA,
    required this.teamB,
    this.inningsList,
    this.onTap,
    this.onContinueScoring,
    this.onViewScorecard,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLive = match.status.toLowerCase() == 'live';
    final isCompleted = match.status.toLowerCase() == 'completed';

    // Find innings for Team A and Team B
    Innings? innTeamA;
    Innings? innTeamB;

    if (inningsList != null) {
      for (final inn in inningsList!) {
        if (inn.battingTeamId == teamA.id) innTeamA = inn;
        if (inn.battingTeamId == teamB.id) innTeamB = inn;
      }
    }

    return AppCard(
      onTap: onTap ?? (isLive ? onContinueScoring : onViewScorecard),
      hasGlow: isLive,
      glowColor: AppColors.liveRed,
      borderColor: isLive ? AppColors.liveRed.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Format, Venue & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: Text(
                      match.format,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormatter.formatShortDate(
                      DateTime.fromMillisecondsSinceEpoch(match.matchDate),
                    ),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              // Status Tag
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.liveRed.withValues(alpha: 0.15),
                    borderRadius: AppRadius.roundedFull,
                    border: Border.all(color: AppColors.liveRed, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.liveRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.liveRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Text(
                    'COMPLETED',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Text(
                    'UPCOMING',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Match Title / Teams & Scores
          Row(
            children: [
              // Team A
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color(teamA.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            teamA.name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (innTeamA != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${innTeamA.totalRuns}/${innTeamA.totalWickets} (${innTeamA.oversDisplay} ov)',
                        style: AppTextStyles.scoreSmall.copyWith(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Text(
                'vs',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),

              // Team B
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            teamB.name,
                            textAlign: TextAlign.end,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color(teamB.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    if (innTeamB != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${innTeamB.totalRuns}/${innTeamB.totalWickets} (${innTeamB.oversDisplay} ov)',
                        style: AppTextStyles.scoreSmall.copyWith(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Footer: Result Summary / Venue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  match.resultSummary ?? match.venue,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: match.resultSummary != null
                        ? AppColors.primary
                        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    fontWeight: match.resultSummary != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
