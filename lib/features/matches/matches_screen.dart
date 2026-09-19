import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/match_tile.dart';
import '../scorecard/match_detail_screen.dart';
import '../scoring/live_scoring_screen.dart';
import '../scoring/widgets/join_match_dialog.dart';
import '../teams/team_provider.dart';
import 'create_match_wizard.dart';
import 'match_provider.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matchProv = context.watch<MatchProvider>();
    final teamProv = context.watch<TeamProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statuses = ['All', 'Live', 'Completed', 'Upcoming'];
    final matches = matchProv.matches;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_find_rounded),
            tooltip: 'Join Live Match (Wi-Fi)',
            onPressed: () => JoinMatchDialog.show(context),
          ),
          AppHeaderActionButton(
            label: 'New Match',
            icon: Icons.add_rounded,
            margin: const EdgeInsets.only(right: 14),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CreateMatchWizard()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: AppTextField(
              hint: 'Search matches by team or venue...',
              prefixIcon: const Icon(Icons.search, size: 20),
              onChanged: (v) => matchProv.setSearchQuery(v),
            ),
          ),

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: statuses.map((s) {
                final isSelected = matchProv.statusFilter.toLowerCase() == s.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s),
                    selected: isSelected,
                    onSelected: (_) => matchProv.setStatusFilter(s),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: AppTextStyles.label.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedFull),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Matches List
          Expanded(
            child: matchProv.isLoading
                ? const LoadingState(message: 'Loading matches...')
                : matches.isEmpty
                    ? EmptyState(
                        title: 'No matches found',
                        message: 'Schedule a match or adjust your filter.',
                        actionLabel: 'Create Match',
                        onAction: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const CreateMatchWizard()),
                          );
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: () => matchProv.loadMatches(),
                        child: ListView.builder(
                          padding: AppSpacing.screenPadding,
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final m = matches[index];
                            final teamA = teamProv.teams.firstWhere(
                              (t) => t.id == m.teamAId,
                              orElse: () => teamProv.teams.first,
                            );
                            final teamB = teamProv.teams.firstWhere(
                              (t) => t.id == m.teamBId,
                              orElse: () => teamProv.teams.length > 1 ? teamProv.teams[1] : teamProv.teams.first,
                            );

                            return MatchTile(
                              match: m,
                              teamA: teamA,
                              teamB: teamB,
                              inningsList: matchProv.getInningsForMatch(m.id),
                              onContinueScoring: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => LiveScoringScreen(matchId: m.id),
                                  ),
                                );
                                if (context.mounted) {
                                  context.read<MatchProvider>().loadMatches(silent: true);
                                }
                              },
                              onViewScorecard: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => MatchDetailScreen(matchId: m.id),
                                  ),
                                );
                                if (context.mounted) {
                                  context.read<MatchProvider>().loadMatches(silent: true);
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
