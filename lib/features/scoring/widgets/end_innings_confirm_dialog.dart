import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../data/models/innings.dart';
import '../../../data/models/match.dart';
import '../../../data/models/team.dart';

class EndInningsConfirmDialog extends StatelessWidget {
  final Innings innings;
  final CricketMatch match;
  final Team battingTeam;
  final Team bowlingTeam;
  final VoidCallback onConfirm;
  final VoidCallback onReview;

  const EndInningsConfirmDialog({
    super.key,
    required this.innings,
    required this.match,
    required this.battingTeam,
    required this.bowlingTeam,
    required this.onConfirm,
    required this.onReview,
  });

  static Future<void> show(
    BuildContext context, {
    required Innings innings,
    required CricketMatch match,
    required Team battingTeam,
    required Team bowlingTeam,
    required VoidCallback onConfirm,
    required VoidCallback onReview,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EndInningsConfirmDialog(
        innings: innings,
        match: match,
        battingTeam: battingTeam,
        bowlingTeam: bowlingTeam,
        onConfirm: onConfirm,
        onReview: onReview,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOversLimit = innings.totalLegalBalls >= (match.totalOvers * match.ballsPerOver);
    final isAllOut = innings.totalWickets >= match.wicketsPerInnings;
    final target = innings.totalRuns + 1;
    final double runRate = innings.totalLegalBalls > 0
        ? (innings.totalRuns / (innings.totalLegalBalls / match.ballsPerOver))
        : 0.0;
    final double reqRunRate = match.totalOvers > 0
        ? (target / match.totalOvers)
        : 0.0;

    return AppDialog(
      title: '1st Innings Finished! 🏁',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status notice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isOversLimit ? AppColors.info : AppColors.wicket).withValues(alpha: 0.12),
                borderRadius: AppRadius.roundedSm,
                border: Border.all(
                  color: (isOversLimit ? AppColors.info : AppColors.wicket).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isOversLimit ? Icons.sports_cricket : Icons.group_off_rounded,
                    size: 18,
                    color: isOversLimit ? AppColors.info : AppColors.wicket,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOversLimit
                          ? 'All ${match.totalOvers} overs completed!'
                          : (isAllOut ? 'All out! Maximum wickets reached.' : 'Innings completed.'),
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOversLimit ? AppColors.info : AppColors.wicket,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Scorecard Highlight Card
            AppCard(
              backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              borderColor: AppColors.primary.withValues(alpha: 0.4),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Batting Team & Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(battingTeam.colorValue),
                            child: Text(
                              battingTeam.shortName,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            battingTeam.name,
                            style: AppTextStyles.h3.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                      Text(
                        '${innings.totalRuns} / ${innings.totalWickets}',
                        style: AppTextStyles.scoreMedium.copyWith(fontSize: 26, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Overs & Run Rate
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overs: ${innings.oversDisplay} / ${match.totalOvers} ov',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Run Rate: ${runRate.toStringAsFixed(2)} RPO',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Target Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: AppRadius.roundedSm,
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TARGET FOR ${bowlingTeam.name.toUpperCase()}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.label.copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$target RUNS',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.scoreMedium.copyWith(
                            color: AppColors.accent,
                            fontSize: 22,
                          ),
                        ),
                        Text(
                          'Need $target runs in ${match.totalOvers} overs (Req. RR: ${reqRunRate.toStringAsFixed(2)} RPO)',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Confirmation question
            Text(
              'Do you want to end the 1st innings and proceed to the 2nd innings break?',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'If you need to edit or undo the last ball, tap "Review / Not Yet".',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onReview();
                },
                child: const Text('Review / Not Yet'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: 'End 1st Innings ➔',
                variant: AppButtonVariant.primary,
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
