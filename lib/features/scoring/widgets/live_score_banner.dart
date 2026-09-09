import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/cricket_calc.dart';
import '../../../core/widgets/animated_score_counter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/innings.dart';
import '../../../data/models/match.dart';
import '../../../data/models/team.dart';

class LiveScoreBanner extends StatelessWidget {
  final CricketMatch match;
  final Innings innings;
  final Team battingTeam;
  final Team bowlingTeam;
  final Innings? firstInnings;

  const LiveScoreBanner({
    super.key,
    required this.match,
    required this.innings,
    required this.battingTeam,
    required this.bowlingTeam,
    this.firstInnings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teamColor = Color(battingTeam.colorValue);

    final totalBallsInMatch = match.totalOvers * match.ballsPerOver;
    final isSecondInnings = innings.inningsNumber == 2 && innings.targetRuns != null;
    final runsNeeded = isSecondInnings ? (innings.targetRuns! - innings.totalRuns) : null;
    final ballsRemaining = isSecondInnings ? (totalBallsInMatch - innings.totalLegalBalls) : null;

    final rrr = isSecondInnings
        ? CricketCalc.calculateRRR(
            targetRuns: innings.targetRuns!,
            currentRuns: innings.totalRuns,
            totalMatchBalls: totalBallsInMatch,
            currentLegalBalls: innings.totalLegalBalls,
            ballsPerOver: match.ballsPerOver,
          )
        : null;

    return AppCard(
      gradient: isDark ? AppColors.liveHeaderGradient : null,
      backgroundColor: isDark ? null : Colors.white,
      borderColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batting Team Badge & Innings Number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: teamColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    battingTeam.name.toUpperCase(),
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primaryLight,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  'Innings ${innings.inningsNumber} of 2',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Big Score & Overs Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Runs
              AnimatedScoreCounter(
                count: innings.totalRuns,
                style: AppTextStyles.scoreDisplay.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontSize: 44,
                ),
              ),
              Text(
                ' / ${innings.totalWickets}',
                style: AppTextStyles.scoreMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 28,
                ),
              ),
              const Spacer(),
              // Overs
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${innings.oversDisplay} / ${match.totalOvers}',
                    style: AppTextStyles.scoreMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    'OVERS',
                    style: AppTextStyles.label.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 20),

          // Rates & Target Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // CRR
              Row(
                children: [
                  Text(
                    'CRR: ',
                    style: AppTextStyles.label.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  Text(
                    innings.currentRunRate.toStringAsFixed(2),
                    style: AppTextStyles.scoreSmall.copyWith(
                      color: AppColors.accent,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              // RRR (if 2nd Innings)
              if (rrr != null) ...[
                Row(
                  children: [
                    Text(
                      'RRR: ',
                      style: AppTextStyles.label.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    Text(
                      rrr.toStringAsFixed(2),
                      style: AppTextStyles.scoreSmall.copyWith(
                        color: AppColors.warning,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],

              // Target requirement note
              if (isSecondInnings && runsNeeded != null && ballsRemaining != null) ...[
                Text(
                  runsNeeded > 0
                      ? 'Need $runsNeeded in $ballsRemaining b'
                      : 'Target reached!',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: runsNeeded > 0 ? AppColors.primaryLight : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                Text(
                  'Extras: ${innings.totalExtras}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
