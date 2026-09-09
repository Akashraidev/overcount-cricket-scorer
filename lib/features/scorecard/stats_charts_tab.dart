import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';
import 'scorecard_provider.dart';

class StatsChartsTab extends StatelessWidget {
  final ScorecardProvider provider;

  const StatsChartsTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inn = provider.currentSelectedInnings;

    if (inn == null) {
      return const Center(child: Text('No match analytics available'));
    }

    final wormSpots1 = provider.getWormSpotsForInnings(0);
    final wormSpots2 = provider.getWormSpotsForInnings(1);
    final barGroups = provider.getRunRateBars(inn.id);

    final inn1 = provider.allInnings.isNotEmpty ? provider.allInnings[0] : null;
    final inn2 = provider.allInnings.length > 1 ? provider.allInnings[1] : null;

    final team1Name = inn1 != null
        ? (inn1.battingTeamId == provider.teamA?.id ? provider.teamA?.name : provider.teamB?.name) ?? '1st Innings'
        : '1st Innings';
    final team2Name = inn2 != null
        ? (inn2.battingTeamId == provider.teamA?.id ? provider.teamA?.name : provider.teamB?.name) ?? '2nd Innings'
        : '2nd Innings';

    // Boundaries Breakdown for selected innings
    final total4s = provider.currentBattingStats.fold<int>(0, (acc, b) => acc + b.fours);
    final total6s = provider.currentBattingStats.fold<int>(0, (acc, b) => acc + b.sixes);
    final boundaryRuns = (total4s * 4) + (total6s * 6);
    final boundaryPct = inn.totalRuns > 0 ? ((boundaryRuns / inn.totalRuns) * 100).toStringAsFixed(0) : '0';

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Boundaries & Scoring Highlights Card
          SectionHeader(
            title: 'Innings Highlights (${inn.inningsNumber == 1 ? team1Name : team2Name})',
            icon: Icons.stars_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 4s Card
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.boundary4.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.crop_square_rounded, size: 14, color: AppColors.boundary4),
                          ),
                          const SizedBox(width: 5),
                          const Text('4s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$total4s',
                        style: AppTextStyles.h2.copyWith(color: AppColors.boundary4),
                      ),
                      Text(
                        '${total4s * 4} runs',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 6s Card
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.boundary6.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.boundary6),
                          ),
                          const SizedBox(width: 5),
                          const Text('6s', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$total6s',
                        style: AppTextStyles.h2.copyWith(color: AppColors.boundary6),
                      ),
                      Text(
                        '${total6s * 6} runs',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Boundary % Card
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.pie_chart_outline_rounded, size: 14, color: AppColors.warning),
                          ),
                          const SizedBox(width: 5),
                          const Text('Bounds', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$boundaryPct%',
                        style: AppTextStyles.h2.copyWith(color: AppColors.warning),
                      ),
                      Text(
                        '$boundaryRuns runs',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Worm Chart (Cumulative Runs)
          const SectionHeader(
            title: 'Worm Chart (Cumulative Score)',
            icon: Icons.show_chart_rounded,
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 24),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      lineBarsData: [
                        // Innings 1 (Royal Blue #2563EB)
                        LineChartBarData(
                          spots: wormSpots1,
                          isCurved: true,
                          color: AppColors.chartInnings1,
                          barWidth: 3.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.chartInnings1.withValues(alpha: 0.08),
                          ),
                        ),
                        // Innings 2 (Vivid Crimson Red #DC2626)
                        if (wormSpots2.isNotEmpty && wormSpots2.length > 1)
                          LineChartBarData(
                            spots: wormSpots2,
                            isCurved: true,
                            color: AppColors.chartInnings2,
                            barWidth: 3.5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.chartInnings2.withValues(alpha: 0.08),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Distinct Legend
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Team 1 Indicator (Royal Blue)
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.chartInnings1,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$team1Name (1st Inn)',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (wormSpots2.length > 1) ...[
                        const SizedBox(width: 20),
                        // Team 2 Indicator (Vivid Crimson Red)
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.chartInnings2,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$team2Name (2nd Inn)',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Runs Per Over Bar Chart
          SectionHeader(
            title: 'Runs Per Over (${inn.inningsNumber == 1 ? team1Name : team2Name})',
            icon: Icons.bar_chart_rounded,
          ),
          const SizedBox(height: 12),
          if (barGroups.isNotEmpty)
            AppCard(
              padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    barGroups: barGroups,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),
            )
          else
            const Text('No overs completed yet'),
        ],
      ),
    );
  }
}
