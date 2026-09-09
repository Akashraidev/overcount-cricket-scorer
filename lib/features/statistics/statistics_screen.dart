import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../players/player_profile_screen.dart';
import 'statistics_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsProv = context.watch<StatisticsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cricket Analytics & Records'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Batting Leaderboard 🏏'),
            Tab(text: 'Bowling Leaderboard ⚾'),
          ],
        ),
      ),
      body: statsProv.isLoading
          ? const LoadingState(message: 'Compiling tournament records...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBattingLeaderboard(context, statsProv, isDark),
                _buildBowlingLeaderboard(context, statsProv, isDark),
              ],
            ),
    );
  }

  Widget _buildBattingLeaderboard(BuildContext context, StatisticsProvider statsProv, bool isDark) {
    final batters = statsProv.topBatters;

    if (batters.isEmpty) {
      return const EmptyState(
        title: 'No batting records yet',
        message: 'Records and leaderboards will automatically populate as matches are scored.',
        icon: Icons.leaderboard_outlined,
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: batters.length,
      itemBuilder: (context, index) {
        final b = batters[index];

        return AppCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => PlayerProfileScreen(playerId: b.playerId)),
            );
          },
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Rank badge
              _buildRankBadge(index + 1),
              const SizedBox(width: 12),

              // Player Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.playerName,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${b.teamName} • ${b.innings} Innings',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${b.runs} Runs',
                    style: AppTextStyles.scoreSmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Avg: ${b.average.toStringAsFixed(1)} | SR: ${b.strikeRate.toStringAsFixed(1)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBowlingLeaderboard(BuildContext context, StatisticsProvider statsProv, bool isDark) {
    final bowlers = statsProv.topBowlers;

    if (bowlers.isEmpty) {
      return const EmptyState(
        title: 'No bowling records yet',
        message: 'Bowling leaderboards will appear here as matches are scored.',
        icon: Icons.sports_baseball_outlined,
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: bowlers.length,
      itemBuilder: (context, index) {
        final bw = bowlers[index];

        return AppCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => PlayerProfileScreen(playerId: bw.playerId)),
            );
          },
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              _buildRankBadge(index + 1),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bw.playerName,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${bw.teamName} • ${(bw.totalLegalBalls / 6.0).toStringAsFixed(1)} Overs',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${bw.wickets} Wickets',
                    style: AppTextStyles.scoreSmall.copyWith(
                      color: AppColors.wicket,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Eco: ${bw.economy.toStringAsFixed(2)} | Best: ${bw.bestBowling}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bg;
    Color fg;

    if (rank == 1) {
      bg = const Color(0xFFEAB308); // Gold
      fg = Colors.black;
    } else if (rank == 2) {
      bg = const Color(0xFF94A3B8); // Silver
      fg = Colors.black;
    } else if (rank == 3) {
      bg = const Color(0xFFB45309); // Bronze
      fg = Colors.white;
    } else {
      bg = const Color(0xFF334155);
      fg = Colors.white70;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
