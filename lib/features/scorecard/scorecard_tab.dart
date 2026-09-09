import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import 'scorecard_provider.dart';

class ScorecardTab extends StatelessWidget {
  final ScorecardProvider provider;

  const ScorecardTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inn = provider.currentSelectedInnings;

    if (inn == null) {
      return const Center(child: Text('No innings data available'));
    }

    final battingStats = provider.currentBattingStats;
    final bowlingStats = provider.currentBowlingStats;

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batting Table Card
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.sports_cricket, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Text('BATTING SCORECARD', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          columnSpacing: 14,
                          headingRowColor: WidgetStateProperty.all(
                            isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                          ),
                          columns: const [
                            DataColumn(label: Text('Batter', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Dismissal', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(numeric: true, label: Text('R', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(numeric: true, label: Text('B', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(numeric: true, label: Text('4s', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(numeric: true, label: Text('6s', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(numeric: true, label: Text('SR', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: battingStats.map((b) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    b.playerName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    b.dismissalSummary,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${b.runs}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                                DataCell(Text('${b.balls}')),
                                DataCell(Text('${b.fours}')),
                                DataCell(Text('${b.sixes}')),
                                DataCell(Text(b.strikeRate.toStringAsFixed(1))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Extras: ${inn.totalExtras} (wd ${inn.wides}, nb ${inn.noBalls}, b ${inn.byes}, lb ${inn.legByes}, p ${inn.penaltyRuns})',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                      Text(
                        'Total: ${inn.totalRuns}/${inn.totalWickets} (${inn.oversDisplay} Ov)',
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bowling Table Card
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.sports_baseball_outlined, size: 16, color: AppColors.accent),
                      ),
                      const SizedBox(width: 10),
                      Text('BOWLING SCORECARD', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          columnSpacing: 20,
                          headingRowColor: WidgetStateProperty.all(
                            isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                          ),
                          columns: const [
                            DataColumn(label: Text('Bowler', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(numeric: true, label: Text('O', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(numeric: true, label: Text('M', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(numeric: true, label: Text('R', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(numeric: true, label: Text('W', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(numeric: true, label: Text('ECO', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: bowlingStats.map((bw) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    bw.playerName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                                DataCell(Text(bw.oversDisplay)),
                                DataCell(Text('${bw.maidens}')),
                                DataCell(Text('${bw.runsConceded}')),
                                DataCell(
                                  Text(
                                    '${bw.wickets}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.wicket),
                                  ),
                                ),
                                DataCell(Text(bw.economy.toStringAsFixed(2))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
