import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/loading_state.dart';
import '../scoring/live_scoring_screen.dart';
import 'commentary_tab.dart';
import 'fall_of_wickets_tab.dart';
import 'partnerships_tab.dart';
import 'scorecard_provider.dart';
import 'scorecard_tab.dart';
import 'stats_charts_tab.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScorecardProvider>().loadMatchScorecard(widget.matchId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scorecardProv = context.watch<ScorecardProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (scorecardProv.isLoading || scorecardProv.match == null) {
      return const Scaffold(body: LoadingState(message: 'Loading match scorecard...'));
    }

    final match = scorecardProv.match!;
    final teamA = scorecardProv.teamA!;
    final teamB = scorecardProv.teamB!;
    final allInnings = scorecardProv.allInnings;
    final isLive = match.status.toLowerCase() == 'live';
    final isCancelled = match.status.toLowerCase() == 'cancelled';

    return Scaffold(
      appBar: AppBar(
        title: Text(match.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF Scorecard',
            onPressed: () => scorecardProv.exportPdfScorecard(),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Match Summary',
            onPressed: () => scorecardProv.shareScorecardText(),
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home Dashboard',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              // Innings Selector Pills
              if (allInnings.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(allInnings.length, (index) {
                        final inn = allInnings[index];
                        final isSelected = scorecardProv.selectedInningsIndex == index;
                        final teamName = inn.battingTeamId == teamA.id ? teamA.shortName : teamB.shortName;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => scorecardProv.setSelectedInningsIndex(index),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '$teamName: ${inn.totalRuns}/${inn.totalWickets} (${inn.oversDisplay})',
                                style: AppTextStyles.label.copyWith(
                                  color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

              // Main Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Scorecard'),
                  Tab(text: 'Commentary'),
                  Tab(text: 'Stats & Charts'),
                  Tab(text: 'Partnerships'),
                  Tab(text: 'Fall of Wickets'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (isCancelled)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.resultSummary ?? 'Match Cancelled',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Scored data and individual player statistics up to cancellation are preserved.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ScorecardTab(provider: scorecardProv),
                CommentaryTab(provider: scorecardProv),
                StatsChartsTab(provider: scorecardProv),
                PartnershipsTab(provider: scorecardProv),
                FallOfWicketsTab(provider: scorecardProv),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isLive
          ? Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: AppButton(
                label: 'Resume Live Scoring 🏏',
                icon: Icons.play_arrow_rounded,
                isFullWidth: true,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => LiveScoringScreen(matchId: match.id),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }
}
